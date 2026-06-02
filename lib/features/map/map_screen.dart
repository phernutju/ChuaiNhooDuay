import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../constants/constants.dart';
import '../../models/request_model.dart';
import '../../utils/geo_utils.dart';
import 'nearby_requests_map.dart';

// ---------------------------------------------------------------------------
// Feature flag — flip to false when MapProvider + real Firestore data is ready.
// ---------------------------------------------------------------------------
const bool kUseMockRequests = true;

// ---------------------------------------------------------------------------
// Service area: Bangkok + Samut Prakan
// ---------------------------------------------------------------------------
const kMockCenter = LatLng(13.68, 100.55);

final kServiceArea = LatLngBounds(
  southwest: const LatLng(13.50, 100.30),
  northeast: const LatLng(13.95, 100.75),
);

bool _inServiceArea(LatLng p) =>
    p.latitude  >= kServiceArea.southwest.latitude &&
    p.latitude  <= kServiceArea.northeast.latitude &&
    p.longitude >= kServiceArea.southwest.longitude &&
    p.longitude <= kServiceArea.northeast.longitude;

// ---------------------------------------------------------------------------
// Mock data (used only when kUseMockRequests == true)
// ---------------------------------------------------------------------------
RequestModel _mock(
  String id,
  String title,
  double lat,
  double lng,
  UrgencyLevel u,
  int max,
  int assigned,
) =>
    RequestModel(
      id: id,
      createdBy: 'mock-user',
      title: title,
      location: RequestLocation(
        address: 'Bangkok (mock)',
        coordinates: GeoPoint(lat, lng),
      ),
      requestType: RequestType.other,
      urgencyLevel: u,
      urgencyScore: u == UrgencyLevel.critical
          ? 3
          : u == UrgencyLevel.urgent
              ? 2
              : 1,
      maxVolunteer: max,
      assignedVolunteerIds: List.generate(assigned, (i) => 'v$i'),
      status: RequestStatus.waiting,
      createdAt: DateTime(2026, 6, 1),
      updatedAt: DateTime(2026, 6, 1),
    );

final _mockRequests = [
  _mock('bkk_1', 'ยกของ (สีลม)',                   13.7563, 100.5018, UrgencyLevel.critical, 5, 0),
  _mock('bkk_2', 'ปฐมพยาบาล (สยาม)',               13.7460, 100.5340, UrgencyLevel.urgent,   3, 1),
  _mock('spk_1', 'แจกอาหาร (เมืองสมุทรปราการ)',    13.5990, 100.5998, UrgencyLevel.general,  4, 0),
  _mock('spk_2', 'หาที่พัก (บางพลี)',               13.6050, 100.7000, UrgencyLevel.urgent,   3, 0),
  _mock('spk_3', 'เต็มแล้ว',                        13.6200, 100.6000, UrgencyLevel.general,  2, 2),
];

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class MapPlaceholderScreen extends StatefulWidget {
  const MapPlaceholderScreen({super.key});

  @override
  State<MapPlaceholderScreen> createState() => _MapPlaceholderScreenState();
}

class _MapPlaceholderScreenState extends State<MapPlaceholderScreen> {
  double _radiusKm = 50;

  // TODO(real-data): when kUseMockRequests == false, replace _requests with:
  //   final mapProvider = context.watch<MapProvider>();
  //   final center     = mapProvider.userLocation ?? kMockCenter;
  //   final radiusKm   = mapProvider.radiusKm;
  //   final requests   = mapProvider.requestsInRadius; // already filtered
  //   Call mapProvider.loadUserLocation() in initState() or didChangeDependencies().

  List<RequestModel> get _requests {
    if (kUseMockRequests) {
      return _mockRequests.where((r) {
        final p = LatLng(
          r.location.coordinates.latitude,
          r.location.coordinates.longitude,
        );
        return !r.isFull && _inServiceArea(p) &&
               isWithinRadius(kMockCenter, p, _radiusKm);
      }).toList();
    }
    // TODO(real-data): return mapProvider.requestsInRadius;
    return const [];
  }

  void _onRequestTap(String id) {
    final request = _mockRequests.firstWhere(
      (r) => r.id == id,
      orElse: () => _mockRequests.first,
    );

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(request.title, style: AppTextStyles.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            _UrgencyChip(request.urgencyLevel),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                // TODO(real-data): navigate to request detail route.
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('View details'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NearbyRequestsMap(
        center: kMockCenter,
        radiusKm: _radiusKm,
        requests: _requests,
        onRadiusChanged: (km) => setState(() => _radiusKm = km),
        onRequestTap: _onRequestTap,
        cameraBounds: kServiceArea,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small helper widget — urgency badge shown in the bottom sheet
// ---------------------------------------------------------------------------
class _UrgencyChip extends StatelessWidget {
  const _UrgencyChip(this.level);

  final UrgencyLevel level;

  @override
  Widget build(BuildContext context) {
    final (label, fg, bg) = switch (level) {
      UrgencyLevel.critical => ('CRITICAL', AppColors.critical, AppColors.criticalBg),
      UrgencyLevel.urgent   => ('URGENT',   AppColors.urgent,   AppColors.urgentBg),
      UrgencyLevel.general  => ('GENERAL',  AppColors.general,  AppColors.generalBg),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: fg),
      ),
    );
  }
}
