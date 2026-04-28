enum WalletBalanceOperation {
  credit,
  debit,
  set,
}

class CreateWalletRequest {
  const CreateWalletRequest({required this.userId});

  final String userId;

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
    };
  }
}

class WalletBalanceUpdateRequest {
  const WalletBalanceUpdateRequest({
    required this.amount,
    required this.operation,
  });

  final double amount;
  final WalletBalanceOperation operation;

  Map<String, dynamic> toJson() {
    return {
      'amount': amount.toStringAsFixed(2),
      'operation': _operationToString(operation),
    };
  }

  String _operationToString(WalletBalanceOperation value) {
    switch (value) {
      case WalletBalanceOperation.credit:
        return 'credit';
      case WalletBalanceOperation.debit:
        return 'debit';
      case WalletBalanceOperation.set:
        return 'set';
    }
  }
}

class Wallet {
  const Wallet({
    required this.id,
    required this.userId,
    required this.balance,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.raw = const {},
  });

  final String id;
  final String userId;
  final double balance;
  final String currency;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> raw;

  bool get isFrozen => status.toLowerCase() == 'frozen';

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: _readString(json, ['id', 'wallet_id', 'walletId']) ?? '',
      userId: _readString(json, ['user_id', 'userId']) ?? '',
      balance: _readDouble(json, ['balance']) ?? 0,
      currency: _readString(json, ['currency']) ?? 'LKR',
      status: _readString(json, ['is_frozen', 'status']) ?? 'active',
      createdAt: _readDateTime(json, ['created_at', 'createdAt']),
      updatedAt: _readDateTime(json, ['updated_at', 'updatedAt']),
      raw: json,
    );
  }
}

class WalletSummary {
  const WalletSummary({
    required this.id,
    required this.userId,
    required this.balance,
    required this.currency,
    required this.status,
    required this.createdAt,
    this.raw = const {},
  });

  final String id;
  final String userId;
  final double balance;
  final String currency;
  final String status;
  final DateTime? createdAt;
  final Map<String, dynamic> raw;

  bool get isFrozen => status.toLowerCase() == 'frozen';

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    return WalletSummary(
      id: _readString(json, ['id', 'wallet_id', 'walletId']) ?? '',
      userId: _readString(json, ['user_id', 'userId']) ?? '',
      balance: _readDouble(json, ['balance']) ?? 0,
      currency: _readString(json, ['currency']) ?? 'LKR',
      status: _readString(json, ['is_frozen', 'status']) ?? 'active',
      createdAt: _readDateTime(json, ['created_at', 'createdAt']),
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

double? _readDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return null;
}

DateTime? _readDateTime(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
  }
  return null;
}
