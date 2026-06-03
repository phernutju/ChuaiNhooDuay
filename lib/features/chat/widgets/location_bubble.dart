import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

abstract class _C {
  static const locGreen  = Color(0xFF1E2E1E);
  static const locBorder = Color(0xFF2A3A2A);
  static const locText   = Color(0xFF5FA85F);
  static const textMuted = Color(0xFF555555);
  static const accent    = Color(0xFFE8442A);
}

/// Opens the native maps app for [coords] ("lat,lng").
///
/// Tries geo: URI first (Android native); falls back to Google Maps web URL.
// TODO(backend): replace coords with real lat/lng once reverse geocoding is added
Future<void> _openMaps(String coords) async {
  final parts = coords.split(',');
  if (parts.length != 2) return;
  final lat = parts[0].trim();
  final lng = parts[1].trim();
  final geo = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
  final web = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
  );
  if (await canLaunchUrl(geo)) {
    await launchUrl(geo);
  } else {
    await launchUrl(web, mode: LaunchMode.externalApplication);
  }
}

class LocationBubble extends StatelessWidget {
  const LocationBubble({
    super.key,
    required this.coords,
    this.address,
  });

  /// Raw "lat,lng" string — used to open the maps app.
  final String coords;

  /// Human-readable address; shown in place of coords when available.
  final String? address;

  @override
  Widget build(BuildContext context) {
    final displayText = (address != null && address!.isNotEmpty)
        ? address!
        : coords;

    return GestureDetector(
      onTap: () => _openMaps(coords),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: _C.locGreen,
          border: Border.all(color: _C.locBorder, width: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 80,
              width: double.infinity,
              child: Stack(
                children: [
                  Container(color: _C.locGreen),
                  CustomPaint(
                    painter: _GridPainter(),
                    child: const SizedBox.expand(),
                  ),
                  const Center(
                    child: Icon(Icons.location_pin, color: _C.accent, size: 28),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayText,
                    style: GoogleFonts.ibmPlexSansThai(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: _C.locText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to open map',
                    style: GoogleFonts.ibmPlexSansThai(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: _C.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _C.locBorder
      ..strokeWidth = 0.5;
    const step = 14.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}
