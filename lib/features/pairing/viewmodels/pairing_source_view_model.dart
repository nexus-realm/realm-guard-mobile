import 'package:flutter/foundation.dart';

import '../data/pairing_exception.dart';
import '../service/pairing_service.dart';

/// État de l'écran « ajouter un appareil » (**appareil source**).
///
/// Sur un QR scanné : confirmation d'identité (biométrie ou code de l'appareil),
/// scellage + dépôt de la VaultKey, puis affichage du SAS. L'inscription de
/// l'appareil au registre du compte n'a lieu qu'**après confirmation du SAS** par
/// l'utilisateur : la clé provient du QR, donc un QR substitué (MITM) ferait sinon
/// inscrire l'appareil de l'attaquant.
class PairingSourceViewModel extends ChangeNotifier {
  PairingSourceViewModel({
    required PairingApi service,
    required Uint8List? Function() vaultKeyProvider,
    required Future<String> Function() accountIdProvider,
    required Future<bool> Function() authorize,
    String deviceName = 'Appareil appairé',
  }) : _service = service,
       _vaultKeyProvider = vaultKeyProvider,
       _accountIdProvider = accountIdProvider,
       _authorize = authorize,
       _deviceName = deviceName;

  final PairingApi _service;
  final Uint8List? Function() _vaultKeyProvider;
  final Future<String> Function() _accountIdProvider;
  final Future<bool> Function() _authorize;
  final String _deviceName;

  bool _busy = false;
  String? _sas;
  Uint8List? _devicePublicKey;
  bool _registered = false;
  String? _error;

  bool get busy => _busy;

  /// SAS à comparer avec le nouvel appareil (non nul ⇒ attente de confirmation).
  String? get sas => _sas;

  /// L'utilisateur a confirmé le SAS et l'appareil est inscrit au compte.
  bool get registered => _registered;

  String? get error => _error;

  /// Traite un QR scanné : gate d'autorisation, puis scellage + dépôt. Ignore les
  /// scans suivants une fois le SAS obtenu ou une opération en cours.
  Future<void> onQrScanned(String qrPayload) async {
    if (_busy || _sas != null) return;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final vaultKey = _vaultKeyProvider();
      if (vaultKey == null) {
        _error = 'Coffre verrouillé.';
        return;
      }

      // L'authentification peut **lever** (aucun verrouillage configuré, biométrie
      // indisponible…) : on distingue ce cas d'un simple refus de l'utilisateur.
      final bool authorized;
      try {
        authorized = await _authorize();
      } catch (error, stack) {
        _logFailure('authentification', error, stack);
        _error =
            "Authentification impossible : configurez un verrouillage de l'appareil "
            '(code ou empreinte), puis réessayez.';
        return;
      }
      if (!authorized) {
        _error = 'Autorisation refusée.';
        return;
      }

      final accountId = await _accountIdProvider();
      final outcome = await _service.pairScannedDevice(
        qrPayload: qrPayload,
        accountId: accountId,
        vaultKey: vaultKey,
      );
      _sas = outcome.sas;
      _devicePublicKey = outcome.devicePublicKey;
    } on PairingException catch (error) {
      _error = error.message;
    } catch (error, stack) {
      _logFailure('pairing', error, stack);
      _error = 'Une erreur inattendue est survenue.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// L'utilisateur confirme que les deux SAS correspondent → inscrit l'appareil au
  /// registre du compte. **Seul chemin** vers l'inscription.
  Future<void> confirmSas() async {
    final devicePublicKey = _devicePublicKey;
    if (_busy || _registered || devicePublicKey == null) return;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await _service.registerPairedDevice(
        devicePublicKey: devicePublicKey,
        name: _deviceName,
      );
      _registered = true;
    } on PairingException catch (error) {
      _error = error.message;
    } catch (error, stack) {
      _logFailure('inscription', error, stack);
      _error = 'Une erreur inattendue est survenue.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Les SAS diffèrent → **rien n'est inscrit**. La VaultKey a en revanche déjà été
  /// déposée (limite du protocole à un tour) : on alerte explicitement.
  void rejectSas() {
    _sas = null;
    _devicePublicKey = null;
    _error =
        'Codes différents : appareil NON autorisé. Le pairing a peut-être été '
        'intercepté — changez votre mot de passe maître par précaution.';
    notifyListeners();
  }

  /// Ne jamais avaler une erreur en silence : en debug on la trace, sinon on reste
  /// aveugle sur l'écran (« erreur inattendue » sans aucun log).
  void _logFailure(String stage, Object error, StackTrace stack) {
    if (kDebugMode) {
      debugPrint('[pairing] échec ($stage) : $error\n$stack');
    }
  }
}
