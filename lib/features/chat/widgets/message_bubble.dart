import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:we_are_ready/features/chat/widgets/location_bubble.dart';
import 'package:we_are_ready/features/chat/widgets/system_message_pill.dart';
import 'package:we_are_ready/models/message_model.dart';

abstract class _C {
  static const surfaceRaise = Color(0xFF242424);
  static const accent       = Color(0xFFE8442A);
  static const textPrimary  = Color(0xFFEEEEEE);
  static const textMuted    = Color(0xFF555555);
  static const senderBlue   = Color(0xFF4A8FCE);
  static const seenGray     = Color(0xFF555555);
  static const seenGreen    = Color(0xFF5FA85F);
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

/// Dispatches to [SystemMessagePill], [LocationBubble], or own/their text
/// bubble based on [message.type] and whether [message.senderId] equals
/// [currentUserId].
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.currentUserId,
  });

  final MessageModel message;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final isOwn = message.senderId == currentUserId;
    final maxW = MediaQuery.of(context).size.width * 0.72;

    switch (message.type) {
      case MessageType.system:
        return SystemMessagePill(text: message.text ?? '');

      case MessageType.location:
        return _LocationRow(message: message, isOwn: isOwn, maxW: maxW);

      case MessageType.message:
        return isOwn
            ? _OwnBubble(message: message, maxW: maxW)
            : _TheirBubble(message: message, maxW: maxW);
    }
  }
}

// ─── Received bubble (left) ───────────────────────────────────────────────────

class _TheirBubble extends StatelessWidget {
  const _TheirBubble({required this.message, required this.maxW});

  final MessageModel message;
  final double maxW;

  @override
  Widget build(BuildContext context) {
    // TODO(backend): replace senderId with resolved display name
    final label = message.senderId;
    final initial = label.isNotEmpty ? label[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 72, top: 1, bottom: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _Avatar(initial: initial),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.ibmPlexSansThai(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _C.senderBlue,
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: const BoxDecoration(
                    color: _C.surfaceRaise,
                    borderRadius: _theirRadius,
                  ),
                  child: Text(
                    message.text ?? '',
                    style: GoogleFonts.ibmPlexSansThai(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: _C.textPrimary,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _fmt(message.createdAt),
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
    );
  }
}

// ─── Own bubble (right) ───────────────────────────────────────────────────────

class _OwnBubble extends StatelessWidget {
  const _OwnBubble({required this.message, required this.maxW});

  final MessageModel message;
  final double maxW;

  @override
  Widget build(BuildContext context) {
    final seen = message.seenCount >= 2;
    return Padding(
      padding: const EdgeInsets.only(right: 10, left: 72, top: 1, bottom: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxW),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: const BoxDecoration(
                    color: _C.accent,
                    borderRadius: _ownRadius,
                  ),
                  child: Text(
                    message.text ?? '',
                    style: GoogleFonts.ibmPlexSansThai(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '✓✓',
                      style: GoogleFonts.ibmPlexSansThai(
                        fontSize: 11,
                        color: seen ? _C.seenGreen : _C.seenGray,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _fmt(message.createdAt),
                      style: GoogleFonts.ibmPlexSansThai(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: _C.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const _Avatar(initial: '·'),
        ],
      ),
    );
  }
}

// ─── Location row (wraps LocationBubble with alignment) ──────────────────────

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.message,
    required this.isOwn,
    required this.maxW,
  });

  final MessageModel message;
  final bool isOwn;
  final double maxW;

  @override
  Widget build(BuildContext context) {
    final initial = isOwn
        ? '·'
        : (message.senderId.isNotEmpty ? message.senderId[0].toUpperCase() : '?');

    final card = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxW),
      child: LocationBubble(
        address: message.text ?? '',
        // TODO(backend): replace print with url_launcher map open
        onTap: () => debugPrint('open map: ${message.text}'),
      ),
    );

    if (isOwn) {
      return Padding(
        padding: const EdgeInsets.only(right: 10, left: 72, top: 1, bottom: 1),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            card,
            const SizedBox(width: 6),
            _Avatar(initial: initial),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 72, top: 1, bottom: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _Avatar(initial: initial),
          const SizedBox(width: 6),
          card,
        ],
      ),
    );
  }
}

// ─── Avatar ───────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(color: _C.surfaceRaise, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.ibmPlexSansThai(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: _C.textPrimary,
        ),
      ),
    );
  }
}

// ─── Timestamp helper ─────────────────────────────────────────────────────────

String _fmt(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
