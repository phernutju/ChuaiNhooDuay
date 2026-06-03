import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:we_are_ready/features/chat/widgets/chat_status_banner.dart';
import 'package:we_are_ready/features/chat/widgets/message_bubble.dart';
import 'package:we_are_ready/features/chat/widgets/message_input_bar.dart';
import 'package:we_are_ready/models/message_model.dart';
import 'package:we_are_ready/models/request_model.dart';
import 'package:we_are_ready/providers/message_provider.dart';
import 'package:we_are_ready/services/message_service.dart';

// ─── Color palette ────────────────────────────────────────────────────────────

abstract class _C {
  static const background    = Color(0xFF0F0F0F);
  static const surface       = Color(0xFF1A1A1A);
  static const surfaceRaise  = Color(0xFF242424);
  static const accent        = Color(0xFFE8442A);
  static const textPrimary   = Color(0xFFEEEEEE);
  static const textSecondary = Color(0xFF888888);
  static const urgentBadgeBg = Color(0xFF7A4A10);
  static const urgentBadgeFg = Color(0xFFF0A040);
}

// ─── Typography ───────────────────────────────────────────────────────────────

abstract class _T {
  static TextStyle headerTitle() => GoogleFonts.ibmPlexSansThai(
        fontSize: 14, fontWeight: FontWeight.w500, color: _C.textPrimary);

  static TextStyle headerSub() => GoogleFonts.ibmPlexSansThai(
        fontSize: 11, fontWeight: FontWeight.w400, color: _C.textSecondary);
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
    required this.requestStatus,
    required this.messageService,
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

  /// Drives the banner (matched) and read-only state (completed).
  final RequestStatus requestStatus;

  /// Firestore message service — injected so the screen stays testable.
  final MessageService messageService;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  late final MessageProvider _provider;
  final _scroll = ScrollController();
  int _prevCount = 0;
  String? _prevError;

  bool get _isReadOnly => widget.requestStatus == RequestStatus.completed;

  @override
  void initState() {
    super.initState();
    _provider = MessageProvider(widget.messageService);
    _provider.subscribeToMessages(widget.requestId);
    _provider.subscribeToUnseenCount(widget.requestId, widget.currentUserId);
    _provider.addListener(_onUpdate);
  }

  void _onUpdate() {
    // Show SnackBar for image/location errors (once per unique error string)
    final err = _provider.error;
    if (err != null && err != _prevError) {
      _prevError = err;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            backgroundColor: const Color(0xFFB71C1C),
            duration: const Duration(seconds: 3),
          ),
        );
      });
    }

    final count = _provider.messages.length;
    if (count != _prevCount) {
      _prevCount = count;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
        if (mounted) {
          _provider.markAllSeen(widget.requestId, widget.currentUserId);
        }
      });
    }
  }

  void _scrollToBottom() {
    if (_scroll.hasClients && _scroll.position.hasContentDimensions) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _onSend(String text) {
    _provider.sendText(widget.requestId, widget.currentUserId, text);
  }

  @override
  void dispose() {
    _provider.removeListener(_onUpdate);
    _provider.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: _C.background,
        body: Column(
          children: [
            _buildHeader(),
            ChatStatusBanner(
              isActive: widget.requestStatus == RequestStatus.matched,
              etaLabel: widget.etaLabel,
            ),
            Expanded(
              child: Consumer<MessageProvider>(
                builder: (_, provider, _) => _buildList(provider),
              ),
            ),
            Consumer<MessageProvider>(
              builder: (_, provider, _) => MessageInputBar(
                isReadOnly: _isReadOnly,
                isSending: provider.isSending,
                isUploadingImage: provider.isUploadingImage,
                isFetchingLocation: provider.isFetchingLocation,
                onSendText: _onSend,
                onPickImage: (source) => _provider.pickAndSendImage(
                  requestId: widget.requestId,
                  senderId: widget.currentUserId,
                  source: source,
                ),
                onSendLocation: () => _provider.sendCurrentLocation(
                  requestId: widget.requestId,
                  senderId: widget.currentUserId,
                ),
              ),
            ),
          ],
        ),
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

  // ─── Message list ──────────────────────────────────────────────────────────

  Widget _buildList(MessageProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _C.accent, strokeWidth: 2),
      );
    }

    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            provider.error!,
            style: const TextStyle(color: _C.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final msgs = provider.messages;

    if (msgs.isEmpty) {
      return const Center(
        child: Text(
          'No messages yet',
          style: TextStyle(color: _C.textSecondary, fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      controller: _scroll,
      reverse: false,
      shrinkWrap: false,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: msgs.length,
      itemBuilder: (_, i) => _buildItem(msgs[i]),
    );
  }

  Widget _buildItem(MessageModel msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MessageBubble(
        message: msg,
        currentUserId: widget.currentUserId,
        senderName: widget.otherUserName,
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
