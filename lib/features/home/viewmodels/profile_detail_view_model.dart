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

  /// Emails de l'enregistrement courant (décodés du JSON), pour pré-remplir
  /// les champs en mode édition.
  List<String> get emails => _decodeList(_current?.emails);

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

  bool hasChanges({required String name, required List<String> emails}) {
    final cleaned = _cleanEmails(emails);
    final profile = _current;
    if (profile == null) return name.isNotEmpty || cleaned.isNotEmpty;
    return name.trim() != profile.name ||
        !listEquals(cleaned, this.emails);
  }

  Future<bool> save({required String name, required List<String> emails}) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      _errorMessage = 'Veuillez saisir un nom de profil.';
      notifyListeners();
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Préserve les champs non encore éditables (usernames, téléphones,
      // couleur, note) en repartant de l'enregistrement courant.
      final existing = _current;
      await _repository.updateProfile(
        _profileId,
        ProfileDraft(
          name: trimmedName,
          emails: _cleanEmails(emails),
          usernames: _decodeList(existing?.usernames),
          phoneNumbers: _decodeList(existing?.phoneNumbers),
          color: existing?.color,
          note: existing?.note,
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

  List<String> _cleanEmails(List<String> emails) => emails
      .map((email) => email.trim())
      .where((email) => email.isNotEmpty)
      .toList();

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
