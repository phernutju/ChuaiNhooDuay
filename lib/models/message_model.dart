import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { message, system, location }

class MessageModel {
  final String id;
  final String senderId;
  final String? text;
  final String? imageUrl;
  final String? locationAddress;
  final MessageType type;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int seenCount;
  final List<String> seenBy;

  MessageModel({
    required this.id,
    required this.senderId,
    this.text,
    this.imageUrl,
    this.locationAddress,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.seenCount = 0,
    this.seenBy = const [],
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return MessageModel(
      id: doc.id,
      senderId: data['senderId'] as String,
      text: data['text'] as String?,
      imageUrl: data['imageUrl'] as String?,
      locationAddress: data['locationAddress'] as String?,
      type: _parseType(data['type'] as String),
      seenCount: data['seenCount'] as int? ?? 0,
      seenBy: data['seenBy'] != null ? List<String>.from(data['seenBy'] as List) : [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static MessageType _parseType(String value) {
    switch (value) {
      case 'message':
        return MessageType.message;
      case 'system':
        return MessageType.system;
      case 'location':
        return MessageType.location;
      default:
        return MessageType.message;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      if (text != null) 'text': text,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (locationAddress != null) 'locationAddress': locationAddress,
      'type': type.name,
      'seenCount': seenCount,
      'seenBy': seenBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Returns updated fields to pass to Firestore when a user sees the message.
  /// Call this on the client, then do a Firestore update with the result.
  /// Uses FieldValue.arrayUnion + increment to avoid race conditions.
  static Map<String, dynamic> markSeenUpdate(String userId) {
    return {
      'seenBy': FieldValue.arrayUnion([userId]),
      'seenCount': FieldValue.increment(1),
    };
  }

  /// Whether a given user has already seen this message.
  bool hasBeenSeenBy(String userId) => seenBy.contains(userId);

  /// Firestore path: requests/{requestId}/messages/{messageId}
  static CollectionReference subcollection(
    FirebaseFirestore firestore,
    String requestId,
  ) {
    return firestore
        .collection('requests')
        .doc(requestId)
        .collection('messages');
  }

  MessageModel copyWith({
    String? text,
    String? imageUrl,
    String? locationAddress,
    DateTime? updatedAt,
    int? seenCount,
    List<String>? seenBy,
  }) {
    return MessageModel(
      id: id,
      senderId: senderId,
      text: text ?? this.text,
      imageUrl: imageUrl ?? this.imageUrl,
      locationAddress: locationAddress ?? this.locationAddress,
      type: type,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      seenCount: seenCount ?? this.seenCount,
      seenBy: seenBy ?? this.seenBy,
    );
  }
}
