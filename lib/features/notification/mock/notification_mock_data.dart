import 'package:we_are_ready/models/notification_model.dart';

abstract class NotificationMockData {

  static final List<dynamic> all = [
    VolunteerNotificationModel(
      id: 'mock-vol-1',
      userId: 'mock-user-volunteer',
      requestId: 'mock-req-1',
      title: 'Critical · 0.3 km away — needs med...',
      detail: 'Elderly woman fell — need someone to suppo...',
      type: VolunteerNotificationType.requestCreated,
      priority: 1,
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
    ),
    VolunteerNotificationModel(
      id: 'mock-vol-2',
      userId: 'mock-user-volunteer',
      requestId: 'mock-req-2',
      title: 'Urgent · 1.2 km away — shelter nee...',
      detail: 'Family of 4 with children needs shelter tonight',
      type: VolunteerNotificationType.requestCreated,
      priority: 2,
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
    ),
    GlobalNotificationModel(
      id: 'mock-global-1',
      userId: 'mock-user-volunteer',
      requestId: 'mock-req-1',
      title: "You accepted Pannavadee's request",
      detail: 'Driving · Din Daeng · 1.6 km',
      type: GlobalNotificationType.requestUpdated,
      priority: 3,
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(minutes: 34)),
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    ),
    GlobalNotificationModel(
      id: 'mock-global-2',
      userId: 'mock-user-volunteer',
      requestId: 'mock-req-1',
      title: 'Pannavadee S. thanked you',
      detail: 'You arrived on time and stayed kind — thank...',
      type: GlobalNotificationType.requestCompleted,
      priority: 4,
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      expiresAt: DateTime.now().add(const Duration(days: 7)),
    ),
    GlobalNotificationModel(
      id: 'mock-global-3',
      userId: 'mock-user-volunteer',
      requestId: 'mock-req-hub',
      title: 'Rescue Hub · Thanks for your se...',
      detail: 'You responded to 7 requests · top 5% in your...',
      type: GlobalNotificationType.chatMessage,
      priority: 5,
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    ),
  ];

  static List<VolunteerNotificationModel> get volunteer =>
      all.whereType<VolunteerNotificationModel>().toList();

  static List<GlobalNotificationModel> get global =>
      all.whereType<GlobalNotificationModel>().toList();

  static int get unreadCount => all.where((n) => _isUnread(n)).length;

  static bool _isUnread(dynamic n) {
    if (n is CivilianNotificationModel) return !n.isRead;
    if (n is VolunteerNotificationModel) return !n.isRead;
    if (n is GlobalNotificationModel) return !n.isRead;
    return false;
  }
}
