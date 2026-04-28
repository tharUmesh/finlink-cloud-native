import 'package:finlink_mobile/features/base_viewmodel.dart';
import 'package:finlink_mobile/models/wallet/wallet_models.dart';
import 'package:finlink_mobile/services/wallet/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:finlink_mobile/utils/bank_names.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class HomeViewmodel extends BaseViewmodel {
	HomeViewmodel(this._walletService);

	final WalletService _walletService;
	final NumberFormat _currencyFormat = NumberFormat.currency(
		locale: 'en_LK',
		symbol: 'LKR',
		decimalDigits: 2,
	);

	int _selectedIndex = 0;
	Wallet? _wallet;
	bool _isWalletLoading = false;
	String? _walletError;
	StreamSubscription<Wallet>? _walletSubscription;

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
	Wallet? get wallet => _wallet;
	bool get isWalletLoading => _isWalletLoading;
	String? get walletError => _walletError;
	String get walletBalanceText {
		if (_isWalletLoading) {
			return 'Loading...';
		}
		final currentWallet = _wallet;
		if (currentWallet == null) {
			return 'LKR --';
		}
		final symbol = currentWallet.currency.toUpperCase() == 'LKR'
				? 'LKR'
				: currentWallet.currency;
		if (symbol == 'LKR') {
			return _currencyFormat.format(currentWallet.balance);
		}
		return NumberFormat.currency(
			locale: 'en_LK',
			symbol: symbol,
			decimalDigits: 2,
		).format(currentWallet.balance);
	}

	String? get walletStatusMessage {
		if (_walletError != null && _walletError!.isNotEmpty) {
			return _walletError;
		}
		if (_wallet?.isFrozen == true) {
			return 'Wallet is frozen';
		}
		return null;
	}

	void startWalletStream({Duration interval = const Duration(seconds: 10)}) {
		_walletSubscription?.cancel();
		_isWalletLoading = true;
		_walletError = null;
		notifyListeners();

		_walletSubscription = _walletService
				.watchMyWallet(interval: interval)
				.listen(
					(wallet) {
						_wallet = wallet;
						debugPrint(
							'Wallet balance updated: ${wallet.currency} ${wallet.balance}',
						);
						_isWalletLoading = false;
						_walletError = null;
						notifyListeners();
					},
					onError: (error) {
						_isWalletLoading = false;
						_walletError = error is WalletServiceException
								? error.message
								: 'Unable to load wallet right now.';
						notifyListeners();
					},
				);
	}

	@override
	void dispose() {
		_walletSubscription?.cancel();
		receiverAddressController.dispose();
		amountController.dispose();
		remarksController.dispose();
		cardNumberController.dispose();
		cvcController.dispose();
		super.dispose();
	}
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

	Future<void> loadWallet() async {
		if (_isWalletLoading) {
			return;
		}
		_isWalletLoading = true;
		_walletError = null;
		notifyListeners();

		try {
			_wallet = await _walletService.getMyWallet();
		} on WalletServiceException catch (error) {
			_walletError = error.message;
		} catch (_) {
			_walletError = 'Unable to load wallet right now.';
		} finally {
			_isWalletLoading = false;
			notifyListeners();
		}
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


}