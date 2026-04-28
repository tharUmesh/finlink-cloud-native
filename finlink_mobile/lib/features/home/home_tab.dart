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
    final viewmodel = context.watch<HomeViewmodel>();
    final transactions = viewmodel.recentTransactions;
    final transactionsError = viewmodel.transactionsError;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          WalletCard(
            balanceText: viewmodel.walletBalanceText,
            statusText: viewmodel.walletStatusMessage,
            linkedBank: viewmodel.linkedBank,
          ),
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
              ActionAvatar(
                iconName: 'deposit',
                label: 'Deposit',
                onTap: () {
                  if (!viewmodel.hasLinkedCard) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Add a card before making a deposit.'),
                      ),
                    );
                    showAddCardBottomSheet(context, viewmodel);
                    return;
                  }
                  context.pushNamed(NamedRoutes.deposit.name);
                },
              ),
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
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          if (viewmodel.isTransactionsLoading && transactions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (transactionsError != null && transactionsError.isNotEmpty)
            Text(
              transactionsError,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF8A8F99),
              ),
            )
          else if (transactions.isEmpty)
            const Text(
              'No transactions yet.',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF8A8F99),
              ),
            )
          else
            ...transactions.map(
              (record) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TransactionCard(
                  type: viewmodel.isTransactionIncoming(record)
                      ? TransactionCardType.received
                      : TransactionCardType.transfer,
                  amount: record.amount,
                  time: viewmodel.formatTransactionTime(record),
                ),
              ),
            ),
        ],
      ),
    );
  }
}