import 'package:finlink_mobile/features/base_viewmodel.dart';
import 'package:finlink_mobile/services/auth/auth_session.dart';
import 'package:finlink_mobile/services/user/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReceiveViewmodel extends BaseViewmodel {
  ReceiveViewmodel(this._authSession, this._userService) {
    _phoneNumber = _authSession.user?.phone;
    _loadPhoneNumber();
  }

  final AuthSession _authSession;
  final UserService _userService;
  static const String qrAssetPath = 'images/dummy-qr.png';

  String? _phoneNumber;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasPhoneNumber => (_phoneNumber ?? '').isNotEmpty;
  bool get hasError => _errorMessage != null && _errorMessage!.isNotEmpty;
  String? get phoneNumber => _phoneNumber;

  String get phoneNumberLabel {
    if (_isLoading) {
      return 'Loading phone number...';
    }
    if (hasError) {
      return _errorMessage!;
    }
    return hasPhoneNumber ? _phoneNumber! : 'Phone number unavailable';
  }

  Future<void> _loadPhoneNumber() async {
    if (_isLoading) {
      return;
    }

    if ((_phoneNumber ?? '').isNotEmpty) {
      return;
    }

    if (!_authSession.isAuthenticated) {
      _errorMessage = 'Please login to view your phone number.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final profile = await _userService.getProfile();
      _phoneNumber = profile.phoneNumber;
    } on UserServiceException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'Unable to load phone number right now.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> copyPhoneNumber(BuildContext context) async {
    if (!hasPhoneNumber) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number is not available yet.')),
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: _phoneNumber ?? ''));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Phone number copied to clipboard')),
    );
  }
}