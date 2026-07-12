import 'dart:convert';

import 'package:finlink_mobile/models/loan/loan_models.dart';
import 'package:finlink_mobile/services/auth/auth_session.dart';
import 'package:http/http.dart' as http;

class LoanService {
  LoanService(
    this._session, {
    http.Client? client,
    this.baseUrl = 'https://loan-service.bravesmoke-f55615c7.eastasia.azurecontainerapps.io',
    this.applyPath = '/loans/apply',
    this.openLoansPath = '/loans/open',
    this.loansPath = '/loans',
  }) : _client = client ?? http.Client();

  final AuthSession _session;
  final http.Client _client;
  final String baseUrl;
  final String applyPath;
  final String openLoansPath;
  final String loansPath;

  Future<LoanApplicationResponse> applyForLoan(
    LoanApplicationRequest request,
  ) async {
    final uri = _buildUri(applyPath);
    final response = await _client.post(
      uri,
      headers: _buildHeaders(requireAuth: true),
      body: jsonEncode(request.toJson()),
    );

    final Map<String, dynamic> decodedBody = _decodeResponse(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw LoanServiceException(
        _extractMessage(decodedBody) ?? 'Unable to submit loan request.',
        statusCode: response.statusCode,
      );
    }

    return LoanApplicationResponse.fromJson(decodedBody);
  }

  Future<List<LoanRecord>> listOpenLoans() async {
    final uri = _buildUri(openLoansPath);
    final response = await _client.get(
      uri,
      headers: _buildHeaders(requireAuth: true),
    );

    final dynamic decoded = _decodeDynamic(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final Map<String, dynamic> decodedBody = _coerceMap(decoded);
      throw LoanServiceException(
        _extractMessage(decodedBody) ?? 'Unable to load loan requests.',
        statusCode: response.statusCode,
      );
    }

    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(LoanRecord.fromJson)
          .toList();
    }
    return [];
  }

  Future<List<LoanRecord>> listMyLoans() async {
    final uri = _buildUri(loansPath);
    final response = await _client.get(
      uri,
      headers: _buildHeaders(requireAuth: true),
    );

    final dynamic decoded = _decodeDynamic(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final Map<String, dynamic> decodedBody = _coerceMap(decoded);
      throw LoanServiceException(
        _extractMessage(decodedBody) ?? 'Unable to load your loans.',
        statusCode: response.statusCode,
      );
    }

    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(LoanRecord.fromJson)
          .toList();
    }
    return [];
  }

  Future<LoanRecord> fundLoan(
    String loanId,
    FundLoanRequest request,
  ) async {
    final uri = _buildUri('$loansPath/$loanId/fund');
    final response = await _client.post(
      uri,
      headers: _buildHeaders(requireAuth: true),
      body: jsonEncode(request.toJson()),
    );

    final Map<String, dynamic> decodedBody = _decodeResponse(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw LoanServiceException(
        _extractMessage(decodedBody) ?? 'Unable to fund loan.',
        statusCode: response.statusCode,
      );
    }

    return LoanRecord.fromJson(decodedBody);
  }

  Map<String, String> _buildHeaders({required bool requireAuth}) {
    if (requireAuth && !_session.isAuthenticated) {
      throw const LoanServiceException('No active session. Please login again.');
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

class LoanServiceException implements Exception {
  const LoanServiceException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    if (statusCode == null) {
      return message;
    }
    return 'LoanServiceException($statusCode): $message';
  }
}
