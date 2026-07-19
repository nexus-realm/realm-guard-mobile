import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/vault_repository.dart';
import '../data/base32.dart';
import '../data/totp_draft.dart';

/// ViewModel de la page détail/édition d'un TOTP.
class TotpDetailViewModel extends ChangeNotifier {
  TotpDetailViewModel({required TotpEditor repository, required int totpId})
    : _repository = repository,
      _totpId = totpId;

  final TotpEditor _repository;
  final int _totpId;

  StreamSubscription<TotpWithProfile?>? _sub;

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

  TotpWithProfile? _current;
  TotpWithProfile? get current => _current;

  List<Profile> _profiles = const [];
  List<Profile> get profiles => _profiles;

  bool get notFound => !_isLoading && _current == null && !_deleted;

  /// Brouillon pré-rempli depuis l'enregistrement courant (pour l'édition).
  TotpDraft? get currentDraft {
    final t = _current?.totp;
    return t == null ? null : _draftFrom(t);
  }

  Future<void> initialize() async {
    _profiles = await _repository.getAllProfiles();
    _sub = _repository.watchTotp(_totpId).listen((value) {
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

  bool hasChanges(TotpDraft draft) {
    final t = _current?.totp;
    if (t == null) {
      return draft.label.isNotEmpty || draft.secret.isNotEmpty;
    }
    return draft.label.trim() != t.label ||
        (draft.account ?? '') != (t.account ?? '') ||
        draft.secret.trim() != t.secret ||
        draft.digits != t.digits ||
        draft.period != t.period ||
        draft.algorithm != t.algorithm ||
        draft.profileId != t.profileId ||
        draft.favorite != t.favorite;
  }

  Future<bool> save(TotpDraft draft) async {
    if (draft.label.trim().isEmpty) {
      return _fail('Veuillez saisir un libellé.');
    }
    if (!Base32.isValid(draft.secret)) {
      return _fail('Le secret doit être un code Base32 valide.');
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.updateTotp(_totpId, draft);
      _isEditing = false;
      return true;
    } catch (_) {
      return _fail('Impossible d\'enregistrer les modifications.');
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Réassocie le profil directement depuis la lecture seule (sans passer en
  /// mode édition), comme la fiche identifiant. Renvoie `true` en cas de succès.
  Future<bool> setProfile(int? profileId) async {
    final totp = _current?.totp;
    if (totp == null) return false;
    if (profileId == totp.profileId) return true; // pas de changement
    _isSubmitting = true;
    notifyListeners();
    try {
      await _repository.updateTotp(
        _totpId,
        TotpDraft(
          label: totp.label,
          account: totp.account,
          secret: totp.secret,
          digits: totp.digits,
          period: totp.period,
          algorithm: totp.algorithm,
          profileId: profileId,
          favorite: totp.favorite,
        ),
      );
      return true;
    } catch (_) {
      return _fail('Impossible de modifier le profil associé.');
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  Future<bool> delete() async {
    _isSubmitting = true;
    notifyListeners();
    try {
      await _repository.deleteTotp(_totpId);
      _deleted = true;
      return true;
    } catch (_) {
      return _fail('Impossible de supprimer ce TOTP.');
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  TotpDraft _draftFrom(Totp t) => TotpDraft(
    label: t.label,
    account: t.account,
    secret: t.secret,
    digits: t.digits,
    period: t.period,
    algorithm: t.algorithm,
    profileId: t.profileId,
    favorite: t.favorite,
  );

  bool _fail(String message) {
    _errorMessage = message;
    notifyListeners();
    return false;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
