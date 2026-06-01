import 'package:flutter/material.dart';

import '../../constants/constants.dart';

/// Placeholder for the volunteer MAP tab.
///
/// Intentionally a stub — a teammate owns the real map (markers, location). The
/// nav slot and icon stay in [VolunteerShell]; this only fills the body.
/// Do NOT add a map package or location logic here.
class MapPlaceholderScreen extends StatelessWidget {
  const MapPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.map_outlined, color: AppColors.textMuted, size: 56),
            SizedBox(height: AppSpacing.md),
            Text(
              'Map — coming soon',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
