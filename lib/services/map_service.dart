// Firebase.initializeApp() must be called before this service is instantiated.
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/request_model.dart';

class MapService {
  MapService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  /// Live stream of all requests that are NOT completed.
  /// Markers stay on map from waiting → assigned → matched
  /// and only disappear when status becomes completed.
  Stream<List<RequestModel>> getOpenRequests() {
    return _db
        .collection('requests')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) => RequestModel.fromFirestore(doc))
              .where((r) => r.status != RequestStatus.completed)
              .toList(),
        );
  }
}
