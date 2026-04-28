import 'dart:convert';

import 'package:finlink_mobile/models/notification/notification_models.dart';
import 'package:finlink_mobile/services/auth/auth_session.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  NotificationService(
    this._session, {
    http.Client? client,
    this.baseUrl =
        'https://notification-service.bravesmoke-f55615c7.eastasia.azurecontainerapps.io',
    this.notificationsPath = '/notifications',
  }) : _client = client ?? http.Client();

  final AuthSession _session;
  final http.Client _client;
  final String baseUrl;
  final String notificationsPath;

  Future<List<NotificationEvent>> listMyNotifications({
    int skip = 0,
    int limit = 20,
  }) {
    final userId = _session.user?.id;
    if (!_session.isAuthenticated || userId == null || userId.isEmpty) {
      throw const NotificationServiceException('No active session. Please login again.');
    }

    return listNotificationsForUser(
      userId,
      skip: skip,
      limit: limit,
      requireAuth: true,
    );
  }

  Future<List<NotificationEvent>> listNotificationsForUser(
    String userId, {
    int skip = 0,
    int limit = 20,
    bool requireAuth = false,
  }) async {
    final uri = _buildUri(
      '$notificationsPath/$userId',
      queryParameters: {
        'skip': skip.toString(),
        'limit': limit.toString(),
      },
    );
    final response = await _client.get(
      uri,
      headers: _buildHeaders(requireAuth: requireAuth),
    );

    final dynamic decoded = _decodeDynamic(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final Map<String, dynamic> decodedBody = _coerceMap(decoded);
      throw NotificationServiceException(
        _extractMessage(decodedBody) ?? 'Unable to load notifications.',
        statusCode: response.statusCode,
      );
    }

    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(NotificationEvent.fromJson)
          .toList();
    }

    if (decoded is Map) {
      final map = Map<String, dynamic>.from(decoded);
      return [NotificationEvent.fromJson(map)];
    }

    return [];
  }

  Future<NotificationEvent> markRead(
    String notificationId, {
    bool requireAuth = true,
  }) async {
    final uri = _buildUri('$notificationsPath/$notificationId/read');
    final response = await _client.post(
      uri,
      headers: _buildHeaders(requireAuth: requireAuth),
      body: jsonEncode(<String, dynamic>{}),
    );

    final Map<String, dynamic> decodedBody = _decodeResponse(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw NotificationServiceException(
        _extractMessage(decodedBody) ?? 'Unable to mark notification as read.',
        statusCode: response.statusCode,
      );
    }

    return NotificationEvent.fromJson(decodedBody);
  }

  Map<String, String> _buildHeaders({required bool requireAuth}) {
    if (requireAuth && !_session.isAuthenticated) {
      throw const NotificationServiceException('No active session. Please login again.');
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_session.isAuthenticated) {
      headers['Authorization'] = '${_session.tokenType} ${_session.accessToken}';
    }

    return headers;
  }

  Map<String, dynamic> _decodeResponse(String body) {
    final dynamic decoded = _decodeDynamic(body);
    return _coerceMap(decoded);
  }

  dynamic _decodeDynamic(String body) {
    if (body.trim().isEmpty) {
      return <String, dynamic>{};
    }
    return jsonDecode(body);
  }

  Map<String, dynamic> _coerceMap(dynamic decoded) {
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
      final dynamic nestedMessage =
          nested['message'] ?? nested['detail'] ?? nested['error'];
      if (nestedMessage != null) {
        return nestedMessage.toString();
      }
    }

    return null;
  }

  Uri _buildUri(String path, {Map<String, String>? queryParameters}) {
    final base = Uri.parse(baseUrl);
    final joinedPath = _joinPaths(base.path, path);
    return base.replace(path: joinedPath, queryParameters: queryParameters);
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

class NotificationServiceException implements Exception {
  const NotificationServiceException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    if (statusCode == null) {
      return message;
    }
    return 'NotificationServiceException($statusCode): $message';
  }
}
