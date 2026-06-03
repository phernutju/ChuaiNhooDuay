import 'package:cloud_firestore/cloud_firestore.dart';

enum RequestType { medical, shelter, water, transport, rescue, evacuate, supplies, other }

enum UrgencyLevel { critical, urgent, general }

enum RequestStatus { waiting, matched, completed }

class RequestLocation {
  final String address;
  final GeoPoint coordinates;

  RequestLocation({required this.address, required this.coordinates});

  factory RequestLocation.fromMap(Map<String, dynamic> map) {
    return RequestLocation(
      address: map['address'] as String,
      coordinates: map['coordinates'] as GeoPoint,
    );
  }

  Map<String, dynamic> toMap() => {'address': address, 'coordinates': coordinates};
}

class RequestModel {
  final String id;
  final String createdBy;
  final String title;
  final String description;
  final RequestLocation location;
  final RequestType requestType;
  final UrgencyLevel urgencyLevel;
  final int urgencyScore;
  final int maxVolunteer;
  final List<String> assignedVolunteerIds;
  final List<String> assignedVolunteerNames;
  final String requesterName;
  final RequestStatus status;
  final bool isAnonymous;
  final DateTime createdAt;
  final DateTime updatedAt;

  RequestModel({
    required this.id,
    required this.createdBy,
    required this.title,
    this.description = '',
    required this.location,
    required this.requestType,
    required this.urgencyLevel,
    required this.urgencyScore,
    required this.maxVolunteer,
    this.assignedVolunteerIds = const [],
    this.assignedVolunteerNames = const [],
    this.requesterName = '',
    required this.status,
    this.isAnonymous = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RequestModel(
      id: doc.id,
      createdBy: data['createdBy'] as String,
      title: data['title'] as String,
      description: data['description'] as String? ?? '',
      location: RequestLocation.fromMap(data['location'] as Map<String, dynamic>),
      requestType: RequestType.values.firstWhere(
        (e) => e.name == (data['request_type'] as String),
        orElse: () => RequestType.other,
      ),
      urgencyLevel: UrgencyLevel.values.firstWhere(
        (e) => e.name == (data['urgency_level'] as String),
        orElse: () => UrgencyLevel.general,
      ),
      urgencyScore: data['urgency_score'] as int? ?? 0,
      maxVolunteer: data['max_volunteer'] as int? ?? 5,
      status: RequestStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String),
        orElse: () => RequestStatus.waiting,
      ),
      isAnonymous: data['is_anonymous'] as bool? ?? false,
      requesterName: data['requester_name'] as String? ?? '',
      assignedVolunteerIds: data['assignedVolunteerIds'] != null
          ? List<String>.from(data['assignedVolunteerIds'] as List)
          : [],
      assignedVolunteerNames: data['assignedVolunteerNames'] != null
          ? List<String>.from(data['assignedVolunteerNames'] as List)
          : [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'createdBy': createdBy,
        'title': title,
        'description': description,
        'location': location.toMap(),
        'request_type': requestType.name,
        'urgency_level': urgencyLevel.name,
        'urgency_score': urgencyScore,
        'max_volunteer': maxVolunteer,
        'status': status.name,
        'is_anonymous': isAnonymous,
        'requester_name': requesterName,
        'assignedVolunteerIds': assignedVolunteerIds,
        'assignedVolunteerNames': assignedVolunteerNames,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

  bool get isFull => assignedVolunteerIds.length >= maxVolunteer;

  RequestModel copyWith({
    String? id,
    String? createdBy,
    String? title,
    String? description,
    RequestLocation? location,
    RequestType? requestType,
    UrgencyLevel? urgencyLevel,
    int? urgencyScore,
    int? maxVolunteer,
    List<String>? assignedVolunteerIds,
    List<String>? assignedVolunteerNames,
    String? requesterName,
    RequestStatus? status,
    bool? isAnonymous,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RequestModel(
      id: id ?? this.id,
      createdBy: createdBy ?? this.createdBy,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      requestType: requestType ?? this.requestType,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      urgencyScore: urgencyScore ?? this.urgencyScore,
      maxVolunteer: maxVolunteer ?? this.maxVolunteer,
      assignedVolunteerIds: assignedVolunteerIds ?? this.assignedVolunteerIds,
      assignedVolunteerNames: assignedVolunteerNames ?? this.assignedVolunteerNames,
      requesterName: requesterName ?? this.requesterName,
      status: status ?? this.status,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
