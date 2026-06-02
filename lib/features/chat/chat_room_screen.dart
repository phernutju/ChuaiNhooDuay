// ignore_for_file: unused_field, unused_element
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:we_are_ready/features/chat/widgets/chat_status_banner.dart';
import 'package:we_are_ready/features/chat/widgets/message_bubble.dart';
import 'package:we_are_ready/features/chat/widgets/message_input_bar.dart';
import 'package:we_are_ready/features/chat/widgets/typing_indicator.dart';
import 'package:we_are_ready/mock/mock_messages.dart';
import 'package:we_are_ready/models/message_model.dart';

// ─── Color palette ────────────────────────────────────────────────────────────

abstract class _C {
  static const background    = Color(0xFF0F0F0F);
  static const surface       = Color(0xFF1A1A1A);
  static const surfaceRaise  = Color(0xFF242424);
  static const surfaceMid    = Color(0xFF1E1E1E);
  static const accent        = Color(0xFFE8442A);
  static const textPrimary   = Color(0xFFEEEEEE);
  static const textSecondary = Color(0xFF888888);
  static const textMuted     = Color(0xFF555555);
  static const senderBlue    = Color(0xFF4A8FCE);
  static const seenGray      = Color(0xFF555555);
  static const seenGreen     = Color(0xFF5FA85F);
  static const locGreen      = Color(0xFF1E2E1E);
  static const locBorder     = Color(0xFF2A3A2A);
  static const locText       = Color(0xFF5FA85F);
  static const closedBg      = Color(0xFF1A1510);
  static const closedBorder  = Color(0xFF3A2A1A);
  static const closedText    = Color(0xFF7A5A4A);
  static const sysBg         = Color(0xFF1E1E1E);
  static const sysBorder     = Color(0xFF2E2E2E);
  static const sysText       = Color(0xFF555555);
  static const urgentBadgeBg = Color(0xFF7A4A10);
  static const urgentBadgeFg = Color(0xFFF0A040);
}

// ─── Typography ───────────────────────────────────────────────────────────────

abstract class _T {
  static TextStyle headerTitle() => GoogleFonts.ibmPlexSansThai(
        fontSize: 14, fontWeight: FontWeight.w500, color: _C.textPrimary);

  static TextStyle headerSub() => GoogleFonts.ibmPlexSansThai(
        fontSize: 11, fontWeight: FontWeight.w400, color: _C.textSecondary);

  static TextStyle bannerText() => GoogleFonts.ibmPlexSansThai(
        fontSize: 11, fontWeight: FontWeight.w400, color: _C.textPrimary);

  static TextStyle bubbleBody() => GoogleFonts.ibmPlexSansThai(
        fontSize: 13, fontWeight: FontWeight.w400, color: _C.textPrimary, height: 1.45);

  static TextStyle bubbleName() => GoogleFonts.ibmPlexSansThai(
        fontSize: 10, fontWeight: FontWeight.w600, color: _C.senderBlue);

  static TextStyle timestamp() => GoogleFonts.ibmPlexSansThai(
        fontSize: 10, fontWeight: FontWeight.w400, color: _C.textMuted);

  static TextStyle systemPill() => GoogleFonts.ibmPlexSansThai(
        fontSize: 10, fontWeight: FontWeight.w400, color: _C.sysText);

  static TextStyle inputText() => GoogleFonts.ibmPlexSansThai(
        fontSize: 13, fontWeight: FontWeight.w400, color: _C.textPrimary);

  static TextStyle readonlyBar() => GoogleFonts.ibmPlexSansThai(
        fontSize: 11, fontWeight: FontWeight.w400, color: _C.closedText);
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({
    super.key,
    required this.requestId,
    required this.requestTitle,
    required this.requestCategory,
    required this.urgencyLabel,
    required this.currentUserId,
    required this.otherUserName,
    required this.distanceLabel,
    this.etaLabel,
    required this.participantCount,
    required this.isReadOnly,
    this.useMockData = true,
  });

  final String requestId;
  final String requestTitle;

  /// Display string shown in the header subtitle, e.g. "MEDICAL AID".
  final String requestCategory;

  /// "CRITICAL" | "URGENT" | "GENERAL"
  final String urgencyLabel;

  final String currentUserId;

  /// Display name of the other participant shown in the header.
  final String otherUserName;

  /// Pre-formatted distance string, e.g. "0.3 km away".
  final String distanceLabel;

  /// Pre-formatted ETA string, e.g. "ETA 9 min". Shown in the status banner.
  final String? etaLabel;

  final int participantCount;
  final bool isReadOnly;

  /// Use [MockMessages] data. Flip to false when the backend is wired.
  final bool useMockData;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  List<MessageModel> _messages = [];
  bool _showTyping = false;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.useMockData) {
      _messages = widget.isReadOnly
          ? MockMessages.closedThread
          : MockMessages.activeThread;
      if (!widget.isReadOnly) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) setState(() => _showTyping = true);
        });
      }
    } else {
      // TODO(backend): set useMockData = false and delete mock branch
      // TODO(backend): final p = context.read<MessageProvider>();
      // TODO(backend): p.subscribeToMessages(requestId);
      // TODO(backend): p.subscribeToUnseenCount(requestId, currentUserId);
      // TODO(backend): p.markAllSeen(requestId, currentUserId);
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onSend(String text) {
    // TODO(backend): replace mock append with:
    // context.read<MessageProvider>().sendText(requestId, currentUserId, text);
    setState(() {
      _messages.add(MessageModel(
        id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
        senderId: MockMessages.currentUserId,
        text: text,
        type: MessageType.message,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        seenBy: [MockMessages.currentUserId],
        seenCount: 1,
      ));
      _showTyping = false;
    });
    _scrollToBottom();
  }

  @override
  void dispose() {
    _scroll.dispose();
    if (!widget.useMockData) {
      // TODO(backend): context.read<MessageProvider>().clearRoom();
    }
    super.dispose();
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final itemCount = _messages.length + (_showTyping ? 1 : 0);

    return Scaffold(
      backgroundColor: _C.background,
      body: Column(
        children: [
          _buildHeader(),
          ChatStatusBanner(isActive: !widget.isReadOnly, etaLabel: widget.etaLabel),
          Expanded(
            // TODO(backend): wrap ListView in Consumer<MessageProvider> and use
            // provider.messages instead of _messages
            // TODO(backend): use provider.isSending for MessageInputBar.isSending
            child: ListView.builder(
              controller: _scroll,
              reverse: false,
              shrinkWrap: false,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: itemCount,
              itemBuilder: (_, i) {
                if (i == _messages.length) return const TypingIndicator();
                return _buildItem(_messages[i]);
              },
            ),
          ),
          MessageInputBar(
            isReadOnly: widget.isReadOnly,
            isSending: false,
            onSendText: _onSend,
            onTapCamera: () {},
            onTapLocation: () {},
          ),
        ],
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return SafeArea(
      bottom: false,
      child: Container(
        color: _C.surface,
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: _C.textPrimary,
              ),
              onPressed: () => Navigator.maybePop(context),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.otherUserName,
                          style: _T.headerTitle(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _UrgencyBadge(label: widget.urgencyLabel),
                    ],
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${widget.requestCategory} · ${widget.distanceLabel} · ${widget.participantCount} participants',
                    style: _T.headerSub(),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.ios_share,
                size: 18,
                color: _C.textPrimary,
              ),
              onPressed: null,
            ),
          ],
        ),
      ),
    );
  }

  // ─── List item ─────────────────────────────────────────────────────────────

  Widget _buildItem(MessageModel msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MessageBubble(
        message: msg,
        currentUserId: widget.currentUserId,
      ),
    );
  }
}

// ─── Urgency badge (string-driven) ───────────────────────────────────────────

class _UrgencyBadge extends StatelessWidget {
  const _UrgencyBadge({required this.label});

  final String label;

  Color get _bg {
    switch (label.toUpperCase()) {
      case 'CRITICAL':
        return _C.accent;
      case 'URGENT':
        return _C.urgentBadgeBg;
      default:
        return _C.surfaceRaise;
    }
  }

  Color get _fg {
    switch (label.toUpperCase()) {
      case 'CRITICAL':
        return _C.textPrimary;
      case 'URGENT':
        return _C.urgentBadgeFg;
      default:
        return _C.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(3)),
      child: Text(
        label,
        style: GoogleFonts.ibmPlexSansThai(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: _fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
