import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/request_model.dart';
import '../services/map_service.dart';
import '../utils/geo_utils.dart';

class MapProvider extends ChangeNotifier {
  MapProvider({MapService? service}) : _service = service ?? MapService();

  void startListening() {
    print('startListening called, _sub: $_sub');
    _sub ??= _service.getOpenRequests().listen(_onRequestsUpdated);
  }

  final MapService _service;
  StreamSubscription<List<RequestModel>>? _sub;

  LatLng? userLocation;
  double radiusKm = 10;
  List<RequestModel> openRequests = [];
  List<RequestModel> requestsInRadius = [];

  /// Requests device GPS and caches [userLocation]; triggers recompute.
  Future<void> loadUserLocation() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }
    final pos = await Geolocator.getCurrentPosition();
    userLocation = LatLng(pos.latitude, pos.longitude);
    _recompute();
    notifyListeners();
  }

  /// Updates radius (allowed values: 10 / 50 / 100 km) and recomputes.
  void setRadius(double km) {
    radiusKm = km;
    _recompute();
    notifyListeners();
  }

  void _onRequestsUpdated(List<RequestModel> requests) {
    print('_onRequestsUpdated: ${requests.length} requests');
    openRequests = requests;
    _recompute();
    print('requestsInRadius: ${requestsInRadius.length}');
    notifyListeners();
  }

  static const _fallbackCenter = LatLng(13.68, 100.55);

  void _recompute() {
    final loc = userLocation ?? _fallbackCenter;
    requestsInRadius = openRequests.where((r) {
      final point = LatLng(
        r.location.coordinates.latitude,
        r.location.coordinates.longitude,
      );
      return isWithinRadius(loc, point, radiusKm);
    }).toList();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
