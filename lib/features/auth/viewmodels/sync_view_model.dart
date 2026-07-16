import 'package:flutter/foundation.dart';

import '../data/auth_exception.dart';
import '../service/auth_service.dart';

/// Mode du formulaire de synchronisation.
enum AuthMode { login, register }

/// État de l'écran de synchronisation (opt-in). Pilote l'inscription / connexion
/// OPAQUE et l'état de session, sans jamais transmettre le mot de passe au serveur.
class SyncViewModel extends ChangeNotifier {
  final AuthService _authService;

  /// Sauvegarde la VaultKey enrobée sur le serveur avec la clé exportée du login.
  /// Renvoie `false` s'il n'y a rien à sauvegarder (coffre pas encore créé : à
  /// l'onboarding, le compte se crée **avant** le mot de passe maître).
  final Future<bool> Function(Uint8List exportKey) _backupVaultKey;

  SyncViewModel({
    required AuthService authService,
    required Future<bool> Function(Uint8List exportKey) backupVaultKey,
  }) : _authService = authService,
       _backupVaultKey = backupVaultKey;

  AuthMode _mode = AuthMode.login;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  bool _vaultKeyBackedUp = false;
  String? _error;

  AuthMode get mode => _mode;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;

  /// Le serveur détient une copie scellée de la VaultKey (récupération possible).
  bool get vaultKeyBackedUp => _vaultKeyBackedUp;

  String? get error => _error;

  /// Charge l'état de session initial (token présent ?) et l'état du backup.
  Future<void> initialize() async {
    _isLoggedIn = await _authService.isLoggedIn();
    if (_isLoggedIn) {
      try {
        _vaultKeyBackedUp = await _authService.hasVaultKeyBackup();
      } catch (_) {
        // Statut non critique : l'écran reste utilisable si le serveur ne répond pas.
      }
    }
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
      // Établit la session (après inscription ou directement à la connexion). La
      // clé exportée n'existe qu'ici : on en profite pour sauvegarder la VaultKey
      // plutôt que de redemander le mot de passe du compte plus tard.
      final exportKey = await _authService.login(handle, password);
      _isLoggedIn = true;
      _vaultKeyBackedUp = await _backupVaultKey(exportKey);
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
    _vaultKeyBackedUp = false;
    _error = null;
    notifyListeners();
  }
}
