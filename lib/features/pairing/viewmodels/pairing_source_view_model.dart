import 'package:flutter/foundation.dart';

import '../data/pairing_exception.dart';
import '../service/pairing_service.dart';

/// État de l'écran « ajouter un appareil » (**appareil source**), protocole en **deux
/// tours**.
///
/// Sur un QR scanné : confirmation d'identité (biométrie ou code), puis **tour 1** —
/// on dépose seulement une clé publique et on affiche le SAS. **Rien de sensible
/// n'est parti.** Ce n'est qu'à [confirmSas] que la VaultKey est scellée et déposée,
/// puis l'appareil inscrit au compte. Sur un QR substitué (MITM), les SAS divergent :
/// l'utilisateur ne confirme pas, et l'attaquant n'obtient **rien**.
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
  PairingSourceHandshake? _handshake;
  bool _completed = false;
  String? _error;

  bool get busy => _busy;

  /// SAS à comparer (non nul ⇒ tour 1 fait, en attente de confirmation).
  String? get sas => _handshake?.sas;

  /// VaultKey transmise **et** appareil inscrit : le pairing est terminé.
  bool get completed => _completed;

  String? get error => _error;

  /// Traite un QR scanné : gate d'autorisation, puis **tour 1** (dépôt de la clé
  /// publique + SAS). Ignore les scans suivants une fois le tour 1 fait.
  Future<void> onQrScanned(String qrPayload) async {
    if (_busy || _handshake != null) return;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      if (_vaultKeyProvider() == null) {
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

      _handshake = await _service.beginPairing(qrPayload: qrPayload);
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

  /// L'utilisateur confirme que les deux SAS correspondent → **tour 2** : scellage +
  /// dépôt de la VaultKey, puis inscription de l'appareil. **Seul chemin** par lequel
  /// la VaultKey quitte cet appareil.
  Future<void> confirmSas() async {
    final handshake = _handshake;
    if (_busy || _completed || handshake == null) return;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final vaultKey = _vaultKeyProvider();
      if (vaultKey == null) {
        _error = 'Coffre verrouillé.';
        return;
      }
      final accountId = await _accountIdProvider();
      await _service.sealVaultKey(
        handshake: handshake,
        accountId: accountId,
        vaultKey: vaultKey,
      );
      await _service.registerPairedDevice(
        devicePublicKey: handshake.devicePublicKey,
        name: _deviceName,
      );
      _completed = true;
    } on PairingException catch (error) {
      _error = error.message;
    } catch (error, stack) {
      _logFailure('transfert', error, stack);
      _error = 'Une erreur inattendue est survenue.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  /// Les SAS diffèrent → on abandonne. **Rien n'a été transmis** : ni VaultKey, ni
  /// inscription. C'est tout l'intérêt du protocole en deux tours.
  void rejectSas() {
    _handshake = null;
    _error =
        'Codes différents : pairing abandonné. Aucune donnée transmise. '
        "Recommencez, et assurez-vous de scanner l'écran du bon appareil.";
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
