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

  /// Brouillon pré-rempli depuis l'enregistrement courant (pour l'édition).
  CredentialDraft? get currentDraft {
    final c = _current?.credential;
    return c == null ? null : _draftFrom(c);
  }

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

  /// Indique si le brouillon saisi diffère de l'enregistrement courant.
  bool hasChanges(CredentialDraft draft) {
    final credential = _current?.credential;
    if (credential == null) {
      return draft.title.isNotEmpty ||
          (draft.username ?? '').isNotEmpty ||
          (draft.password ?? '').isNotEmpty ||
          (draft.uri ?? '').isNotEmpty ||
          (draft.notes ?? '').isNotEmpty ||
          draft.customFields.isNotEmpty;
    }
    return draft.title.trim() != credential.title ||
        (draft.username ?? '') != (credential.username ?? '') ||
        (draft.password ?? '') != (credential.password ?? '') ||
        (draft.uri ?? '') != (credential.uri ?? '') ||
        (draft.notes ?? '') != (credential.notes ?? '') ||
        draft.favorite != credential.favorite ||
        draft.profileId != credential.profileId ||
        !_sameCustomFields(draft.customFields, credential.customFields);
  }

  bool _sameCustomFields(List<CustomField> draft, String? rawExisting) {
    final existing = CustomField.decode(rawExisting);
    if (draft.length != existing.length) return false;
    for (var i = 0; i < draft.length; i++) {
      if (draft[i].label != existing[i].label ||
          draft[i].value != existing[i].value ||
          draft[i].secret != existing[i].secret) {
        return false;
      }
    }
    return true;
  }

  Future<bool> save(CredentialDraft draft) async {
    if (draft.title.trim().isEmpty) {
      _errorMessage = 'Veuillez saisir un titre.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateCredential(_credentialId, draft);
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

  /// Bascule l'état favori et enregistre immédiatement (action rapide).
  Future<void> toggleFavorite() async {
    final credential = _current?.credential;
    if (credential == null) return;
    await _repository.updateCredential(
      _credentialId,
      _draftFrom(credential, favorite: !credential.favorite),
    );
  }

  /// Construit un brouillon à partir de l'enregistrement courant, en
  /// surchargeant éventuellement le favori.
  CredentialDraft _draftFrom(Credential c, {bool? favorite}) => CredentialDraft(
    title: c.title,
    username: c.username,
    password: c.password,
    uri: c.uri,
    notes: c.notes,
    customFields: CustomField.decode(c.customFields),
    favorite: favorite ?? c.favorite,
    profileId: c.profileId,
  );

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
