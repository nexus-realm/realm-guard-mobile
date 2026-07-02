import 'package:flutter/foundation.dart';
import 'package:flutter_autofill_service/flutter_autofill_service.dart';

import '../service/autofill_gateway.dart';

/// ViewModel du réglage « Remplissage automatique » : expose le statut du
/// service d'autofill de l'OS et les actions activer / désactiver.
class AutofillSettingsViewModel extends ChangeNotifier {
  AutofillSettingsViewModel({AutofillGateway? gateway})
    : _gateway = gateway ?? const PlatformAutofillGateway();

  final AutofillGateway _gateway;

  AutofillServiceStatus? _status;
  AutofillServiceStatus? get status => _status;

  bool _isBusy = false;
  bool get isBusy => _isBusy;

  /// `true` si l'appareil supporte l'autofill (statut chargé et ≠ unsupported).
  bool get isSupported =>
      _status != null && _status != AutofillServiceStatus.unsupported;

  /// `true` si Realm Guard est actuellement le service d'autofill actif.
  bool get isEnabled => _status == AutofillServiceStatus.enabled;

  /// Recharge le statut. À appeler à l'ouverture et au retour des réglages OS
  /// (l'activation se fait dans les réglages système, hors de l'application).
  Future<void> refresh() async {
    _status = await _gateway.status();
    // Active le remplissage + l'enregistrement dès que le service est supporté
    // (l'utilisateur est justement dans les réglages pour l'activer).
    if (isSupported) {
      await _gateway.configureAutofill();
    }
    notifyListeners();
  }

  Future<void> enable() async {
    _isBusy = true;
    notifyListeners();
    try {
      await _gateway.requestEnable();
      await refresh();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> disable() async {
    _isBusy = true;
    notifyListeners();
    try {
      await _gateway.disable();
      await refresh();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }
}
