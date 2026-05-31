import 'package:flutter/foundation.dart';

import '../../../core/database/vault_repository.dart';

/// ViewModel de la page d'ajout de profil.
class AddProfileViewModel extends ChangeNotifier {
  final VaultEditor _repository;

  AddProfileViewModel(this._repository);

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Enregistre un profil. Retourne `true` en cas de succès.
  /// Le nom est requis ; les emails vides sont ignorés.
  Future<bool> submit(String name, List<String> emails) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      _errorMessage = 'Veuillez saisir un nom de profil.';
      notifyListeners();
      return false;
    }

    final cleanedEmails = emails
        .map((email) => email.trim())
        .where((email) => email.isNotEmpty)
        .toList();

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.addProfile(trimmedName, cleanedEmails);
      return true;
    } catch (_) {
      _errorMessage =
          'Impossible d\'enregistrer le profil. Veuillez réessayer.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
