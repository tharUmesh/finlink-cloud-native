import 'dart:async';

import 'package:finlink_mobile/features/base_viewmodel.dart';
import 'package:finlink_mobile/models/transaction/transaction_models.dart';
import 'package:finlink_mobile/models/notification/notification_models.dart';
import 'package:finlink_mobile/models/wallet/wallet_models.dart';
import 'package:finlink_mobile/services/cards/linked_cards_store.dart';
import 'package:finlink_mobile/services/notification/notification_service.dart';
import 'package:finlink_mobile/services/transaction/transaction_service.dart';
import 'package:finlink_mobile/services/transaction/transaction_refresh_notifier.dart';
import 'package:finlink_mobile/services/wallet/wallet_service.dart';
import 'package:finlink_mobile/utils/bank_names.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeViewmodel extends BaseViewmodel {
	HomeViewmodel(
		this._walletService,
		this._transactionService,
		this._notificationService,
		this._transactionRefresh,
		this._linkedCardsStore,
	) {
		_transactionRefresh.addListener(_handleTransactionRefresh);
		_linkedCardsStore.addListener(_handleLinkedCardsChanged);
	}

	final WalletService _walletService;
	final TransactionService _transactionService;
	final NotificationService _notificationService;
	final TransactionRefreshNotifier _transactionRefresh;
	final LinkedCardsStore _linkedCardsStore;
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
	Timer? _transactionTimer;
	bool _isTransactionsLoading = false;
	String? _transactionsError;
	List<TransactionRecord> _recentTransactions = [];
	StreamSubscription<List<NotificationEvent>>? _notificationSubscription;
	bool _isNotificationsLoading = false;
	String? _notificationsError;
	List<NotificationEvent> _notifications = [];
	final Set<String> _locallyReadNotificationIds = <String>{};
	bool _isSending = false;
	String? _sendErrorMessage;

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
	bool get isTransactionsLoading => _isTransactionsLoading;
	String? get transactionsError => _transactionsError;
	List<TransactionRecord> get recentTransactions => _recentTransactions;
	bool get isNotificationsLoading => _isNotificationsLoading;
	String? get notificationsError => _notificationsError;
	List<NotificationEvent> get notifications => _notifications;
	int get unreadNotificationsCount =>
			_notifications.where((item) => item.isUnread).length;
	bool get isSending => _isSending;
	String? get sendErrorMessage => _sendErrorMessage;
	BankName? get linkedBank => _linkedCardsStore.primaryBank;
	bool get hasLinkedCard => _linkedCardsStore.hasCards;
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

		void startTransactionPolling({Duration interval = const Duration(seconds: 15)}) {
			_transactionTimer?.cancel();
			loadRecentTransactions();
			_transactionTimer = Timer.periodic(interval, (_) => loadRecentTransactions());
		}

		void startNotificationStream({Duration interval = const Duration(seconds: 20)}) {
			_notificationSubscription?.cancel();
			_isNotificationsLoading = true;
			_notificationsError = null;
			notifyListeners();

			_notificationSubscription = _notificationService
					.watchMyNotifications(interval: interval)
					.listen(
						(values) {
							_notifications = _applyLocalReadOverrides(values);
							_isNotificationsLoading = false;
							_notificationsError = null;
							notifyListeners();
						},
						onError: (error) {
							_isNotificationsLoading = false;
							_notificationsError = error is NotificationServiceException
									? error.message
									: 'Unable to load notifications right now.';
							notifyListeners();
						},
					);
		}

		Future<void> loadNotifications({bool force = false}) async {
			if (_isNotificationsLoading && !force) {
				return;
			}

			_isNotificationsLoading = true;
			_notificationsError = null;
			notifyListeners();

			try {
				final values = await _notificationService.listMyNotifications();
				_notifications = _applyLocalReadOverrides(values);
			} on NotificationServiceException catch (error) {
				_notificationsError = error.message;
			} catch (_) {
				_notificationsError = 'Unable to load notifications right now.';
			} finally {
				_isNotificationsLoading = false;
				notifyListeners();
			}
		}

		void _handleTransactionRefresh() {
			loadRecentTransactions();
		}

		void _handleLinkedCardsChanged() {
			notifyListeners();
		}

		Future<void> loadRecentTransactions({int limit = 5}) async {
			if (_isTransactionsLoading) {
				return;
			}

			_isTransactionsLoading = true;
			_transactionsError = null;
			notifyListeners();

			try {
				final response = await _transactionService.listMyTransactions(
					limit: limit,
					skip: 0,
				);
				_recentTransactions = response.transactions;
			} on TransactionServiceException catch (error) {
				_transactionsError = error.message;
			} catch (_) {
				_transactionsError = 'Unable to load transactions right now.';
			} finally {
				_isTransactionsLoading = false;
				notifyListeners();
			}
		}

		Future<void> markNotificationRead(NotificationEvent notification) async {
			if (notification.isRead) {
				return;
			}

			final optimistic = _notifications.map((item) {
				if (item.id == notification.id) {
					_locallyReadNotificationIds.add(item.id);
					return NotificationEvent(
						id: item.id,
						userId: item.userId,
						eventType: item.eventType,
						title: item.title,
						message: item.message,
						isRead: true,
						createdAt: item.createdAt,
						payload: item.payload,
						raw: item.raw,
					);
				}
				return item;
			}).toList();
			_notifications = optimistic;
			notifyListeners();

			try {
				await _notificationService.markRead(notification.id);
			} catch (_) {
				// no-op: UI stays optimistic
			}
		}

		List<NotificationEvent> _applyLocalReadOverrides(
			List<NotificationEvent> values,
		) {
			if (_locallyReadNotificationIds.isEmpty) {
				return values;
			}
			return values.map((item) {
				if (_locallyReadNotificationIds.contains(item.id)) {
					return NotificationEvent(
						id: item.id,
						userId: item.userId,
						eventType: item.eventType,
						title: item.title,
						message: item.message,
						isRead: true,
						createdAt: item.createdAt,
						payload: item.payload,
						raw: item.raw,
					);
				}
				return item;
			}).toList();
		}

		bool isTransactionIncoming(TransactionRecord record) {
			final walletId = _wallet?.id;
			if (walletId != null && walletId.isNotEmpty) {
				return record.receiverWalletId == walletId;
			}

			switch (record.transactionType) {
				case TransactionType.deposit:
					return true;
				case TransactionType.withdrawal:
					return false;
				default:
					return record.isIncoming;
			}
		}

		String formatTransactionTime(TransactionRecord record) {
			final createdAt = record.createdAt;
			if (createdAt == null) {
				return 'Just now';
			}

			final now = DateTime.now();
			final isToday = now.year == createdAt.year &&
				now.month == createdAt.month &&
				now.day == createdAt.day;
			if (isToday) {
				return 'Today ${DateFormat('h:mm a').format(createdAt)}';
			}
			return DateFormat('MMM d, h:mm a').format(createdAt);
		}

	@override
	void dispose() {
		_walletSubscription?.cancel();
		_transactionTimer?.cancel();
		_notificationSubscription?.cancel();
		_transactionRefresh.removeListener(_handleTransactionRefresh);
		_linkedCardsStore.removeListener(_handleLinkedCardsChanged);
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

	Future<bool> submitSendForm(BuildContext context) async {
		if (_isSending) {
			return false;
		}

		if (!(sendFormKey.currentState?.validate() ?? false)) {
			return false;
		}

		final receiverPhone = receiverAddressController.text.trim();
		final amount = double.tryParse(amountController.text.trim());
		final note = remarksController.text.trim();
		if (receiverPhone.isEmpty) {
			_showSnack(context, "Receiver's address is required.");
			return false;
		}
		if (amount == null || amount <= 0) {
			_showSnack(context, 'Enter a valid amount.');
			return false;
		}

		_isSending = true;
		_sendErrorMessage = null;
		notifyListeners();

		try {
			await _transactionService.transfer(
				TransferRequest(
					receiverPhone: receiverPhone,
					amount: amount,
					note: note.isEmpty ? null : note,
				),
			);
			_transactionRefresh.notifyRefresh();
			return true;
		} on TransactionServiceException catch (error) {
			_sendErrorMessage = error.message;
			_showSnack(context, error.message);
			return false;
		} catch (_) {
			const message = 'Unable to send funds right now.';
			_sendErrorMessage = message;
			_showSnack(context, message);
			return false;
		} finally {
			_isSending = false;
			notifyListeners();
		}
	}

	void closeSendBottomSheet(BuildContext context) {
		clearSendForm();
		Navigator.pop(context);
	}

	void clearSendForm() {
		receiverAddressController.clear();
		amountController.clear();
		remarksController.clear();
		_sendErrorMessage = null;
		notifyListeners();
	}

	void setReceiverAddress(String value) {
		receiverAddressController.text = value;
		notifyListeners();
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
		final selectedBank = _selectedBank;
		if (selectedBank != null) {
			_linkedCardsStore.addBank(selectedBank);
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

	void _showSnack(BuildContext context, String message) {
		if (!context.mounted) {
			return;
		}
		ScaffoldMessenger.of(context).showSnackBar(
			SnackBar(content: Text(message)),
		);
	}


}