import 'package:finlink_mobile/models/loan/loan_models.dart';
import 'package:flutter/material.dart';

class LoanCard extends StatelessWidget {
  const LoanCard({
    super.key,
    required this.loan,
    required this.onTap,
    required this.isLoading,
  });

  final LoanRecord loan;
  final VoidCallback? onTap;
  final bool isLoading;

  String get _purposeLabel {
    final value = loan.purpose?.trim();
    if (value == null || value.isEmpty) {
      return 'No purpose provided';
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                color: const Color(0xFFEAF8EE),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Center(
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 18,
                  color: Color(0xFF2F7D32),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Loan Request',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF26262A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _purposeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Borrower: ${loan.applicantUserId}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8A8F99),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Term: ${loan.termWeeks} weeks',
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C2E34),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${loan.interestRate.toStringAsFixed(2)}% interest',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF8A8F99),
                  ),
                ),
                if (isLoading) ...[
                  const SizedBox(height: 6),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
