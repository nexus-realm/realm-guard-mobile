import 'package:flutter/foundation.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/vault_repository.dart';
import '../data/base32.dart';
import '../data/totp_draft.dart';

/// ViewModel de la page d'ajout d'un TOTP.
class AddTotpViewModel extends ChangeNotifier {
  AddTotpViewModel(this._repository);

  final TotpEditor _repository;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<Profile> _profiles = const [];
  List<Profile> get profiles => _profiles;

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

  /// Enregistre un TOTP. Le libellé et un secret Base32 valide sont requis.
  Future<bool> submit(TotpDraft draft) async {
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
      await _repository.addTotp(draft);
      return true;
    } catch (_) {
      return _fail('Impossible d\'enregistrer le TOTP. Veuillez réessayer.');
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  bool _fail(String message) {
    _errorMessage = message;
    notifyListeners();
    return false;
  }
}
