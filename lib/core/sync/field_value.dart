import 'dart:convert';
import 'dart:typed_data';

/// Valeur d'un champ CRDT, sérialisée **balisée** `[tag][charge utile]` avant
/// chiffrement par entrée. Ce balisage est le **format sur le fil** (durable,
/// partagé entre appareils) : ne pas réordonner ni réaffecter les tags.
///
/// | tag | type    | charge utile               |
/// |-----|---------|----------------------------|
/// | 0   | null    | (vide)                     |
/// | 1   | texte   | UTF-8                      |
/// | 2   | entier  | i64 little-endian (8 o)    |
/// | 3   | booléen | 1 octet (0 / 1)            |
/// | 4   | uuid    | 16 octets                  |
///
/// `null` (tag 0) distingue « champ vidé » de « champ jamais renseigné » (ce
/// dernier n'est tout simplement pas émis).
sealed class FieldValue {
  const FieldValue();

  static const int tagNull = 0;
  static const int tagText = 1;
  static const int tagInt = 2;
  static const int tagBool = 3;
  static const int tagUuid = 4;

  /// Sérialise en `[tag][charge utile]`.
  Uint8List encode();

  /// Désérialise un `[tag][charge utile]`.
  ///
  /// Lève [FormatException] si l'entrée est vide, le tag inconnu, ou la charge
  /// utile de taille incohérente avec le tag.
  factory FieldValue.decode(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const FormatException('valeur de champ vide (tag manquant)');
    }
    final tag = bytes[0];
    final payload = Uint8List.sublistView(bytes, 1);
    switch (tag) {
      case tagNull:
        return const NullValue();
      case tagText:
        return TextValue(utf8.decode(payload));
      case tagInt:
        if (payload.length != 8) {
          throw FormatException(
            'entier de ${payload.length} octets (8 attendus)',
          );
        }
        return IntValue(ByteData.sublistView(payload).getInt64(0, Endian.little));
      case tagBool:
        if (payload.length != 1) {
          throw FormatException(
            'booléen de ${payload.length} octets (1 attendu)',
          );
        }
        return BoolValue(payload[0] != 0);
      case tagUuid:
        if (payload.length != 16) {
          throw FormatException('uuid de ${payload.length} octets (16 attendus)');
        }
        return UuidValue(Uint8List.fromList(payload));
      default:
        throw FormatException('tag de champ inconnu : $tag');
    }
  }
}

/// Absence de valeur — champ explicitement vidé.
final class NullValue extends FieldValue {
  const NullValue();

  @override
  Uint8List encode() => Uint8List.fromList(const [FieldValue.tagNull]);

  @override
  bool operator ==(Object other) => other is NullValue;

  @override
  int get hashCode => FieldValue.tagNull;
}

/// Valeur texte (UTF-8).
final class TextValue extends FieldValue {
  final String value;

  const TextValue(this.value);

  @override
  Uint8List encode() {
    final body = utf8.encode(value);
    final out = Uint8List(1 + body.length);
    out[0] = FieldValue.tagText;
    out.setRange(1, out.length, body);
    return out;
  }

  @override
  bool operator ==(Object other) => other is TextValue && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// Valeur entière signée (encodée i64 little-endian).
final class IntValue extends FieldValue {
  final int value;

  const IntValue(this.value);

  @override
  Uint8List encode() {
    final out = Uint8List(9);
    out[0] = FieldValue.tagInt;
    ByteData.sublistView(out, 1).setInt64(0, value, Endian.little);
    return out;
  }

  @override
  bool operator ==(Object other) => other is IntValue && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// Valeur booléenne.
final class BoolValue extends FieldValue {
  final bool value;

  const BoolValue(this.value);

  @override
  Uint8List encode() =>
      Uint8List.fromList([FieldValue.tagBool, value ? 1 : 0]);

  @override
  bool operator ==(Object other) => other is BoolValue && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

/// Valeur UUID / identifiant binaire de 16 octets (p. ex. un `syncId` référencé).
final class UuidValue extends FieldValue {
  final Uint8List value;

  UuidValue(this.value)
    : assert(value.length == 16, 'un UUID fait 16 octets');

  @override
  Uint8List encode() {
    final out = Uint8List(17);
    out[0] = FieldValue.tagUuid;
    out.setRange(1, 17, value);
    return out;
  }

  @override
  bool operator ==(Object other) {
    if (other is! UuidValue || other.value.length != value.length) return false;
    for (var i = 0; i < value.length; i++) {
      if (other.value[i] != value[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(value);
}
