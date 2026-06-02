import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:we_are_ready/models/message_model.dart';
import 'package:we_are_ready/models/request_model.dart';
import 'package:we_are_ready/providers/message_provider.dart';
import 'package:we_are_ready/services/message_service.dart';

// ─── Color palette ────────────────────────────────────────────────────────────

abstract class _C {
  static const background   = Color(0xFF0F0F0F);
  static const surface      = Color(0xFF1A1A1A);
  static const surfaceRaise = Color(0xFF242424);
  static const surfaceMid   = Color(0xFF1E1E1E);
  static const accent       = Color(0xFFE8442A);
  static const textPrimary  = Color(0xFFEEEEEE);
  static const textSecondary = Color(0xFF888888);
  static const textMuted    = Color(0xFF555555);
  static const senderBlue   = Color(0xFF4A8FCE);
  static const seenGray     = Color(0xFF555555);
  static const seenGreen    = Color(0xFF5FA85F);
  static const locGreen     = Color(0xFF1E2E1E);
  static const locBorder    = Color(0xFF2A3A2A);
  static const locText      = Color(0xFF5FA85F);
  static const closedBg     = Color(0xFF1A1510);
  static const closedBorder = Color(0xFF3A2A1A);
  static const closedText   = Color(0xFF7A5A4A);
  static const sysBg        = Color(0xFF1E1E1E);
  static const sysBorder    = Color(0xFF2E2E2E);
  static const sysText      = Color(0xFF555555);
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
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: _C.textPrimary,
        height: 1.45);

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

// ─── Public screen ────────────────────────────────────────────────────────────

/// Chat message room for a single [RequestModel].
///
/// Active (open / assigned): status banner + input bar.
/// Closed: read-only history with locked footer.
class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({
    super.key,
    required this.request,
    required this.currentUserId,
    required this.myInitial,
    required this.participantNames,
    required this.messageService,
    this.etaMinutes,
    this.isOtherTyping = false,
  });

  final RequestModel request;
  final String currentUserId;

  /// Single uppercase letter shown on the current user's avatar.
  final String myInitial;

  /// Maps userId → display name for bubble sender labels.
  final Map<String, String> participantNames;

  final MessageService messageService;

  /// Shown in the status banner as "ETA X min" when non-null.
  final int? etaMinutes;

  /// Shows a typing indicator at the bottom of the list.
  final bool isOtherTyping;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  late final MessageProvider _provider;
  final _scroll = ScrollController();
  final _text = TextEditingController();
  int _prevCount = 0;

  @override
  void initState() {
    super.initState();
    _provider = MessageProvider(widget.messageService);
    _provider.subscribeToMessages(widget.request.id);
    _provider.subscribeToUnseenCount(widget.request.id, widget.currentUserId);
    _provider.addListener(_onUpdate);
  }

  void _onUpdate() {
    final count = _provider.messages.length;
    if (count != _prevCount) {
      _prevCount = count;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
        if (mounted) _provider.markAllSeen(widget.request.id, widget.currentUserId);
      });
    }
  }

  void _scrollToBottom() {
    if (_scroll.hasClients && _scroll.position.hasContentDimensions) {
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  void _send() {
    final t = _text.text.trim();
    if (t.isEmpty) return;
    _text.clear();
    _provider.sendText(widget.request.id, widget.currentUserId, t);
  }

  @override
  void dispose() {
    _provider.removeListener(_onUpdate);
    _provider.dispose();
    _scroll.dispose();
    _text.dispose();
    super.dispose();
  }

  String get _roomTitle {
    final isCiv = widget.currentUserId == widget.request.createdBy;
    if (isCiv) {
      final vid = widget.request.assignedVolunteerIds.firstOrNull;
      return vid != null ? (widget.participantNames[vid] ?? 'Volunteer') : 'Volunteer';
    }
    return widget.participantNames[widget.request.createdBy] ?? 'Requester';
  }

  String get _subtitle {
    final closed = widget.request.status == RequestStatus.completed;
    final type = _typeName(widget.request.requestType);
    if (closed) return '$type · completed ${_timeAgo(widget.request.updatedAt)}';
    final n = widget.request.assignedVolunteerIds.length + 1;
    return '$type · $n participant${n == 1 ? '' : 's'}';
  }

  String get _otherInitial {
    final isCiv = widget.currentUserId == widget.request.createdBy;
    final oid = isCiv
        ? widget.request.assignedVolunteerIds.firstOrNull
        : widget.request.createdBy;
    final name = oid != null ? (widget.participantNames[oid] ?? '?') : '?';
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: _Body(
        request: widget.request,
        currentUserId: widget.currentUserId,
        myInitial: widget.myInitial,
        participantNames: widget.participantNames,
        roomTitle: _roomTitle,
        roomSubtitle: _subtitle,
        etaMinutes: widget.etaMinutes,
        isOtherTyping: widget.isOtherTyping,
        otherInitial: _otherInitial,
        scroll: _scroll,
        textCtrl: _text,
        onSend: _send,
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({
    required this.request,
    required this.currentUserId,
    required this.myInitial,
    required this.participantNames,
    required this.roomTitle,
    required this.roomSubtitle,
    required this.etaMinutes,
    required this.isOtherTyping,
    required this.otherInitial,
    required this.scroll,
    required this.textCtrl,
    required this.onSend,
  });

  final RequestModel request;
  final String currentUserId;
  final String myInitial;
  final Map<String, String> participantNames;
  final String roomTitle;
  final String roomSubtitle;
  final int? etaMinutes;
  final bool isOtherTyping;
  final String otherInitial;
  final ScrollController scroll;
  final TextEditingController textCtrl;
  final VoidCallback onSend;

  bool get _isClosed => request.status == RequestStatus.completed;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MessageProvider>();
    return Scaffold(
      backgroundColor: _C.background,
      appBar: _AppBar(
        roomTitle: roomTitle,
        roomSubtitle: roomSubtitle,
        urgencyLevel: request.urgencyLevel,
        isClosed: _isClosed,
      ),
      body: Column(
        children: [
          if (!_isClosed) _StatusBanner(etaMinutes: etaMinutes),
          Expanded(child: _buildList(context, provider)),
          _isClosed
              ? const _ReadOnlyBar()
              : _InputBar(ctrl: textCtrl, onSend: onSend, isSending: provider.isSending),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, MessageProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _C.accent, strokeWidth: 2),
      );
    }
    if (provider.error != null) {
      return Center(child: Text(provider.error!, style: _T.headerSub()));
    }

    final msgs = provider.messages;
    if (msgs.isEmpty && !isOtherTyping) {
      return Center(child: Text('No messages yet', style: _T.headerSub()));
    }

    final maxW = MediaQuery.sizeOf(context).width * 0.72;

    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: msgs.length + (isOtherTyping ? 1 : 0),
      itemBuilder: (ctx, i) {
        if (i == msgs.length) return _TypingBubble(initial: otherInitial);
        final msg = msgs[i];
        final isMe = msg.senderId == currentUserId;
        final name = participantNames[msg.senderId] ?? _shortId(msg.senderId);
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _Bubble(
            message: msg,
            isMe: isMe,
            senderName: name,
            myInitial: myInitial,
            maxWidth: maxW,
          ),
        );
      },
    );
  }

  static String _shortId(String id) =>
      id.length >= 6 ? id.substring(0, 6) : id;
}

// ─── App bar ──────────────────────────────────────────────────────────────────

class _AppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AppBar({
    required this.roomTitle,
    required this.roomSubtitle,
    required this.urgencyLevel,
    required this.isClosed,
  });

  final String roomTitle;
  final String roomSubtitle;
  final UrgencyLevel urgencyLevel;
  final bool isClosed;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: _C.surface,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: _C.textPrimary, size: 20),
        onPressed: () => Navigator.maybePop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          _Avatar(
            initial: roomTitle.isNotEmpty ? roomTitle[0].toUpperCase() : '?',
            size: 34,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        roomTitle,
                        style: _T.headerTitle(),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    isClosed
                        ? _Badge(
                            label: 'CLOSED',
                            bg: _C.surfaceRaise,
                            fg: _C.textSecondary,
                          )
                        : _UrgencyBadge(level: urgencyLevel),
                  ],
                ),
                Text(
                  roomSubtitle,
                  style: _T.headerSub(),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: _C.textPrimary, size: 20),
          onPressed: null,
        ),
      ],
    );
  }
}

// ─── Status banner ────────────────────────────────────────────────────────────

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({this.etaMinutes});

  final int? etaMinutes;

  @override
  Widget build(BuildContext context) {
    final eta = etaMinutes != null ? ' · ETA $etaMinutes min' : '';
    return Container(
      color: _C.surfaceMid,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: _C.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Request active · Volunteer assigned$eta',
              style: _T.bannerText(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bubble dispatcher ────────────────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.isMe,
    required this.senderName,
    required this.myInitial,
    required this.maxWidth,
  });

  final MessageModel message;
  final bool isMe;
  final String senderName;
  final String myInitial;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (message.type == MessageType.system) {
      return _SystemPill(text: message.text ?? '');
    }
    if (isMe) {
      return _OwnBubble(message: message, myInitial: myInitial, maxWidth: maxWidth);
    }
    final initial = senderName.isNotEmpty ? senderName[0].toUpperCase() : '?';
    return _TheirBubble(
      message: message,
      senderName: senderName,
      senderInitial: initial,
      maxWidth: maxWidth,
    );
  }
}

// ─── Their bubble (received / left) ──────────────────────────────────────────

class _TheirBubble extends StatelessWidget {
  const _TheirBubble({
    required this.message,
    required this.senderName,
    required this.senderInitial,
    required this.maxWidth,
  });

  final MessageModel message;
  final String senderName;
  final String senderInitial;
  final double maxWidth;

  static const _r = BorderRadius.only(
    topLeft: Radius.circular(16),
    topRight: Radius.circular(16),
    bottomLeft: Radius.circular(4),
    bottomRight: Radius.circular(16),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 72, top: 1, bottom: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _Avatar(initial: senderInitial, size: 28),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(senderName, style: _T.bubbleName()),
                const SizedBox(height: 3),
                message.type == MessageType.location
                    ? _LocationCard(text: message.text, radius: _r, maxWidth: maxWidth)
                    : _BubbleBox(text: message.text ?? '', color: _C.surfaceRaise, radius: _r),
                const SizedBox(height: 2),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(_fmt(message.createdAt), style: _T.timestamp()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Own bubble (sent / right) ────────────────────────────────────────────────

class _OwnBubble extends StatelessWidget {
  const _OwnBubble({
    required this.message,
    required this.myInitial,
    required this.maxWidth,
  });

  final MessageModel message;
  final String myInitial;
  final double maxWidth;

  static const _r = BorderRadius.only(
    topLeft: Radius.circular(16),
    topRight: Radius.circular(16),
    bottomLeft: Radius.circular(16),
    bottomRight: Radius.circular(4),
  );

  @override
  Widget build(BuildContext context) {
    final seen = message.seenBy.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(right: 10, left: 72, top: 1, bottom: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                message.type == MessageType.location
                    ? _LocationCard(text: message.text, radius: _r, maxWidth: maxWidth)
                    : _BubbleBox(text: message.text ?? '', color: _C.accent, radius: _r),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.done_all,
                      size: 12,
                      color: seen ? _C.seenGreen : _C.seenGray,
                    ),
                    const SizedBox(width: 2),
                    Text(_fmt(message.createdAt), style: _T.timestamp()),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          _Avatar(initial: myInitial, size: 28),
        ],
      ),
    );
  }
}

// ─── Plain text bubble box ────────────────────────────────────────────────────

class _BubbleBox extends StatelessWidget {
  const _BubbleBox({
    required this.text,
    required this.color,
    required this.radius,
  });

  final String text;
  final Color color;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color, borderRadius: radius),
      child: Text(text, style: _T.bubbleBody()),
    );
  }
}

// ─── Location card ────────────────────────────────────────────────────────────

class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.text,
    required this.radius,
    required this.maxWidth,
  });

  final String? text;
  final BorderRadius radius;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: maxWidth,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _C.locGreen,
        border: Border.all(color: _C.locBorder),
        borderRadius: radius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            height: 120,
            child: Stack(
              children: [
                Container(color: _C.locGreen),
                CustomPaint(
                  painter: _GridPainter(),
                  child: const SizedBox.expand(),
                ),
                const Center(
                  child: Icon(Icons.location_pin, color: Color(0xFFFF2D55), size: 36),
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
                  'Exact location shared',
                  style: GoogleFonts.ibmPlexSansThai(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _C.textPrimary,
                  ),
                ),
                if (text != null && text!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      text!,
                      style: GoogleFonts.ibmPlexSansThai(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: _C.locText,
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

// ─── System pill ──────────────────────────────────────────────────────────────

class _SystemPill extends StatelessWidget {
  const _SystemPill({required this.text});

  final String text;

  bool get _isClosed => text.contains('has been closed');

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: _C.sysBg,
            border: Border.all(color: _C.sysBorder),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isClosed) ...[
                const Icon(Icons.lock_outline, size: 10, color: _C.sysText),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  text,
                  style: _T.systemPill(),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Typing indicator ─────────────────────────────────────────────────────────

class _TypingBubble extends StatelessWidget {
  const _TypingBubble({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, right: 72, top: 1, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _Avatar(initial: initial, size: 28),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: _C.surfaceRaise,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Text(
              '· · ·',
              style: GoogleFonts.ibmPlexSansThai(
                fontSize: 14,
                color: _C.textSecondary,
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

// ─── Input bar ────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.ctrl,
    required this.onSend,
    required this.isSending,
  });

  final TextEditingController ctrl;
  final VoidCallback onSend;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _C.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 10, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.camera_alt_outlined, size: 20),
                color: _C.textSecondary,
                onPressed: null,
              ),
              IconButton(
                icon: const Icon(Icons.location_on_outlined, size: 20),
                color: _C.textSecondary,
                onPressed: null,
              ),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: _C.surfaceRaise,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: TextField(
                    controller: ctrl,
                    style: _T.inputText(),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: _T.inputText().copyWith(color: _C.textSecondary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      isDense: true,
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    keyboardAppearance: Brightness.dark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _SendBtn(isSending: isSending, onTap: onSend),
            ],
          ),
        ),
      ),
    );
  }
}

class _SendBtn extends StatelessWidget {
  const _SendBtn({required this.isSending, required this.onTap});

  final bool isSending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSending ? null : onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isSending ? _C.accent.withValues(alpha: 0.5) : _C.accent,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: isSending
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.arrow_upward, color: Colors.white, size: 18),
      ),
    );
  }
}

// ─── Read-only bar ────────────────────────────────────────────────────────────

class _ReadOnlyBar extends StatelessWidget {
  const _ReadOnlyBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _C.closedBg,
        border: Border(top: BorderSide(color: _C.closedBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 12, color: _C.closedText),
              const SizedBox(width: 6),
              Text('Request closed · messages are read-only', style: _T.readonlyBar()),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Avatar ───────────────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initial, required this.size});

  final String initial;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: _C.surfaceRaise, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initial.toUpperCase(),
        style: GoogleFonts.ibmPlexSansThai(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w600,
          color: _C.textPrimary,
        ),
      ),
    );
  }
}

// ─── Badges ───────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(3)),
      child: Text(
        label,
        style: GoogleFonts.ibmPlexSansThai(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: fg,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _UrgencyBadge extends StatelessWidget {
  const _UrgencyBadge({required this.level});

  final UrgencyLevel level;

  @override
  Widget build(BuildContext context) {
    switch (level) {
      case UrgencyLevel.critical:
        return _Badge(label: 'CRITICAL', bg: _C.accent, fg: _C.textPrimary);
      case UrgencyLevel.urgent:
        return _Badge(
          label: 'URGENT',
          bg: const Color(0xFF7A4A10),
          fg: const Color(0xFFF0A040),
        );
      case UrgencyLevel.general:
        return _Badge(label: 'GENERAL', bg: _C.surfaceRaise, fg: _C.textSecondary);
    }
  }
}

// ─── Grid painter for location card ──────────────────────────────────────────

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _C.locBorder
      ..strokeWidth = 0.5;
    const step = 20.0;
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

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _fmt(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _typeName(RequestType type) {
  switch (type) {
    case RequestType.medical:   return 'Medical Aid';
    case RequestType.water:     return 'Water / Food';
    case RequestType.shelter:   return 'Shelter';
    case RequestType.evacuate:  return 'Evacuation';
    case RequestType.transport: return 'Transport';
    case RequestType.rescue:    return 'Rescue';
    case RequestType.supplies:  return 'Supplies';
    case RequestType.other:     return 'Other';
  }
}

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1)  return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24)   return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
