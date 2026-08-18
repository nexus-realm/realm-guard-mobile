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
      roundTrip(
        UuidValue(Uint8List.fromList(List.generate(16, (i) => i * 7 % 256))),
      );
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

  _equalityContract();
}

/// Égalité / hachage : le codec sert de clé de comparaison dans la projection
/// (un `==` faux ferait réécrire des lignes identiques à chaque tirage).
void _equalityContract() {
  group('Contrat d\'égalité', () {
    test('NullValue est égal à lui-même, distinct des autres', () {
      expect(const NullValue(), const NullValue());
      expect(const NullValue(), isNot(const TextValue('')));
      expect(const NullValue().hashCode, FieldValue.tagNull);
    });

    test('TextValue : égalité et hachage par contenu', () {
      expect(const TextValue('a'), const TextValue('a'));
      expect(const TextValue('a'), isNot(const TextValue('b')));
      expect(const TextValue('a').hashCode, 'a'.hashCode);
    });

    test('IntValue : égalité et hachage par valeur', () {
      expect(const IntValue(42), const IntValue(42));
      expect(const IntValue(42), isNot(const IntValue(43)));
      expect(const IntValue(42).hashCode, 42.hashCode);
    });

    test('BoolValue : égalité et hachage par valeur', () {
      expect(const BoolValue(true), const BoolValue(true));
      expect(const BoolValue(true), isNot(const BoolValue(false)));
      expect(const BoolValue(true).hashCode, true.hashCode);
    });

    test('UuidValue : deux octets identiques ⇒ même hachage', () {
      final a = UuidValue(Uint8List.fromList(List.filled(16, 5)));
      final b = UuidValue(Uint8List.fromList(List.filled(16, 5)));
      expect(a.hashCode, b.hashCode);
      // Rappel : `Uint8List ==` est référentiel — c'est bien le codec qui
      // compare les octets, pas la liste.
      expect(a.value == b.value, isFalse);
    });

    test('un booléen encodé sur plus d\'un octet est rejeté', () {
      final malformed = Uint8List.fromList([FieldValue.tagBool, 1, 0]);
      expect(
        () => FieldValue.decode(malformed),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
