import 'package:flutter/foundation.dart';

import '../features/request_detail/mock/request_mock_data.dart';

/// Lifecycle of a request the volunteer has joined.
///
/// [active] — joined, not yet on-site. [checkedIn] — the volunteer confirmed
/// they've arrived to help.
enum JoinedStatus { active, checkedIn }

/// A request the volunteer tapped "Respond" on, plus when they joined and
/// whether it's still ongoing. Backed by the in-memory provider below until a
/// real backend lands.
class JoinedRequest {
  const JoinedRequest({
    required this.request,
    required this.joinedAt,
    this.status = JoinedStatus.active,
  });

  final RequestDetailData request;
  final DateTime joinedAt;
  final JoinedStatus status;

  JoinedRequest copyWith({JoinedStatus? status}) => JoinedRequest(
        request: request,
        joinedAt: joinedAt,
        status: status ?? this.status,
      );
}

/// Tracks the requests the volunteer has joined via the feed's "Respond"
/// action. Feeds the ACTIVE tab, where each can be checked-in on arrival.
///
/// Mock/in-memory only for now — resets on app restart. A Firestore-backed
/// implementation can replace the store without changing the screen API.
class JoinedRequestsProvider extends ChangeNotifier {
  final List<JoinedRequest> _items = [];

  /// All joined requests, most-recently-joined first.
  List<JoinedRequest> get all => List.unmodifiable(_items);

  bool isJoined(String requestId) =>
      _items.any((j) => j.request.id == requestId);

  /// Adds [request] to the active list. No-op if already joined.
  void join(RequestDetailData request) {
    if (isJoined(request.id)) return;
    _items.insert(
      0,
      JoinedRequest(request: request, joinedAt: DateTime.now()),
    );
    notifyListeners();
  }

  /// Marks a joined request as checked-in (volunteer has arrived on-site).
  void checkIn(String requestId) {
    final i = _items.indexWhere((j) => j.request.id == requestId);
    if (i == -1 || _items[i].status == JoinedStatus.checkedIn) return;
    _items[i] = _items[i].copyWith(status: JoinedStatus.checkedIn);
    notifyListeners();
  }
}
