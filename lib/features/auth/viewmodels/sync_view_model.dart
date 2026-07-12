import 'package:flutter/foundation.dart';

import '../data/auth_exception.dart';
import '../service/auth_service.dart';

/// Mode du formulaire de synchronisation.
enum AuthMode { login, register }

/// État de l'écran de synchronisation (opt-in). Pilote l'inscription / connexion
/// OPAQUE et l'état de session, sans jamais transmettre le mot de passe au serveur.
class SyncViewModel extends ChangeNotifier {
  final AuthService _authService;

  SyncViewModel({required AuthService authService})
    : _authService = authService;

  AuthMode _mode = AuthMode.login;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  String? _error;

  AuthMode get mode => _mode;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Charge l'état de session initial (token présent ?).
  Future<void> initialize() async {
    _isLoggedIn = await _authService.isLoggedIn();
    notifyListeners();
  }

  /// Bascule entre connexion et inscription.
  void setMode(AuthMode mode) {
    if (_mode == mode || _isLoading) return;
    _mode = mode;
    _error = null;
    notifyListeners();
  }

  /// Soumet le formulaire (inscription puis connexion, ou connexion directe).
  Future<void> submit({
    required String username,
    required String password,
  }) async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    final handle = username.trim();
    try {
      if (_mode == AuthMode.register) {
        await _authService.register(handle, password);
      }
      // Établit la session (après inscription ou directement à la connexion).
      await _authService.login(handle, password);
      _isLoggedIn = true;
    } on AuthException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'Une erreur inattendue est survenue.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Déconnecte (efface la session locale).
  Future<void> logout() async {
    await _authService.logout();
    _isLoggedIn = false;
    _error = null;
    notifyListeners();
  }
}
