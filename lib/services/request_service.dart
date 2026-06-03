import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/request_model.dart';
import 'user_service.dart';

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

  Future<void> joinRequest(String requestId, String volunteerId) async {
    final user = await UserService().getUser(volunteerId);
    final name = user?.name?.isNotEmpty == true ? user!.name! : 'Volunteer';
    await _db.collection('requests').doc(requestId).update({
      'assignedVolunteerIds': FieldValue.arrayUnion([volunteerId]),
      'assignedVolunteerNames': FieldValue.arrayUnion([name]),
      'status': 'matched',
      'updatedAt': Timestamp.now(),
    });
  }

  // Stub — FCM not wired yet. Returns placeholder count.
  Future<int> notifyNearbyVolunteers(String requestId, GeoPoint location) async {
    return 147;
  }
}
