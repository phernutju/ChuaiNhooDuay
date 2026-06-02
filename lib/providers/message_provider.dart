import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:we_are_ready/models/message_model.dart';
import 'package:we_are_ready/services/message_service.dart';

/// Manages real-time message state for a single active request room.
///
/// Call [subscribeToMessages] and [subscribeToUnseenCount] when entering
/// the chat screen, and [clearRoom] (or let [dispose] handle it) on exit.
class MessageProvider extends ChangeNotifier {
  final MessageService _messageService;

  MessageProvider(this._messageService);

  List<MessageModel> messages = [];
  int unseenCount = 0;
  bool isSending = false;
  bool isLoading = false;
  String? error;

  StreamSubscription<List<MessageModel>>? _messagesSub;
  StreamSubscription<int>? _unseenSub;

  // ---------------------------------------------------------------------------
  // Subscriptions
  // ---------------------------------------------------------------------------

  /// Subscribes to real-time messages for [requestId].
  ///
  /// Cancels any existing subscription before starting a new one.
  void subscribeToMessages(String requestId) {
    _messagesSub?.cancel();
    isLoading = true;
    notifyListeners();

    _messagesSub = _messageService.watchMessages(requestId).listen(
      (incoming) {
        messages = incoming;
        isLoading = false;
        notifyListeners();
      },
      onError: (Object e) {
        error = e.toString();
        isLoading = false;
        notifyListeners();
      },
    );
  }

  /// Subscribes to the unseen message count for [userId] in [requestId].
  ///
  /// Cancels any existing unseen-count subscription before starting a new one.
  void subscribeToUnseenCount(String requestId, String userId) {
    _unseenSub?.cancel();

    _unseenSub = _messageService
        .watchUnseenCount(requestId: requestId, userId: userId)
        .listen(
      (count) {
        unseenCount = count;
        notifyListeners();
      },
      onError: (_) {
        // Unseen count is best-effort — ignore errors silently.
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Writes
  // ---------------------------------------------------------------------------

  /// Sends a plain text message from [senderId] in [requestId].
  ///
  /// Sets [isSending] during the call and stores any error in [error] on failure.
  Future<void> sendText(
    String requestId,
    String senderId,
    String text,
  ) async {
    isSending = true;
    notifyListeners();
    try {
      await _messageService.sendTextMessage(
        requestId: requestId,
        senderId: senderId,
        text: text,
      );
    } catch (e) {
      error = e.toString();
      notifyListeners();
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  /// Marks all currently loaded unseen messages as seen by [userId].
  ///
  /// Errors are swallowed silently — seen tracking is best-effort.
  Future<void> markAllSeen(String requestId, String userId) async {
    try {
      await _messageService.markAllSeen(
        requestId: requestId,
        userId: userId,
        messages: messages,
      );
    } catch (_) {
      // Best-effort — do not surface to the user.
    }
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Cancels subscriptions and resets all room state.
  ///
  /// Call this when leaving the chat screen, or let [dispose] handle it.
  void clearRoom() {
    _messagesSub?.cancel();
    _messagesSub = null;
    _unseenSub?.cancel();
    _unseenSub = null;

    messages = [];
    unseenCount = 0;
    isSending = false;
    isLoading = false;
    error = null;
  }

  @override
  void dispose() {
    clearRoom();
    super.dispose();
  }
}
