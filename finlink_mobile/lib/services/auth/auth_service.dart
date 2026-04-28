import 'dart:convert';

import 'package:finlink_mobile/models/auth/auth_models.dart';
import 'package:http/http.dart' as http;

class AuthService {
  AuthService({
    http.Client? client,
    this.baseUrl = 'https://user-service.bravesmoke-f55615c7.eastasia.azurecontainerapps.io',
    this.loginPath = '/login',
    this.registerPath = '/register',
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  final String loginPath;
  final String registerPath;

  Future<AuthResponse> login(LoginRequest request) {
    return _post(loginPath, request.toJson());
  }

  Future<AuthResponse> register(RegisterRequest request) {
    return _post(registerPath, request.toJson());
  }

  Future<AuthResponse> _post(String path, Map<String, dynamic> body) async {
    final uri = _buildUri(path);
    final response = await _client.post(
      uri,
      headers: const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );

    final Map<String, dynamic> decodedBody = _decodeResponse(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        message: _extractMessage(decodedBody) ?? 'Authentication request failed.',
        statusCode: response.statusCode,
        responseBody: decodedBody,
      );
    }

    return AuthResponse.fromJson(decodedBody);
  }

  Map<String, dynamic> _decodeResponse(String body) {
    if (body.trim().isEmpty) {
      return <String, dynamic>{};
    }

    final dynamic decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return Map<String, dynamic>.from(decoded);
    }
    return <String, dynamic>{'data': decoded};
  }

  String? _extractMessage(Map<String, dynamic> body) {
    final dynamic data = body['message'] ?? body['detail'] ?? body['error'];
    if (data != null) {
      return data.toString();
    }

    final dynamic nested = body['data'];
    if (nested is Map<String, dynamic>) {
      final dynamic nestedMessage = nested['message'] ?? nested['detail'] ?? nested['error'];
      if (nestedMessage != null) {
        return nestedMessage.toString();
      }
    }

    return null;
  }

  Uri _buildUri(String path) {
    final base = Uri.parse(baseUrl);
    final joinedPath = _joinPaths(base.path, path);
    return base.replace(path: joinedPath);
  }

  String _joinPaths(String basePath, String path) {
    final normalizedBase = basePath.endsWith('/') && basePath.length > 1
        ? basePath.substring(0, basePath.length - 1)
        : basePath;
    var normalizedPath = path.startsWith('/') ? path : '/$path';
    if (normalizedBase.endsWith('/api') && normalizedPath.startsWith('/api/')) {
      normalizedPath = normalizedPath.substring('/api'.length);
    }

    if (normalizedBase.isEmpty || normalizedBase == '/') {
      return normalizedPath;
    }
    return '$normalizedBase$normalizedPath';
  }
}

class AuthException implements Exception {
  const AuthException({
    required this.message,
    this.statusCode,
    this.responseBody,
  });

  final String message;
  final int? statusCode;
  final Map<String, dynamic>? responseBody;

  @override
  String toString() {
    if (statusCode == null) {
      return message;
    }
    return 'AuthException($statusCode): $message';
  }
}