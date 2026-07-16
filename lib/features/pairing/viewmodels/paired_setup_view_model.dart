import 'package:flutter/foundation.dart';

import '../../onboarding/data/onboarding_step.dart';
import '../../onboarding/service/onboarding_storage_service.dart';
import '../data/pairing_exception.dart';
import '../service/pairing_service.dart';

/// Flux « **lier cet appareil** » à l'onboarding : reçoit la VaultKey par pairing,
/// puis l'installe en coffre local protégé par un **mot de passe local** — propre à
/// cet appareil, ce n'est **pas** le mot de passe maître du compte.
class PairedSetupViewModel extends ChangeNotifier {
  PairedSetupViewModel({
    required PairingApi pairing,
    required Future<void> Function(List<int> vaultKey, String password) install,
    required OnboardingStorageService onboardingStorage,
  }) : _pairing = pairing,
       _install = install,
       _onboardingStorage = onboardingStorage;

  final PairingApi _pairing;
  final Future<void> Function(List<int> vaultKey, String password) _install;
  final OnboardingStorageService _onboardingStorage;

  PairingSession? _session;
  bool _waiting = false;
  String? _sas;
  Uint8List? _vaultKey;
  bool _submitting = false;
  bool _installed = false;
  String? _error;

  /// QR à afficher (phase 1).
  String? get qrPayload => _session?.qrPayload;

  /// En attente du transfert depuis l'appareil source ?
  bool get waiting => _waiting;

  /// SAS reçu : non nul ⇒ VaultKey reçue → on passe au code local (phase 2).
  String? get sas => _sas;

  bool get submitting => _submitting;

  /// Coffre installé : l'onboarding peut reprendre (biométrie…).
  bool get installed => _installed;

  String? get error => _error;

  /// **Phase 1** — affiche le QR et attend le transfert depuis l'appareil source.
  Future<void> startPairing() async {
    if (_waiting || _sas != null) return;
    _session = await _pairing.startNewDevice();
    if (kDebugMode) {
      // Permet de récupérer le payload depuis la console de l'hôte quand le
      // presse-papiers ne traverse pas entre deux émulateurs.
      debugPrint('[pairing] QR payload: ${_session!.qrPayload}');
    }
    _waiting = true;
    _error = null;
    notifyListeners();
    try {
      final receipt = await _pairing.receiveVaultKey(_session!);
      _vaultKey = receipt.vaultKey;
      _sas = receipt.sas;
    } on PairingException catch (error) {
      _error = error.message;
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('[pairing] échec (réception) : $error\n$stack');
      }
      _error = 'Une erreur inattendue est survenue.';
    } finally {
      _waiting = false;
      notifyListeners();
    }
  }

  /// **Phase 2** — installe le coffre sous un mot de passe **local**. Renvoie `true`
  /// en cas de succès (l'onboarding reprend alors à l'étape suivante).
  Future<bool> installVault(String password, String confirmation) async {
    final vaultKey = _vaultKey;
    if (vaultKey == null || _submitting) return false;

    final normalized = password.trim();
    final normalizedConfirmation = confirmation.trim();

    if (normalized.isEmpty || normalizedConfirmation.isEmpty) {
      _error = 'Veuillez remplir les deux champs du mot de passe.';
      notifyListeners();
      return false;
    }
    if (normalized.length < 12) {
      _error = 'Le mot de passe doit contenir au moins 12 caractères.';
      notifyListeners();
      return false;
    }
    if (normalized != normalizedConfirmation) {
      _error = 'Les mots de passe saisis ne correspondent pas.';
      notifyListeners();
      return false;
    }

    _submitting = true;
    _error = null;
    notifyListeners();

    try {
      await _install(vaultKey, normalized);
      await _authenticateQuietly();
      await _markOnboardingSteps();
      _installed = true;
      return true;
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('[pairing] échec (installation) : $error\n$stack');
      }
      _error = "Impossible d'installer le coffre sur cet appareil. Réessayez.";
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  /// Ouvre une session d'appareil (challenge-response Ed25519). **Best-effort** : au
  /// moment de l'installation, la source n'a en général pas encore inscrit cet
  /// appareil (elle ne le fait qu'après confirmation du SAS) → l'auth échoue et sera
  /// retentée plus tard. Un échec ne doit jamais empêcher l'installation du coffre.
  Future<void> _authenticateQuietly() async {
    try {
      await _pairing.authenticateDevice();
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('[pairing] session appareil non obtenue : $error\n$stack');
      }
    }
  }

  /// Le pairing résout le choix de synchronisation (« lier un appareil ») **et**
  /// fournit le coffre : il satisfait donc « accueil », « synchronisation » et
  /// « mot de passe maître » (remplacé par le mot de passe local du pairing).
  /// L'onboarding reprend à la biométrie.
  Future<void> _markOnboardingSteps() async {
    var progress = await _onboardingStorage.loadProgress();
    progress = progress.markStepCompleted(OnboardingStep.welcome);
    progress = progress.markStepCompleted(OnboardingStep.syncChoice);
    progress = progress.markStepCompleted(OnboardingStep.masterPassword);
    await _onboardingStorage.saveProgress(progress);
  }
}
