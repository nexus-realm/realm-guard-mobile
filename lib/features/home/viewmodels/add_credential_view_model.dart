import 'package:flutter/foundation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/vault_repository.dart';
import '../data/credential_draft.dart';

/// ViewModel de la page d'ajout d'identifiant.
class AddCredentialViewModel extends ChangeNotifier {
  final VaultEditor _repository;

  AddCredentialViewModel(this._repository);

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Profile> _profiles = const [];
  List<Profile> get profiles => _profiles;

  /// Charge les profils disponibles pour l'association (menu déroulant).
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    try {
      _profiles = await _repository.getAllProfiles();
    } catch (_) {
      _profiles = const [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Enregistre un identifiant. Retourne `true` en cas de succès.
  /// Le titre est requis ; les autres champs sont optionnels.
  Future<bool> submit(CredentialDraft draft) async {
    if (draft.title.trim().isEmpty) {
      _errorMessage = 'Veuillez saisir un titre.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.addCredential(draft);
      return true;
    } catch (_) {
      _errorMessage =
          'Impossible d\'enregistrer l\'identifiant. Veuillez réessayer.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
