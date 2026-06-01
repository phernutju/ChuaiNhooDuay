import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:we_are_ready/constants/constants.dart';
import 'package:we_are_ready/features/notification/widgets/notification_icon_badge.dart';
import 'package:we_are_ready/models/notification_model.dart';
import 'package:we_are_ready/providers/notification_provider.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({super.key, required this.notification});

  final dynamic notification;

  @override
  Widget build(BuildContext context) {
    final String id;
    final String title;
    final String detail;
    final bool isRead;
    final DateTime createdAt;
    final String requestId;
    final String recipientType;
    final String notificationType;
    GlobalNotificationType? globalType;

    if (notification is VolunteerNotificationModel) {
      final n = notification as VolunteerNotificationModel;
      id = n.id;
      title = n.title;
      detail = n.detail;
      isRead = n.isRead;
      createdAt = n.createdAt;
      requestId = n.requestId;
      recipientType = 'volunteer';
      notificationType = n.priority == 1
          ? 'critical'
          : n.priority == 2
              ? 'urgent'
              : 'request_created';
    } else if (notification is CivilianNotificationModel) {
      final n = notification as CivilianNotificationModel;
      id = n.id;
      title = n.title;
      detail = n.detail;
      isRead = n.isRead;
      createdAt = n.createdAt;
      requestId = n.requestId;
      recipientType = 'civilian';
      notificationType = 'request_assigned';
    } else if (notification is GlobalNotificationModel) {
      final n = notification as GlobalNotificationModel;
      id = n.id;
      title = n.title;
      detail = n.detail;
      isRead = n.isRead;
      createdAt = n.createdAt;
      requestId = n.requestId;
      recipientType = 'global';
      globalType = n.type;
      notificationType = switch (n.type) {
        GlobalNotificationType.chatMessage => 'chat_message',
        GlobalNotificationType.evacuationNotice => 'evacuation_notice',
        _ => 'default',
      };
    } else {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: () => _onTap(context, id, requestId, recipientType, globalType),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 16,
              height: 40,
              child: isRead
                  ? null
                  : Center(
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 4),
            NotificationIconBadge(
              recipientType: recipientType,
              notificationType: notificationType,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isRead
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatTime(createdAt),
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onTap(
    BuildContext context,
    String id,
    String requestId,
    String recipientType,
    GlobalNotificationType? globalType,
  ) async {
    final notifier = context.read<NotificationProvider>();
    await notifier.markRead(id);
    if (!context.mounted) return;

    switch (recipientType) {
      case 'volunteer':
        context.push('${AppRoutes.notificationDetail}/$requestId');
      case 'civilian':
        context.push('${AppRoutes.requestStatus}/$requestId');
      case 'global':
        switch (globalType) {
          case GlobalNotificationType.chatMessage:
            context.push(AppRoutes.chat);
          case GlobalNotificationType.evacuationNotice:
            context.push(AppRoutes.evacuationDetail);
          default:
            context.push('${AppRoutes.notificationDetail}/$requestId');
        }
    }
  }

  static String _formatTime(DateTime createdAt) {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours} hr';

    final nowDate = DateTime(now.year, now.month, now.day);
    final createdDate =
        DateTime(createdAt.year, createdAt.month, createdAt.day);
    if (nowDate.difference(createdDate).inDays == 1) return 'Yesterday';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${createdAt.day} ${months[createdAt.month - 1]}';
  }
}
