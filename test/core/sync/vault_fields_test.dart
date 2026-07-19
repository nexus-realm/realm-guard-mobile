import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/core/database/app_database.dart';
import 'package:realmguard/core/sync/field_value.dart';
import 'package:realmguard/core/sync/vault_fields.dart';

final _epoch = DateTime.fromMillisecondsSinceEpoch(1700000000000);
final _profileUuid = Uint8List.fromList(List.filled(16, 9));

Profile _profile({int? color, String? note}) => Profile(
  id: 1,
  name: 'Perso',
  emails: '["a@b.c"]',
  usernames: '["alice"]',
  phoneNumbers: '[]',
  color: color,
  note: note,
  createdAt: _epoch,
  updatedAt: _epoch,
);

Credential _credential({String? username, String? password}) => Credential(
  id: 1,
  title: 'GitHub',
  username: username,
  password: password,
  customFields: '[]',
  favorite: true,
  createdAt: _epoch,
  updatedAt: _epoch,
);

Totp _totp({String? account}) => Totp(
  id: 1,
  label: 'GitHub',
  account: account,
  secret: 'JBSWY3DPEHPK3PXP',
  digits: 6,
  period: 30,
  algorithm: 'SHA1',
  favorite: false,
  createdAt: _epoch,
  updatedAt: _epoch,
);

void main() {
  group('VaultKind', () {
    test('codes durables', () {
      expect(VaultKind.profile.code, 0);
      expect(VaultKind.credential.code, 1);
      expect(VaultKind.totp.code, 2);
    });

    test('fromCode (connu / inconnu)', () {
      expect(VaultKind.fromCode(0), VaultKind.profile);
      expect(VaultKind.fromCode(1), VaultKind.credential);
      expect(VaultKind.fromCode(2), VaultKind.totp);
      expect(VaultKind.fromCode(99), isNull);
    });
  });

  group('VaultFieldMap.ofProfile', () {
    test('champs requis + kind', () {
      final fields = VaultFieldMap.ofProfile(_profile());
      expect(fields[VaultFields.kind], const IntValue(0));
      expect(fields[VaultFields.profileName], const TextValue('Perso'));
      expect(fields[VaultFields.profileEmails], const TextValue('["a@b.c"]'));
      expect(
        fields[VaultFields.profileUsernames],
        const TextValue('["alice"]'),
      );
      expect(
        (fields[VaultFields.profileCreatedAt] as IntValue).value,
        1700000000000,
      );
    });

    test('optionnels null omis, sinon présents', () {
      expect(
        VaultFieldMap.ofProfile(
          _profile(),
        ).containsKey(VaultFields.profileColor),
        isFalse,
      );
      final withColor = VaultFieldMap.ofProfile(_profile(color: 42, note: 'x'));
      expect(withColor[VaultFields.profileColor], const IntValue(42));
      expect(withColor[VaultFields.profileNote], const TextValue('x'));
    });
  });

  group('VaultFieldMap.ofCredential', () {
    test('champs + FK profil en UUID', () {
      final fields = VaultFieldMap.ofCredential(
        _credential(password: 'pw'),
        profileSyncId: _profileUuid,
      );
      expect(fields[VaultFields.kind], const IntValue(1));
      expect(fields[VaultFields.credentialTitle], const TextValue('GitHub'));
      expect(fields[VaultFields.credentialPassword], const TextValue('pw'));
      expect(fields[VaultFields.credentialFavorite], const BoolValue(true));
      expect(fields[VaultFields.credentialProfileId], UuidValue(_profileUuid));
    });

    test('username null omis, pas de profil ⇒ pas de FK', () {
      final fields = VaultFieldMap.ofCredential(_credential());
      expect(fields.containsKey(VaultFields.credentialUsername), isFalse);
      expect(fields.containsKey(VaultFields.credentialProfileId), isFalse);
    });
  });

  group('VaultFieldMap.ofTotp', () {
    test('champs + paramètres', () {
      final fields = VaultFieldMap.ofTotp(
        _totp(account: 'me@example.com'),
        profileSyncId: _profileUuid,
      );
      expect(fields[VaultFields.kind], const IntValue(2));
      expect(
        fields[VaultFields.totpSecret],
        const TextValue('JBSWY3DPEHPK3PXP'),
      );
      expect(fields[VaultFields.totpDigits], const IntValue(6));
      expect(fields[VaultFields.totpPeriod], const IntValue(30));
      expect(fields[VaultFields.totpAlgorithm], const TextValue('SHA1'));
      expect(
        fields[VaultFields.totpAccount],
        const TextValue('me@example.com'),
      );
      expect(fields[VaultFields.totpProfileId], UuidValue(_profileUuid));
    });

    test('account null omis', () {
      expect(
        VaultFieldMap.ofTotp(_totp()).containsKey(VaultFields.totpAccount),
        isFalse,
      );
    });
  });

  group('VaultFieldMap — clearNulls (mise à jour)', () {
    test('émet NullValue pour les optionnels null au lieu de les omettre', () {
      final fields = VaultFieldMap.ofCredential(
        _credential(),
        clearNulls: true,
      );
      expect(fields[VaultFields.credentialUsername], const NullValue());
      expect(fields[VaultFields.credentialPassword], const NullValue());
      expect(fields[VaultFields.credentialProfileId], const NullValue());
    });

    test('FK profil dissociée (profileSyncId null) ⇒ NullValue', () {
      final fields = VaultFieldMap.ofTotp(
        _totp(account: 'x'),
        clearNulls: true,
      );
      // account fourni ⇒ valeur ; profil absent ⇒ effacement explicite.
      expect(fields[VaultFields.totpAccount], const TextValue('x'));
      expect(fields[VaultFields.totpProfileId], const NullValue());
    });

    test('valeurs non-null inchangées par clearNulls', () {
      final fields = VaultFieldMap.ofProfile(
        _profile(color: 42, note: 'n'),
        clearNulls: true,
      );
      expect(fields[VaultFields.profileColor], const IntValue(42));
      expect(fields[VaultFields.profileNote], const TextValue('n'));
    });
  });
}
