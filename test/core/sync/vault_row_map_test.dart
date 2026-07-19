import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/core/sync/field_value.dart';
import 'package:realmguard/core/sync/vault_fields.dart';
import 'package:realmguard/core/sync/vault_projection.dart';
import 'package:realmguard/core/sync/vault_row_map.dart';

Uint8List _id(int fill) => Uint8List.fromList(List.filled(16, fill));

DecodedEntry _entry(VaultKind kind, Map<int, FieldValue> fields) =>
    DecodedEntry(syncId: _id(1), kind: kind, fields: fields);

void main() {
  group('VaultRowMap.profile', () {
    test('mappe les champs, syncId posé, optionnels absents → null/défaut', () {
      final companion = VaultRowMap.profile(
        _entry(VaultKind.profile, {
          VaultFields.profileName: const TextValue('Perso'),
          VaultFields.profileEmails: const TextValue('["a@b.c"]'),
          VaultFields.profileCreatedAt: const IntValue(1700000000000),
        }),
      );

      expect(companion.syncId.value, _id(1));
      expect(companion.name.value, 'Perso');
      expect(companion.emails.value, '["a@b.c"]');
      expect(companion.color.value, isNull);
      expect(
        companion.createdAt.value,
        DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );
    });

    test('createdAt absent ⇒ Value.absent (défaut de colonne à l\'insert)', () {
      final companion = VaultRowMap.profile(
        _entry(VaultKind.profile, {
          VaultFields.profileName: const TextValue('X'),
          VaultFields.profileEmails: const TextValue('[]'),
        }),
      );
      expect(companion.createdAt.present, isFalse);
      expect(companion.color.value, isNull);
    });
  });

  group('VaultRowMap.credential', () {
    test('mappe les champs + FK profil résolue (int local)', () {
      final companion = VaultRowMap.credential(
        _entry(VaultKind.credential, {
          VaultFields.credentialTitle: const TextValue('GitHub'),
          VaultFields.credentialPassword: const TextValue('pw'),
          VaultFields.credentialFavorite: const BoolValue(true),
        }),
        profileId: 42,
      );

      expect(companion.title.value, 'GitHub');
      expect(companion.password.value, 'pw');
      expect(companion.username.value, isNull);
      expect(companion.favorite.value, true);
      expect(companion.profileId.value, 42);
      expect(companion.customFields.value, '[]'); // défaut
    });

    test('FK non résolue ⇒ profileId null', () {
      final companion = VaultRowMap.credential(
        _entry(VaultKind.credential, {
          VaultFields.credentialTitle: const TextValue('X'),
        }),
      );
      expect(companion.profileId.value, isNull);
    });
  });

  group('VaultRowMap.totp', () {
    test('mappe les champs, paramètres par défaut si absents', () {
      final companion = VaultRowMap.totp(
        _entry(VaultKind.totp, {
          VaultFields.totpLabel: const TextValue('GitHub'),
          VaultFields.totpSecret: const TextValue('JBSWY3DPEHPK3PXP'),
        }),
        profileId: 7,
      );

      expect(companion.label.value, 'GitHub');
      expect(companion.secret.value, 'JBSWY3DPEHPK3PXP');
      expect(companion.digits.value, 6);
      expect(companion.period.value, 30);
      expect(companion.algorithm.value, 'SHA1');
      expect(companion.profileId.value, 7);
    });
  });

  group('VaultRowMap.profileRef', () {
    test('extrait le syncId (UUID) du profil référencé', () {
      final ref = _id(9);
      expect(
        VaultRowMap.profileRef(
          _entry(VaultKind.credential, {
            VaultFields.credentialProfileId: UuidValue(ref),
          }),
        ),
        ref,
      );
    });

    test('champ TOTP + absence ⇒ null', () {
      expect(
        VaultRowMap.profileRef(
          _entry(VaultKind.totp, {
            VaultFields.totpProfileId: UuidValue(_id(3)),
          }),
        ),
        _id(3),
      );
      expect(
        VaultRowMap.profileRef(_entry(VaultKind.credential, const {})),
        isNull,
      );
    });
  });
}
