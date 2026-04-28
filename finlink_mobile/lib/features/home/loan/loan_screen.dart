import 'package:finlink_mobile/features/home/loan/loan_viewmodel.dart';
import 'package:finlink_mobile/features/home/widgets/success_widget.dart';
import 'package:finlink_mobile/features/home/loan/widgets/my_loan_card.dart';
import 'package:finlink_mobile/service_locator.dart';
import 'package:finlink_mobile/services/auth/auth_session.dart';
import 'package:finlink_mobile/services/loan/loan_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class LoanScreen extends StatelessWidget {
  const LoanScreen({super.key});

  Future<void> _handleSubmit(
    BuildContext context,
    LoanViewmodel viewmodel,
  ) async {
    final response = await viewmodel.submit(context);
    if (response == null || !context.mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return SuccessDialog(
          title: 'Loan Request Submitted',
          message: 'Your loan request listed successfully',
          buttonText: 'Done',
          onPressed: () {
            Navigator.of(dialogContext).pop();
            viewmodel.clear();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoanViewmodel(
        servicelocator<AuthSession>(),
        servicelocator<LoanService>(),
      ),
      child: Consumer<LoanViewmodel>(
        builder: (context, viewmodel, child) {
          return WillPopScope(
            onWillPop: () async {
              viewmodel.clear();
              return true;
            },
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Request Loan'),
                centerTitle: false,
                leading: IconButton(
                  onPressed: () => viewmodel.close(context),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded),
                ),
              ),
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: viewmodel.loanFormKey,
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView(
                            children: [
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: viewmodel.amountController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}'),
                                  ),
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Amount',
                                  hintText: 'Enter amount',
                                  border: OutlineInputBorder(),
                                ),
                                validator: viewmodel.validateAmount,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: viewmodel.termController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Term (weeks)',
                                  hintText: 'Enter term in weeks',
                                  border: OutlineInputBorder(),
                                ),
                                validator: viewmodel.validateTerm,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: viewmodel.purposeController,
                                maxLength: 80,
                                decoration: const InputDecoration(
                                  labelText: 'Purpose',
                                  hintText: 'Optional purpose',
                                  border: OutlineInputBorder(),
                                  counterText: '',
                                ),
                              ),
                              if (viewmodel.errorMessage != null &&
                                  viewmodel.errorMessage!.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Text(
                                  viewmodel.errorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFFB91C1C),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 20),
                              const Divider(height: 1),
                              const SizedBox(height: 16),
                              const Text(
                                'My Loans',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (viewmodel.isLoansLoading &&
                                  viewmodel.myLoans.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else if (viewmodel.loansError != null &&
                                  viewmodel.loansError!.isNotEmpty)
                                Text(
                                  viewmodel.loansError!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF8A8F99),
                                  ),
                                )
                              else if (viewmodel.myLoans.isEmpty)
                                const Text(
                                  'No loans requested yet.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF8A8F99),
                                  ),
                                )
                              else
                                ...viewmodel.myLoans.map(
                                  (loan) => Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: MyLoanCard(loan: loan),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: viewmodel.isSubmitting
                                ? null
                                : () => _handleSubmit(context, viewmodel),
                            child: viewmodel.isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text('Request Loan'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
