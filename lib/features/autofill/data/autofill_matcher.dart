import '../../../core/database/app_database.dart';

/// Correspondance entre les identifiants du coffre et l'application / le site
/// tiers qui a déclenché le remplissage. Logique pure, testable.
///
/// Sécurité : on ne fait correspondre que sur le **domaine web** demandé. Les
/// requêtes issues d'applications natives (nom de paquet, sans domaine fiable)
/// ne produisent aucune correspondance automatique — l'interface propose alors
/// la liste complète (recherche), jamais un remplissage silencieux du mauvais
/// identifiant.
abstract final class AutofillMatcher {
  /// Identifiants dont l'hôte de l'URI correspond à l'un des [requestedDomains].
  static List<Credential> matchByDomain(
    Iterable<Credential> credentials,
    Set<String> requestedDomains,
  ) {
    final wanted = requestedDomains
        .map(_normalizeHost)
        .whereType<String>()
        .toSet();
    if (wanted.isEmpty) return const [];

    return credentials.where((credential) {
      final host = _hostOf(credential.uri);
      if (host == null) return false;
      return wanted.any((domain) => _hostsMatch(host, domain));
    }).toList();
  }

  /// Hôte normalisé d'une URI d'identifiant (schéma optionnel, `www.` retiré).
  static String? _hostOf(String? uri) {
    if (uri == null || uri.trim().isEmpty) return null;
    var value = uri.trim();
    if (!value.contains('://')) value = 'https://$value';
    final host = Uri.tryParse(value)?.host;
    if (host == null || host.isEmpty) return null;
    return _normalizeHost(host);
  }

  static String? _normalizeHost(String host) {
    var normalized = host.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    if (normalized.startsWith('www.')) normalized = normalized.substring(4);
    return normalized.isEmpty ? null : normalized;
  }

  /// Égalité d'hôte ou relation de sous-domaine, avec frontière de point pour
  /// éviter qu'un hôte piège comme `github.com.evil.com` corresponde à
  /// `github.com`.
  static bool _hostsMatch(String a, String b) {
    if (a == b) return true;
    return a.endsWith('.$b') || b.endsWith('.$a');
  }
}
