import 'package:finlink_mobile/features/base_screen.dart';
import 'package:finlink_mobile/features/notifications/widgets/notification_card.dart';
import 'package:finlink_mobile/features/home/home_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum NotificationFilter {
  all,
  unread,
  read,
}

class NotificationScreen extends BaseScreen {
  const NotificationScreen({super.key});

  @override
  Widget mainContent(BuildContext context) {
    return const _NotificationScreenBody();
  }
}

class _NotificationScreenBody extends StatefulWidget {
  const _NotificationScreenBody();

  @override
  State<_NotificationScreenBody> createState() => _NotificationScreenBodyState();
}

class _NotificationScreenBodyState extends State<_NotificationScreenBody> {
  NotificationFilter _filter = NotificationFilter.all;

  Future<void> _showNotificationDialog(
    BuildContext context,
    HomeViewmodel viewmodel,
    NotificationCardData data,
  ) async {
    await viewmodel.markNotificationRead(data.notification);
    if (!context.mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(data.notification.title),
          content: Text(data.notification.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  List<NotificationCardData> _buildFiltered(
    List<NotificationCardData> items,
  ) {
    switch (_filter) {
      case NotificationFilter.unread:
        return items.where((item) => item.notification.isUnread).toList();
      case NotificationFilter.read:
        return items.where((item) => !item.notification.isUnread).toList();
      case NotificationFilter.all:
      default:
        return items;
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewmodel = context.watch<HomeViewmodel>();
    final notifications = viewmodel.notifications;
    final allItems = notifications
        .map((notification) => NotificationCardData(notification))
        .toList();
    final filteredItems = _buildFiltered(allItems);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () => viewmodel.loadNotifications(force: true),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _filter == NotificationFilter.all,
                  onSelected: (_) {
                    setState(() => _filter = NotificationFilter.all);
                  },
                ),
                ChoiceChip(
                  label: const Text('Unread'),
                  selected: _filter == NotificationFilter.unread,
                  onSelected: (_) {
                    setState(() => _filter = NotificationFilter.unread);
                  },
                ),
                ChoiceChip(
                  label: const Text('Read'),
                  selected: _filter == NotificationFilter.read,
                  onSelected: (_) {
                    setState(() => _filter = NotificationFilter.read);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (viewmodel.isNotificationsLoading && notifications.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (viewmodel.notificationsError != null &&
                viewmodel.notificationsError!.isNotEmpty)
              Text(
                viewmodel.notificationsError!,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8A8F99),
                ),
              )
            else if (filteredItems.isEmpty)
              const Text(
                'No notifications in this filter.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8A8F99),
                ),
              )
            else
              ...filteredItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: NotificationCard(
                    data: item,
                    onTap: () => _showNotificationDialog(
                      context,
                      viewmodel,
                      item,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
