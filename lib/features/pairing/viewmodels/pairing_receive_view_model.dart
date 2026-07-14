import 'package:flutter/foundation.dart';

import '../data/pairing_exception.dart';
import '../service/pairing_service.dart';

/// État de l'écran « lier cet appareil » (**nouvel appareil**) : affiche un QR,
/// attend (poll) la réponse de l'appareil source, puis expose le SAS à comparer.
class PairingReceiveViewModel extends ChangeNotifier {
  PairingReceiveViewModel({required PairingApi service}) : _service = service;

  final PairingApi _service;

  PairingSession? _session;
  bool _waiting = false;
  String? _sas;
  Uint8List? _vaultKey;
  String? _error;

  /// Contenu du QR à afficher (null tant que non démarré).
  String? get qrPayload => _session?.qrPayload;

  /// En attente de l'appareil source ?
  bool get waiting => _waiting;

  /// SAS reçu (à comparer avec l'appareil source). Non nul ⇒ pairing réussi.
  String? get sas => _sas;

  /// Message d'erreur (français) le cas échéant.
  String? get error => _error;

  /// VaultKey reçue — l'**installation** locale (déverrouillage nouvel appareil)
  /// est une intégration à venir.
  Uint8List? get vaultKey => _vaultKey;

  /// Démarre le pairing : génère le QR puis attend la réponse déposée par la source.
  Future<void> start() async {
    if (_waiting || _sas != null) return;
    _session = _service.startNewDevice();
    _waiting = true;
    _error = null;
    notifyListeners();
    try {
      final receipt = await _service.receiveVaultKey(_session!);
      _vaultKey = receipt.vaultKey;
      _sas = receipt.sas;
    } on PairingException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Une erreur inattendue est survenue.';
    } finally {
      _waiting = false;
      notifyListeners();
    }
  }
}
