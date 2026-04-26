import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:finlink_mobile/features/base_screen.dart';
import 'package:finlink_mobile/features/home/home_tab.dart';
import 'package:finlink_mobile/features/home/home_viewmodel.dart';
import 'package:finlink_mobile/features/profile/profile_screen.dart';


class HomeScreen extends BaseScreen {
  const HomeScreen({super.key});

  @override
  Widget mainContent(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HomeViewmodel(),
      child: Consumer<HomeViewmodel>(
        builder: (context, viewmodel, child) {
          return Scaffold(
            body: IndexedStack(
              index: viewmodel.selectedIndex,
              children: const [
                HomeTab(),
                _CommunityTab(),
                _NotificationsTab(),
                ProfileScreen(),
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: viewmodel.selectedIndex,
              onTap: viewmodel.onTabChanged,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: _NavIcon(assetName: 'images/svg_icons/home.svg'),
                  activeIcon: _NavIcon(
                    assetName: 'images/svg_icons/home.svg',
                    isActive: true,
                  ),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: _NavIcon(assetName: 'images/svg_icons/community.svg'),
                  activeIcon: _NavIcon(
                    assetName: 'images/svg_icons/community.svg',
                    isActive: true,
                  ),
                  label: 'Community',
                ),
                BottomNavigationBarItem(
                  icon: _NavIcon(assetName: 'images/svg_icons/notifications.svg'),
                  activeIcon: _NavIcon(
                    assetName: 'images/svg_icons/notifications.svg',
                    isActive: true,
                  ),
                  label: 'Notifications',
                ),
                BottomNavigationBarItem(
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

  const _NavIcon({required this.assetName, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetName,
      width: 22,
      height: 22,
      colorFilter: ColorFilter.mode(
        isActive ? Theme.of(context).colorScheme.primary : Colors.grey,
        BlendMode.srcIn,
      ),
    );
  }
}

class _CommunityTab extends StatelessWidget {
  const _CommunityTab();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Community'));
  }
}

class _NotificationsTab extends StatelessWidget {
  const _NotificationsTab();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Notifications'));
  }
}

