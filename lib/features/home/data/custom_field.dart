import 'dart:convert';

/// Champ personnalisé d'un identifiant : un libellé, une valeur, et un marqueur
/// `secret` indiquant si la valeur doit être masquée dans l'UI.
class CustomField {
  const CustomField({
    required this.label,
    required this.value,
    this.secret = false,
  });

  final String label;
  final String value;
  final bool secret;

  CustomField copyWith({String? label, String? value, bool? secret}) =>
      CustomField(
        label: label ?? this.label,
        value: value ?? this.value,
        secret: secret ?? this.secret,
      );

  Map<String, Object?> toJson() => {
    'label': label,
    'value': value,
    'secret': secret,
  };

  factory CustomField.fromJson(Map<String, Object?> json) => CustomField(
    label: json['label'] as String? ?? '',
    value: json['value'] as String? ?? '',
    secret: json['secret'] as bool? ?? false,
  );

  /// Encode une liste de champs en JSON (pour la colonne `customFields`).
  static String encode(List<CustomField> fields) =>
      jsonEncode(fields.map((f) => f.toJson()).toList());

  /// Décode la colonne `customFields`. Tolérant : retourne une liste vide si le
  /// contenu est vide ou mal formé.
  static List<CustomField> decode(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((m) => CustomField.fromJson(Map<String, Object?>.from(m)))
            .toList();
      }
    } catch (_) {
      // Format inattendu : on ignore.
    }
    return const [];
  }
}
