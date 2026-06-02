import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract class _C {
  static const surface       = Color(0xFF1A1A1A);
  static const surfaceRaise  = Color(0xFF242424);
  static const textPrimary   = Color(0xFFEEEEEE);
  static const textMuted     = Color(0xFF555555);
  static const textSecondary = Color(0xFF888888);
  static const accent        = Color(0xFFE8442A);
  static const sysBorder     = Color(0xFF2E2E2E);
  static const closedBg      = Color(0xFF1A1510);
  static const closedBorder  = Color(0xFF3A2A1A);
  static const closedText    = Color(0xFF7A5A4A);
}

class MessageInputBar extends StatefulWidget {
  const MessageInputBar({
    super.key,
    required this.isReadOnly,
    required this.isSending,
    required this.onSendText,
    required this.onTapCamera,
    required this.onTapLocation,
  });

  final bool isReadOnly;
  final bool isSending;
  final void Function(String text) onSendText;
  final VoidCallback onTapCamera;
  final VoidCallback onTapLocation;

  @override
  State<MessageInputBar> createState() => _MessageInputBarState();
}

class _MessageInputBarState extends State<MessageInputBar> {
  final _ctrl = TextEditingController();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final notEmpty = _ctrl.text.trim().isNotEmpty;
      if (notEmpty != _hasText) setState(() => _hasText = notEmpty);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    // TODO(backend): disable input while isSending == true (already wired via prop)
    widget.onSendText(text);
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isReadOnly) {
      return Container(
        decoration: const BoxDecoration(
          color: _C.closedBg,
          border: Border(top: BorderSide(color: _C.closedBorder, width: 0.5)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 14, color: _C.closedText),
                const SizedBox(width: 6),
                Text(
                  'Request closed · messages are read-only',
                  style: GoogleFonts.ibmPlexSansThai(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: _C.closedText,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final canSend = _hasText && !widget.isSending;

    return Container(
      decoration: const BoxDecoration(
        color: _C.surface,
        border: Border(top: BorderSide(color: _C.sysBorder, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.camera_alt_outlined, size: 20),
                color: _C.textSecondary,
                onPressed: widget.onTapCamera,
              ),
              IconButton(
                icon: const Icon(Icons.location_on_outlined, size: 20),
                color: _C.textSecondary,
                onPressed: widget.onTapLocation,
              ),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  style: GoogleFonts.ibmPlexSansThai(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: _C.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type a message…',
                    hintStyle: GoogleFonts.ibmPlexSansThai(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: _C.textMuted,
                    ),
                    filled: true,
                    fillColor: _C.surfaceRaise,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: _C.sysBorder, width: 0.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: _C.sysBorder, width: 0.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: _C.sysBorder, width: 0.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                  keyboardAppearance: Brightness.dark,
                  onSubmitted: (_) => _handleSend(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: canSend ? _handleSend : null,
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor:
                      canSend ? _C.accent : _C.accent.withValues(alpha: 0.35),
                  child: const Icon(
                    Icons.arrow_upward,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
