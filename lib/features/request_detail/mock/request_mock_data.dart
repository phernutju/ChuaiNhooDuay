import 'package:we_are_ready/models/request_model.dart';

class RequestDetailData {
  final String id;
  final String category;
  final UrgencyLevel urgencyLevel;
  final String title;
  final double? distanceKm;
  final int minutesAgo;
  final DateTime postedAt;
  final String requesterName;
  final String requesterLocation;
  final bool isAnonymous;
  final bool isVerified;
  final String description;
  final List<String> skillsNeeded;
  final double lat;
  final double lng;
  final String createdBy;
  final RequestStatus requestStatus;

  const RequestDetailData({
    required this.id,
    required this.category,
    required this.urgencyLevel,
    required this.title,
    required this.distanceKm,
    required this.minutesAgo,
    required this.postedAt,
    required this.requesterName,
    required this.requesterLocation,
    required this.isAnonymous,
    required this.isVerified,
    required this.description,
    required this.skillsNeeded,
    required this.lat,
    required this.lng,
    this.createdBy = '',
    this.requestStatus = RequestStatus.waiting,
  });
}

/// Resolves a request by id — returns null when navigating by deep link
/// without an `extra` model; the caller shows a "not found" screen.
RequestDetailData? requestById(String id) => null;
