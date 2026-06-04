import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class _C {
  static const sysBg     = Color(0xFF1E1E1E);
  static const sysBorder = Color(0xFF2E2E2E);
  static const sysText   = Color(0xFF555555);
}

class SystemMessagePill extends StatelessWidget {
  const SystemMessagePill({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _C.sysBg,
              border: Border.all(color: _C.sysBorder, width: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.ibmPlexSansThai(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: _C.sysText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
