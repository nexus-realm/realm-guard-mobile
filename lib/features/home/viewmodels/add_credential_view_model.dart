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
  /// Le titre est requis ; le profil associé est optionnel.
  Future<bool> submit({
    required String title,
    required String data,
    int? profileId,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      _errorMessage = 'Veuillez saisir un titre.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.addCredential(
        CredentialDraft(title: trimmedTitle, notes: data, profileId: profileId),
      );
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
