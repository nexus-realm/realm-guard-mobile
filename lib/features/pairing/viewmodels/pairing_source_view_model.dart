import 'package:flutter/foundation.dart';

import '../data/pairing_exception.dart';
import '../service/pairing_service.dart';

/// État de l'écran « ajouter un appareil » (**appareil source**) : sur un QR scanné,
/// demande une **confirmation biométrique**, scelle la VaultKey et la dépose, puis
/// expose le SAS à comparer.
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
      if (!await _authorize()) {
        _error = 'Autorisation biométrique refusée.';
        return;
      }
      _sas = await _service.pairScannedDevice(
        qrPayload: qrPayload,
        vaultKey: vaultKey,
      );
    } on PairingException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Une erreur inattendue est survenue.';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }
}
