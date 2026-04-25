import 'package:finlink_mobile/features/base_viewmodel.dart';
import 'package:finlink_mobile/utils/bank_names.dart';
import 'package:flutter/material.dart';

class WithdrawViewmodel extends BaseViewmodel {
  final withdrawFormKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final remarksController = TextEditingController();

  BankName? _selectedBank;

  BankName? get selectedBank => _selectedBank;

  void setSelectedBank(BankName? bank) {
    _selectedBank = bank;
    notifyListeners();
  }

  String? validateBank(BankName? bank) {
    if (bank == null) {
      return 'Please select a bank';
    }
    return null;
  }

  String? validateAmount(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Amount is required';
    }
    final amount = double.tryParse(text);
    if (amount == null || amount <= 0) {
      return 'Enter a valid amount';
    }
    return null;
  }

  bool submit() {
    return withdrawFormKey.currentState?.validate() ?? false;
  }

  void close(BuildContext context) {
    clear();
    Navigator.pop(context);
  }

  void clear() {
    _selectedBank = null;
    amountController.clear();
    remarksController.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    amountController.dispose();
    remarksController.dispose();
    super.dispose();
  }
}