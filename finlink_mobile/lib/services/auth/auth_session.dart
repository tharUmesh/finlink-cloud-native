import 'package:finlink_mobile/models/auth/auth_models.dart';

class AuthSession {
  String? _accessToken;
  String _tokenType = 'Bearer';
  AuthUser? _user;

  String? get accessToken => _accessToken;
  String get tokenType => _tokenType;
  AuthUser? get user => _user;
  bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;

  void applyAuthResponse(AuthResponse response) {
    _accessToken = response.accessToken;
    _tokenType = response.tokenType ?? 'Bearer';
    _user = response.user;
  }

  void clear() {
    _accessToken = null;
    _user = null;
    _tokenType = 'Bearer';
  }
}