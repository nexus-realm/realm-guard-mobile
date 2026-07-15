import 'package:flutter/foundation.dart';

import '../data/pairing_exception.dart';
import '../service/pairing_service.dart';

/// État de l'écran « ajouter un appareil » (**appareil source**) : sur un QR scanné,
/// demande une **confirmation d'identité** (biométrie, ou code de l'appareil en
/// repli), scelle la VaultKey et la dépose, puis expose le SAS à comparer.
class PairingSourceViewModel extends ChangeNotifier {
  PairingSourceViewModel({
    required PairingApi service,
    required Uint8List? Function() vaultKeyProvider,
    required Future<bool> Function() authorize,
  }) : _service = service,
       _vaultKeyProvider = vaultKeyProvider,
       _authorize = authorize;

  final PairingApi _service;
  final Uint8List? Function() _vaultKeyProvider;
  final Future<bool> Function() _authorize;

  bool _busy = false;
  String? _sas;
  String? _error;

  bool get busy => _busy;
  String? get sas => _sas;
  String? get error => _error;

  /// Traite un QR scanné : gate biométrique, puis scellage + dépôt. Ignore les scans
  /// suivants une fois le pairing réussi ou en cours.
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

      _sas = await _service.pairScannedDevice(
        qrPayload: qrPayload,
        vaultKey: vaultKey,
      );
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

  /// Ne jamais avaler une erreur en silence : en debug on la trace, sinon on reste
  /// aveugle sur l'écran (« erreur inattendue » sans aucun log).
  void _logFailure(String stage, Object error, StackTrace stack) {
    if (kDebugMode) {
      debugPrint('[pairing] échec ($stage) : $error\n$stack');
    }
  }
}
