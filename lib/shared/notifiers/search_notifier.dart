import 'package:flutter/material.dart';

class SearchNotifier extends ChangeNotifier {
  String _query = '';
  String get query => _query;

  void updateQuery(String query) {
    _query = query;
    notifyListeners();
  }

  void clear() {
    _query = '';
    notifyListeners();
  }
}
