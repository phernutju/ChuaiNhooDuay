import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class _C {
  static const surface       = Color(0xFF1A1A1A);
  static const textPrimary   = Color(0xFFEEEEEE);
  static const textSecondary = Color(0xFF888888);
  static const accent        = Color(0xFFE8442A);
}

class MediaPickerSheet extends StatelessWidget {
  const MediaPickerSheet({
    super.key,
    required this.onPickGallery,
    required this.onPickCamera,
    required this.onSendLocation,
  });

  final VoidCallback onPickGallery;
  final VoidCallback onPickCamera;
  final VoidCallback onSendLocation;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.only(
          topLeft:  Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Send media',
            style: GoogleFonts.ibmPlexSansThai(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _C.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _SheetOption(
                icon: Icons.photo_library_outlined,
                label: 'Gallery',
                onTap: () {
                  Navigator.pop(context);
                  // Delay until sheet dismissal animation completes so the
                  // system image picker can attach to the activity cleanly.
                  Future<void>.delayed(
                    const Duration(milliseconds: 300),
                    onPickGallery,
                  );
                },
              ),
              _SheetOption(
                icon: Icons.camera_alt_outlined,
                label: 'Camera',
                onTap: () {
                  Navigator.pop(context);
                  Future<void>.delayed(
                    const Duration(milliseconds: 300),
                    onPickCamera,
                  );
                },
              ),
              _SheetOption(
                icon: Icons.location_on_outlined,
                label: 'Location',
                onTap: () {
                  Navigator.pop(context);
                  Future<void>.delayed(
                    const Duration(milliseconds: 300),
                    onSendLocation,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: _C.accent),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.ibmPlexSansThai(
              fontSize: 11,
              color: _C.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
