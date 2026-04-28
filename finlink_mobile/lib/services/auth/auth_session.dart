import 'package:finlink_mobile/models/auth/auth_models.dart';

class AuthSession {
  String? _accessToken;
  String _tokenType = 'Bearer';
  AuthUser? _user;
  String? _walletId;

  String? get accessToken => _accessToken;
  String get tokenType => _tokenType;
  AuthUser? get user => _user;
  String? get walletId => _walletId;
  bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;

  void applyAuthResponse(AuthResponse response) {
    _accessToken = response.accessToken;
    _tokenType = response.tokenType ?? 'Bearer';
    _user = response.user;
    _walletId = response.user?.walletId;
  }

  void setWalletId(String? walletId) {
    _walletId = walletId;
  }

  void clear() {
    _accessToken = null;
    _user = null;
    _tokenType = 'Bearer';
    _walletId = null;
  }
}