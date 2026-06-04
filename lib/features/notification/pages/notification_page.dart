import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:we_are_ready/constants/constants.dart';
import 'package:we_are_ready/features/notification/widgets/lock_screen_preview_banner.dart';
import 'package:we_are_ready/features/notification/widgets/notification_app_bar.dart';
import 'package:we_are_ready/features/notification/widgets/notification_tile.dart';
import 'package:we_are_ready/providers/auth_provider.dart';
import 'package:we_are_ready/providers/notification_provider.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().userModel?.id ?? '';
      context.read<NotificationProvider>().init(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<NotificationProvider>();
    final all = notifier.all;

    final latestCritical = notifier.volunteerNotifications
        .where((n) => n.priority == 1 && !n.isRead)
        .firstOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: NotificationAppBar(
        unreadCount: notifier.unreadCount,
        onMarkAllRead: () => notifier.markAllRead(),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LockScreenPreviewBanner(latestCritical: latestCritical),
          if (latestCritical != null)
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Text(
                'HOW IT APPEARS ON YOUR LOCK SCREEN',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          Expanded(
            child: notifier.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2.4,
                    ),
                  )
                : all.isEmpty
                    ? const _EmptyState()
                    : ListView.separated(
                        itemCount: all.length,
                        separatorBuilder: (_, i) => const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.border,
                          indent: 52,
                        ),
                        itemBuilder: (ctx, i) =>
                            NotificationTile(notification: all[i]),
                      ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            color: AppColors.textMuted,
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            'No notifications',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
