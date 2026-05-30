import 'package:cloud_firestore/cloud_firestore.dart';

enum RequestType { medical, food, shelter, evacuation, other }

enum UrgencyLevel { critical, urgent, general }

enum RequestStatus { open, assigned, closed }

class RequestLocation {
  final String address;
  final GeoPoint coordinates;

  RequestLocation({
    required this.address,
    required this.coordinates,
  });

  factory RequestLocation.fromMap(Map<String, dynamic> map) {
    return RequestLocation(
      address: map['address'] as String,
      coordinates: map['coordinates'] as GeoPoint,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'coordinates': coordinates,
    };
  }
}

class RequestModel {
  final String id;
  final String createdBy; // userId of the civilian
  final String title;
  final RequestLocation location;
  final RequestType requestType;
  final UrgencyLevel urgencyLevel;
  final int urgencyScore;
  final int maxVolunteer;
  final List<String> assignedVolunteerIds;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  RequestModel({
    required this.id,
    required this.createdBy,
    required this.title,
    required this.location,
    required this.requestType,
    required this.urgencyLevel,
    required this.urgencyScore,
    required this.maxVolunteer,
    this.assignedVolunteerIds = const [],
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return RequestModel(
      id: doc.id,
      createdBy: data['createdBy'] as String,
      title: data['title'] as String,
      location: RequestLocation.fromMap(data['location'] as Map<String, dynamic>),
      requestType: RequestType.values.firstWhere(
        (e) => e.name.toLowerCase() == (data['request_type'] as String).toLowerCase(),
        orElse: () => RequestType.other,
      ),
      urgencyLevel: UrgencyLevel.values.firstWhere(
        (e) => e.name.toLowerCase() == (data['urgency_level'] as String).toLowerCase(),
        orElse: () => UrgencyLevel.general,
      ),
      urgencyScore: data['urgency_score'] as int,
      maxVolunteer: data['max_volunteer'] as int,
      status: RequestStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == (data['status'] as String).toLowerCase(),
        orElse: () => RequestStatus.open,
      ),
      assignedVolunteerIds: data['assignedVolunteerIds'] != null
          ? List<String>.from(data['assignedVolunteerIds'] as List)
          : [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'createdBy': createdBy,
      'title': title,
      'location': location.toMap(),
      'request_type': requestType.name,
      'urgency_level': urgencyLevel.name,
      'urgency_score': urgencyScore,
      'max_volunteer': maxVolunteer,
      'status': status.name,
      'assignedVolunteerIds': assignedVolunteerIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  bool get isFull => assignedVolunteerIds.length >= maxVolunteer;

  RequestModel copyWith({
    String? id,
    String? createdBy,
    String? title,
    RequestLocation? location,
    RequestType? requestType,
    UrgencyLevel? urgencyLevel,
    int? urgencyScore,
    int? maxVolunteer,
    List<String>? assignedVolunteerIds,
    RequestStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RequestModel(
      id: id ?? this.id,
      createdBy: createdBy ?? this.createdBy,
      title: title ?? this.title,
      location: location ?? this.location,
      requestType: requestType ?? this.requestType,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      urgencyScore: urgencyScore ?? this.urgencyScore,
      maxVolunteer: maxVolunteer ?? this.maxVolunteer,
      assignedVolunteerIds: assignedVolunteerIds ?? this.assignedVolunteerIds,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
