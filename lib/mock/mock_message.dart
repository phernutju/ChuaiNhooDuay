// lib/mock/mock_messages.dart

import '../models/message_model.dart';

abstract class MockMessages {
  static const civilianId  = 'user_civ_001';
  static const volunteerId = 'user_vol_001';
  static const requestId   = 'req_mock_001';
  static const currentUserId = volunteerId; // "You" in the UI

  static List<MessageModel> get activeThread => [
    _sys('m1', 'Arisa V. joined the request', -10),
    _msg('m2', civilianId,
        "She's conscious but can't stand. We're at the alley behind the market.",
        -9, [civilianId, volunteerId]),
    _msg('m3', volunteerId,
        'On my way! 4 minutes out. Can you keep her still?',
        -8, [civilianId, volunteerId]),
    _loc('m4', civilianId,
        'Soi Phahonyothin 24, Chatuchak',
        -7, [civilianId, volunteerId]),
    _msg('m5', volunteerId,
        'Got it, heading there now',
        -6, [volunteerId]),          // ← unseen by civilian
  ];

  static List<MessageModel> get closedThread => [
    ...activeThread,
    _msg('m6', civilianId,
        'Ambulance is here. Thank you so much.',
        -4, [civilianId, volunteerId]),
    _msg('m7', volunteerId,
        'Stay safe, glad I could help.',
        -3, [civilianId, volunteerId]),
    _sys('m8',
        'This request has been closed. No new messages can be sent.',
        -1),
  ];

  // helpers
  static MessageModel _msg(String id, String sender, String text,
      int minAgo, List<String> seenBy) =>
    MessageModel(
      id: id, senderId: sender, text: text,
      type: MessageType.message,
      createdAt: DateTime.now().subtract(Duration(minutes: -minAgo)),
      updatedAt: DateTime.now().subtract(Duration(minutes: -minAgo)),
      seenBy: seenBy, seenCount: seenBy.length,
    );

  static MessageModel _sys(String id, String text, int minAgo) =>
    MessageModel(
      id: id, senderId: '', text: text,
      type: MessageType.system,
      createdAt: DateTime.now().subtract(Duration(minutes: -minAgo)),
      updatedAt: DateTime.now().subtract(Duration(minutes: -minAgo)),
      seenBy: [civilianId, volunteerId], seenCount: 2,
    );

  static MessageModel _loc(String id, String sender, String address,
      int minAgo, List<String> seenBy) =>
    MessageModel(
      id: id, senderId: sender, text: address,
      type: MessageType.location,
      createdAt: DateTime.now().subtract(Duration(minutes: -minAgo)),
      updatedAt: DateTime.now().subtract(Duration(minutes: -minAgo)),
      seenBy: seenBy, seenCount: seenBy.length,
    );
}