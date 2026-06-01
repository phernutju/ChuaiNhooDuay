import 'package:we_are_ready/features/notification/datasources/notification_data_source.dart';
import 'package:we_are_ready/features/notification/mock/notification_mock_data.dart';

class MockNotificationDataSource implements NotificationDataSource {
  @override
  Stream<List<dynamic>> watchForUser(String userId) =>
      Stream.value(NotificationMockData.all);

  @override
  Future<void> markRead(String id) async {}

  @override
  Future<void> markAllRead(String userId) async {}
}
