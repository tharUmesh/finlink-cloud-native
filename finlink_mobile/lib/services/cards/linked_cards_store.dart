import 'package:finlink_mobile/utils/bank_names.dart';
import 'package:flutter/material.dart';

class LinkedCardsStore extends ChangeNotifier {
  final List<BankName> _banks = [];

  List<BankName> get banks => List.unmodifiable(_banks);

  BankName? get primaryBank => _banks.isEmpty ? null : _banks.last;

  bool get hasCards => _banks.isNotEmpty;

  void addBank(BankName bank) {
    if (_banks.contains(bank)) {
      _banks.remove(bank);
    }
    _banks.add(bank);
    notifyListeners();
  }
}
