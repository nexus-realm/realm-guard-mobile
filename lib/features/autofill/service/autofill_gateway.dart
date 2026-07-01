import 'package:flutter_autofill_service/flutter_autofill_service.dart';

/// Accès au service de remplissage automatique de l'OS.
///
/// Abstrait pour permettre un faux en test : le canal natif n'existe que sur
/// Android, et la logique d'autofill ne peut être exercée que sur appareil.
abstract interface class AutofillGateway {
  // --- Réglage (lot 1) ---

  /// Statut courant : non supporté / désactivé / activé.
  Future<AutofillServiceStatus> status();

  /// Ouvre les réglages système pour définir Realm Guard comme service
  /// d'autofill.
  Future<void> requestEnable();

  /// Désactive Realm Guard comme service d'autofill.
  Future<void> disable();

  // --- Remplissage (lot 2) ---

  /// `true` si l'écran a été lancé pour servir une requête de remplissage
  /// interactive (l'utilisateur a tapé l'entrée « Déverrouiller Realm Guard »).
  Future<bool> isInteractiveFillRequest();

  /// Métadonnées de la requête : application (packageNames) et site (webDomains)
  /// à l'origine du remplissage.
  Future<AutofillMetadata?> fillMetadata();

  /// Renvoie l'identifiant choisi à l'OS, qui remplit le champ et ferme l'écran.
  Future<void> submit(PwDataset dataset);

  /// Configure le service pour le remplissage seul (v1) : pas d'enregistrement,
  /// pas de suggestions clavier (IME).
  Future<void> configureFillOnly();
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

  @override
  Future<bool> isInteractiveFillRequest() =>
      AutofillService().fillRequestedInteractive;

  @override
  Future<AutofillMetadata?> fillMetadata() => AutofillService().autofillMetadata;

  @override
  Future<void> submit(PwDataset dataset) => AutofillService().resultWithDataset(
    label: dataset.label,
    username: dataset.username,
    password: dataset.password,
  );

  @override
  Future<void> configureFillOnly() => AutofillService().setPreferences(
    AutofillPreferences(
      enableDebug: false,
      enableSaving: false,
      enableIMERequests: false,
    ),
  );
}
