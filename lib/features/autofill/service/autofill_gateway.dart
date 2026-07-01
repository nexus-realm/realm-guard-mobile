import 'package:flutter_autofill_service/flutter_autofill_service.dart';

/// Accès au service de remplissage automatique de l'OS (statut + activation).
///
/// Abstrait pour permettre un faux en test : le canal natif n'existe que sur
/// Android, et la logique d'autofill ne peut être exercée que sur appareil.
abstract interface class AutofillGateway {
  /// Statut courant : non supporté / désactivé / activé.
  Future<AutofillServiceStatus> status();

  /// Ouvre les réglages système pour définir Realm Guard comme service
  /// d'autofill.
  Future<void> requestEnable();

  /// Désactive Realm Guard comme service d'autofill.
  Future<void> disable();
}

/// Implémentation réelle adossée au plugin `flutter_autofill_service`.
class PlatformAutofillGateway implements AutofillGateway {
  const PlatformAutofillGateway();

  @override
  Future<AutofillServiceStatus> status() => AutofillService().status;

  @override
  Future<void> requestEnable() => AutofillService().requestSetAutofillService();

  @override
  Future<void> disable() => AutofillService().disableAutofillServices();
}
