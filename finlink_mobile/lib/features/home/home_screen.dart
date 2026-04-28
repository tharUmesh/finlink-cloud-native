import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:finlink_mobile/features/base_screen.dart';
import 'package:finlink_mobile/features/home/home_tab.dart';
import 'package:finlink_mobile/features/home/home_viewmodel.dart';
import 'package:finlink_mobile/features/community/community_screen.dart';
import 'package:finlink_mobile/features/notifications/notification_screen.dart';
import 'package:finlink_mobile/features/profile/profile_screen.dart';
import 'package:finlink_mobile/service_locator.dart';
import 'package:finlink_mobile/services/cards/linked_cards_store.dart';
import 'package:finlink_mobile/services/notification/notification_service.dart';
import 'package:finlink_mobile/services/transaction/transaction_service.dart';
import 'package:finlink_mobile/services/transaction/transaction_refresh_notifier.dart';
import 'package:finlink_mobile/services/wallet/wallet_service.dart';


class HomeScreen extends BaseScreen {
  const HomeScreen({super.key});

  @override
  Widget mainContent(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final viewmodel = HomeViewmodel(
          servicelocator<WalletService>(),
          servicelocator<TransactionService>(),
          servicelocator<NotificationService>(),
          servicelocator<TransactionRefreshNotifier>(),
          servicelocator<LinkedCardsStore>(),
        );
        viewmodel.startWalletStream();
        viewmodel.startTransactionPolling();
        viewmodel.startNotificationStream();
        return viewmodel;
      },
      child: Consumer<HomeViewmodel>(
        builder: (context, viewmodel, child) {
          return Scaffold(
            body: IndexedStack(
              index: viewmodel.selectedIndex,
              children: const [
                HomeTab(),
                CommunityScreen(),
                NotificationScreen(),
                ProfileScreen(),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: viewmodel.selectedIndex,
              onTap: viewmodel.onTabChanged,
              type: BottomNavigationBarType.fixed,
              items: [
                const BottomNavigationBarItem(
                  icon: _NavIcon(assetName: 'images/svg_icons/home.svg'),
                  activeIcon: _NavIcon(
                    assetName: 'images/svg_icons/home.svg',
                    isActive: true,
                  ),
                  label: 'Home',
                ),
                const BottomNavigationBarItem(
                  icon: _NavIcon(assetName: 'images/svg_icons/community.svg'),
                  activeIcon: _NavIcon(
                    assetName: 'images/svg_icons/community.svg',
                    isActive: true,
                  ),
                  label: 'Community',
                ),
                BottomNavigationBarItem(
                  icon: _NavIcon(
                    assetName: 'images/svg_icons/notifications.svg',
                    badgeCount: viewmodel.unreadNotificationsCount,
                  ),
                  activeIcon: _NavIcon(
                    assetName: 'images/svg_icons/notifications.svg',
                    isActive: true,
                    badgeCount: viewmodel.unreadNotificationsCount,
                  ),
                  label: 'Notifications',
                ),
                const BottomNavigationBarItem(
                  icon: _NavIcon(assetName: 'images/svg_icons/profile.svg'),
                  activeIcon: _NavIcon(
                    assetName: 'images/svg_icons/profile.svg',
                    isActive: true,
                  ),
                  label: 'Profile',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final String assetName;
  final bool isActive;
  final int badgeCount;

  const _NavIcon({
    required this.assetName,
    this.isActive = false,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final icon = SvgPicture.asset(
      assetName,
      width: 22,
      height: 22,
      colorFilter: ColorFilter.mode(
        isActive ? Theme.of(context).colorScheme.primary : Colors.grey,
        BlendMode.srcIn,
      ),
    );

    if (badgeCount <= 0) {
      return icon;
    }

    final label = badgeCount > 99 ? '99+' : badgeCount.toString();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -8,
          top: -6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: const Color(0xFFE11D48),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

