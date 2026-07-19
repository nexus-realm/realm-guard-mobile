import 'package:flutter/foundation.dart';

import '../../../core/security/vault_service.dart';
import '../../../core/security/password_validation_rules.dart';

/// ViewModel de la page de changement du mot de passe maître.
class ChangePasswordViewModel extends ChangeNotifier {
  ChangePasswordViewModel({required VaultService vaultService})
    : _vaultService = vaultService;

  final VaultService _vaultService;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _success = false;
  bool get success => _success;

  /// Valide les saisies puis change le mot de passe. Retourne `true` en cas de
  /// succès.
  Future<bool> submit({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    final current = currentPassword.trim();
    final next = newPassword.trim();
    final confirm = confirmation.trim();

    if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
      return _fail('Veuillez remplir tous les champs.');
    }
    if (!_isStrong(next)) {
      return _fail('Le nouveau mot de passe ne respecte pas les conditions.');
    }
    if (next != confirm) {
      return _fail('Les nouveaux mots de passe ne correspondent pas.');
    }
    if (next == current) {
      return _fail('Le nouveau mot de passe doit être différent de l\'actuel.');
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _vaultService.changeMasterPassword(
        currentPassword: current,
        newPassword: next,
      );
      switch (result) {
        case ChangePasswordResult.success:
          _success = true;
          return true;
        case ChangePasswordResult.wrongCurrentPassword:
          return _fail('Le mot de passe actuel est incorrect.');
        case ChangePasswordResult.vaultLocked:
          return _fail('Le coffre est verrouillé. Veuillez le déverrouiller.');
        case ChangePasswordResult.failure:
          return _fail(
            'Le changement de mot de passe a échoué. Vos données sont '
            'intactes ; réessayez.',
          );
      }
    } catch (_) {
      return _fail('Une erreur inattendue est survenue.');
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  bool _isStrong(String password) {
    final rules = PasswordValidationRules.getPasswordValidationRules(password);
    return rules.every((rule) => rule.validate(password));
  }

  bool _fail(String message) {
    _errorMessage = message;
    notifyListeners();
    return false;
  }
}
