import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Returns the great-circle distance in kilometres between two points (Haversine).
double distanceKm(LatLng a, LatLng b) {
  const earthR = 6371.0;
  final dLat = _rad(b.latitude - a.latitude);
  final dLon = _rad(b.longitude - a.longitude);
  final h = pow(sin(dLat / 2), 2) +
      cos(_rad(a.latitude)) * cos(_rad(b.latitude)) * pow(sin(dLon / 2), 2);
  return 2 * earthR * asin(sqrt(h.clamp(0.0, 1.0)));
}

/// Returns true if [point] is within [radiusKm] of [center].
bool isWithinRadius(LatLng center, LatLng point, double radiusKm) =>
    distanceKm(center, point) <= radiusKm;

double _rad(double deg) => deg * pi / 180;
