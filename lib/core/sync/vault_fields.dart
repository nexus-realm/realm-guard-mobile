import 'dart:typed_data';

import '../database/app_database.dart';
import 'field_value.dart';

/// Type d'une entrée du coffre, porté par le champ partagé [VaultFields.kind].
/// Le code numérique est **durable** (format sur le fil) : ne pas renuméroter.
enum VaultKind {
  profile(0),
  credential(1),
  totp(2);

  const VaultKind(this.code);

  final int code;

  /// [VaultKind] du code, ou `null` si inconnu (tolérance aux versions futures).
  static VaultKind? fromCode(int code) {
    for (final kind in VaultKind.values) {
      if (kind.code == code) return kind;
    }
    return null;
  }
}

/// Identifiants de champ CRDT (`FieldId`), **durables**. Plages par type :
/// `0` partagé, `1–19` profil, `20–39` credential, `40–59` TOTP.
abstract final class VaultFields {
  /// Champ partagé : le [VaultKind] de l'entrée (encodé entier).
  static const int kind = 0;

  // Profil (1–19).
  static const int profileName = 1;
  static const int profileEmails = 2;
  static const int profileUsernames = 3;
  static const int profilePhoneNumbers = 4;
  static const int profileColor = 5;
  static const int profileNote = 6;
  static const int profileCreatedAt = 7;

  // Credential (20–39).
  static const int credentialTitle = 20;
  static const int credentialUsername = 21;
  static const int credentialPassword = 22;
  static const int credentialUri = 23;
  static const int credentialNotes = 24;
  static const int credentialCustomFields = 25;
  static const int credentialFavorite = 26;
  static const int credentialProfileId = 27;
  static const int credentialCreatedAt = 28;

  // TOTP (40–59).
  static const int totpLabel = 40;
  static const int totpAccount = 41;
  static const int totpSecret = 42;
  static const int totpDigits = 43;
  static const int totpPeriod = 44;
  static const int totpAlgorithm = 45;
  static const int totpProfileId = 46;
  static const int totpFavorite = 47;
  static const int totpCreatedAt = 48;
}

/// Projection **ligne drift → carte de champs CRDT** (chiffrée ensuite champ par
/// champ). Les optionnels `null` sont **omis** — LWW n'écrase pas ce qui n'est
/// pas émis ; un effacement explicite passe par [NullValue], décidé par
/// l'appelant (chemin d'écriture différentiel, P3.3c). Les emails / usernames /
/// numéros / champs perso voyagent tels quels (chaînes JSON déjà stockées).
///
/// Les FK profil voyagent en **UUID** (le `syncId` du profil référencé),
/// résolu depuis la PK locale par l'appelant et passé via `profileSyncId` ;
/// `null` ⇒ champ omis (profil non associé).
abstract final class VaultFieldMap {
  /// Champs d'un [Profile].
  static Map<int, FieldValue> ofProfile(Profile profile) {
    final fields = <int, FieldValue>{
      VaultFields.kind: const IntValue(0),
      VaultFields.profileName: TextValue(profile.name),
      VaultFields.profileEmails: TextValue(profile.emails),
      VaultFields.profileUsernames: TextValue(profile.usernames),
      VaultFields.profilePhoneNumbers: TextValue(profile.phoneNumbers),
      VaultFields.profileCreatedAt: IntValue(
        profile.createdAt.millisecondsSinceEpoch,
      ),
    };
    final color = profile.color;
    if (color != null) fields[VaultFields.profileColor] = IntValue(color);
    final note = profile.note;
    if (note != null) fields[VaultFields.profileNote] = TextValue(note);
    return fields;
  }

  /// Champs d'un [Credential]. `profileSyncId` = `syncId` du profil associé.
  static Map<int, FieldValue> ofCredential(
    Credential credential, {
    Uint8List? profileSyncId,
  }) {
    final fields = <int, FieldValue>{
      VaultFields.kind: const IntValue(1),
      VaultFields.credentialTitle: TextValue(credential.title),
      VaultFields.credentialCustomFields: TextValue(credential.customFields),
      VaultFields.credentialFavorite: BoolValue(credential.favorite),
      VaultFields.credentialCreatedAt: IntValue(
        credential.createdAt.millisecondsSinceEpoch,
      ),
    };
    final username = credential.username;
    if (username != null) {
      fields[VaultFields.credentialUsername] = TextValue(username);
    }
    final password = credential.password;
    if (password != null) {
      fields[VaultFields.credentialPassword] = TextValue(password);
    }
    final uri = credential.uri;
    if (uri != null) fields[VaultFields.credentialUri] = TextValue(uri);
    final notes = credential.notes;
    if (notes != null) fields[VaultFields.credentialNotes] = TextValue(notes);
    if (profileSyncId != null) {
      fields[VaultFields.credentialProfileId] = UuidValue(profileSyncId);
    }
    return fields;
  }

  /// Champs d'un [Totp]. `profileSyncId` = `syncId` du profil associé.
  static Map<int, FieldValue> ofTotp(Totp totp, {Uint8List? profileSyncId}) {
    final fields = <int, FieldValue>{
      VaultFields.kind: const IntValue(2),
      VaultFields.totpLabel: TextValue(totp.label),
      VaultFields.totpSecret: TextValue(totp.secret),
      VaultFields.totpDigits: IntValue(totp.digits),
      VaultFields.totpPeriod: IntValue(totp.period),
      VaultFields.totpAlgorithm: TextValue(totp.algorithm),
      VaultFields.totpFavorite: BoolValue(totp.favorite),
      VaultFields.totpCreatedAt: IntValue(totp.createdAt.millisecondsSinceEpoch),
    };
    final account = totp.account;
    if (account != null) fields[VaultFields.totpAccount] = TextValue(account);
    if (profileSyncId != null) {
      fields[VaultFields.totpProfileId] = UuidValue(profileSyncId);
    }
    return fields;
  }
}
