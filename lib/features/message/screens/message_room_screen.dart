import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:we_are_ready/constants/constants.dart';
import 'package:we_are_ready/features/message/widgets/chat_app_bar.dart';
import 'package:we_are_ready/features/message/widgets/message_bubble.dart';
import 'package:we_are_ready/features/message/widgets/message_input_bar.dart';
import 'package:we_are_ready/features/message/widgets/read_only_bar.dart';
import 'package:we_are_ready/features/message/widgets/status_banner.dart';
import 'package:we_are_ready/models/message_model.dart';
import 'package:we_are_ready/models/request_model.dart';
import 'package:we_are_ready/providers/message_provider.dart';
import 'package:we_are_ready/services/message_service.dart';

// ─── Public screen ────────────────────────────────────────────────────────────

/// Chat message room tied to a single [RequestModel].
///
/// - Active (open / assigned): shows status banner and input bar.
/// - Closed: read-only history with a locked footer.
///
/// [participantNames] maps userId → display name and is used to label
/// each received bubble and the typing indicator.
class MessageRoomScreen extends StatefulWidget {
  const MessageRoomScreen({
    super.key,
    required this.request,
    required this.currentUserId,
    required this.myInitial,
    required this.participantNames,
    required this.messageService,
    this.etaMinutes,
    this.isOtherTyping = false,
  });

  /// The request this room belongs to.
  final RequestModel request;

  /// Auth user ID of whoever is currently viewing the screen.
  final String currentUserId;

  /// Single uppercase letter shown on the current user's sent-message avatar.
  final String myInitial;

  /// Maps every participant's userId to a display name (e.g. "Somchai N.").
  /// Used for bubble sender labels and the typing indicator initial.
  final Map<String, String> participantNames;

  /// Firestore message service — injected so the screen stays testable.
  final MessageService messageService;

  /// When non-null, shown in the status banner as "ETA X min".
  final int? etaMinutes;

  /// Displays a typing indicator bubble at the bottom of the message list.
  final bool isOtherTyping;

  @override
  State<MessageRoomScreen> createState() => _MessageRoomScreenState();
}

class _MessageRoomScreenState extends State<MessageRoomScreen> {
  late final MessageProvider _provider;
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
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
        if (mounted) {
          _provider.markAllSeen(widget.request.id, widget.currentUserId);
        }
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients &&
        _scrollController.position.hasContentDimensions) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    }
  }

  void _send() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _textController.clear();
    _provider.sendText(widget.request.id, widget.currentUserId, text);
  }

  @override
  void dispose() {
    _provider.removeListener(_onUpdate);
    _provider.dispose();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  // Derive room title: show the other party's name.
  String get _roomTitle {
    final isCivilian = widget.currentUserId == widget.request.createdBy;
    if (isCivilian) {
      final firstVolId = widget.request.assignedVolunteerIds.firstOrNull;
      return firstVolId != null
          ? (widget.participantNames[firstVolId] ?? 'Volunteer')
          : 'Volunteer';
    }
    return widget.participantNames[widget.request.createdBy] ?? 'Requester';
  }

  String get _subtitle {
    final isClosed = widget.request.status == RequestStatus.completed;
    final type = _typeName(widget.request.requestType);
    if (isClosed) {
      return '$type · completed ${_timeAgo(widget.request.updatedAt)}';
    }
    final n = widget.request.assignedVolunteerIds.length + 1;
    return '$type · $n participant${n == 1 ? '' : 's'}';
  }

  // Other-party typing indicator initial (first non-self participant).
  String get _otherInitial {
    final isCivilian = widget.currentUserId == widget.request.createdBy;
    final otherId = isCivilian
        ? widget.request.assignedVolunteerIds.firstOrNull
        : widget.request.createdBy;
    final name = otherId != null
        ? (widget.participantNames[otherId] ?? '?')
        : '?';
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: _MessageRoomBody(
        request: widget.request,
        currentUserId: widget.currentUserId,
        myInitial: widget.myInitial,
        participantNames: widget.participantNames,
        roomTitle: _roomTitle,
        roomSubtitle: _subtitle,
        etaMinutes: widget.etaMinutes,
        isOtherTyping: widget.isOtherTyping,
        otherInitial: _otherInitial,
        scrollController: _scrollController,
        textController: _textController,
        onSend: _send,
      ),
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _MessageRoomBody extends StatelessWidget {
  const _MessageRoomBody({
    required this.request,
    required this.currentUserId,
    required this.myInitial,
    required this.participantNames,
    required this.roomTitle,
    required this.roomSubtitle,
    required this.etaMinutes,
    required this.isOtherTyping,
    required this.otherInitial,
    required this.scrollController,
    required this.textController,
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
  final ScrollController scrollController;
  final TextEditingController textController;
  final VoidCallback onSend;

  bool get _isClosed => request.status == RequestStatus.completed;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MessageProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: ChatAppBar(
        roomTitle: roomTitle,
        roomSubtitle: roomSubtitle,
        urgencyLevel: request.urgencyLevel,
        isClosed: _isClosed,
      ),
      body: Column(
        children: [
          if (!_isClosed) StatusBanner(etaMinutes: etaMinutes),
          Expanded(
            child: _buildList(provider),
          ),
          _isClosed
              ? const ReadOnlyBar()
              : MessageInputBar(
                  controller: textController,
                  onSend: onSend,
                  isSending: provider.isSending,
                ),
        ],
      ),
    );
  }

  Widget _buildList(MessageProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFE84935),
          strokeWidth: 2,
        ),
      );
    }

    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            provider.error!,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final msgs = provider.messages;

    if (msgs.isEmpty && !isOtherTyping) {
      return const Center(
        child: Text(
          'No messages yet',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      );
    }

    final itemCount = msgs.length + (isOtherTyping ? 1 : 0);

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == msgs.length && isOtherTyping) {
          return TypingIndicator(senderInitial: otherInitial);
        }
        return _buildBubble(msgs[index]);
      },
    );
  }

  Widget _buildBubble(MessageModel msg) {
    final isMe = msg.senderId == currentUserId;
    final name = participantNames[msg.senderId] ?? _fallbackName(msg.senderId);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: MessageBubble(
        message: msg,
        isMe: isMe,
        senderName: name,
        senderInitial: initial,
        myInitial: myInitial,
      ),
    );
  }

  String _fallbackName(String senderId) {
    if (senderId.isEmpty) return '';
    return senderId.length >= 6 ? senderId.substring(0, 6) : senderId;
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

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
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
