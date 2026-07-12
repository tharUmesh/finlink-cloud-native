import 'dart:convert';

import 'package:finlink_mobile/models/transaction/transaction_models.dart';
import 'package:finlink_mobile/services/auth/auth_session.dart';
import 'package:http/http.dart' as http;

class TransactionService {
  TransactionService(
    this._session, {
    http.Client? client,
    this.baseUrl = 'https://transaction-service.bravesmoke-f55615c7.eastasia.azurecontainerapps.io',
    this.transferPath = '/transfer',
    this.depositPath = '/deposit',
    this.transactionsPath = '/transactions',
  }) : _client = client ?? http.Client();

  final AuthSession _session;
  final http.Client _client;
  final String baseUrl;
  final String transferPath;
  final String depositPath;
  final String transactionsPath;

  Future<TransactionRecord> transfer(
    TransferRequest request, {
    String? idempotencyKey,
  }) async {
    final uri = _buildUri(transferPath);
    final headers = _buildHeaders(requireAuth: true);
    if (idempotencyKey != null && idempotencyKey.trim().isNotEmpty) {
      headers['Idempotency-Key'] = idempotencyKey;
    }

    final response = await _client.post(
      uri,
      headers: headers,
      body: jsonEncode(request.toJson()),
    );

    return _handleTransactionResponse(response, 'Unable to submit transfer.');
  }

  Future<TransactionRecord> deposit(DepositRequest request) async {
    final uri = _buildUri(depositPath);
    final response = await _client.post(
      uri,
      headers: _buildHeaders(requireAuth: true),
      body: jsonEncode(request.toJson()),
    );

    return _handleTransactionResponse(response, 'Unable to deposit funds.');
  }

  Future<TransactionListResponse> listMyTransactions({
    int skip = 0,
    int limit = 20,
  }) async {
    final uri = _buildUri(
      transactionsPath,
      queryParameters: {
        'skip': skip.toString(),
        'limit': limit.toString(),
      },
    );
    final response = await _client.get(
      uri,
      headers: _buildHeaders(requireAuth: true),
    );

    final Map<String, dynamic> decodedBody = _decodeResponse(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw TransactionServiceException(
        _extractMessage(decodedBody) ?? 'Unable to load transactions.',
        statusCode: response.statusCode,
      );
    }

    return TransactionListResponse.fromJson(decodedBody);
  }

  Future<TransactionRecord> getTransactionById(String transactionId) async {
    final uri = _buildUri('$transactionsPath/$transactionId');
    final response = await _client.get(
      uri,
      headers: _buildHeaders(requireAuth: true),
    );

    return _handleTransactionResponse(response, 'Unable to load transaction.');
  }

  TransactionRecord _handleTransactionResponse(
    http.Response response,
    String fallbackMessage,
  ) {
    final Map<String, dynamic> decodedBody = _decodeResponse(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw TransactionServiceException(
        _extractMessage(decodedBody) ?? fallbackMessage,
        statusCode: response.statusCode,
      );
    }

    return TransactionRecord.fromJson(decodedBody);
  }

  Map<String, String> _buildHeaders({required bool requireAuth}) {
    if (requireAuth && !_session.isAuthenticated) {
      throw const TransactionServiceException('No active session. Please login again.');
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

class TransactionServiceException implements Exception {
  const TransactionServiceException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    if (statusCode == null) {
      return message;
    }
    return 'TransactionServiceException($statusCode): $message';
  }
}
