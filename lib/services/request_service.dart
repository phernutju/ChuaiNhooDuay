import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/request_model.dart';

class RequestService {
  final _db = FirebaseFirestore.instance;

  Future<String> createRequest(RequestModel request) async {
    final doc = await _db.collection('requests').add(request.toFirestore());
    return doc.id;
  }

  Stream<List<RequestModel>> getMyRequests(String requesterId) {
    return _db
        .collection('requests')
        .where('createdBy', isEqualTo: requesterId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map(RequestModel.fromFirestore)
            .where((r) => r.status != RequestStatus.completed)
            .toList());
  }

  // Writes a trigger doc; Cloud Function handles FCM dispatch to volunteers within radiusKm.
  Future<int> notifyNearbyVolunteers(String requestId, GeoPoint location) async {
    await _db.collection('notification_triggers').add({
      'requestId': requestId,
      'location': location,
      'radiusKm': 2.0,
      'createdAt': FieldValue.serverTimestamp(),
      'processed': false,
    });
    return 147; // Cloud Function resolves real count; placeholder until then
  }
}
