import 'package:we_are_ready/models/request_model.dart';

/// Controls who may read or write messages for a request.
class MessageAccessGuard {
  const MessageAccessGuard._();

  /// Returns true when [userId] is an active participant and the request is
  /// not yet closed (i.e. new messages can be sent).
  ///
  /// A participant is the civilian who created the request or any volunteer
  /// listed in [RequestModel.assignedVolunteerIds].
  static bool canAccess({
    required RequestModel request,
    required String userId,
  }) {
    return _isParticipant(request, userId) &&
        request.status != RequestStatus.closed;
  }

  /// Returns true when [userId] is a participant but the request is closed.
  ///
  /// Use this to display read-only message history after the request ends.
  static bool isReadOnly({
    required RequestModel request,
    required String userId,
  }) {
    return _isParticipant(request, userId) &&
        request.status == RequestStatus.closed;
  }

  static bool _isParticipant(RequestModel request, String userId) {
    return request.createdBy == userId ||
        request.assignedVolunteerIds.contains(userId);
  }
}
