import 'package:we_are_ready/features/notification/datasources/notification_data_source.dart';
import 'package:we_are_ready/services/notification_service.dart';

class FirestoreNotificationDataSource implements NotificationDataSource {
  final NotificationService _service;

  FirestoreNotificationDataSource(this._service);

  @override
  Stream<List<dynamic>> watchForUser(String userId) =>
      _service.watchForUser(userId);

  @override
  Future<void> markRead(String id) => _service.markRead(id);

  @override
  Future<void> markAllRead(String userId) => _service.markAllRead(userId);
}
