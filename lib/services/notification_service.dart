import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:we_are_ready/models/notification_model.dart';
import 'package:we_are_ready/models/request_model.dart';
import 'package:we_are_ready/services/notification_exception.dart';

class NotificationService {
  final FirebaseFirestore _db;

  static const String _col = 'notifications';

  NotificationService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection(_col);

  // ---------------------------------------------------------------------------
  // Read / Watch
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Mark read
  // ---------------------------------------------------------------------------

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

      for (final chunk in _chunks(snapshot.docs, 500)) {
        final batch = _db.batch();
        for (final doc in chunk) {
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

  // ---------------------------------------------------------------------------
  // Write — volunteer
  // ---------------------------------------------------------------------------

  /// Notifies [volunteerIds] about a newly created [request].
  ///
  /// Writes one [VolunteerNotificationModel] per volunteer.
  /// Critical and urgent requests expire in 2 hours; general in 24 hours.
  /// Uses batched writes (max 500 per batch).
  Future<void> notifyVolunteersNewRequest(
    RequestModel request,
    List<String> volunteerIds,
  ) async {
    if (volunteerIds.isEmpty) return;

    final now = DateTime.now();
    final expires = _volunteerExpiry(request.urgencyLevel, now);
    final title = '${_urgencyLabel(request.urgencyLevel)} · ${request.title}';

    try {
      for (final chunk in _chunks(volunteerIds, 500)) {
        final batch = _db.batch();
        for (final uid in chunk) {
          final ref = _collection.doc();
          final model = VolunteerNotificationModel(
            id: ref.id,
            userId: uid,
            requestId: request.id,
            title: title,
            detail: request.description,
            type: VolunteerNotificationType.requestCreated,
            priority: request.urgencyScore,
            isRead: false,
            createdAt: now,
            expiresAt: expires,
          );
          batch.set(ref, model.toFirestore());
        }
        await batch.commit();
      }
    } on FirebaseException catch (e) {
      throw NotificationException(
        'Failed to notify volunteers for request ${request.id}',
        cause: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Write — civilian
  // ---------------------------------------------------------------------------

  /// Notifies the civilian who owns [request] that a volunteer has joined.
  ///
  /// Writes one [CivilianNotificationModel] to [request.createdBy].
  /// Expires in 24 hours.
  Future<void> notifyCivilianVolunteerJoined(
    RequestModel request,
    String volunteerName,
  ) async {
    final now = DateTime.now();
    final ref = _collection.doc();
    final model = CivilianNotificationModel(
      id: ref.id,
      userId: request.createdBy,
      requestId: request.id,
      volunteerIds: request.assignedVolunteerIds,
      title: '$volunteerName is on the way',
      detail: 'Your request "${request.title}" has been accepted',
      type: CivilianNotificationType.requestAssigned,
      isRead: false,
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 24)),
    );
    try {
      await ref.set(model.toFirestore());
    } on FirebaseException catch (e) {
      throw NotificationException(
        'Failed to notify civilian ${request.createdBy} '
        'for request ${request.id}',
        cause: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Write — global
  // ---------------------------------------------------------------------------

  /// Notifies the request owner that their request has been updated.
  ///
  /// Writes one [GlobalNotificationModel] to [request.createdBy].
  /// Expires in 24 hours.
  Future<void> notifyRequestUpdated(RequestModel request) async {
    final now = DateTime.now();
    final ref = _collection.doc();
    final model = GlobalNotificationModel(
      id: ref.id,
      userId: request.createdBy,
      requestId: request.id,
      title: 'Request updated',
      detail: request.title,
      type: GlobalNotificationType.requestUpdated,
      priority: 1,
      isRead: false,
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 24)),
    );
    try {
      await ref.set(model.toFirestore());
    } on FirebaseException catch (e) {
      throw NotificationException(
        'Failed to notify request updated for ${request.id}',
        cause: e,
      );
    }
  }

  /// Notifies all participants that [request] has been cancelled.
  ///
  /// Writes one [GlobalNotificationModel] to the owner and each assigned
  /// volunteer. Uses batched writes (max 500 per batch).
  /// Expires in 24 hours.
  Future<void> notifyRequestCancelled(RequestModel request) async {
    final recipients = [
      request.createdBy,
      ...request.assignedVolunteerIds,
    ];
    final now = DateTime.now();
    final detail = '"${request.title}" has been cancelled';

    try {
      for (final chunk in _chunks(recipients, 500)) {
        final batch = _db.batch();
        for (final uid in chunk) {
          final ref = _collection.doc();
          final model = GlobalNotificationModel(
            id: ref.id,
            userId: uid,
            requestId: request.id,
            title: 'Request cancelled',
            detail: detail,
            type: GlobalNotificationType.requestCancelled,
            priority: 1,
            isRead: false,
            createdAt: now,
            expiresAt: now.add(const Duration(hours: 24)),
          );
          batch.set(ref, model.toFirestore());
        }
        await batch.commit();
      }
    } on FirebaseException catch (e) {
      throw NotificationException(
        'Failed to notify request cancelled for ${request.id}',
        cause: e,
      );
    }
  }

  /// Notifies all participants that [request] has been completed.
  ///
  /// Writes one [GlobalNotificationModel] to the owner and each assigned
  /// volunteer, including volunteer names in metadata.
  /// Uses batched writes (max 500 per batch). Expires in 24 hours.
  Future<void> notifyRequestCompleted(RequestModel request) async {
    final recipients = [
      request.createdBy,
      ...request.assignedVolunteerIds,
    ];
    final now = DateTime.now();
    final detail = '"${request.title}" has been marked as complete';
    final metadata = GlobalNotificationMetadata(
      volunteerName: request.assignedVolunteerNames.join(', '),
    );

    try {
      for (final chunk in _chunks(recipients, 500)) {
        final batch = _db.batch();
        for (final uid in chunk) {
          final ref = _collection.doc();
          final model = GlobalNotificationModel(
            id: ref.id,
            userId: uid,
            requestId: request.id,
            title: 'Request completed',
            detail: detail,
            type: GlobalNotificationType.requestCompleted,
            priority: 1,
            isRead: false,
            metadata: metadata,
            createdAt: now,
            expiresAt: now.add(const Duration(hours: 24)),
          );
          batch.set(ref, model.toFirestore());
        }
        await batch.commit();
      }
    } on FirebaseException catch (e) {
      throw NotificationException(
        'Failed to notify request completed for ${request.id}',
        cause: e,
      );
    }
  }

  /// Notifies all chat participants except [senderId] about a new message.
  ///
  /// [messagePreview] is truncated to 80 characters.
  /// Writes one [GlobalNotificationModel] per recipient.
  /// Uses batched writes (max 500 per batch). Expires in 7 days.
  Future<void> notifyChatMessage(
    RequestModel request,
    String senderName,
    String messagePreview, {
    required String senderId,
  }) async {
    final participants = [
      request.createdBy,
      ...request.assignedVolunteerIds,
    ];
    final recipients = participants.where((id) => id != senderId).toList();
    if (recipients.isEmpty) return;

    final now = DateTime.now();
    final preview = messagePreview.length > 80
        ? '${messagePreview.substring(0, 80)}…'
        : messagePreview;

    try {
      for (final chunk in _chunks(recipients, 500)) {
        final batch = _db.batch();
        for (final uid in chunk) {
          final ref = _collection.doc();
          final model = GlobalNotificationModel(
            id: ref.id,
            userId: uid,
            requestId: request.id,
            title: '$senderName · ${request.title}',
            detail: preview,
            type: GlobalNotificationType.chatMessage,
            priority: 1,
            isRead: false,
            createdAt: now,
            expiresAt: now.add(const Duration(days: 7)),
          );
          batch.set(ref, model.toFirestore());
        }
        await batch.commit();
      }
    } on FirebaseException catch (e) {
      throw NotificationException(
        'Failed to send chat message notification for request ${request.id}',
        cause: e,
      );
    }
  }

  /// Sends an evacuation notice to every user in [userIds].
  ///
  /// Priority is 0 (highest). Expires in 30 days.
  /// Splits [userIds] into chunks of 500 for batched writes.
  Future<void> notifyEvacuation(
    List<String> userIds,
    String title,
    String detail,
  ) async {
    if (userIds.isEmpty) return;

    final now = DateTime.now();

    try {
      for (final chunk in _chunks(userIds, 500)) {
        final batch = _db.batch();
        for (final uid in chunk) {
          final ref = _collection.doc();
          final model = GlobalNotificationModel(
            id: ref.id,
            userId: uid,
            requestId: '',
            title: title,
            detail: detail,
            type: GlobalNotificationType.evacuationNotice,
            priority: 0,
            isRead: false,
            createdAt: now,
            expiresAt: now.add(const Duration(days: 30)),
          );
          batch.set(ref, model.toFirestore());
        }
        await batch.commit();
      }
    } on FirebaseException catch (e) {
      throw NotificationException(
        'Failed to send evacuation notice',
        cause: e,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static DateTime _volunteerExpiry(UrgencyLevel level, DateTime now) {
    switch (level) {
      case UrgencyLevel.critical:
      case UrgencyLevel.urgent:
        return now.add(const Duration(hours: 2));
      case UrgencyLevel.general:
        return now.add(const Duration(hours: 24));
    }
  }

  static String _urgencyLabel(UrgencyLevel level) {
    switch (level) {
      case UrgencyLevel.critical: return 'Critical';
      case UrgencyLevel.urgent:   return 'Urgent';
      case UrgencyLevel.general:  return 'General';
    }
  }

  /// Splits [items] into consecutive sub-lists of at most [size] elements.
  static List<List<T>> _chunks<T>(List<T> items, int size) {
    final result = <List<T>>[];
    for (var i = 0; i < items.length; i += size) {
      result.add(items.sublist(i, (i + size).clamp(0, items.length)));
    }
    return result;
  }
}
