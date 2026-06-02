// Firebase.initializeApp() must be called before this service is instantiated.
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/request_model.dart';

class MapService {
  MapService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Live stream of all requests with status == "open".
  /// isFull filtering is done client-side in [MapProvider] because isFull
  /// is a computed getter and cannot be queried server-side.
  Stream<List<RequestModel>> getOpenRequests() {
    return _db
        .collection('requests')
        .where('status', isEqualTo: 'waiting')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => RequestModel.fromFirestore(doc)).toList(),
        );
  }
}
