import 'package:finlink_mobile/features/home/home_viewmodel.dart';
import 'package:finlink_mobile/features/home/qr_scanner/qr_scanner.dart';
import 'package:finlink_mobile/features/home/widgets/success_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class SendBottomsheet extends StatelessWidget {
  const SendBottomsheet({super.key});

  Future<void> _handleSend(
    BuildContext context,
    HomeViewmodel viewmodel,
  ) async {
    final didSubmit = await viewmodel.submitSendForm(context);
    if (!didSubmit || !context.mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return SuccessDialog(
          title: 'Transfer Submitted',
          message: 'Your transfer is being processed.',
          buttonText: 'Done',
          onPressed: () {
            Navigator.of(dialogContext).pop();
            viewmodel.closeSendBottomSheet(context);
          },
        );
      },
    );
  }

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
          key: viewmodel.sendFormKey,
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
                      'Send Money',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => viewmodel.closeSendBottomSheet(context),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: viewmodel.receiverAddressController,
                decoration: InputDecoration(
                  labelText: "Receiver's Address",
                  hintText: 'Enter receiver address',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () async {
                      final value = await Navigator.of(context).push<String>(
                        MaterialPageRoute(
                          builder: (_) => const QrScannerScreen(
                            returnOnScan: true,
                          ),
                        ),
                      );
                      if (value == null || value.trim().isEmpty) {
                        return;
                      }
                      viewmodel.setReceiverAddress(value.trim());
                    },
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    tooltip: 'Scan QR',
                  ),
                ),
                validator: viewmodel.validateReceiverAddress,
              ),
              
              const SizedBox(height: 12),
              TextFormField(
                controller: viewmodel.amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                controller: viewmodel.remarksController,
                maxLength: 16,
                decoration: const InputDecoration(
                  labelText: 'Remarks',
                  hintText: 'Add remarks (max 16 chars)',
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              if (viewmodel.sendErrorMessage != null &&
                  viewmodel.sendErrorMessage!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  viewmodel.sendErrorMessage!,
                  style: const TextStyle(
                    color: Color(0xFFB91C1C),
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: viewmodel.isSending
                      ? null
                      : () => _handleSend(context, viewmodel),
                  child: viewmodel.isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Send'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showSendBottomSheet(
  BuildContext context,
  HomeViewmodel viewmodel,
) {
  final screenHeight = MediaQuery.of(context).size.height;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    useSafeArea: true,
    constraints: BoxConstraints(
      minHeight: screenHeight * 0.62,
      maxHeight: screenHeight * 0.92,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => ChangeNotifierProvider<HomeViewmodel>.value(
      value: viewmodel,
      child: const SendBottomsheet(),
    ),
  );
}