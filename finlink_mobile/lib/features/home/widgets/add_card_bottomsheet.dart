import 'package:finlink_mobile/features/home/home_viewmodel.dart';
import 'package:finlink_mobile/utils/bank_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

class AddCardBottomsheet extends StatelessWidget {
  const AddCardBottomsheet({super.key});

  @override
  Widget build(BuildContext context) {
    final viewmodel = context.watch<HomeViewmodel>();

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Form(
          key: viewmodel.addCardFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8D8DD),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Add Card',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => viewmodel.closeAddCardBottomSheet(context),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<BankName>(
                value: viewmodel.selectedBank,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Bank',
                  border: OutlineInputBorder(),
                ),
                items: BankName.values
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
                validator: (_) => viewmodel.validateSelectedBank(viewmodel.selectedBank),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: viewmodel.cardNumberController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Card No',
                  hintText: 'Enter card number',
                  border: OutlineInputBorder(),
                ),
                validator: viewmodel.validateCardNumber,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FormField<DateTime>(
                      validator: (_) => viewmodel.validateExpiration(),
                      builder: (field) {
                        return InkWell(
                          onTap: () async {
                            await viewmodel.pickExpirationDate(context);
                            field.didChange(viewmodel.selectedExpirationDate);
                            field.validate();
                          },
                          borderRadius: BorderRadius.circular(6),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Expiration',
                              hintText: 'MM/YY',
                              border: const OutlineInputBorder(),
                              errorText: field.errorText,
                            ),
                            child: Text(
                              viewmodel.expirationText.isEmpty
                                  ? 'MM/YY'
                                  : viewmodel.expirationText,
                              style: TextStyle(
                                color: viewmodel.expirationText.isEmpty
                                    ? Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withValues(alpha: 0.6)
                                    : Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: viewmodel.cvcController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'CVC',
                        hintText: '123',
                        border: OutlineInputBorder(),
                      ),
                      validator: viewmodel.validateCvc,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => viewmodel.submitAddCardForm(context),
                  child: const Text('Add Card'),
                ),
              ),
            ],
          ),
        ),
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

Future<void> showAddCardBottomSheet(
  BuildContext context,
  HomeViewmodel viewmodel,
) {
  final screenHeight = MediaQuery.of(context).size.height;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: BoxConstraints(
      minHeight: screenHeight * 0.68,
      maxHeight: screenHeight * 0.94,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => ChangeNotifierProvider<HomeViewmodel>.value(
      value: viewmodel,
      child: const AddCardBottomsheet(),
    ),
  );
}