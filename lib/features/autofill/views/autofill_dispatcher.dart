import 'package:flutter/material.dart';

import '../service/autofill_gateway.dart';
import 'autofill_fill_page.dart';
import 'autofill_save_page.dart';

enum _AutofillMode { deciding, fill, save }

/// Aiguille l'écran d'autofill : une requête de sauvegarde (l'OS fournit des
/// données à enregistrer) mène à l'écran de sauvegarde ; sinon on ouvre l'écran
/// de remplissage.
class AutofillDispatcher extends StatefulWidget {
  const AutofillDispatcher({super.key});

  @override
  State<AutofillDispatcher> createState() => _AutofillDispatcherState();
}

class _AutofillDispatcherState extends State<AutofillDispatcher> {
  _AutofillMode _mode = _AutofillMode.deciding;

  @override
  void initState() {
    super.initState();
    _decide();
  }

  Future<void> _decide() async {
    _AutofillMode mode;
    try {
      final metadata = await const PlatformAutofillGateway().fillMetadata();
      mode = metadata?.saveInfo != null
          ? _AutofillMode.save
          : _AutofillMode.fill;
    } catch (_) {
      mode = _AutofillMode.fill;
    }
    if (!mounted) return;
    setState(() => _mode = mode);
  }

  @override
  Widget build(BuildContext context) {
    switch (_mode) {
      case _AutofillMode.deciding:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case _AutofillMode.fill:
        return const AutofillFillPage();
      case _AutofillMode.save:
        return const AutofillSavePage();
    }
  }
}
