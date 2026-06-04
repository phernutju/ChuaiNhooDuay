import 'package:we_are_ready/models/notification_model.dart';

class NotificationSortUtil {
  NotificationSortUtil._();

  static List<T> sortByPriority<T>(List<T> notifications) {
    final copy = List<T>.from(notifications);
    copy.sort((a, b) {
      final pa = _priority(a);
      final pb = _priority(b);
      if (pa != null && pb != null) return pa.compareTo(pb);
      if (pa != null) return -1;
      if (pb != null) return 1;
      return 0;
    });
    return copy;
  }

  static List<T> filterUnread<T>(List<T> notifications) {
    return notifications.where((n) => _isUnread(n)).toList();
  }

  static Map<String, List<dynamic>> groupByRecipientType(
    List<dynamic> notifications,
  ) {
    final result = <String, List<dynamic>>{};
    for (final n in notifications) {
      result.putIfAbsent(_recipientType(n), () => []).add(n);
    }
    return result;
  }

  static int? _priority(dynamic n) {
    if (n is VolunteerNotificationModel) return n.priority;
    if (n is GlobalNotificationModel) return n.priority;
    return null;
  }

  static bool _isUnread(dynamic n) {
    if (n is CivilianNotificationModel) return !n.isRead;
    if (n is VolunteerNotificationModel) return !n.isRead;
    if (n is GlobalNotificationModel) return !n.isRead;
    return false;
  }

  static String _recipientType(dynamic n) {
    if (n is CivilianNotificationModel) return 'civilian';
    if (n is VolunteerNotificationModel) return 'volunteer';
    if (n is GlobalNotificationModel) return 'global';
    return 'unknown';
  }
}
