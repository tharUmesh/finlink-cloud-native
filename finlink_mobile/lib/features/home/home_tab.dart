import 'package:finlink_mobile/features/base_screen.dart';
import 'package:finlink_mobile/features/home/home_viewmodel.dart';
import 'package:finlink_mobile/features/home/widgets/add_card_bottomsheet.dart';
import 'package:finlink_mobile/features/home/widgets/action_avatar.dart';
import 'package:finlink_mobile/features/home/widgets/send_bottmsheet.dart';
import 'package:finlink_mobile/features/home/widgets/transaction_card.dart';
import 'package:finlink_mobile/features/home/widgets/wallet_card.dart';
import 'package:finlink_mobile/utils/named_routes.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class HomeTab extends BaseScreen {
  const HomeTab({super.key});

  @override
  Widget mainContent(BuildContext context) {
    final viewmodel = context.read<HomeViewmodel>();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const WalletCard(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ActionAvatar(
                iconName: 'money-send',
                label: 'Send',
                onTap: () => showSendBottomSheet(context, viewmodel),
              ),
              ActionAvatar(
                iconName: 'money-receive',
                label: 'Receive',
                onTap: () => context.pushNamed(NamedRoutes.receive.name),
              ),
              ActionAvatar(
                iconName: 'add-card',
                label: 'Add Card',
                onTap: () => showAddCardBottomSheet(context, viewmodel),
              ),
              ActionAvatar(
                iconName: 'qr-scan',
                label: 'QR scan',
                onTap: () => context.pushNamed(NamedRoutes.qrScanner.name),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const ActionAvatar(iconName: 'deposit', label: 'Deposit'),
              ActionAvatar(
                iconName: 'withdraw',
                label: 'Withdraw',
                onTap: () => context.pushNamed(NamedRoutes.withdraw.name),
              ),
              const ActionAvatar(iconName: 'loan', label: 'Loan'),
              const ActionAvatar(iconName: 'more-vertical', label: 'More'),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Recent Transactions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const TransactionCard(
            type: TransactionCardType.transfer,
            amount: 500,
            time: 'Today 2:33 PM',
          ),
          const SizedBox(height: 8),
          const TransactionCard(
            type: TransactionCardType.received,
            amount: 50,
            time: 'Today 3:32 PM',
          ),
        ],
      ),
    );
  }
}