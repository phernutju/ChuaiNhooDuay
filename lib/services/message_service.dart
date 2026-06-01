import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:we_are_ready/models/message_model.dart';
import 'package:we_are_ready/services/message_exception.dart';

class MessageService {
  final FirebaseFirestore _db;

  MessageService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // String helpers — callers are responsible for sending via sendSystemMessage.
  // ---------------------------------------------------------------------------

  /// System message text when a volunteer joins.
  static String joinedSystemMessage(String volunteerName) =>
      '$volunteerName joined the request';

  /// System message text when a volunteer leaves.
  static String leftSystemMessage(String volunteerName) =>
      '$volunteerName left the request';

  /// System message text when the request is closed.
  static String closedSystemMessage() =>
      'This request has been closed. No new messages can be sent.';

  // ---------------------------------------------------------------------------
  // Streams
  // ---------------------------------------------------------------------------

  /// Real-time stream of messages for [requestId], ordered by [createdAt] ascending.
  Stream<List<MessageModel>> watchMessages(String requestId) {
    return MessageModel.subcollection(_db, requestId)
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snap) => snap.docs.map(MessageModel.fromFirestore).toList(),
        )
        .handleError(
          (Object error) {
            throw MessageException(
              'Failed to watch messages for request $requestId',
              cause: error,
            );
          },
          test: (e) => e is FirebaseException,
        );
  }

  /// Stream of how many messages in [requestId] have not been seen by [userId].
  Stream<int> watchUnseenCount({
    required String requestId,
    required String userId,
  }) {
    return watchMessages(requestId).map(
      (messages) => messages.where((m) => !m.hasBeenSeenBy(userId)).length,
    );
  }

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  /// Sends a plain text message from [senderId] in [requestId].
  ///
  /// Throws [MessageException] if [text] is blank or a Firestore write fails.
  Future<void> sendTextMessage({
    required String requestId,
    required String senderId,
    required String text,
  }) async {
    if (text.trim().isEmpty) {
      throw const MessageException('Message text must not be empty');
    }
    try {
      await MessageModel.subcollection(_db, requestId).add({
        'senderId': senderId,
        'text': text.trim(),
        'type': MessageType.message.name,
        'seenCount': 0,
        'seenBy': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw MessageException(
        'Failed to send message in request $requestId',
        cause: e,
      );
    }
  }

  /// Sends an automated system message in [requestId].
  ///
  /// Use the static string helpers ([joinedSystemMessage], etc.) to build [text].
  Future<void> sendSystemMessage({
    required String requestId,
    required String text,
  }) async {
    try {
      await MessageModel.subcollection(_db, requestId).add({
        'senderId': '',
        'text': text,
        'type': MessageType.system.name,
        'seenCount': 0,
        'seenBy': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw MessageException(
        'Failed to send system message in request $requestId',
        cause: e,
      );
    }
  }

  /// Marks a single message as seen by [userId].
  ///
  /// Uses [MessageModel.markSeenUpdate] — does not re-implement the logic.
  Future<void> markMessageSeen({
    required String requestId,
    required String messageId,
    required String userId,
  }) async {
    try {
      await MessageModel.subcollection(_db, requestId)
          .doc(messageId)
          .update(MessageModel.markSeenUpdate(userId));
    } on FirebaseException catch (e) {
      throw MessageException(
        'Failed to mark message $messageId as seen',
        cause: e,
      );
    }
  }

  /// Marks all unseen messages in [messages] as seen by [userId] in a single batch.
  Future<void> markAllSeen({
    required String requestId,
    required String userId,
    required List<MessageModel> messages,
  }) async {
    final unseen = messages.where((m) => !m.hasBeenSeenBy(userId)).toList();
    if (unseen.isEmpty) return;

    try {
      final col = MessageModel.subcollection(_db, requestId);
      final batch = _db.batch();
      for (final msg in unseen) {
        batch.update(col.doc(msg.id), MessageModel.markSeenUpdate(userId));
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw MessageException(
        'Failed to batch-mark messages as seen in request $requestId',
        cause: e,
      );
    }
  }
}
