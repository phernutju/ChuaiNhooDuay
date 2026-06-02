import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../constants/constants.dart';

const _permissionDeniedMsg = 'Location permission needed to check in';
const _permissionForeverMsg = 'Location permission is permanently denied';
const _locationErrorMsg = 'Could not get your location — try again';
const _openSettingsLabel = 'Open Settings';

String _tooFarMsg(int dist, int radius) =>
    "You're ${dist}m away — get within ${radius}m to check in";

/// Geolocation check-in flow — shared between the Active tab and Request
/// Detail screen.
///
/// Handles permission requests, position fetch, and proximity check.
/// Shows failure [SnackBar]s internally for each error case.
/// Returns `true` only if the volunteer is within
/// [AppConstants.checkInRadiusMeters] of ([requestLat], [requestLng]).
///
/// The caller handles success side-effects (state update, provider call,
/// success snackbar).
Future<bool> performCheckIn({
  required BuildContext context,
  required double requestLat,
  required double requestLng,
}) async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (!context.mounted) return false;

  // Case C — permanently denied: offer settings shortcut
  if (permission == LocationPermission.deniedForever) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(_permissionForeverMsg),
        backgroundColor: AppColors.critical,
        action: SnackBarAction(
          label: _openSettingsLabel,
          textColor: AppColors.textPrimary,
          onPressed: Geolocator.openAppSettings,
        ),
      ),
    );
    return false;
  }

  // Case B — denied once: user can tap again to re-request
  if (permission == LocationPermission.denied) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(_permissionDeniedMsg),
        backgroundColor: AppColors.critical,
      ),
    );
    return false;
  }

  // Case D — location services off or any platform error
  Position position;
  try {
    position = await Geolocator.getCurrentPosition();
  } catch (_) {
    if (!context.mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(_locationErrorMsg),
        backgroundColor: AppColors.critical,
      ),
    );
    return false;
  }
  if (!context.mounted) return false;

  final distanceMeters = Geolocator.distanceBetween(
    position.latitude,
    position.longitude,
    requestLat,
    requestLng,
  );

  // Case A — too far: caller's button stays tappable
  if (distanceMeters > AppConstants.checkInRadiusMeters) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _tooFarMsg(
            distanceMeters.round(),
            AppConstants.checkInRadiusMeters.toInt(),
          ),
        ),
        backgroundColor: AppColors.critical,
        duration: const Duration(seconds: 3),
      ),
    );
    return false;
  }

  return true;
}
