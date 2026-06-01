import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:we_are_ready/models/notification_model.dart';
import 'package:we_are_ready/services/notification_exception.dart';

class NotificationService {
  final FirebaseFirestore _db;

  static const String _col = 'notifications';

  NotificationService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection(_col);

  Stream<List<dynamic>> watchForUser(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map(_mapSnapshot)
        .handleError(
          (Object error) {
            throw NotificationException(
              'Failed to watch notifications for user $userId',
              cause: error,
            );
          },
          test: (error) => error is FirebaseException,
        );
  }

  List<dynamic> _mapSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final now = DateTime.now();
    final result = <dynamic>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final type = data['type'] as String? ?? '';

      if (type != 'evacuation_notice') {
        final raw = data['expiresAt'];
        if (raw is Timestamp && raw.toDate().isBefore(now)) continue;
      }

      final recipientType = data['recipientType'] as String? ?? '';
      try {
        switch (recipientType) {
          case 'civilian':
            result.add(CivilianNotificationModel.fromFirestore(doc));
          case 'volunteer':
            result.add(VolunteerNotificationModel.fromFirestore(doc));
          case 'global':
            result.add(GlobalNotificationModel.fromFirestore(doc));
        }
      } catch (e) {
        throw NotificationException(
          'Failed to parse notification document ${doc.id}',
          cause: e,
        );
      }
    }

    _sort(result);
    return result;
  }

  void _sort(List<dynamic> list) {
    list.sort((a, b) {
      final pa = _priority(a);
      final pb = _priority(b);

      if (pa != null || pb != null) {
        final cmp = (pa ?? 999).compareTo(pb ?? 999);
        if (cmp != 0) return cmp;
      }

      return _createdAt(b).compareTo(_createdAt(a));
    });
  }

  int? _priority(dynamic n) {
    if (n is VolunteerNotificationModel) return n.priority;
    if (n is GlobalNotificationModel) return n.priority;
    return null;
  }

  DateTime _createdAt(dynamic n) {
    if (n is CivilianNotificationModel) return n.createdAt;
    if (n is VolunteerNotificationModel) return n.createdAt;
    if (n is GlobalNotificationModel) return n.createdAt;
    return DateTime(0);
  }

  Future<void> markRead(String notificationId) async {
    try {
      await _collection.doc(notificationId).update({'isRead': true});
    } on FirebaseException catch (e) {
      throw NotificationException(
        'Failed to mark notification $notificationId as read',
        cause: e,
      );
    }
  }

  Future<void> markAllRead(String userId) async {
    try {
      final snapshot = await _collection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) return;

      const chunkSize = 500;
      final docs = snapshot.docs;
      for (var i = 0; i < docs.length; i += chunkSize) {
        final batch = _db.batch();
        final end = (i + chunkSize).clamp(0, docs.length);
        for (final doc in docs.sublist(i, end)) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();
      }
    } on FirebaseException catch (e) {
      throw NotificationException(
        'Failed to mark all notifications as read for user $userId',
        cause: e,
      );
    }
  }
}
