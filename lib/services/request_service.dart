import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/request_model.dart';
import 'notification_exception.dart';
import 'notification_service.dart';
import 'user_service.dart';

class RequestService {
  final FirebaseFirestore _db;
  final NotificationService _notifications;

  RequestService({
    FirebaseFirestore? firestore,
    NotificationService? notificationService,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _notifications = notificationService ?? NotificationService();

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  /// Creates a new request document in Firestore and notifies nearby volunteers.
  ///
  /// Returns the generated Firestore document ID.
  /// Notification failures that are not [NotificationException] are logged and
  /// swallowed so the request creation is never rolled back.
  Future<String> createRequest(RequestModel request) async {
    final doc = await _db.collection('requests').add(request.toFirestore());

    final nearbyVolunteerIds =
        await _getNearbyVolunteerIds(request.location.coordinates);
    await _notify(() => _notifications.notifyVolunteersNewRequest(
          request.copyWith(id: doc.id),
          nearbyVolunteerIds,
        ));

    return doc.id;
  }

  /// Adds [volunteerId] to the request's assigned volunteers and notifies the
  /// civilian owner.
  ///
  /// Fetches the updated request document after the write so the notification
  /// reflects the latest volunteer list.
  Future<void> joinRequest(String requestId, String volunteerId) async {
    final user = await UserService().getUser(volunteerId);
    final name = user?.name?.isNotEmpty == true ? user!.name! : 'Volunteer';

    await _db.collection('requests').doc(requestId).update({
      'assignedVolunteerIds': FieldValue.arrayUnion([volunteerId]),
      'assignedVolunteerNames': FieldValue.arrayUnion([name]),
      'status': 'matched',
      'updatedAt': Timestamp.now(),
    });

    final snap = await _db.collection('requests').doc(requestId).get();
    final updated = RequestModel.fromFirestore(snap);
    await _notify(
      () => _notifications.notifyCivilianVolunteerJoined(updated, name),
    );
  }

  /// Marks [requestId] as completed in Firestore and notifies all participants.
  ///
  /// Uses [RequestStatus.completed] for cancellation since the enum has no
  /// dedicated cancelled value — add one if the distinction becomes important.
  Future<void> cancelRequest(String requestId) async {
    await _db.collection('requests').doc(requestId).update({
      'status': RequestStatus.completed.name,
      'updatedAt': Timestamp.now(),
    });

    final snap = await _db.collection('requests').doc(requestId).get();
    final request = RequestModel.fromFirestore(snap);
    await _notify(() => _notifications.notifyRequestCancelled(request));
  }

  /// Marks [requestId] as completed in Firestore and notifies all participants.
  Future<void> completeRequest(String requestId) async {
    await _db.collection('requests').doc(requestId).update({
      'status': RequestStatus.completed.name,
      'updatedAt': Timestamp.now(),
    });

    final snap = await _db.collection('requests').doc(requestId).get();
    final request = RequestModel.fromFirestore(snap);
    await _notify(() => _notifications.notifyRequestCompleted(request));
  }

  // ---------------------------------------------------------------------------
  // Reads / Streams
  // ---------------------------------------------------------------------------

  /// Returns the [RequestModel] for [requestId].
  ///
  /// Throws [StateError] if the document does not exist.
  Future<RequestModel> getById(String requestId) async {
    final snap =
        await _db.collection('requests').doc(requestId).get();
    if (!snap.exists) throw StateError('Request $requestId not found');
    return RequestModel.fromFirestore(snap);
  }

  Stream<List<RequestModel>> getMyRequests(String requesterId) {
    if (requesterId.isEmpty) return Stream.value([]);
    return _db
        .collection('requests')
        .where('createdBy', isEqualTo: requesterId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map(RequestModel.fromFirestore)
              .where((r) => r.status != RequestStatus.completed)
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<RequestModel>> getOpenRequests() {
    return _db
        .collection('requests')
        .where('status', isEqualTo: 'waiting')
        .snapshots()
        .map((snap) {
          final list = snap.docs.map(RequestModel.fromFirestore).toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // ---------------------------------------------------------------------------
  // Notifications
  // ---------------------------------------------------------------------------

  /// Fetches nearby volunteer IDs and sends them a request-created notification.
  ///
  /// Returns the number of volunteers notified.
  Future<int> notifyNearbyVolunteers(
    String requestId,
    GeoPoint location,
  ) async {
    final ids = await _getNearbyVolunteerIds(location);

    final snap = await _db.collection('requests').doc(requestId).get();
    final request = RequestModel.fromFirestore(snap);

    await _notify(
      () => _notifications.notifyVolunteersNewRequest(request, ids),
    );

    return ids.length;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Returns IDs of all volunteers in the `users` collection.
  ///
  /// TODO: add geo-filter using [location] once geo-indexing is in place.
  Future<List<String>> _getNearbyVolunteerIds(GeoPoint location) async {
    final snap = await _db
        .collection('users')
        .where('role', isEqualTo: 'volunteer')
        .get();
    return snap.docs.map((d) => d.id).toList();
  }

  /// Executes [fn] and swallows non-[NotificationException] errors.
  ///
  /// [NotificationException] propagates to the caller.
  /// All other errors are logged via [debugPrint] and discarded so that
  /// notification failures never roll back an already-committed Firestore write.
  Future<void> _notify(Future<void> Function() fn) async {
    try {
      await fn();
    } on NotificationException {
      rethrow;
    } catch (e) {
      debugPrint('[RequestService] notification failed: $e');
    }
  }
}
