class NotificationEvent {
  const NotificationEvent({
    required this.id,
    required this.userId,
    required this.eventType,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.payload,
    this.raw = const {},
  });

  final String id;
  final String userId;
  final String eventType;
  final String title;
  final String message;
  final bool isRead;
  final DateTime? createdAt;
  final Map<String, dynamic>? payload;
  final Map<String, dynamic> raw;

  bool get isUnread => !isRead;

  factory NotificationEvent.fromJson(Map<String, dynamic> json) {
    return NotificationEvent(
      id: _readString(json, ['id', 'notification_id', 'notificationId']) ?? '',
      userId: _readString(json, ['user_id', 'userId']) ?? '',
      eventType: _readString(json, ['event_type', 'eventType']) ?? 'unknown',
      title: _readString(json, ['title']) ?? '',
      message: _readString(json, ['message']) ?? '',
      isRead: _readBool(json, ['is_read', 'isRead']) ?? false,
      createdAt: _readDateTime(json, ['created_at', 'createdAt']),
      payload: _readMap(json['payload']),
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

bool? _readBool(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.toLowerCase().trim();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
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
