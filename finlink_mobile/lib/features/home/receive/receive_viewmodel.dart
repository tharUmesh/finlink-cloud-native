import 'package:finlink_mobile/features/base_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReceiveViewmodel extends BaseViewmodel {
  static const String dummyWalletAddress = 'finlink_wallet_0xA1B2C3D4E5F6';
  static const String qrAssetPath = 'images/dummy-qr.png';

  Future<void> copyWalletAddress(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: dummyWalletAddress));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wallet address copied to clipboard')),
    );
  }
}