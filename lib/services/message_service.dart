import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart' show XFile;
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
  ///
  /// Sorting is done in memory so that pending-write documents (whose server
  /// timestamp is still null) are included immediately — Firestore excludes
  /// them from `orderBy` queries until the server confirms the timestamp.
  Stream<List<MessageModel>> watchMessages(String requestId) {
    return MessageModel.subcollection(_db, requestId)
        .snapshots()
        .map(
          (snap) {
            final msgs = snap.docs.map(MessageModel.fromFirestore).toList();
            msgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            return msgs;
          },
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
  /// Throws [MessageException] if [text] is blank or na Firestore write fails.
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

  /// Uploads [imageFile] to Firebase Storage then sends a message with [imageUrl].
  ///
  /// Path: chat_images/{requestId}/{timestamp}_{filename}
  Future<void> sendImageMessage({
    required String requestId,
    required String senderId,
    required XFile imageFile,
    String? caption,
  }) async {
    final ref = FirebaseStorage.instance.ref(
      'chat_images/$requestId/${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}',
    );
    final UploadTask uploadTask;
    if (kIsWeb) {
      uploadTask = ref.putData(await imageFile.readAsBytes());
    } else {
      uploadTask = ref.putFile(File(imageFile.path));
    }
    final snapshot = await uploadTask;
    final imageUrl = await snapshot.ref.getDownloadURL();

    try {
      await MessageModel.subcollection(_db, requestId).add({
        'senderId': senderId,
        if (caption?.trim().isNotEmpty == true) 'text': caption!.trim(),
        'imageUrl': imageUrl,
        'type': MessageType.message.name,
        'seenCount': 0,
        'seenBy': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw MessageException(
        'Failed to send image in request $requestId',
        cause: e,
      );
    }
  }

  /// Sends current device GPS as a location message.
  ///
  /// Stores coords as "lat,lng" in [text]; human-readable [address] goes in
  /// [locationAddress] (nullable — only set when reverse geocoding is available).
  Future<void> sendLocationMessage({
    required String requestId,
    required String senderId,
    required double lat,
    required double lng,
    String? address,
  }) async {
    try {
      await MessageModel.subcollection(_db, requestId).add({
        'senderId': senderId,
        'text': '$lat,$lng',
        // ignore: use_null_aware_elements
        if (address != null) 'locationAddress': address,
        'type': MessageType.location.name,
        'seenCount': 0,
        'seenBy': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw MessageException(
        'Failed to send location in request $requestId',
        cause: e,
      );
    }
  }

  /// Permanently deletes a message document from Firestore.
  ///
  /// Callers are responsible for verifying ownership before calling this.
  Future<void> deleteMessage({
    required String requestId,
    required String messageId,
  }) async {
    try {
      await MessageModel.subcollection(_db, requestId).doc(messageId).delete();
    } on FirebaseException catch (e) {
      throw MessageException(
        'Failed to delete message $messageId',
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
