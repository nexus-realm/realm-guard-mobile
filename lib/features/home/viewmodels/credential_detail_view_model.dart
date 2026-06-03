import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/vault_repository.dart';
import '../data/credential_draft.dart';
import '../data/custom_field.dart';

/// ViewModel de la page détail/édition d'un identifiant.
///
/// Charge l'identifiant de façon réactive, gère la bascule lecture ⇄ édition,
/// le suivi des modifications non enregistrées (pour confirmer l'abandon) et
/// les actions d'enregistrement / suppression.
class CredentialDetailViewModel extends ChangeNotifier {
  CredentialDetailViewModel({
    required CredentialEditor repository,
    required int credentialId,
  }) : _repository = repository,
       _credentialId = credentialId;

  final CredentialEditor _repository;
  final int _credentialId;

  StreamSubscription<CredentialWithProfile?>? _sub;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isEditing = false;
  bool get isEditing => _isEditing;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  bool _deleted = false;
  bool get deleted => _deleted;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  CredentialWithProfile? _current;
  CredentialWithProfile? get current => _current;

  List<Profile> _profiles = const [];
  List<Profile> get profiles => _profiles;

  /// `true` si l'identifiant n'existe plus (supprimé hors de cet écran).
  bool get notFound => !_isLoading && _current == null && !_deleted;

  Future<void> initialize() async {
    _profiles = await _repository.getAllProfiles();
    _sub = _repository.watchCredential(_credentialId).listen((value) {
      _current = value;
      _isLoading = false;
      notifyListeners();
    });
  }

  void startEditing() {
    _isEditing = true;
    _errorMessage = null;
    notifyListeners();
  }

  void cancelEditing() {
    _isEditing = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Indique si les valeurs saisies diffèrent de l'enregistrement courant.
  bool hasChanges({
    required String title,
    required String data,
    required int? profileId,
  }) {
    final credential = _current?.credential;
    if (credential == null) return title.isNotEmpty || data.isNotEmpty;
    return title.trim() != credential.title ||
        data != (credential.notes ?? '') ||
        profileId != credential.profileId;
  }

  Future<bool> save({
    required String title,
    required String data,
    required int? profileId,
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
      // Préserve les champs non encore éditables (username, password, …) en
      // repartant de l'enregistrement courant ; seuls titre/notes/profil
      // changent à ce stade.
      final existing = _current?.credential;
      await _repository.updateCredential(
        _credentialId,
        CredentialDraft(
          title: trimmedTitle,
          username: existing?.username,
          password: existing?.password,
          uri: existing?.uri,
          notes: data,
          customFields: CustomField.decode(existing?.customFields),
          favorite: existing?.favorite ?? false,
          profileId: profileId,
        ),
      );
      _isEditing = false;
      return true;
    } catch (_) {
      _errorMessage = 'Impossible d\'enregistrer les modifications.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> delete() async {
    _isSubmitting = true;
    notifyListeners();
    try {
      await _repository.deleteCredential(_credentialId);
      _deleted = true;
      return true;
    } catch (_) {
      _errorMessage = 'Impossible de supprimer cet identifiant.';
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
