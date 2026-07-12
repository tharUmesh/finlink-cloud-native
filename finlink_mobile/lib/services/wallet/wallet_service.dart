import 'dart:async';
import 'dart:convert';

import 'package:finlink_mobile/models/wallet/wallet_models.dart';
import 'package:finlink_mobile/services/auth/auth_session.dart';
import 'package:http/http.dart' as http;

class WalletService {
  WalletService(
    this._session, {
    http.Client? client,
    this.baseUrl = 'https://wallet-service.bravesmoke-f55615c7.eastasia.azurecontainerapps.io',
    this.walletsPath = '/wallets',
    this.userWalletPath = '/wallets/user',
  }) : _client = client ?? http.Client();

  final AuthSession _session;
  final http.Client _client;
  final String baseUrl;
  final String walletsPath;
  final String userWalletPath;

  Future<Wallet> getMyWallet() {
    if (!_session.isAuthenticated) {
      throw const WalletServiceException('No active session. Please login again.');
    }
    final userId = _session.user?.id;
    if (userId == null || userId.isEmpty) {
      throw const WalletServiceException('User ID is unavailable. Please login again.');
    }
    return _getWallet('$userWalletPath/$userId', requireAuth: true);
  }

  Stream<Wallet> watchMyWallet({Duration interval = const Duration(seconds: 10)}) {
    final controller = StreamController<Wallet>();
    Timer? timer;

    Future<void> fetchWallet() async {
      try {
        final wallet = await getMyWallet();
        if (!controller.isClosed) {
          controller.add(wallet);
        }
      } catch (error, stackTrace) {
        if (!controller.isClosed) {
          controller.addError(error, stackTrace);
        }
      }
    }

    controller.onListen = () {
      fetchWallet();
      timer = Timer.periodic(interval, (_) => fetchWallet());
    };

    controller.onCancel = () {
      timer?.cancel();
    };

    return controller.stream;
  }

  Future<Wallet> getWalletById(String walletId) {
    return _getWallet('$walletsPath/$walletId', requireAuth: false);
  }

  Future<Wallet> getWalletByUserId(String userId) {
    return _getWallet('$userWalletPath/$userId', requireAuth: false);
  }

  Future<List<WalletSummary>> listWallets() async {
    final uri = _buildUri(walletsPath);
    final response = await _client.get(
      uri,
      headers: _buildHeaders(requireAuth: true),
    );

    final dynamic decoded = _decodeDynamic(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final Map<String, dynamic> decodedBody = _coerceMap(decoded);
      throw WalletServiceException(
        _extractMessage(decodedBody) ?? 'Unable to load wallets.',
        statusCode: response.statusCode,
      );
    }

    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(WalletSummary.fromJson)
          .toList();
    }
    return [];
  }

  Future<Wallet> updateBalance(
    String walletId,
    WalletBalanceUpdateRequest request, {
    bool requireAuth = false,
  }) async {
    final uri = _buildUri('$walletsPath/$walletId/balance');
    final response = await _client.put(
      uri,
      headers: _buildHeaders(requireAuth: requireAuth),
      body: jsonEncode(request.toJson()),
    );

    return _handleWalletResponse(response, 'Unable to update balance.');
  }

  Future<Wallet> freezeWallet(String walletId) {
    return _postWallet('$walletsPath/$walletId/freeze');
  }

  Future<Wallet> unfreezeWallet(String walletId) {
    return _postWallet('$walletsPath/$walletId/unfreeze');
  }

  Future<Wallet> _getWallet(String path, {required bool requireAuth}) async {
    final uri = _buildUri(path);
    final response = await _client.get(
      uri,
      headers: _buildHeaders(requireAuth: requireAuth),
    );

    return _handleWalletResponse(response, 'Unable to load wallet.');
  }

  Future<Wallet> _postWallet(String path) async {
    final uri = _buildUri(path);
    final response = await _client.post(
      uri,
      headers: _buildHeaders(requireAuth: true),
      body: jsonEncode(<String, dynamic>{}),
    );

    return _handleWalletResponse(response, 'Unable to update wallet.');
  }

  Wallet _handleWalletResponse(http.Response response, String fallbackMessage) {
    final Map<String, dynamic> decodedBody = _decodeResponse(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw WalletServiceException(
        _extractMessage(decodedBody) ?? fallbackMessage,
        statusCode: response.statusCode,
      );
    }

    return Wallet.fromJson(decodedBody);
  }

  Map<String, String> _buildHeaders({required bool requireAuth}) {
    if (requireAuth && !_session.isAuthenticated) {
      throw const WalletServiceException('No active session. Please login again.');
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

class WalletServiceException implements Exception {
  const WalletServiceException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() {
    if (statusCode == null) {
      return message;
    }
    return 'WalletServiceException($statusCode): $message';
  }
}
