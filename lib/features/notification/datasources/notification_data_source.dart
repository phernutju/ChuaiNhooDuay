abstract class NotificationDataSource {
  Stream<List<dynamic>> watchForUser(String userId);
  Future<void> markRead(String id);
  Future<void> markAllRead(String userId);
}
