import 'package:flutter/material.dart';

import 'search_notifier.dart';

class SearchNotifierScope extends InheritedNotifier<SearchNotifier> {
  const SearchNotifierScope({
    super.key,
    required SearchNotifier notifier,
    required super.child,
  }) : super(notifier: notifier);

  static SearchNotifier of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<SearchNotifierScope>();
    assert(scope != null, 'SearchNotifierScope introuvable dans le context');
    return scope!.notifier!;
  }
}
