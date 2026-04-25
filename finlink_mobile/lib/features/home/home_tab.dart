import 'package:finlink_mobile/features/base_screen.dart';
import 'package:finlink_mobile/features/home/widgets/action_avatar.dart';
import 'package:finlink_mobile/features/home/widgets/transaction_card.dart';
import 'package:finlink_mobile/features/home/widgets/wallet_card.dart';
import 'package:flutter/material.dart';

class HomeTab extends BaseScreen {
  const HomeTab({super.key});

  @override
  Widget mainContent(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          WalletCard(),
           SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ActionAvatar(iconName: 'money-send', label: 'Send'),
              ActionAvatar(iconName: 'money-receive', label: 'Receive'),
              ActionAvatar(iconName: 'add-card', label: 'Add Card'),
              ActionAvatar(iconName: 'more-vertical', label: 'More'),
            ],
          ),
           SizedBox(height: 24),
          Text(
            'Recent Transactions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          TransactionCard(
            type: TransactionCardType.transfer,
            amount: 500,
            time: 'Today 2:33 PM',
          ),
          SizedBox(height: 8),
          TransactionCard(
            type: TransactionCardType.received,
            amount: 50,
            time: 'Today 3:32 PM',
          ),
        ],
      ),
    );
  }
}