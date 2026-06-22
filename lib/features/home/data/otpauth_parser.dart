import 'base32.dart';
import 'totp_draft.dart';

/// Parse une URI de configuration `otpauth://totp/...` (format standard des QR
/// codes d'authentification) en [TotpDraft]. Logique pure, testable.
///
/// Exemple :
/// `otpauth://totp/GitHub:me@example.com?secret=JBSWY3DP&issuer=GitHub&digits=6&period=30&algorithm=SHA1`
abstract final class OtpauthParser {
  /// Tente de parser [raw]. Lève [FormatException] si l'URI n'est pas un TOTP
  /// valide (mauvais schéma, type ≠ totp, secret absent/invalide).
  static TotpDraft parse(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.scheme.toLowerCase() != 'otpauth') {
      throw const FormatException('QR code non reconnu (schéma otpauth requis).');
    }
    if (uri.host.toLowerCase() != 'totp') {
      throw const FormatException('Seuls les codes TOTP sont pris en charge.');
    }

    final params = uri.queryParameters;

    // Secret : obligatoire et Base32 valide.
    final secret = params['secret'] ?? '';
    if (!Base32.isValid(secret)) {
      throw const FormatException('Secret du QR code invalide.');
    }

    // Le "label" du chemin est de la forme "Issuer:account" (le ':' peut être
    // encodé). On en déduit issuer + compte.
    final label = uri.pathSegments.isNotEmpty
        ? Uri.decodeComponent(uri.pathSegments.first)
        : '';
    // Le label « Issuer:account » : la partie avant ':' est l'émetteur, après
    // le compte. Sans ':', le label entier est l'émetteur (et non le compte).
    String? labelIssuer;
    String? account;
    if (label.contains(':')) {
      final parts = label.split(':');
      labelIssuer = parts.first.trim();
      account = parts.sublist(1).join(':').trim();
    } else if (label.isNotEmpty) {
      labelIssuer = label.trim();
    }

    // `issuer` du query a priorité comme libellé ; sinon l'issuer du label ;
    // sinon le compte ; sinon un défaut.
    final issuer = params['issuer']?.trim();
    final displayLabel = (issuer != null && issuer.isNotEmpty)
        ? issuer
        : (labelIssuer != null && labelIssuer.isNotEmpty)
        ? labelIssuer
        : (account != null && account.isNotEmpty ? account : 'TOTP');

    return TotpDraft(
      label: displayLabel,
      account: (account != null && account.isNotEmpty) ? account : null,
      secret: secret.replaceAll(' ', ''),
      digits: int.tryParse(params['digits'] ?? '') ?? 6,
      period: int.tryParse(params['period'] ?? '') ?? 30,
      algorithm: _normalizeAlgorithm(params['algorithm']),
    );
  }

  /// `true` si [raw] ressemble à une URI otpauth TOTP exploitable.
  static bool canParse(String raw) {
    try {
      parse(raw);
      return true;
    } catch (_) {
      return false;
    }
  }

  static String _normalizeAlgorithm(String? raw) {
    switch ((raw ?? '').toUpperCase()) {
      case 'SHA256':
        return 'SHA256';
      case 'SHA512':
        return 'SHA512';
      default:
        return 'SHA1';
    }
  }
}
