import 'package:flutter/foundation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/vault_repository.dart';
import '../../../core/security/unlock_service.dart';
import '../../../core/security/vault_service.dart';
import '../../home/data/credential_draft.dart';
import '../data/autofill_matcher.dart';
import '../service/autofill_gateway.dart';

/// Étape courante du flux de sauvegarde automatique.
enum AutofillSaveStage {
  loading,
  unlocking,
  needsPassword,
  editing,
  submitting,
  saved,
  locked,
  invalid,
  error,
}

/// Orchestration de la sauvegarde (l'OS propose « Enregistrer dans Realm Guard »
/// après une connexion dans une app tierce) : déverrouille le coffre, pré-remplit
/// un brouillon d'identifiant à partir des données saisies, puis l'enregistre.
///
/// S'exécute dans l'isolate de `autofillEntryPoint` : instance propre de
/// [VaultService], base refermée à la destruction.
class AutofillSaveViewModel extends ChangeNotifier {
  AutofillSaveViewModel({
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

  AutofillSaveStage _stage = AutofillSaveStage.loading;
  AutofillSaveStage get stage => _stage;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  CredentialDraft? _initialDraft;

  /// Brouillon pré-rempli (titre/URL déduits du site ou de l'app, identifiant et
  /// mot de passe saisis) proposé à l'utilisateur avant enregistrement.
  CredentialDraft? get initialDraft => _initialDraft;

  List<Profile> _profiles = const [];
  List<Profile> get profiles => _profiles;

  String? _domain;

  /// Site/app à l'origine de la sauvegarde (pour l'en-tête), si connu.
  String? get domain => _domain;

  Future<void> initialize() async {
    try {
      final metadata = await _gateway.fillMetadata();
      final saveInfo = metadata?.saveInfo;
      if (metadata == null || saveInfo == null) {
        _setStage(AutofillSaveStage.invalid);
        return;
      }

      final webDomain = metadata.webDomains.isNotEmpty
          ? metadata.webDomains.first.domain
          : null;
      final packageDomains = AutofillMatcher.domainsFromPackages(
        metadata.packageNames,
      );
      _domain =
          webDomain ??
          (packageDomains.isNotEmpty ? packageDomains.first : null);

      _initialDraft = CredentialDraft(
        title: _domain ?? 'Nouvel identifiant',
        username: _nullIfEmpty(saveInfo.username),
        password: _nullIfEmpty(saveInfo.password),
        uri: _domain != null ? 'https://$_domain' : null,
      );

      final strategy = await _unlockService.determineUnlockStrategy();
      if (strategy == UnlockStrategy.biometric) {
        await attemptBiometric();
      } else {
        _setStage(AutofillSaveStage.needsPassword);
      }
    } catch (_) {
      _errorMessage = 'Une erreur est survenue.';
      _setStage(AutofillSaveStage.error);
    }
  }

  Future<void> attemptBiometric() async {
    _setStage(AutofillSaveStage.unlocking);
    final (result, ok) = await _unlockService.attemptBiometricUnlock();
    if (ok) {
      await _onUnlocked();
    } else if (result == UnlockAttemptResult.locked) {
      _setStage(AutofillSaveStage.locked);
    } else {
      _setStage(AutofillSaveStage.needsPassword);
    }
  }

  Future<void> unlockWithPassword(String password) async {
    if (password.trim().isEmpty) {
      _errorMessage = 'Veuillez saisir votre mot de passe maître.';
      notifyListeners();
      return;
    }
    _errorMessage = null;
    _setStage(AutofillSaveStage.unlocking);
    final (result, locked) = await _unlockService.attemptPasswordUnlock(
      password,
    );
    if (result == UnlockAttemptResult.success) {
      await _onUnlocked();
    } else if (result == UnlockAttemptResult.locked || locked) {
      _setStage(AutofillSaveStage.locked);
    } else {
      _errorMessage = 'Mot de passe incorrect.';
      _setStage(AutofillSaveStage.needsPassword);
    }
  }

  Future<void> _onUnlocked() async {
    _profiles = await VaultRepository(_vaultService.db).getAllProfiles();
    _setStage(AutofillSaveStage.editing);
  }

  /// Enregistre le brouillon dans le coffre puis signale la fin à l'OS.
  Future<bool> save(CredentialDraft draft) async {
    if (draft.title.trim().isEmpty) {
      _errorMessage = 'Veuillez saisir un titre.';
      notifyListeners();
      return false;
    }
    _setStage(AutofillSaveStage.submitting);
    try {
      await VaultRepository(
        _vaultService.db,
        crdtSession: _vaultService.ensureCrdtSession,
      ).addCredential(draft);
      await _gateway.onSaveComplete();
      _setStage(AutofillSaveStage.saved);
      return true;
    } catch (_) {
      _errorMessage = 'Impossible d\'enregistrer.';
      _setStage(AutofillSaveStage.editing);
      return false;
    }
  }

  String? _nullIfEmpty(String? value) =>
      (value == null || value.trim().isEmpty) ? null : value;

  void _setStage(AutofillSaveStage stage) {
    _stage = stage;
    notifyListeners();
  }

  @override
  void dispose() {
    _vaultService.lockVault();
    super.dispose();
  }
}
