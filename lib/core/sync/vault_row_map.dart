import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'field_value.dart';
import 'vault_fields.dart';
import 'vault_projection.dart';

/// Projection inverse **entrée décodée → companion drift** (miroir de
/// `VaultFieldMap`). **Pure** : la résolution FK profil (UUID→int local) est faite
/// par l'appelant et fournie via `profileId`.
///
/// `updatedAt` n'est jamais posé (dérivé local, non synchronisé). Un champ
/// absent ou `NullValue` retombe sur le défaut de colonne (`Value.absent()`) ou
/// `null` pour un optionnel — sur *insert*, le `clientDefault` / `withDefault`
/// s'applique ; sur *update*, la colonne est laissée inchangée.
abstract final class VaultRowMap {
  static ProfilesCompanion profile(DecodedEntry entry) {
    final f = entry.fields;
    return ProfilesCompanion(
      syncId: Value(entry.syncId),
      name: Value(_text(f, VaultFields.profileName) ?? ''),
      emails: Value(_text(f, VaultFields.profileEmails) ?? '[]'),
      usernames: Value(_text(f, VaultFields.profileUsernames) ?? '[]'),
      phoneNumbers: Value(_text(f, VaultFields.profilePhoneNumbers) ?? '[]'),
      color: Value(_int(f, VaultFields.profileColor)),
      note: Value(_text(f, VaultFields.profileNote)),
      createdAt: _dateValue(f, VaultFields.profileCreatedAt),
    );
  }

  static CredentialsCompanion credential(DecodedEntry entry, {int? profileId}) {
    final f = entry.fields;
    return CredentialsCompanion(
      syncId: Value(entry.syncId),
      title: Value(_text(f, VaultFields.credentialTitle) ?? ''),
      username: Value(_text(f, VaultFields.credentialUsername)),
      password: Value(_text(f, VaultFields.credentialPassword)),
      uri: Value(_text(f, VaultFields.credentialUri)),
      notes: Value(_text(f, VaultFields.credentialNotes)),
      customFields: Value(_text(f, VaultFields.credentialCustomFields) ?? '[]'),
      favorite: Value(_bool(f, VaultFields.credentialFavorite)),
      profileId: Value(profileId),
      createdAt: _dateValue(f, VaultFields.credentialCreatedAt),
    );
  }

  static TotpsCompanion totp(DecodedEntry entry, {int? profileId}) {
    final f = entry.fields;
    return TotpsCompanion(
      syncId: Value(entry.syncId),
      label: Value(_text(f, VaultFields.totpLabel) ?? ''),
      account: Value(_text(f, VaultFields.totpAccount)),
      secret: Value(_text(f, VaultFields.totpSecret) ?? ''),
      digits: Value(_int(f, VaultFields.totpDigits) ?? 6),
      period: Value(_int(f, VaultFields.totpPeriod) ?? 30),
      algorithm: Value(_text(f, VaultFields.totpAlgorithm) ?? 'SHA1'),
      favorite: Value(_bool(f, VaultFields.totpFavorite)),
      profileId: Value(profileId),
      createdAt: _dateValue(f, VaultFields.totpCreatedAt),
    );
  }

  /// `syncId` (UUID) du profil référencé par une entrée credential / totp, ou
  /// `null` si non associé. À résoudre en id local par l'appelant.
  static Uint8List? profileRef(DecodedEntry entry) {
    final id = entry.kind == VaultKind.totp
        ? VaultFields.totpProfileId
        : VaultFields.credentialProfileId;
    final value = entry.fields[id];
    return value is UuidValue ? value.value : null;
  }

  static String? _text(Map<int, FieldValue> fields, int id) {
    final value = fields[id];
    return value is TextValue ? value.value : null;
  }

  static int? _int(Map<int, FieldValue> fields, int id) {
    final value = fields[id];
    return value is IntValue ? value.value : null;
  }

  static bool _bool(Map<int, FieldValue> fields, int id) {
    final value = fields[id];
    return value is BoolValue && value.value;
  }

  static Value<DateTime> _dateValue(Map<int, FieldValue> fields, int id) {
    final ms = _int(fields, id);
    return ms == null
        ? const Value.absent()
        : Value(DateTime.fromMillisecondsSinceEpoch(ms));
  }
}
