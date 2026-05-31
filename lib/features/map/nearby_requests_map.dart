// Usage example:
// NearbyRequestsMap(
//   center: mapProvider.userLocation!,
//   radiusKm: mapProvider.radiusKm,
//   requests: mapProvider.requestsInRadius,  // already filtered by provider
//   onRequestTap: (id) => Navigator.pushNamed(context, '/request/$id'),
//   onRadiusChanged: (km) => mapProvider.setRadius(km),
// )

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/request_model.dart';

/// Presentational widget — volunteer "Requests Near Me" map.
///
/// Renders markers for every [RequestModel] in [requests].
/// The caller (backed by [MapProvider]) is responsible for filtering:
/// status == open, !isFull, and within radius.
class NearbyRequestsMap extends StatefulWidget {
  const NearbyRequestsMap({
    super.key,
    required this.center,
    required this.radiusKm,
    required this.requests,
    this.onRequestTap,
    this.onRadiusChanged,
  });

  final LatLng center;
  final double radiusKm;
  final List<RequestModel> requests;
  final void Function(String requestId)? onRequestTap;
  final void Function(double km)? onRadiusChanged;

  @override
  State<NearbyRequestsMap> createState() => _NearbyRequestsMapState();
}

class _NearbyRequestsMapState extends State<NearbyRequestsMap> {
  Map<UrgencyLevel, BitmapDescriptor> _markerIcons = {};
  bool _iconsBuilt = false;

  static const Map<UrgencyLevel, Color> _urgencyColors = {
    UrgencyLevel.critical: Color(0xFFE53935), // red
    UrgencyLevel.urgent: Color(0xFFFB8C00),   // orange
    UrgencyLevel.general: Color(0xFF43A047),  // green
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_iconsBuilt) {
      _iconsBuilt = true;
      final dpr = MediaQuery.of(context).devicePixelRatio.clamp(1.0, 3.0);
      _buildMarkerIcons(dpr);
    }
  }

  Future<void> _buildMarkerIcons(double dpr) async {
    final icons = <UrgencyLevel, BitmapDescriptor>{};
    for (final entry in _urgencyColors.entries) {
      icons[entry.key] = await _createMarkerBitmap(entry.value, dpr);
    }
    if (mounted) setState(() => _markerIcons = icons);
  }

  Future<BitmapDescriptor> _createMarkerBitmap(Color color, double dpr) async {
    const logicalSize = 48.0;
    final S = (logicalSize * dpr).roundToDouble();
    final cx = S / 2;

    // Classic Google-Maps pin geometry
    final headCY = S * 0.38;
    final headR  = S * 0.30;
    final tipY   = S * 0.96;

    // Tangent angle α where the straight sides meet the head circle
    final d     = tipY - headCY;
    final sinA  = headR / d;
    final cosA  = math.sqrt(1.0 - sinA * sinA);
    final alpha = math.asin(sinA);

    // Left tangent point (T2); right tangent point (T1) is the arc end
    final t2x = cx - headR * cosA;
    final t2y = headCY + headR * sinA;

    // Arc starts at T2 (≈148.9°) and sweeps clockwise through the top to T1
    final arcStart = math.pi - alpha;       // ≈ 148.9°
    final arcSweep = math.pi + 2.0 * alpha; // ≈ 242.2° — passes through 270° (top)

    // Outline: 70% luminance of the body colour
    final outlineColor = Color.from(
      alpha: 1.0,
      red:   color.r * 0.7,
      green: color.g * 0.7,
      blue:  color.b * 0.7,
    );

    ui.Path buildPinPath() {
      final p = ui.Path();
      p.moveTo(cx, tipY);   // sharp bottom tip
      p.lineTo(t2x, t2y);   // left straight side
      p.arcTo(
        ui.Rect.fromCircle(center: ui.Offset(cx, headCY), radius: headR),
        arcStart, arcSweep, false, // clockwise around top to right side
      );
      p.close();             // right straight side back to tip
      return p;
    }

    final recorder = ui.PictureRecorder();
    final canvas   = ui.Canvas(recorder);
    final pinPath  = buildPinPath();

    // Filled body
    canvas.drawPath(
      pinPath,
      ui.Paint()
        ..color       = color
        ..isAntiAlias = true
        ..style       = ui.PaintingStyle.fill,
    );

    // Thin darker outline (stroke centred on path edge)
    canvas.drawPath(
      pinPath,
      ui.Paint()
        ..color       = outlineColor
        ..isAntiAlias = true
        ..style       = ui.PaintingStyle.stroke
        ..strokeWidth = 2.0 * dpr,
    );

    // White hole in the centre of the round head
    canvas.drawCircle(
      ui.Offset(cx, headCY),
      S * 0.12,
      ui.Paint()
        ..color       = Colors.white
        ..isAntiAlias = true,
    );

    final picture  = recorder.endRecording();
    final image    = await picture.toImage(S.toInt(), S.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(
      byteData!.buffer.asUint8List(),
      width: logicalSize,
    );
  }

  Set<Marker> _buildMarkers() {
    return widget.requests.map((r) {
      return Marker(
        markerId: MarkerId(r.id),
        position: LatLng(
          r.location.coordinates.latitude,
          r.location.coordinates.longitude,
        ),
        icon: _markerIcons[r.urgencyLevel] ?? BitmapDescriptor.defaultMarker,
        anchor: const Offset(0.5, 1.0),
        infoWindow: InfoWindow(title: r.title),
        onTap: () => widget.onRequestTap?.call(r.id),
      );
    }).toSet();
  }

  Set<Circle> _buildCircle() {
    return {
      Circle(
        circleId: const CircleId('nearby_radius'),
        center: widget.center,
        radius: widget.radiusKm * 1000, // km → metres
        fillColor: Colors.blue.withAlpha(25),
        strokeColor: Colors.blue,
        strokeWidth: 2,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition:
              CameraPosition(target: widget.center, zoom: 11),
          markers: _buildMarkers(),
          circles: _buildCircle(),
          myLocationButtonEnabled: false,
        ),
        if (widget.onRadiusChanged != null)
          Positioned(
            top: 16,
            right: 16,
            child: _RadiusPicker(
              current: widget.radiusKm,
              onChanged: widget.onRadiusChanged!,
            ),
          ),
      ],
    );
  }
}

class _RadiusPicker extends StatelessWidget {
  const _RadiusPicker({required this.current, required this.onChanged});

  final double current;
  final void Function(double) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<double>(
          value: current,
          items: const [
            DropdownMenuItem(value: 10, child: Text('10 km')),
            DropdownMenuItem(value: 50, child: Text('50 km')),
            DropdownMenuItem(value: 100, child: Text('100 km')),
          ],
          onChanged: (km) {
            if (km != null) onChanged(km);
          },
        ),
      ),
    );
  }
}
