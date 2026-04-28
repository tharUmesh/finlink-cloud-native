import 'package:finlink_mobile/features/base_viewmodel.dart';
import 'package:finlink_mobile/models/transaction/transaction_models.dart';
import 'package:finlink_mobile/services/auth/auth_session.dart';
import 'package:finlink_mobile/services/transaction/transaction_service.dart';
import 'package:finlink_mobile/services/wallet/wallet_service.dart';
import 'package:flutter/material.dart';

class DepositViewmodel extends BaseViewmodel {
  DepositViewmodel(
    this._authSession,
    this._walletService,
    this._transactionService,
  ) {
    _walletId = _authSession.walletId;
    walletIdController.text = _walletId ?? '';
    _loadWalletId();
  }

  final AuthSession _authSession;
  final WalletService _walletService;
  final TransactionService _transactionService;

  final depositFormKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final walletIdController = TextEditingController();

  String? _walletId;
  bool _isLoadingWalletId = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get isLoadingWalletId => _isLoadingWalletId;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  bool get hasWalletId => (_walletId ?? '').isNotEmpty;

  String? validateWalletId(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return 'Wallet ID is unavailable';
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

  Future<void> refreshWalletId() async {
    await _loadWalletId(force: true);
  }

  Future<bool> submit(BuildContext context) async {
    if (_isSubmitting) {
      return false;
    }

    if (!(depositFormKey.currentState?.validate() ?? false)) {
      return false;
    }

    if (!hasWalletId) {
      _showSnack(context, 'Wallet ID is not available yet.');
      return false;
    }

    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showSnack(context, 'Enter a valid amount.');
      return false;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _transactionService.deposit(
        DepositRequest(walletId: _walletId!, amount: amount),
      );
      return true;
    } on TransactionServiceException catch (error) {
      _errorMessage = error.message;
      _showSnack(context, error.message);
      return false;
    } catch (_) {
      const message = 'Unable to deposit funds right now.';
      _errorMessage = message;
      _showSnack(context, message);
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  void clear() {
    amountController.clear();
    _errorMessage = null;
    notifyListeners();
  }

  void close(BuildContext context) {
    clear();
    Navigator.pop(context);
  }

  Future<void> _loadWalletId({bool force = false}) async {
    if (_isLoadingWalletId) {
      return;
    }

    if (!force && (_walletId ?? '').isNotEmpty) {
      return;
    }

    if (!_authSession.isAuthenticated) {
      _errorMessage = 'Please login to access your wallet ID.';
      notifyListeners();
      return;
    }

    _isLoadingWalletId = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final wallet = await _walletService.getMyWallet();
      _walletId = wallet.id;
      _authSession.setWalletId(wallet.id);
      walletIdController.text = wallet.id;
    } on WalletServiceException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load wallet ID right now.';
    } finally {
      _isLoadingWalletId = false;
      notifyListeners();
    }
  }

  void _showSnack(BuildContext context, String message) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    amountController.dispose();
    walletIdController.dispose();
    super.dispose();
  }
}
