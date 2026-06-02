import 'package:flutter/material.dart';
import 'package:we_are_ready/models/message_model.dart';

// Chat-local palette extracted from chatroom.png / closed_chatroom.png
const _kSentColor = Color(0xFFE84935);
const _kReceivedColor = Color(0xFF22272F);
const _kAvatarBg = Color(0xFF2C3340);
const _kLabelColor = Color(0xFFE84935);
const _kTimestampColor = Color(0xFF505868);
const _kSystemColor = Color(0xFF8B95A8);
const _kMapBg = Color(0xFF1B3A2F);

String _fmt(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

// ─── Public entry point ───────────────────────────────────────────────────────

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.senderName,
    required this.senderInitial,
    required this.myInitial,
  });

  final MessageModel message;
  final bool isMe;
  final String senderName;
  final String senderInitial;
  final String myInitial;

  @override
  Widget build(BuildContext context) {
    if (message.type == MessageType.system) {
      return _SystemMessage(message: message);
    }
    if (isMe) {
      return _SentBubble(message: message, myInitial: myInitial);
    }
    return _ReceivedBubble(
      message: message,
      senderName: senderName,
      senderInitial: senderInitial,
    );
  }
}

// ─── Typing indicator ─────────────────────────────────────────────────────────

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key, required this.senderInitial});

  final String senderInitial;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 64, top: 2, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _AvatarCircle(initial: senderInitial),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: _kReceivedColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: const Text(
              '· · ·',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 18,
                letterSpacing: 3,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── System message ───────────────────────────────────────────────────────────

class _SystemMessage extends StatelessWidget {
  const _SystemMessage({required this.message});

  final MessageModel message;

  bool get _isClosed => message.text?.contains('has been closed') == true;

  @override
  Widget build(BuildContext context) {
    if (_isClosed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF2C3340)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 12,
                  color: _kSystemColor,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    message.text ?? '',
                    style: const TextStyle(color: _kSystemColor, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      child: Center(
        child: Text(
          message.text ?? '',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _kSystemColor, fontSize: 12),
        ),
      ),
    );
  }
}

// ─── Received bubble (left) ───────────────────────────────────────────────────

class _ReceivedBubble extends StatelessWidget {
  const _ReceivedBubble({
    required this.message,
    required this.senderName,
    required this.senderInitial,
  });

  final MessageModel message;
  final String senderName;
  final String senderInitial;

  static const _radius = BorderRadius.only(
    topLeft: Radius.circular(4),
    topRight: Radius.circular(18),
    bottomLeft: Radius.circular(18),
    bottomRight: Radius.circular(18),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 64, top: 2, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _AvatarCircle(initial: senderInitial),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  senderName,
                  style: const TextStyle(
                    color: _kLabelColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                message.type == MessageType.location
                    ? _locationBubble(_kReceivedColor, _radius, message)
                    : _TextBubble(
                        text: message.text ?? '',
                        color: _kReceivedColor,
                        radius: _radius,
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                const SizedBox(height: 2),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _fmt(message.createdAt),
                    style: const TextStyle(
                      color: _kTimestampColor,
                      fontSize: 11,
                    ),
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

// ─── Sent bubble (right) ─────────────────────────────────────────────────────

class _SentBubble extends StatelessWidget {
  const _SentBubble({required this.message, required this.myInitial});

  final MessageModel message;
  final String myInitial;

  static const _radius = BorderRadius.only(
    topLeft: Radius.circular(18),
    topRight: Radius.circular(4),
    bottomLeft: Radius.circular(18),
    bottomRight: Radius.circular(18),
  );

  @override
  Widget build(BuildContext context) {
    final seen = message.seenBy.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(right: 8, left: 64, top: 2, bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'You',
            style: TextStyle(
              color: _kLabelColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    message.type == MessageType.location
                        ? _locationBubble(_kSentColor, _radius, message)
                        : _TextBubble(
                            text: message.text ?? '',
                            color: _kSentColor,
                            radius: _radius,
                            textStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          seen ? Icons.done_all : Icons.done,
                          size: 13,
                          color: seen
                              ? Colors.white70
                              : _kTimestampColor,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _fmt(message.createdAt),
                          style: const TextStyle(
                            color: _kTimestampColor,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              _AvatarCircle(initial: myInitial),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Location bubble content ──────────────────────────────────────────────────

Widget _locationBubble(
  Color color,
  BorderRadius radius,
  MessageModel msg,
) {
  return ClipRRect(
    borderRadius: radius,
    child: Container(
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            height: 140,
            child: Stack(
              children: [
                Container(color: _kMapBg),
                CustomPaint(
                  painter: _GridPainter(),
                  child: const SizedBox.expand(),
                ),
                const Center(
                  child: Icon(
                    Icons.location_pin,
                    color: Color(0xFFFF2D55),
                    size: 40,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Exact location shared',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (msg.text != null && msg.text!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      msg.text!,
                      style: const TextStyle(
                        color: _kSystemColor,
                        fontSize: 12,
                      ),
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

// ─── Plain text bubble ────────────────────────────────────────────────────────

class _TextBubble extends StatelessWidget {
  const _TextBubble({
    required this.text,
    required this.color,
    required this.radius,
    required this.textStyle,
  });

  final String text;
  final Color color;
  final BorderRadius radius;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: color, borderRadius: radius),
      child: Text(text, style: textStyle),
    );
  }
}

// ─── Avatar circle ────────────────────────────────────────────────────────────

class _AvatarCircle extends StatelessWidget {
  const _AvatarCircle({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: _kAvatarBg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Grid painter for map placeholder ────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 0.5;
    const step = 22.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
