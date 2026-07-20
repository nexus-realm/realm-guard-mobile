import 'package:flutter/material.dart';

import 'fab_notifier.dart';

class FabNotifierScope extends InheritedNotifier<FabNotifier> {
  const FabNotifierScope({
    super.key,
    required FabNotifier notifier,
    required super.child,
  }) : super(notifier: notifier);

  static FabNotifier of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<FabNotifierScope>();
    assert(scope != null, 'FabNotifierScope introuvable dans le context');
    return scope!.notifier!;
  }
}
