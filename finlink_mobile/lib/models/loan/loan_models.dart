enum LoanStatus {
  pending,
  approved,
  rejected,
  active,
  repaid,
  defaulted,
  unknown,
}

class LoanApplicationRequest {
  const LoanApplicationRequest({
    required this.amount,
    required this.termWeeks,
    this.purpose,
  });

  final double amount;
  final int termWeeks;
  final String? purpose;

  Map<String, dynamic> toJson() {
    return {
      'amount': amount.toStringAsFixed(2),
      'term_weeks': termWeeks,
      if (purpose != null && purpose!.trim().isNotEmpty) 'purpose': purpose,
    };
  }
}

class FundLoanRequest {
  const FundLoanRequest({required this.lenderUserId});

  final String lenderUserId;

  Map<String, dynamic> toJson() {
    return {
      'lender_user_id': lenderUserId,
    };
  }
}

class LoanApplicationResponse {
  const LoanApplicationResponse({
    required this.loan,
    required this.decision,
    required this.creditScore,
    required this.message,
    this.raw = const {},
  });

  final LoanRecord loan;
  final String decision;
  final int creditScore;
  final String message;
  final Map<String, dynamic> raw;

  factory LoanApplicationResponse.fromJson(Map<String, dynamic> json) {
    return LoanApplicationResponse(
      loan: LoanRecord.fromJson(_readMap(json, ['loan']) ?? const {}),
      decision: _readString(json, ['decision']) ?? 'unknown',
      creditScore: _readInt(json, ['credit_score', 'creditScore']) ?? 0,
      message: _readString(json, ['message']) ?? '',
      raw: json,
    );
  }
}

class LoanRecord {
  const LoanRecord({
    required this.id,
    required this.applicantUserId,
    required this.amount,
    required this.interestRate,
    required this.termWeeks,
    required this.status,
    required this.createdAt,
    this.lenderUserId,
    this.creditScore,
    this.rejectionReason,
    this.purpose,
    this.approvedAt,
    this.dueDate,
    this.raw = const {},
  });

  final String id;
  final String applicantUserId;
  final String? lenderUserId;
  final double amount;
  final double interestRate;
  final int termWeeks;
  final LoanStatus status;
  final int? creditScore;
  final String? rejectionReason;
  final String? purpose;
  final DateTime? createdAt;
  final DateTime? approvedAt;
  final DateTime? dueDate;
  final Map<String, dynamic> raw;

  bool get isOpen => status == LoanStatus.approved && lenderUserId == null;

  factory LoanRecord.fromJson(Map<String, dynamic> json) {
    return LoanRecord(
      id: _readString(json, ['id']) ?? '',
      applicantUserId: _readString(json, ['applicant_user_id', 'applicantUserId']) ?? '',
      lenderUserId: _readString(json, ['lender_user_id', 'lenderUserId']),
      amount: _readDouble(json, ['amount']) ?? 0,
      interestRate: _readDouble(json, ['interest_rate', 'interestRate']) ?? 0,
      termWeeks: _readInt(json, ['term_weeks', 'termWeeks']) ?? 0,
      status: _parseLoanStatus(_readString(json, ['status'])),
      creditScore: _readInt(json, ['credit_score', 'creditScore']),
      rejectionReason: _readString(json, ['rejection_reason', 'rejectionReason']),
      purpose: _readString(json, ['purpose']),
      createdAt: _readDateTime(json, ['created_at', 'createdAt']),
      approvedAt: _readDateTime(json, ['approved_at', 'approvedAt']),
      dueDate: _readDateTime(json, ['due_date', 'dueDate']),
      raw: json,
    );
  }
}

LoanStatus _parseLoanStatus(String? value) {
  switch (value?.toLowerCase()) {
    case 'pending':
      return LoanStatus.pending;
    case 'approved':
      return LoanStatus.approved;
    case 'rejected':
      return LoanStatus.rejected;
    case 'active':
      return LoanStatus.active;
    case 'repaid':
      return LoanStatus.repaid;
    case 'defaulted':
      return LoanStatus.defaulted;
    default:
      return LoanStatus.unknown;
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

Map<String, dynamic>? _readMap(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
  }
  return null;
}
