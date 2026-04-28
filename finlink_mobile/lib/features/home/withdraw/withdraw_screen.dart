import 'package:finlink_mobile/features/home/withdraw/withdraw_viewmodel.dart';
import 'package:finlink_mobile/features/home/widgets/success_widget.dart';
import 'package:finlink_mobile/service_locator.dart';
import 'package:finlink_mobile/services/cards/linked_cards_store.dart';
import 'package:finlink_mobile/utils/named_routes.dart';
import 'package:finlink_mobile/utils/bank_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class WithdrawScreen extends StatelessWidget {
  const WithdrawScreen({super.key});

  Future<void> _handleWithdraw(
    BuildContext context,
    WithdrawViewmodel viewmodel,
  ) async {
    if (!viewmodel.submit()) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return SuccessDialog(
          title: 'Withdraw Successful',
          message: 'Your withdraw request has been completed.',
          buttonText: 'Go Home',
          onPressed: () {
            viewmodel.clear();
            Navigator.of(dialogContext).pop();
            context.goNamed(NamedRoutes.home.name);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WithdrawViewmodel(servicelocator<LinkedCardsStore>()),
      child: Consumer<WithdrawViewmodel>(
        builder: (context, viewmodel, child) {
          return WillPopScope(
            onWillPop: () async {
              viewmodel.clear();
              return true;
            },
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Withdraw'),
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
                    key: viewmodel.withdrawFormKey,
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView(
                            children: [
                              const SizedBox(height: 8),
                              DropdownButtonFormField<BankName>(
                                value: viewmodel.selectedBank,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Bank',
                                  border: OutlineInputBorder(),
                                ),
                                items: viewmodel.availableBanks
                                    .map(
                                      (bank) => DropdownMenuItem<BankName>(
                                        value: bank,
                                        child: Row(
                                          children: [
                                            _BankLogo(bank: bank),
                                            const SizedBox(width: 10),
                                            Flexible(
                                              child: Text(
                                                bank.displayName,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: viewmodel.setSelectedBank,
                                validator: (_) => viewmodel.validateBank(viewmodel.selectedBank),
                              ),
                              if (!viewmodel.hasLinkedCards) ...[
                                const SizedBox(height: 10),
                                const Text(
                                  'Add a card before making a withdraw.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF8A8F99),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: viewmodel.amountController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: const InputDecoration(
                                  labelText: 'Amount',
                                  hintText: 'Enter amount',
                                  border: OutlineInputBorder(),
                                ),
                                validator: viewmodel.validateAmount,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: viewmodel.remarksController,
                                maxLength: 16,
                                decoration: const InputDecoration(
                                  labelText: 'Remarks',
                                  hintText: 'Add remarks (max 16 chars)',
                                  border: OutlineInputBorder(),
                                  counterText: '',
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
                            onPressed: viewmodel.hasLinkedCards
                                ? () => _handleWithdraw(context, viewmodel)
                                : null,
                            child: const Text('Withdraw'),
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

class _BankLogo extends StatelessWidget {
  final BankName bank;

  const _BankLogo({required this.bank});

  @override
  Widget build(BuildContext context) {
    if (bank.isSvg) {
      return SvgPicture.asset(
        bank.logoAssetPath,
        width: 24,
        height: 24,
      );
    }

    return Image.asset(
      bank.logoAssetPath,
      width: 24,
      height: 24,
      fit: BoxFit.cover,
    );
  }
}