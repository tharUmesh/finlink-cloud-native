import 'package:finlink_mobile/features/home/receive/receive_viewmodel.dart';
import 'package:finlink_mobile/service_locator.dart';
import 'package:finlink_mobile/services/auth/auth_session.dart';
import 'package:finlink_mobile/services/user/user_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ReceiveScreen extends StatelessWidget {
  const ReceiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReceiveViewmodel(
        servicelocator<AuthSession>(),
        servicelocator<UserService>(),
      ),
      child: Consumer<ReceiveViewmodel>(
        builder: (context, viewmodel, child) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Receive'),
              centerTitle: false,
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Your Phone Number',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F8),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE3E6EF)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              viewmodel.phoneNumberLabel,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: viewmodel.hasError
                                    ? const Color(0xFFB91C1C)
                                    : null,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: viewmodel.hasPhoneNumber
                                ? () => viewmodel.copyPhoneNumber(context)
                                : null,
                            icon: const Icon(Icons.copy_rounded),
                            tooltip: 'Copy phone number',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Scan QR Code',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x14000000),
                                blurRadius: 18,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: viewmodel.hasPhoneNumber
                              ? QrImageView(
                                  data: viewmodel.phoneNumber ?? '',
                                  size: 220,
                                )
                              : const SizedBox(
                                  width: 220,
                                  height: 220,
                                  child: Center(
                                    child: Text('QR unavailable'),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Let others scan this QR to send funds to your phone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}