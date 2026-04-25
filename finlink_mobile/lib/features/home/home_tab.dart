import 'package:finlink_mobile/features/base_screen.dart';
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
        ],
      ),
    );
  }
}