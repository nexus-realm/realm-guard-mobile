import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:realmguard/core/sync/field_value.dart';

void main() {
  group('FieldValue — aller-retour', () {
    void roundTrip(FieldValue value) {
      expect(FieldValue.decode(value.encode()), value);
    }

    test('texte (unicode, vide)', () {
      roundTrip(const TextValue('héllo 🌍 mdp'));
      roundTrip(const TextValue(''));
    });

    test('entier (zéro, grand, négatif, i64 max)', () {
      roundTrip(const IntValue(0));
      roundTrip(const IntValue(1700000000000));
      roundTrip(const IntValue(-42));
      roundTrip(const IntValue(9223372036854775807));
    });

    test('booléen', () {
      roundTrip(const BoolValue(true));
      roundTrip(const BoolValue(false));
    });

    test('uuid (16 octets)', () {
      roundTrip(UuidValue(Uint8List.fromList(List.generate(16, (i) => i * 7 % 256))));
    });

    test('null', () {
      roundTrip(const NullValue());
    });
  });

  group('FieldValue — format sur le fil', () {
    test('tags durables', () {
      expect(const NullValue().encode().first, 0);
      expect(const TextValue('x').encode().first, 1);
      expect(const IntValue(1).encode().first, 2);
      expect(const BoolValue(true).encode().first, 3);
      expect(UuidValue(Uint8List(16)).encode().first, 4);
    });

    test('entier = i64 little-endian sur 8 octets', () {
      final bytes = const IntValue(1).encode();
      expect(bytes.length, 9);
      expect(bytes.sublist(1), [1, 0, 0, 0, 0, 0, 0, 0]);
    });

    test('booléen = 1 octet', () {
      expect(const BoolValue(true).encode(), [3, 1]);
      expect(const BoolValue(false).encode(), [3, 0]);
    });
  });

  group('FieldValue — entrées invalides', () {
    test('valeur vide (tag manquant)', () {
      expect(() => FieldValue.decode(Uint8List(0)), throwsFormatException);
    });

    test('tag inconnu', () {
      expect(
        () => FieldValue.decode(Uint8List.fromList([9, 1, 2])),
        throwsFormatException,
      );
    });

    test('entier tronqué', () {
      expect(
        () => FieldValue.decode(Uint8List.fromList([2, 1, 2, 3])),
        throwsFormatException,
      );
    });

    test('uuid de mauvaise taille', () {
      expect(
        () => FieldValue.decode(Uint8List.fromList([4, 1, 2, 3])),
        throwsFormatException,
      );
    });
  });

  group('FieldValue — égalité', () {
    test('même contenu ⇒ égaux (uuid compare les octets)', () {
      expect(
        UuidValue(Uint8List.fromList(List.filled(16, 5))),
        UuidValue(Uint8List.fromList(List.filled(16, 5))),
      );
      expect(
        UuidValue(Uint8List.fromList(List.filled(16, 5))),
        isNot(UuidValue(Uint8List.fromList(List.filled(16, 6)))),
      );
    });
  });
}
