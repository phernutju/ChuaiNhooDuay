import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:we_are_ready/models/message_model.dart';
import 'package:we_are_ready/models/request_model.dart';
import 'package:we_are_ready/services/message_service.dart';
import 'package:we_are_ready/services/notification_service.dart';
import 'package:we_are_ready/services/request_service.dart';
import 'package:we_are_ready/services/user_service.dart';

/// Manages real-time message state for a single active request room.
///
/// Call [subscribeToMessages] and [subscribeToUnseenCount] when entering
/// the chat screen, and [clearRoom] (or let [dispose] handle it) on exit.
class MessageProvider extends ChangeNotifier {
  final MessageService _messageService;
  final NotificationService _notificationService;
  final RequestService _requestService;
  final UserService _userService;

  MessageProvider(
    this._messageService, {
    NotificationService? notificationService,
    RequestService? requestService,
    UserService? userService,
  })  : _notificationService = notificationService ?? NotificationService(),
        _requestService = requestService ?? RequestService(),
        _userService = userService ?? UserService();

  List<MessageModel> messages = [];
  /// UID → display name cache, populated as messages arrive.
  Map<String, String> senderNames = {};
  int unseenCount = 0;
  bool isSending = false;
  bool isLoading = false;
  bool isUploadingImage = false;
  bool isFetchingLocation = false;
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
        _loadSenderNames(incoming);
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
  /// Sets [isSending] during the call and stores any error in [error] on
  /// failure. Triggers a chat notification on success (best-effort).
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
      await _triggerChatNotification(
        requestId: requestId,
        senderId: senderId,
        preview: text,
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

  /// Opens image picker, uploads to Storage, and sends the image message.
  ///
  /// Returns silently if the user cancels the picker.
  /// Triggers a chat notification on success (best-effort).
  Future<void> pickAndSendImage({
    required String requestId,
    required String senderId,
    required ImageSource source,
    String? caption,
  }) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 72,
      maxWidth: 1080,
    );
    if (picked == null) return;

    isUploadingImage = true;
    error = null;
    notifyListeners();

    try {
      await _messageService.sendImageMessage(
        requestId: requestId,
        senderId: senderId,
        imageFile: picked,
        caption: caption,
      );
      await _triggerChatNotification(
        requestId: requestId,
        senderId: senderId,
        preview: caption ?? '📷 Photo',
      );
    } catch (e) {
      error = 'Failed to send image. Please try again.';
    } finally {
      isUploadingImage = false;
      notifyListeners();
    }
  }

  /// Gets device GPS and sends a location message.
  ///
  /// Sets [error] to a user-facing string on permission denial or timeout.
  /// Triggers a chat notification on success (best-effort).
  Future<void> sendCurrentLocation({
    required String requestId,
    required String senderId,
  }) async {
    isFetchingLocation = true;
    error = null;
    notifyListeners();

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        error = 'Location permission required';
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // TODO(backend): reverse geocode position to address using a maps API
      await _messageService.sendLocationMessage(
        requestId: requestId,
        senderId: senderId,
        lat: position.latitude,
        lng: position.longitude,
      );
      await _triggerChatNotification(
        requestId: requestId,
        senderId: senderId,
        preview: '📍 Location shared',
      );
    } catch (e) {
      error = 'Could not get location. Check permissions.';
    } finally {
      isFetchingLocation = false;
      notifyListeners();
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
    isUploadingImage = false;
    isFetchingLocation = false;
    error = null;
  }

  @override
  void dispose() {
    clearRoom();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Fetches the request, resolves the sender's display name, and calls
  /// [NotificationService.notifyChatMessage].
  ///
  /// Only triggered for [MessageType.message] and [MessageType.location]
  /// messages — never for system messages.
  /// All errors are caught and logged; this method never throws.
  Future<void> _triggerChatNotification({
    required String requestId,
    required String senderId,
    required String preview,
  }) async {
    try {
      final request = await _requestService.getById(requestId);
      final senderName = _resolveSenderName(request, senderId);
      await _notificationService.notifyChatMessage(
        request,
        senderName,
        preview,
        senderId: senderId,
      );
    } catch (e) {
      // Best-effort — never let notification failure break messaging.
      debugPrint('[MessageProvider] chat notification failed: $e');
    }
  }

  /// Fetches user profiles for any sender UIDs not yet in [senderNames].
  Future<void> _loadSenderNames(List<MessageModel> msgs) async {
    final unknown = msgs
        .map((m) => m.senderId)
        .where((id) => id.isNotEmpty && !senderNames.containsKey(id))
        .toSet();
    if (unknown.isEmpty) return;
    await Future.wait(unknown.map((id) async {
      try {
        final user = await _userService.getUser(id);
        if (user?.name?.isNotEmpty == true) {
          senderNames[id] = user!.name!;
        }
      } catch (_) {}
    }));
    notifyListeners();
  }

  /// Resolves the display name of [senderId] from [request] participant lists.
  ///
  /// Returns [request.requesterName] for the request creator,
  /// the matching entry from [request.assignedVolunteerNames] for a volunteer,
  /// or `'Someone'` if the sender is not found in either list.
  String _resolveSenderName(RequestModel request, String senderId) {
    if (request.createdBy == senderId) return request.requesterName;
    final i = request.assignedVolunteerIds.indexOf(senderId);
    if (i != -1 && i < request.assignedVolunteerNames.length) {
      return request.assignedVolunteerNames[i];
    }
    return 'Someone';
  }
}
