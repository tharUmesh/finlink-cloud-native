import 'package:finlink_mobile/models/loan/loan_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyLoanCard extends StatelessWidget {
  const MyLoanCard({super.key, required this.loan});

  final LoanRecord loan;

  String get _statusLabel {
    switch (loan.status) {
      case LoanStatus.pending:
        return 'Pending';
      case LoanStatus.approved:
        return 'Approved';
      case LoanStatus.rejected:
        return 'Rejected';
      case LoanStatus.active:
        return 'Active';
      case LoanStatus.repaid:
        return 'Repaid';
      case LoanStatus.defaulted:
        return 'Defaulted';
      default:
        return 'Unknown';
    }
  }

  Color get _statusColor {
    switch (loan.status) {
      case LoanStatus.approved:
      case LoanStatus.active:
      case LoanStatus.repaid:
        return const Color(0xFF2F7D32);
      case LoanStatus.rejected:
      case LoanStatus.defaulted:
        return const Color(0xFFB91C1C);
      case LoanStatus.pending:
      case LoanStatus.unknown:
      default:
        return const Color(0xFF8A8F99);
    }
  }

  Color get _statusBackground {
    switch (loan.status) {
      case LoanStatus.approved:
      case LoanStatus.active:
      case LoanStatus.repaid:
        return const Color(0xFFEAF8EE);
      case LoanStatus.rejected:
      case LoanStatus.defaulted:
        return const Color(0xFFF9ECEC);
      case LoanStatus.pending:
      case LoanStatus.unknown:
      default:
        return const Color(0xFFF3F4F8);
    }
  }

  String get _timeLabel {
    final createdAt = loan.createdAt;
    if (createdAt == null) {
      return 'Just now';
    }

    final now = DateTime.now();
    final isToday = now.year == createdAt.year &&
        now.month == createdAt.month &&
        now.day == createdAt.day;
    if (isToday) {
      return 'Today ${DateFormat('h:mm a').format(createdAt)}';
    }
    return DateFormat('MMM d, h:mm a').format(createdAt);
  }

  String get _purposeLabel {
    final value = loan.purpose?.trim();
    if (value == null || value.isEmpty) {
      return 'No purpose provided';
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _statusBackground,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
              child: Icon(
                Icons.receipt_long_rounded,
                size: 18,
                color: _statusColor,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Loan Request',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF26262A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _timeLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF8A8F99),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _purposeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A8F99),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'LKR ${loan.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF2C2E34),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _statusLabel,
                style: TextStyle(
                  fontSize: 13,
                  color: _statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
