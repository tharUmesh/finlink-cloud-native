import 'package:finlink_mobile/features/base_viewmodel.dart';
import 'package:finlink_mobile/services/auth/auth_session.dart';
import 'package:finlink_mobile/services/wallet/wallet_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReceiveViewmodel extends BaseViewmodel {
  ReceiveViewmodel(this._authSession, this._walletService) {
    _walletId = _authSession.walletId;
    _loadWalletId();
  }

  final AuthSession _authSession;
  final WalletService _walletService;
  static const String qrAssetPath = 'images/dummy-qr.png';

  String? _walletId;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasWalletId => (_walletId ?? '').isNotEmpty;
  bool get hasError => _errorMessage != null && _errorMessage!.isNotEmpty;

  String get walletIdLabel {
    if (_isLoading) {
      return 'Loading wallet ID...';
    }
    if (hasError) {
      return _errorMessage!;
    }
    return hasWalletId ? _walletId! : 'Wallet ID unavailable';
  }

  Future<void> _loadWalletId() async {
    if (_isLoading) {
      return;
    }

    if ((_walletId ?? '').isNotEmpty) {
      return;
    }

    if (!_authSession.isAuthenticated) {
      _errorMessage = 'Please login to view your wallet ID.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final wallet = await _walletService.getMyWallet();
      _walletId = wallet.id;
      _authSession.setWalletId(wallet.id);
    } on WalletServiceException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load wallet ID right now.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> copyWalletId(BuildContext context) async {
    if (!hasWalletId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wallet ID is not available yet.')),
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: _walletId ?? ''));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wallet ID copied to clipboard')),
    );
  }
}