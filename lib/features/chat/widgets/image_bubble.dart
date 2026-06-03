import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '_net_image_stub.dart'
    if (dart.library.html) '_net_image_web.dart';

abstract class _C {
  static const surfaceRaise  = Color(0xFF242424);
  static const accent        = Color(0xFFE8442A);
  static const textPrimary   = Color(0xFFEEEEEE);
  static const textMuted     = Color(0xFF555555);
  static const seenGray      = Color(0xFF555555);
  static const seenGreen     = Color(0xFF5FA85F);
}

const _ownRadius = BorderRadius.only(
  topLeft:     Radius.circular(16),
  topRight:    Radius.circular(16),
  bottomLeft:  Radius.circular(16),
  bottomRight: Radius.circular(4),
);

const _theirRadius = BorderRadius.only(
  topLeft:     Radius.circular(16),
  topRight:    Radius.circular(16),
  bottomLeft:  Radius.circular(4),
  bottomRight: Radius.circular(16),
);

class ImageBubble extends StatelessWidget {
  const ImageBubble({
    super.key,
    required this.imageUrl,
    this.caption,
    required this.isOwn,
    required this.createdAt,
    required this.seenCount,
  });

  final String imageUrl;
  final String? caption;
  final bool isOwn;
  final DateTime createdAt;
  final int seenCount;

  @override
  Widget build(BuildContext context) {
    final radius = isOwn ? _ownRadius : _theirRadius;
    final seen = seenCount >= 2;

    return Column(
      crossAxisAlignment:
          isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        // On web:    HtmlElementView + <img> — no CORS restriction
        // On native: Firebase SDK getData() + Image.memory()
        ClipRRect(
          borderRadius: radius,
          child: buildNetworkImage(
            url: imageUrl,
            width: 220,
            height: 160,
            isOwn: isOwn,
          ),
        ),
        if (caption != null && caption!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxWidth: 220),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isOwn ? _C.accent : _C.surfaceRaise,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              caption!,
              style: GoogleFonts.ibmPlexSansThai(
                fontSize: 12,
                color: isOwn ? Colors.white : _C.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwn) ...[
              Text(
                '✓✓',
                style: GoogleFonts.ibmPlexSansThai(
                  fontSize: 11,
                  color: seen ? _C.seenGreen : _C.seenGray,
                  height: 1,
                ),
              ),
              const SizedBox(width: 3),
            ],
            Text(
              _fmt(createdAt),
              style: GoogleFonts.ibmPlexSansThai(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: _C.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

String _fmt(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
