import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum TransactionCardType { transfer, received }

class TransactionCard extends StatelessWidget {
  final TransactionCardType type;
  final double amount;
  final String time;

  const TransactionCard({
    super.key,
    required this.type,
    required this.amount,
    required this.time,
  });

  bool get _isReceived => type == TransactionCardType.received;

  String get _title => _isReceived ? 'Received' : 'Transfer';

  String get _iconName => _isReceived ? 'received' : 'transfer';

  String get _actionName => _isReceived ? 'Deposit' : 'Send';

  String get _formattedAmount =>
      '${_isReceived ? '+' : '-'} LKR ${amount.toStringAsFixed(2)}';

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
              color: _isReceived
                  ? const Color(0xFFEAF8EE)
                  : const Color(0xFFF9ECEC),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
              child: SvgPicture.asset(
                'images/svg_icons/$_iconName.svg',
                width: 18,
                height: 18,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF26262A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 14,
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
                _formattedAmount,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF2C2E34),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _actionName,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8A8F99),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}