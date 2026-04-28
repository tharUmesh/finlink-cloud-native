import 'dart:convert';

import 'package:finlink_mobile/models/user/user_profile_models.dart';
import 'package:finlink_mobile/services/auth/auth_session.dart';
import 'package:http/http.dart' as http;

class UserService {
  UserService(
    this._session, {
    http.Client? client,
    this.baseUrl = 'https://user-service.bravesmoke-f55615c7.eastasia.azurecontainerapps.io',
    this.profilePath = '/me',
  }) : _client = client ?? http.Client();

  final AuthSession _session;
  final http.Client _client;
  final String baseUrl;
  final String profilePath;

  Future<UserProfile> getProfile() async {
    if (!_session.isAuthenticated) {
      throw const UserServiceException('No active session. Please login again.');
    }

    final uri = _buildUri(profilePath);
    final response = await _client.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': '${_session.tokenType} ${_session.accessToken}',
      },
    );

    final Map<String, dynamic> decodedBody = _decodeResponse(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw UserServiceException(
        _extractMessage(decodedBody) ?? 'Unable to load profile.',
        statusCode: response.statusCode,
      );
    }

    return UserProfile.fromJson(decodedBody);
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

class UserServiceException implements Exception {
  const UserServiceException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    if (statusCode == null) {
      return message;
    }
    return 'UserServiceException($statusCode): $message';
  }
}