import 'package:we_are_ready/models/request_model.dart';

class RequestDetailData {
  final String id;
  final String category;
  final UrgencyLevel urgencyLevel;
  final String title;
  final double distanceKm;
  final int minutesAgo;
  final String requesterName;
  final String requesterLocation;
  final bool isAnonymous;
  final bool isVerified;
  final String description;
  final List<String> skillsNeeded;

  const RequestDetailData({
    required this.id,
    required this.category,
    required this.urgencyLevel,
    required this.title,
    required this.distanceKm,
    required this.minutesAgo,
    required this.requesterName,
    required this.requesterLocation,
    required this.isAnonymous,
    required this.isVerified,
    required this.description,
    required this.skillsNeeded,
  });
}

const mockRequest1 = RequestDetailData(
  id: 'mock_001',
  category: 'MEDICAL AID',
  urgencyLevel: UrgencyLevel.critical,
  title:
      'Elderly woman fell — need someone to support her until ambulance arrives',
  distanceKm: 0.3,
  minutesAgo: 2,
  requesterName: 'Somchai N.',
  requesterLocation: 'Soi Phahonyothin 24, Chatuchak',
  isAnonymous: false,
  isVerified: true,
  description:
      'My mother slipped in the alley near the market. She is conscious but cannot stand. I called 1669 — ETA 9 minutes. Just need a calm person to wait with us. Thank you.',
  skillsNeeded: ['First aid', 'Lift assist'],
);

const mockRequest2 = RequestDetailData(
  id: 'mock_002',
  category: 'SHELTER',
  urgencyLevel: UrgencyLevel.critical,
  title: 'Family of 4 with young kids — need safe place for tonight',
  distanceKm: 1.2,
  minutesAgo: 8,
  requesterName: 'Anonymous',
  requesterLocation: 'Lat Yao, Chatuchak',
  isAnonymous: true,
  isVerified: true,
  description:
      'We have two young children (ages 3 and 6). Our home is flooded and we have nowhere to go tonight. Please help us find a safe place to stay.',
  skillsNeeded: ['Shelter', 'Transport'],
);
