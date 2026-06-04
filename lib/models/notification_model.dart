import 'package:cloud_firestore/cloud_firestore.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum CivilianNotificationType {
  requestAssigned,
}

enum VolunteerNotificationType {
  requestCreated,
}

enum GlobalNotificationType {
  requestCreated,
  requestUpdated,
  requestCancelled,
  requestCompleted,
  newVolunteerNearby,
  chatMessage,
  evacuationNotice,
}

// ---------------------------------------------------------------------------
// Civilian Notification
// Sent to a civilian when volunteer(s) accept their request.
// Collection: civilianNotifications
// ---------------------------------------------------------------------------

class CivilianNotificationModel {
  final String id;
  final String userId;       // civilianId
  final String requestId;
  final List<String> volunteerIds;
  final String title;
  final String detail;
  final CivilianNotificationType type;
  final bool isRead;
  final DateTime createdAt;
  final DateTime expiresAt;

  CivilianNotificationModel({
    required this.id,
    required this.userId,
    required this.requestId,
    required this.volunteerIds,
    required this.title,
    required this.detail,
    required this.type,
    required this.isRead,
    required this.createdAt,
    required this.expiresAt,
  });

  factory CivilianNotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CivilianNotificationModel(
      id: doc.id,
      userId: data['userId'] as String,
      requestId: data['requestId'] as String,
      volunteerIds: List<String>.from(data['volunteerId'] as List),
      title: data['title'] as String,
      detail: data['detail'] as String,
      type: _parseCivilianType(data['type'] as String),
      isRead: data['isRead'] as bool,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
    );
  }

  static CivilianNotificationType _parseCivilianType(String value) {
    switch (value) {
      case 'request_assigned':
        return CivilianNotificationType.requestAssigned;
      default:
        return CivilianNotificationType.requestAssigned;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'requestId': requestId,
      'volunteerId': volunteerIds,
      'title': title,
      'detail': detail,
      'type': _typeToString(type),
      'isRead': isRead,
      'recipientType': 'civilian',
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
  }

  static String _typeToString(CivilianNotificationType type) {
    switch (type) {
      case CivilianNotificationType.requestAssigned:
        return 'request_assigned';
    }
  }

  CivilianNotificationModel copyWith({bool? isRead}) {
    return CivilianNotificationModel(
      id: id,
      userId: userId,
      requestId: requestId,
      volunteerIds: volunteerIds,
      title: title,
      detail: detail,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      expiresAt: expiresAt,
    );
  }
}

// ---------------------------------------------------------------------------
// Volunteer Notification
// Sent to a specific volunteer when a civilian creates a nearby request.
// Collection: volunteerNotifications
// ---------------------------------------------------------------------------

class VolunteerNotificationModel {
  final String id;
  final String userId;     // volunteerId
  final String requestId;
  final String title;
  final String detail;
  final VolunteerNotificationType type;
  final int priority;
  final bool isRead;
  final DateTime createdAt;
  final DateTime expiresAt;

  VolunteerNotificationModel({
    required this.id,
    required this.userId,
    required this.requestId,
    required this.title,
    required this.detail,
    required this.type,
    required this.priority,
    required this.isRead,
    required this.createdAt,
    required this.expiresAt,
  });

  factory VolunteerNotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return VolunteerNotificationModel(
      id: doc.id,
      userId: data['userId'] as String,
      requestId: data['requestId'] as String,
      title: data['title'] as String,
      detail: data['detail'] as String,
      type: _parseVolunteerType(data['type'] as String),
      priority: data['priority'] as int,
      isRead: data['isRead'] as bool,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
    );
  }

  static VolunteerNotificationType _parseVolunteerType(String value) {
    switch (value) {
      case 'request_created':
        return VolunteerNotificationType.requestCreated;
      default:
        return VolunteerNotificationType.requestCreated;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'requestId': requestId,
      'title': title,
      'detail': detail,
      'type': _typeToString(type),
      'priority': priority,
      'isRead': isRead,
      'recipientType': 'volunteer',
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
  }

  static String _typeToString(VolunteerNotificationType type) {
    switch (type) {
      case VolunteerNotificationType.requestCreated:
        return 'request_created';
    }
  }

  VolunteerNotificationModel copyWith({bool? isRead}) {
    return VolunteerNotificationModel(
      id: id,
      userId: userId,
      requestId: requestId,
      title: title,
      detail: detail,
      type: type,
      priority: priority,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      expiresAt: expiresAt,
    );
  }
}

// ---------------------------------------------------------------------------
// Global Notification Metadata
// Extra data attached to global notifications (e.g. ETA, volunteer name).
// ---------------------------------------------------------------------------

class GlobalNotificationMetadata {
  final int? etaMinutes;
  final String? volunteerName;

  GlobalNotificationMetadata({
    this.etaMinutes,
    this.volunteerName,
  });

  factory GlobalNotificationMetadata.fromMap(Map<String, dynamic> map) {
    return GlobalNotificationMetadata(
      etaMinutes: map['etaMinutes'] as int?,
      volunteerName: map['volunteerName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (etaMinutes != null) 'etaMinutes': etaMinutes,
      if (volunteerName != null) 'volunteerName': volunteerName,
    };
  }
}

// ---------------------------------------------------------------------------
// Global Notification
// Broadcast to all relevant users (e.g. evacuation alerts, nearby volunteer).
// Collection: globalNotifications
// ---------------------------------------------------------------------------

class GlobalNotificationModel {
  final String id;
  final String userId;
  final String? volunteerId;
  final String requestId;
  final String title;
  final String detail;
  final GlobalNotificationType type;
  final int priority;
  final bool isRead;
  final GlobalNotificationMetadata? metadata;
  final DateTime createdAt;
  final DateTime expiresAt;

  GlobalNotificationModel({
    required this.id,
    required this.userId,
    this.volunteerId,
    required this.requestId,
    required this.title,
    required this.detail,
    required this.type,
    required this.priority,
    required this.isRead,
    this.metadata,
    required this.createdAt,
    required this.expiresAt,
  });

  factory GlobalNotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return GlobalNotificationModel(
      id: doc.id,
      userId: data['userId'] as String,
      volunteerId: data['volunteerId'] as String?,
      requestId: data['requestId'] as String,
      title: data['title'] as String,
      detail: data['detail'] as String,
      type: _parseGlobalType(data['type'] as String),
      priority: data['priority'] as int,
      isRead: data['isRead'] as bool,
      metadata: data['metadata'] != null
          ? GlobalNotificationMetadata.fromMap(
              data['metadata'] as Map<String, dynamic>)
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
    );
  }

  static GlobalNotificationType _parseGlobalType(String value) {
    switch (value) {
      case 'request_created':
        return GlobalNotificationType.requestCreated;
      case 'request_updated':
        return GlobalNotificationType.requestUpdated;
      case 'request_cancelled':
        return GlobalNotificationType.requestCancelled;
      case 'request_completed':
        return GlobalNotificationType.requestCompleted;
      case 'new_volunteer_nearby':
        return GlobalNotificationType.newVolunteerNearby;
      case 'chat_message':
        return GlobalNotificationType.chatMessage;
      case 'evacuation_notice':
        return GlobalNotificationType.evacuationNotice;
      default:
        return GlobalNotificationType.requestCreated;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      if (volunteerId != null) 'volunteerId': volunteerId,
      'requestId': requestId,
      'title': title,
      'detail': detail,
      'type': _typeToString(type),
      'priority': priority,
      'isRead': isRead,
      'recipientType': 'global',
      if (metadata != null) 'metadata': metadata!.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
    };
  }

  static String _typeToString(GlobalNotificationType type) {
    switch (type) {
      case GlobalNotificationType.requestCreated:
        return 'request_created';
      case GlobalNotificationType.requestUpdated:
        return 'request_updated';
      case GlobalNotificationType.requestCancelled:
        return 'request_cancelled';
      case GlobalNotificationType.requestCompleted:
        return 'request_completed';
      case GlobalNotificationType.newVolunteerNearby:
        return 'new_volunteer_nearby';
      case GlobalNotificationType.chatMessage:
        return 'chat_message';
      case GlobalNotificationType.evacuationNotice:
        return 'evacuation_notice';
    }
  }

  GlobalNotificationModel copyWith({bool? isRead}) {
    return GlobalNotificationModel(
      id: id,
      userId: userId,
      volunteerId: volunteerId,
      requestId: requestId,
      title: title,
      detail: detail,
      type: type,
      priority: priority,
      isRead: isRead ?? this.isRead,
      metadata: metadata,
      createdAt: createdAt,
      expiresAt: expiresAt,
    );
  }
}
