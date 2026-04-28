import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ActionAvatar extends StatelessWidget {
  final String iconName;
  final String label;
  final VoidCallback? onTap;

  const ActionAvatar({
    super.key,
    required this.iconName,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF8B898C).withValues(alpha: 0.12),
            ),
            child: Center(
              child: SvgPicture.asset(
                'images/svg_icons/$iconName.svg',
                width: 40,
                height: 40,
                colorFilter: const ColorFilter.mode(
                  Colors.black,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8A8F99),
            ),
          ),
        ],
      ),
    );
  }
}