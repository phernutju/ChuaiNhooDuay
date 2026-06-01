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
  category: 'EMERGENCY SHELTER',
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

const mockRequest3 = RequestDetailData(
  id: 'mock_003',
  category: 'FOOD & WATER',
  urgencyLevel: UrgencyLevel.urgent,
  title: 'Need 12 bottles of drinking water for shelter at Semianari temple',
  distanceKm: 0.8,
  minutesAgo: 18,
  requesterName: 'Wat Semianari',
  requesterLocation: 'Wat Semianari, Chatuchak',
  isAnonymous: false,
  isVerified: true,
  description:
      'Around 30 evacuees are sheltering at the temple hall. We have run low on drinking water — 12 large bottles would cover tonight. Drop-off at the side gate is easiest.',
  skillsNeeded: ['Supplies', 'Transport'],
);

const mockRequest4 = RequestDetailData(
  id: 'mock_004',
  category: 'MEDICAL AID',
  urgencyLevel: UrgencyLevel.urgent,
  title: 'Diabetic neighbour out of insulin — pharmacy run needed',
  distanceKm: 1.5,
  minutesAgo: 24,
  requesterName: 'Pranee K.',
  requesterLocation: 'Soi Ratchadaphisek 14, Chatuchak',
  isAnonymous: false,
  isVerified: false,
  description:
      'My elderly neighbour ran out of insulin and cannot leave the building. The pharmacy on the main road has stock — someone able to collect and deliver it would be a huge help.',
  skillsNeeded: ['Errand', 'Transport'],
);

const mockRequest5 = RequestDetailData(
  id: 'mock_005',
  category: 'FOOD & WATER',
  urgencyLevel: UrgencyLevel.general,
  title: 'Baby formula and diapers needed for 6-month-old',
  distanceKm: 2.1,
  minutesAgo: 41,
  requesterName: 'Anonymous',
  requesterLocation: 'Chom Phon, Chatuchak',
  isAnonymous: true,
  isVerified: false,
  description:
      'We are staying with relatives after evacuating and have run out of formula and diapers for our infant. Any size 3 diapers or stage-1 formula would help enormously.',
  skillsNeeded: ['Supplies'],
);

/// Seed data for the "Nearby Requests" volunteer feed. Counts are tuned so the
/// filter chips read realistically: 5 total · 2 critical · 2 urgent · 2 food.
const mockFeedRequests = <RequestDetailData>[
  mockRequest1,
  mockRequest2,
  mockRequest3,
  mockRequest4,
  mockRequest5,
];

/// Resolves a feed request by id — used by the router's detail route when the
/// model wasn't passed through as `extra` (e.g. a deep link or refresh).
RequestDetailData? requestById(String id) {
  for (final r in mockFeedRequests) {
    if (r.id == id) return r;
  }
  return null;
}
