import 'package:flutter/material.dart';

class FabNotifier extends ChangeNotifier {
  VoidCallback? _onPressed;
  IconData? _icon;
  String? _label;
  bool _visible = false;

  bool get visible => _visible;
  IconData? get icon => _icon;
  String? get label => _label;

  void register({
    required VoidCallback onPressed,
    IconData icon = Icons.add,
    String? label,
  }) {
    _onPressed = onPressed;
    _icon = icon;
    _label = label;
    _visible = true;
    notifyListeners();
  }

  void unregister() {
    _onPressed = null;
    _visible = false;
    notifyListeners();
  }

  void call() => _onPressed?.call();
}
