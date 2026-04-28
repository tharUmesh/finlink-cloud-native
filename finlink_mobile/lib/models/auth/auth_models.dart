class LoginRequest {
  const LoginRequest({
    required this.phoneNumber,
    required this.password,
  });

  final String phoneNumber;
  final String password;

  Map<String, dynamic> toJson() {
    return {
      'phone_number': phoneNumber,
      'password': password,
    };
  }
}

class RegisterRequest {
  const RegisterRequest({
    required this.fullName,
    required this.phoneNumber,
    required this.nationalId,
    required this.password,
  });

  final String fullName;
  final String phoneNumber;
  final String nationalId;
  final String password;

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'phone_number': phoneNumber,
      'national_id': nationalId,
      'password': password,
    };
  }
}

class AuthUser {
  const AuthUser({
    required this.id,
    this.name,
    this.email,
    this.phone,
    this.nic,
    this.role,
    this.walletId,
    this.raw = const {},
  });

  final String id;
  final String? name;
  final String? email;
  final String? phone;
  final String? nic;
  final String? role;
  final String? walletId;
  final Map<String, dynamic> raw;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: _readString(json, ['id', 'user_id', 'userId']) ?? '',
      name: _readString(json, ['name', 'full_name', 'fullName']),
      email: _readString(json, ['email']),
      phone: _readString(json, ['phone', 'phone_number', 'phoneNumber']),
      nic: _readString(json, ['nic', 'national_id', 'nationalId']),
      role: _readString(json, ['role']),
      walletId: _readString(json, ['wallet_id', 'walletId']),
      raw: json,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'nic': nic,
      'role': role,
      'wallet_id': walletId,
    };
  }
}

class AuthResponse {
  const AuthResponse({
    this.accessToken,
    this.refreshToken,
    this.tokenType,
    this.user,
    this.message,
    this.raw = const {},
  });

  final String? accessToken;
  final String? refreshToken;
  final String? tokenType;
  final AuthUser? user;
  final String? message;
  final Map<String, dynamic> raw;

  bool get isAuthenticated => accessToken != null && accessToken!.isNotEmpty;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> payload = _readMap(json, ['data']) ?? json;
    final Map<String, dynamic>? userJson =
        _readMap(payload, ['user', 'account', 'profile']) ?? _readMap(json, ['user']);

    return AuthResponse(
      accessToken: _readString(payload, [
        'access_token',
        'accessToken',
        'token',
        'jwt',
      ]),
      refreshToken: _readString(payload, [
        'refresh_token',
        'refreshToken',
      ]),
      tokenType: _readString(payload, ['token_type', 'tokenType']) ?? 'Bearer',
      user: userJson == null ? null : AuthUser.fromJson(userJson),
      message: _readString(json, ['message', 'detail', 'error']) ??
          _readString(payload, ['message', 'detail', 'error']),
      raw: json,
    );
  }
}

String? _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null) {
      return value.toString();
    }
  }
  return null;
}

Map<String, dynamic>? _readMap(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
  }
  return null;
}