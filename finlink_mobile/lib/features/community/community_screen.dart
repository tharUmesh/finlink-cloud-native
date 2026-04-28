import 'package:finlink_mobile/features/base_screen.dart';
import 'package:finlink_mobile/features/community/community_viewmodel.dart';
import 'package:finlink_mobile/features/community/widgets/loan_card.dart';
import 'package:finlink_mobile/models/loan/loan_models.dart';
import 'package:finlink_mobile/service_locator.dart';
import 'package:finlink_mobile/services/auth/auth_session.dart';
import 'package:finlink_mobile/services/loan/loan_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CommunityScreen extends BaseScreen {
  const CommunityScreen({super.key});

  Future<void> _confirmFundLoan(
    BuildContext context,
    CommunityViewmodel viewmodel,
    LoanRecord loan,
  ) async {
    final shouldFund = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Fund this loan?'),
          content: Text(
            'You will transfer LKR ${loan.amount.toStringAsFixed(2)} '
            'for ${loan.termWeeks} weeks at '
            '${loan.interestRate.toStringAsFixed(2)}% interest.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (shouldFund != true || !context.mounted) {
      return;
    }

    await viewmodel.fundLoan(context, loan);
  }

  @override
  Widget mainContent(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final viewmodel = CommunityViewmodel(
          servicelocator<AuthSession>(),
          servicelocator<LoanService>(),
        );
        viewmodel.loadOpenLoans();
        return viewmodel;
      },
      child: Consumer<CommunityViewmodel>(
        builder: (context, viewmodel, child) {
          return SafeArea(
            child: RefreshIndicator(
              onRefresh: () => viewmodel.loadOpenLoans(force: true),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Community Loans',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap a request to fund it.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (viewmodel.isLoading && viewmodel.openLoans.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (viewmodel.errorMessage != null &&
                      viewmodel.errorMessage!.isNotEmpty)
                    Text(
                      viewmodel.errorMessage!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8A8F99),
                      ),
                    )
                  else if (viewmodel.openLoans.isEmpty)
                    const Text(
                      'No open loan requests right now.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8A8F99),
                      ),
                    )
                  else
                    ...viewmodel.openLoans.map(
                      (loan) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: LoanCard(
                          loan: loan,
                          isLoading: viewmodel.isFundingLoan(loan.id),
                          onTap: () => _confirmFundLoan(context, viewmodel, loan),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
