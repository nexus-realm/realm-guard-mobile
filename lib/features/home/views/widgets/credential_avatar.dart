import 'package:flutter/material.dart';

import '../../data/domain_identity.dart';

/// Pastille d'un identifiant : initiale + couleur dérivées **localement** du
/// domaine de l'URL (ou du titre en repli). Aucun accès réseau.
class CredentialAvatar extends StatelessWidget {
  const CredentialAvatar({
    required this.title,
    this.uri,
    this.radius = 20,
    super.key,
  });

  final String title;
  final String? uri;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final identity = DomainIdentity.from(uri: uri, title: title);
    return CircleAvatar(
      radius: radius,
      backgroundColor: identity.color,
      child: Text(
        identity.initial,
        style: TextStyle(
          color: Colors.black,
          fontSize: radius * 0.85,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
