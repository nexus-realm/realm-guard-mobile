import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/vault_repository.dart';
import '../data/profile_deletion_strategy.dart';
import '../data/profile_draft.dart';

/// ViewModel de la page détail/édition d'un profil.
///
/// Charge le profil de façon réactive, gère la bascule lecture ⇄ édition, le
/// suivi des modifications non enregistrées et les actions enregistrer /
/// supprimer. La suppression expose le nombre d'identifiants liés afin que la
/// vue propose le choix dissocier / supprimer en cascade.
class ProfileDetailViewModel extends ChangeNotifier {
  ProfileDetailViewModel({
    required ProfileEditor repository,
    required int profileId,
  }) : _repository = repository,
       _profileId = profileId;

  final ProfileEditor _repository;
  final int _profileId;

  StreamSubscription<Profile?>? _sub;

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

  Profile? _current;
  Profile? get current => _current;

  bool get notFound => !_isLoading && _current == null && !_deleted;

  /// Emails de l'enregistrement courant (décodés du JSON).
  List<String> get emails => _decodeList(_current?.emails);

  /// Noms d'utilisateur / téléphones de l'enregistrement courant.
  List<String> get usernames => _decodeList(_current?.usernames);
  List<String> get phoneNumbers => _decodeList(_current?.phoneNumbers);

  /// Brouillon pré-rempli depuis l'enregistrement courant (pour l'édition).
  ProfileDraft? get currentDraft {
    final p = _current;
    return p == null
        ? null
        : ProfileDraft(
            name: p.name,
            emails: emails,
            usernames: usernames,
            phoneNumbers: phoneNumbers,
            color: p.color,
            note: p.note,
          );
  }

  /// Décode une colonne JSON contenant un tableau de chaînes. Tolérant.
  static List<String> _decodeList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<String>().toList();
      }
    } catch (_) {
      // Format inattendu : on retourne une liste vide.
    }
    return const [];
  }

  Future<void> initialize() async {
    _sub = _repository.watchProfile(_profileId).listen((value) {
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

  bool hasChanges(ProfileDraft draft) {
    final profile = _current;
    if (profile == null) {
      return draft.name.isNotEmpty ||
          draft.emails.isNotEmpty ||
          draft.usernames.isNotEmpty ||
          draft.phoneNumbers.isNotEmpty ||
          draft.color != null ||
          (draft.note ?? '').isNotEmpty;
    }
    return draft.name.trim() != profile.name ||
        !listEquals(draft.emails, emails) ||
        !listEquals(draft.usernames, usernames) ||
        !listEquals(draft.phoneNumbers, phoneNumbers) ||
        draft.color != profile.color ||
        (draft.note ?? '') != (profile.note ?? '');
  }

  Future<bool> save(ProfileDraft draft) async {
    if (draft.name.trim().isEmpty) {
      _errorMessage = 'Veuillez saisir un nom de profil.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.updateProfile(_profileId, draft);
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

  /// Nombre d'identifiants rattachés à ce profil (pour la popup de suppression).
  Future<int> linkedCredentialsCount() =>
      _repository.countCredentialsForProfile(_profileId);

  Future<bool> delete(ProfileDeletionStrategy strategy) async {
    _isSubmitting = true;
    notifyListeners();
    try {
      await _repository.deleteProfile(_profileId, strategy);
      _deleted = true;
      return true;
    } catch (_) {
      _errorMessage = 'Impossible de supprimer ce profil.';
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
