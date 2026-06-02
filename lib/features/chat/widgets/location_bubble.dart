import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class _C {
  static const locGreen  = Color(0xFF1E2E1E);
  static const locBorder = Color(0xFF2A3A2A);
  static const locText   = Color(0xFF5FA85F);
  static const textMuted = Color(0xFF555555);
  static const accent    = Color(0xFFE8442A);
}

class LocationBubble extends StatelessWidget {
  const LocationBubble({
    super.key,
    required this.address,
    required this.onTap,
  });

  final String address;
  // TODO(backend): parse real lat/lng from message payload and launch maps URL
  // TODO(backend): use url_launcher: launchUrl(Uri.parse('geo:$lat,$lng'))
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
                    address,
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
