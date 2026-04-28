class UserProfile {
  const UserProfile({
    required this.id,
    required this.phoneNumber,
    required this.nationalId,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.raw = const {},
  });

  final String id;
  final String phoneNumber;
  final String nationalId;
  final String fullName;
  final String role;
  final bool isActive;
  final DateTime? createdAt;
  final Map<String, dynamic> raw;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: _readString(json, ['id', 'user_id', 'userId']) ?? '',
      phoneNumber: _readString(json, ['phone_number', 'phoneNumber']) ?? '',
      nationalId: _readString(json, ['national_id', 'nationalId']) ?? '',
      fullName: _readString(json, ['full_name', 'fullName']) ?? '',
      role: _readString(json, ['role']) ?? 'user',
      isActive: _readBool(json, ['is_active', 'isActive']) ?? true,
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

bool? _readBool(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) {
      return value;
    }
    if (value != null) {
      final normalized = value.toString().toLowerCase();
      if (normalized == 'true') {
        return true;
      }
      if (normalized == 'false') {
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