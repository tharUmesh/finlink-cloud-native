enum TransactionType {
  transfer,
  deposit,
  withdrawal,
  unknown,
}

enum TransactionStatus {
  pending,
  approved,
  flagged,
  failed,
  unknown,
}

class TransferRequest {
  const TransferRequest({
    required this.receiverPhone,
    required this.amount,
    this.note,
  });

  final String receiverPhone;
  final double amount;
  final String? note;

  Map<String, dynamic> toJson() {
    return {
      'receiver_phone': receiverPhone,
      'amount': amount.toStringAsFixed(2),
      if (note != null && note!.trim().isNotEmpty) 'note': note,
    };
  }
}

class DepositRequest {
  const DepositRequest({
    required this.walletId,
    required this.amount,
  });

  final String walletId;
  final double amount;

  Map<String, dynamic> toJson() {
    return {
      'wallet_id': walletId,
      'amount': amount.toStringAsFixed(2),
    };
  }
}

class TransactionRecord {
  const TransactionRecord({
    required this.id,
    required this.receiverWalletId,
    required this.amount,
    required this.currency,
    required this.transactionType,
    required this.status,
    required this.createdAt,
    this.senderWalletId,
    this.idempotencyKey,
    this.meta,
    this.raw = const {},
  });

  final String id;
  final String? senderWalletId;
  final String receiverWalletId;
  final double amount;
  final String currency;
  final TransactionType transactionType;
  final TransactionStatus status;
  final String? idempotencyKey;
  final Map<String, dynamic>? meta;
  final DateTime? createdAt;
  final Map<String, dynamic> raw;

  bool get isIncoming => senderWalletId == null;

  factory TransactionRecord.fromJson(Map<String, dynamic> json) {
    return TransactionRecord(
      id: _readString(json, ['id']) ?? '',
      senderWalletId: _readString(json, ['sender_wallet_id', 'senderWalletId']),
      receiverWalletId: _readString(json, ['receiver_wallet_id', 'receiverWalletId']) ?? '',
      amount: _readDouble(json, ['amount']) ?? 0,
      currency: _readString(json, ['currency']) ?? 'LKR',
      transactionType: _parseTransactionType(
        _readString(json, ['transaction_type', 'transactionType']),
      ),
      status: _parseTransactionStatus(_readString(json, ['status'])),
      idempotencyKey: _readString(json, ['idempotency_key', 'idempotencyKey']),
      meta: _readMap(json['meta']),
      createdAt: _readDateTime(json, ['created_at', 'createdAt']),
      raw: json,
    );
  }
}

class TransactionListResponse {
  const TransactionListResponse({
    required this.transactions,
    required this.total,
    this.raw = const {},
  });

  final List<TransactionRecord> transactions;
  final int total;
  final Map<String, dynamic> raw;

  factory TransactionListResponse.fromJson(Map<String, dynamic> json) {
    final rawTransactions = json['transactions'];
    final transactions = <TransactionRecord>[];
    if (rawTransactions is List) {
      for (final item in rawTransactions) {
        if (item is Map<String, dynamic>) {
          transactions.add(TransactionRecord.fromJson(item));
        } else if (item is Map) {
          transactions.add(TransactionRecord.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }

    return TransactionListResponse(
      transactions: transactions,
      total: _readInt(json, ['total']) ?? transactions.length,
      raw: json,
    );
  }
}

TransactionType _parseTransactionType(String? value) {
  switch (value?.toLowerCase()) {
    case 'transfer':
      return TransactionType.transfer;
    case 'deposit':
      return TransactionType.deposit;
    case 'withdrawal':
      return TransactionType.withdrawal;
    default:
      return TransactionType.unknown;
  }
}

TransactionStatus _parseTransactionStatus(String? value) {
  switch (value?.toLowerCase()) {
    case 'pending':
      return TransactionStatus.pending;
    case 'approved':
      return TransactionStatus.approved;
    case 'flagged':
      return TransactionStatus.flagged;
    case 'failed':
      return TransactionStatus.failed;
    default:
      return TransactionStatus.unknown;
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

int? _readInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
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

Map<String, dynamic>? _readMap(dynamic value) {
  if (value == null) {
    return null;
  }
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return <String, dynamic>{'data': value};
}
