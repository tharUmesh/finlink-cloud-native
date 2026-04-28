import 'package:finlink_mobile/models/notification/notification_models.dart';
import 'package:flutter/material.dart';

class NotificationCardData {
  const NotificationCardData(this.notification);

  final NotificationEvent notification;

  String get timeLabel {
    final createdAt = notification.createdAt;
    if (createdAt == null) {
      return 'Just now';
    }

    final now = DateTime.now();
    final isToday = now.year == createdAt.year &&
        now.month == createdAt.month &&
        now.day == createdAt.day;
    if (isToday) {
      final hour = createdAt.hour % 12 == 0 ? 12 : createdAt.hour % 12;
      final minute = createdAt.minute.toString().padLeft(2, '0');
      final period = createdAt.hour >= 12 ? 'PM' : 'AM';
      return 'Today $hour:$minute $period';
    }

    return '${createdAt.month}/${createdAt.day}/${createdAt.year}';
  }
}

class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.data,
    this.onTap,
  });

  final NotificationCardData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final notification = data.notification;
    final isUnread = notification.isUnread;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isUnread ? const Color(0xFFEFF6FF) : const Color(0xFFF1F2F7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnread ? const Color(0xFFBFDBFE) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isUnread
                    ? const Color(0xFFDBEAFE)
                    : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Center(
                child: Icon(
                  Icons.notifications_rounded,
                  size: 18,
                  color: Color(0xFF2563EB),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                      color: const Color(0xFF26262A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              data.timeLabel,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF8A8F99),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
