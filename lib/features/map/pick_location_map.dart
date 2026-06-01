// Usage example:
// PickLocationMap(
//   initialCenter: LatLng(13.7563, 100.5018),
//   onLocationPicked: (latlng) {
//     final geoPoint = GeoPoint(latlng.latitude, latlng.longitude);
//   },
// )

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Presentational widget — owner taps to pin ONE request location.
///
/// Calls [onLocationPicked] on every tap (place or move the marker).
/// Firestore writes are the caller's responsibility: convert [LatLng] →
/// [GeoPoint] and supply a reverse-geocoded address before saving.
class PickLocationMap extends StatefulWidget {
  const PickLocationMap({
    super.key,
    this.initialCenter,
    required this.onLocationPicked,
  });

  final LatLng? initialCenter;
  final void Function(LatLng) onLocationPicked;

  @override
  State<PickLocationMap> createState() => _PickLocationMapState();
}

class _PickLocationMapState extends State<PickLocationMap> {
  // Fallback center: Bangkok, Thailand
  static const _defaultCenter = LatLng(13.7563, 100.5018);

  LatLng? _picked;

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: widget.initialCenter ?? _defaultCenter,
        zoom: 14,
      ),
      markers: _picked == null
          ? const {}
          : {
              Marker(
                markerId: const MarkerId('picked_location'),
                position: _picked!,
              ),
            },
      onTap: (latlng) {
        setState(() => _picked = latlng);
        widget.onLocationPicked(latlng);
      },
    );
  }
}
