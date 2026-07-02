import 'package:flutter/foundation.dart';
import 'package:flutter_autofill_service/flutter_autofill_service.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/vault_repository.dart';
import '../../../core/security/unlock_service.dart';
import '../../../core/security/vault_service.dart';
import '../data/autofill_matcher.dart';
import '../service/autofill_gateway.dart';

/// Étape courante du flux de remplissage automatique.
enum AutofillFillStage {
  loading,
  unlocking,
  needsPassword,
  picking,
  submitting,
  locked,
  invalidRequest,
  error,
}

/// Orchestration du remplissage interactif (lot 2) : vérifie la requête,
/// déverrouille le coffre (biométrie → mot de passe, avec la même politique de
/// lockout que l'écran de déverrouillage), fait correspondre les identifiants à
/// l'app/au site demandé, puis renvoie le choix à l'OS.
///
/// S'exécute dans l'isolate de `autofillEntryPoint` : il possède sa propre
/// instance de [VaultService] et referme la base à la destruction.
class AutofillFillViewModel extends ChangeNotifier {
  AutofillFillViewModel({
    required AutofillGateway gateway,
    VaultService? vaultService,
    UnlockService? unlockService,
  }) : _gateway = gateway,
       _vaultService = vaultService ?? VaultService() {
    _unlockService =
        unlockService ?? UnlockService(vaultService: _vaultService);
  }

  final AutofillGateway _gateway;
  final VaultService _vaultService;
  late final UnlockService _unlockService;

  AutofillFillStage _stage = AutofillFillStage.loading;
  AutofillFillStage get stage => _stage;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Duration _lockoutRemaining = Duration.zero;
  Duration get lockoutRemaining => _lockoutRemaining;

  Set<String> _requestedDomains = const {};

  /// Domaine demandé (pour l'en-tête), ou `null` si l'origine est une app native
  /// sans domaine fiable.
  String? get requestedDomain =>
      _requestedDomains.isNotEmpty ? _requestedDomains.first : null;

  List<Credential> _matched = const [];

  /// Identifiants correspondant au site demandé (proposés en premier).
  List<Credential> get matched => _matched;

  List<Credential> _all = const [];

  /// Tous les identifiants (pour la recherche / le repli).
  List<Credential> get all => _all;

  Future<void> initialize() async {
    try {
      final interactive = await _gateway.isInteractiveFillRequest();
      final metadata = await _gateway.fillMetadata();

      // v1 : remplissage interactif uniquement (ni requête de sauvegarde, ni
      // lancement hors contexte de remplissage).
      if (!interactive || metadata?.saveInfo != null) {
        _setStage(AutofillFillStage.invalidRequest);
        return;
      }

      // Domaines demandés = domaines web + domaines déduits du nom de paquet de
      // l'app native (heuristique reverse-DNS), pour proposer le bon identifiant
      // aussi bien sur un site que dans une application.
      _requestedDomains = <String>{
        ...?metadata?.webDomains.map((d) => d.domain),
        ...AutofillMatcher.domainsFromPackages(
          metadata?.packageNames ?? const {},
        ),
      };

      final strategy = await _unlockService.determineUnlockStrategy();
      if (strategy == UnlockStrategy.biometric) {
        await attemptBiometric();
      } else {
        _setStage(AutofillFillStage.needsPassword);
      }
    } catch (_) {
      _errorMessage = 'Une erreur est survenue.';
      _setStage(AutofillFillStage.error);
    }
  }

  Future<void> attemptBiometric() async {
    _setStage(AutofillFillStage.unlocking);
    final (result, ok) = await _unlockService.attemptBiometricUnlock();
    if (ok) {
      await _loadCredentials();
    } else if (result == UnlockAttemptResult.locked) {
      await _enterLockout();
    } else {
      _setStage(AutofillFillStage.needsPassword);
    }
  }

  Future<void> unlockWithPassword(String password) async {
    if (password.trim().isEmpty) {
      _errorMessage = 'Veuillez saisir votre mot de passe maître.';
      notifyListeners();
      return;
    }
    _errorMessage = null;
    _setStage(AutofillFillStage.unlocking);
    final (result, locked) = await _unlockService.attemptPasswordUnlock(
      password,
    );
    if (result == UnlockAttemptResult.success) {
      await _loadCredentials();
    } else if (result == UnlockAttemptResult.locked || locked) {
      await _enterLockout();
    } else {
      _errorMessage = 'Mot de passe incorrect.';
      _setStage(AutofillFillStage.needsPassword);
    }
  }

  Future<void> _loadCredentials() async {
    final repo = VaultRepository(_vaultService.db);
    final creds = await repo.getAllCredentials();
    creds.sort(
      (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    );
    _all = creds;
    _matched = AutofillMatcher.matchByDomain(creds, _requestedDomains);
    _setStage(AutofillFillStage.picking);
  }

  /// Renvoie l'identifiant choisi à l'OS (qui remplit le champ et ferme l'écran).
  Future<void> select(Credential credential) async {
    _setStage(AutofillFillStage.submitting);
    await _gateway.submit(
      PwDataset(
        label: credential.title,
        username: credential.username ?? '',
        password: credential.password ?? '',
      ),
    );
  }

  Future<void> _enterLockout() async {
    _lockoutRemaining = await _unlockService.getRemainingLockout();
    _setStage(AutofillFillStage.locked);
  }

  void _setStage(AutofillFillStage stage) {
    _stage = stage;
    notifyListeners();
  }

  @override
  void dispose() {
    // Referme la base chiffrée ouverte dans cet isolate.
    _vaultService.lockVault();
    super.dispose();
  }
}
