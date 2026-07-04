import 'package:flutter/material.dart';

import '../data/legal_documents.dart';

/// Page générique d'affichage d'un document légal/informatif en lecture seule.
class LegalPage extends StatelessWidget {
  const LegalPage({required this.document, super.key});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(document.title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Text(
            document.body,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
