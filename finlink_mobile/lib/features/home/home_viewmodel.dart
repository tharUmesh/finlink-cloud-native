import 'package:finlink_mobile/features/base_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:finlink_mobile/utils/bank_names.dart';

class HomeViewmodel extends BaseViewmodel {
	int _selectedIndex = 0;

	final sendFormKey = GlobalKey<FormState>();
	final receiverAddressController = TextEditingController();
	final amountController = TextEditingController();
	final remarksController = TextEditingController();

	final addCardFormKey = GlobalKey<FormState>();
	final cardNumberController = TextEditingController();
	final cvcController = TextEditingController();
	BankName? _selectedBank;
	DateTime? _selectedExpirationDate;

	int get selectedIndex => _selectedIndex;
	BankName? get selectedBank => _selectedBank;
	DateTime? get selectedExpirationDate => _selectedExpirationDate;
	String get expirationText {
		final value = _selectedExpirationDate;
		if (value == null) {
			return '';
		}
		final month = value.month.toString().padLeft(2, '0');
		final year = (value.year % 100).toString().padLeft(2, '0');
		return '$month/$year';
	}

	void onTabChanged(int index) {
		if (_selectedIndex == index) {
			return;
		}
		_selectedIndex = index;
		notifyListeners();
	}

	String? validateReceiverAddress(String? value) {
		if (value == null || value.trim().isEmpty) {
			return "Receiver's address is required";
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

	void submitSendForm(BuildContext context) {
		if (!(sendFormKey.currentState?.validate() ?? false)) {
			return;
		}
		clearSendForm();
		Navigator.pop(context);
	}

	void closeSendBottomSheet(BuildContext context) {
		clearSendForm();
		Navigator.pop(context);
	}

	void clearSendForm() {
		receiverAddressController.clear();
		amountController.clear();
		remarksController.clear();
	}

	void setSelectedBank(BankName? bank) {
		_selectedBank = bank;
		notifyListeners();
	}

	String? validateSelectedBank(BankName? bank) {
		if (bank == null) {
			return 'Please select a bank';
		}
		return null;
	}

	String? validateCardNumber(String? value) {
		final text = value?.trim() ?? '';
		if (text.isEmpty) {
			return 'Card number is required';
		}
		if (text.length < 12) {
			return 'Enter a valid card number';
		}
		return null;
	}

	String? validateExpiration() {
		if (_selectedExpirationDate == null) {
			return 'Expiration is required';
		}
		final now = DateTime.now();
		final selected = DateTime(
			_selectedExpirationDate!.year,
			_selectedExpirationDate!.month,
		);
		final current = DateTime(now.year, now.month);
		if (selected.isBefore(current)) {
			return 'Expiration must be current or future month';
		}
		return null;
	}

	Future<void> pickExpirationDate(BuildContext context) async {
		final now = DateTime.now();
		final initialDate = _selectedExpirationDate ?? now;
		final selected = await showDatePicker(
			context: context,
			initialDate: initialDate,
			firstDate: DateTime(now.year, now.month),
			lastDate: DateTime(now.year + 20, 12),
		);
		if (selected == null) {
			return;
		}
		_selectedExpirationDate = DateTime(selected.year, selected.month);
		notifyListeners();
	}

	String? validateCvc(String? value) {
		final text = value?.trim() ?? '';
		if (text.isEmpty) {
			return 'CVC is required';
		}
		if (text.length < 3 || text.length > 4) {
			return 'Enter valid CVC';
		}
		return null;
	}

	void submitAddCardForm(BuildContext context) {
		if (!(addCardFormKey.currentState?.validate() ?? false)) {
			return;
		}
		clearAddCardForm();
		Navigator.pop(context);
	}

	void closeAddCardBottomSheet(BuildContext context) {
		clearAddCardForm();
		Navigator.pop(context);
	}

	void clearAddCardForm() {
		_selectedBank = null;
		_selectedExpirationDate = null;
		cardNumberController.clear();
		cvcController.clear();
		notifyListeners();
	}

	@override
	void dispose() {
		receiverAddressController.dispose();
		amountController.dispose();
		remarksController.dispose();
		cardNumberController.dispose();
		cvcController.dispose();
		super.dispose();
	}
}