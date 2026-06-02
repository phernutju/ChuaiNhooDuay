import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/request_model.dart';

class RequestService {
  final _db = FirebaseFirestore.instance;

  Future<String> createRequest(RequestModel request) async {
    final doc = await _db.collection('requests').add(request.toFirestore());
    return doc.id;
  }

  Stream<List<RequestModel>> getMyRequests(String requesterId) {
    if (requesterId.isEmpty) return Stream.value([]);
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

  // Stub — FCM not wired yet. Returns placeholder count.
  Future<int> notifyNearbyVolunteers(String requestId, GeoPoint location) async {
    return 147;
  }
}
