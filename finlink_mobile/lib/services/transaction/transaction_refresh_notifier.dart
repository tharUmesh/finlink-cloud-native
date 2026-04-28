import 'package:flutter/material.dart';

class TransactionRefreshNotifier extends ChangeNotifier {
  int _revision = 0;

  int get revision => _revision;

  void notifyRefresh() {
    _revision += 1;
    notifyListeners();
  }
}
