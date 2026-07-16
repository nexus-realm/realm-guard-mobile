import 'package:flutter/foundation.dart';

import '../data/pairing_exception.dart';
import '../service/devices_service.dart';

/// État de l'écran « Appareils » : liste du registre du compte, renommage et
/// révocation. « Cet appareil » est marqué pour éviter une auto-révocation subie.
class DevicesViewModel extends ChangeNotifier {
  DevicesViewModel({required DevicesApi service}) : _service = service;

  final DevicesApi _service;

  List<PairedDevice> _devices = const [];
  bool _loading = false;
  bool _busy = false;
  String? _error;

  List<PairedDevice> get devices => _devices;
  bool get loading => _loading;

  /// Une action (renommage / révocation) est en cours.
  bool get busy => _busy;

  String? get error => _error;

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _devices = await _service.list();
    } on PairingException catch (error) {
      _error = error.message;
    } catch (error, stack) {
      _logFailure('liste', error, stack);
      _error = 'Une erreur inattendue est survenue.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Renomme un appareil puis rafraîchit la liste. Renvoie `true` au succès.
  Future<bool> rename(String deviceId, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      _error = 'Le nom ne peut pas être vide.';
      notifyListeners();
      return false;
    }
    return _run(() => _service.rename(deviceId, trimmed), 'renommage');
  }

  /// Révoque un appareil puis rafraîchit la liste. Renvoie `true` au succès.
  Future<bool> revoke(String deviceId) =>
      _run(() => _service.revoke(deviceId), 'révocation');

  Future<bool> _run(Future<void> Function() action, String stage) async {
    if (_busy) return false;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
      _devices = await _service.list();
      return true;
    } on PairingException catch (error) {
      _error = error.message;
      return false;
    } catch (error, stack) {
      _logFailure(stage, error, stack);
      _error = 'Une erreur inattendue est survenue.';
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void _logFailure(String stage, Object error, StackTrace stack) {
    if (kDebugMode) {
      debugPrint('[devices] échec ($stage) : $error\n$stack');
    }
  }
}
