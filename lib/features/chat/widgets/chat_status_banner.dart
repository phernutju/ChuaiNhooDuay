import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class _C {
  static const surfaceMid    = Color(0xFF1E1E1E);
  static const sysBorder     = Color(0xFF2E2E2E);
  static const accent        = Color(0xFFE8442A);
  static const textSecondary = Color(0xFF888888);
}

/// Pulsing-dot status row.
/// Returns [SizedBox.shrink] immediately when [isActive] is false.
// TODO(backend): derive isActive from RequestModel.status == RequestStatus.assigned
// TODO(backend): derive etaLabel from request metadata or volunteer location
class ChatStatusBanner extends StatefulWidget {
  const ChatStatusBanner({
    super.key,
    required this.isActive,
    this.etaLabel,
  });

  final bool isActive;

  /// Pre-formatted ETA string, e.g. "ETA 9 min".
  final String? etaLabel;

  @override
  State<ChatStatusBanner> createState() => _ChatStatusBannerState();
}

class _ChatStatusBannerState extends State<ChatStatusBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 1.0, end: 0.35).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return const SizedBox.shrink();

    return Container(
      decoration: const BoxDecoration(
        color: _C.surfaceMid,
        border: Border(bottom: BorderSide(color: _C.sysBorder, width: 0.5)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _opacity,
            builder: (context, child) => Opacity(
              opacity: _opacity.value,
              child: Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: _C.accent,
                  borderRadius: BorderRadius.all(Radius.circular(50)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Request active',
            style: GoogleFonts.ibmPlexSansThai(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: _C.textSecondary,
            ),
          ),
          if (widget.etaLabel != null)
            Text(
              ' · ${widget.etaLabel}',
              style: GoogleFonts.ibmPlexSansThai(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: _C.accent,
              ),
            ),
        ],
      ),
    );
  }
}
