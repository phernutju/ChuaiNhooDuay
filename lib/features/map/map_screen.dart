import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:provider/provider.dart';
import '../../constants/constants.dart';
import '../../models/request_model.dart';
import '../../providers/map_provider.dart';
import 'nearby_requests_map.dart';

// ---------------------------------------------------------------------------
// Service area: Bangkok + Samut Prakan
// ---------------------------------------------------------------------------
const kMockCenter = LatLng(13.68, 100.55);

final kServiceArea = LatLngBounds(
  southwest: const LatLng(13.50, 100.30),
  northeast: const LatLng(13.95, 100.75),
);

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class MapPlaceholderScreen extends StatefulWidget {
  const MapPlaceholderScreen({super.key});

  @override
  State<MapPlaceholderScreen> createState() => _MapPlaceholderScreenState();
}

class _MapPlaceholderScreenState extends State<MapPlaceholderScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MapProvider>().loadUserLocation();
    });
  }

  void _onRequestTap(String id) {
    final mapProvider = context.read<MapProvider>();
    final request = mapProvider.openRequests.firstWhere(
      (r) => r.id == id,
      orElse: () => mapProvider.openRequests.first,
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
    final map = context.watch<MapProvider>();
    final center = map.userLocation ?? kMockCenter;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NearbyRequestsMap(
        center: center,
        radiusKm: map.radiusKm,
        requests: map.requestsInRadius,
        onRadiusChanged: map.setRadius,
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
