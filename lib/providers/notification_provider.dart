import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:we_are_ready/features/notification/datasources/notification_data_source.dart';
import 'package:we_are_ready/models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationDataSource _source;

  NotificationProvider(this._source);

  List<dynamic> _all = [];

  bool isLoading = false;
  String? error;

  String? _userId;
  StreamSubscription<List<dynamic>>? _sub;

  List<dynamic> get all => List.unmodifiable(_all);

  List<VolunteerNotificationModel> get volunteerNotifications =>
      _all.whereType<VolunteerNotificationModel>().toList();

  List<CivilianNotificationModel> get civilianNotifications =>
      _all.whereType<CivilianNotificationModel>().toList();

  List<GlobalNotificationModel> get globalNotifications =>
      _all.whereType<GlobalNotificationModel>().toList();

  List<GlobalNotificationModel> get evacuationNotices => globalNotifications
      .where((n) => n.type == GlobalNotificationType.evacuationNotice)
      .toList();

  int get unreadCount => _all.where(_isUnread).length;

  bool _isUnread(dynamic n) {
    if (n is CivilianNotificationModel) return !n.isRead;
    if (n is VolunteerNotificationModel) return !n.isRead;
    if (n is GlobalNotificationModel) return !n.isRead;
    return false;
  }

  void init(String userId) {
    _sub?.cancel();
    _userId = userId;
    isLoading = true;
    error = null;
    notifyListeners();

    _sub = _source.watchForUser(userId).listen(
      (notifications) {
        _all = notifications;
        isLoading = false;
        error = null;
        notifyListeners();
      },
      onError: (Object e) {
        isLoading = false;
        error = e.toString();
        notifyListeners();
      },
    );
  }

  Future<void> markRead(String id) async {
    try {
      await _source.markRead(id);
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> markAllRead() async {
    if (_userId == null) return;
    try {
      await _source.markAllRead(_userId!);
    } catch (e) {
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
