import 'package:finlink_mobile/utils/bank_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WalletCard extends StatelessWidget {
  const WalletCard({
    super.key,
    required this.balanceText,
    this.statusText,
    this.linkedBank,
  });

  final String balanceText;
  final String? statusText;
  final BankName? linkedBank;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 170),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF7656E8),
            Color(0xFF6A4CE1),
            Color(0xFF5538B8),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 4,
            right: 0,
            child: Row(
              children: List.generate(
                3,
                (_) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 6),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF5DE58A),
                  ),
                ),
              ),
            ),
          ),
          if (linkedBank != null)
            Positioned(
              top: 22,
              right: 0,
              child: Container(
                width: 26,
                height: 26,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: linkedBank!.isSvg
                    ? SvgPicture.asset(
                        linkedBank!.logoAssetPath,
                        width: 18,
                        height: 18,
                      )
                    : Image.asset(
                        linkedBank!.logoAssetPath,
                        width: 18,
                        height: 18,
                        fit: BoxFit.contain,
                      ),
              ),
            ),
          Positioned(
            right: -18,
            bottom: -24,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            right: 22,
            bottom: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.14),
                  width: 2,
                ),
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFF5DE58A),
                ),
                child: const Text(
                  'finLink',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Available Balance',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                balanceText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              if (statusText != null && statusText!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  statusText!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 36),
              // Container(
              //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              //   decoration: BoxDecoration(
              //     borderRadius: BorderRadius.circular(16),
              //     color: const Color(0xFF5DE58A),
              //   ),
              //   child: const Text(
              //     '+4.12%',
              //     style: TextStyle(
              //       color: Color(0xFF126835),
              //       fontSize: 12,
              //       fontWeight: FontWeight.w700,
              //     ),
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }
}