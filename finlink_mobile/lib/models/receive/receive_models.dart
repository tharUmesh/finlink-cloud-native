import 'dart:convert';

class QrWalletPayload {
  const QrWalletPayload({
    required this.walletId,
    this.phone,
    this.version = 1,
  });

  final String walletId;
  final String? phone;
  final int version;

  Map<String, dynamic> toJson() {
    return {
      'v': version,
      'wallet_id': walletId,
      if (phone != null && phone!.trim().isNotEmpty) 'phone': phone,
    };
  }

  String toQrString() {
    return jsonEncode(toJson());
  }

  static QrWalletPayload? tryParse(String value) {
    if (value.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(value);
      if (decoded is! Map) {
        return null;
      }
      final map = Map<String, dynamic>.from(decoded);
      final walletId = map['wallet_id']?.toString();
      if (walletId == null || walletId.trim().isEmpty) {
        return null;
      }
      return QrWalletPayload(
        walletId: walletId,
        phone: map['phone']?.toString(),
        version: _readInt(map['v']) ?? 1,
      );
    } catch (_) {
      return null;
    }
  }

  static int? _readInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}
