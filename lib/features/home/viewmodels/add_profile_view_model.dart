import 'package:flutter/foundation.dart';

import '../../../core/database/vault_repository.dart';
import '../data/profile_draft.dart';

/// ViewModel de la page d'ajout de profil.
class AddProfileViewModel extends ChangeNotifier {
  final VaultEditor _repository;

  AddProfileViewModel(this._repository);

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Enregistre un profil. Retourne `true` en cas de succès.
  /// Le nom est requis.
  Future<bool> submit(ProfileDraft draft) async {
    if (draft.name.trim().isEmpty) {
      _errorMessage = 'Veuillez saisir un nom de profil.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.addProfile(draft);
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
