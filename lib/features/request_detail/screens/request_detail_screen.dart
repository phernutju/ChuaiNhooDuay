import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:we_are_ready/constants/constants.dart';
import 'package:we_are_ready/features/map/nearby_requests_map.dart';
import 'package:we_are_ready/features/widgets/app_widgets.dart';
import 'package:we_are_ready/utils/check_in_service.dart';
import 'package:we_are_ready/utils/time_ago.dart';
import 'package:we_are_ready/features/request_detail/mock/request_mock_data.dart';
import 'package:we_are_ready/features/chat/chat_room_screen.dart';
import 'package:we_are_ready/services/message_service.dart';
import 'package:provider/provider.dart';
import 'package:we_are_ready/providers/providers.dart';
import 'package:we_are_ready/services/request_service.dart';
import 'package:we_are_ready/models/request_model.dart';

RequestModel _toRequestModel(RequestDetailData data) {
  return RequestModel(
    id: data.id,
    createdBy: '',
    title: data.title,
    location: RequestLocation(
      address: data.requesterLocation,
      coordinates: GeoPoint(data.lat, data.lng),
    ),
    requestType: RequestType.other,
    urgencyLevel: data.urgencyLevel,
    urgencyScore: 1,
    maxVolunteer: 1,
    assignedVolunteerIds: const [],
    status: RequestStatus.waiting,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

Color _avatarColorFromName(String name) {
  const colors = [
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFF9C27B0),
    Color(0xFFFF9800),
    Color(0xFF00BCD4),
    Color(0xFFE91E63),
  ];
  final hash = name.codeUnits.fold(0, (acc, e) => acc + e);
  return colors[hash % colors.length];
}

class RequestDetailScreen extends StatefulWidget {
  const RequestDetailScreen({
    super.key,
    required this.request,
    this.showActions = true,
  });

  final RequestDetailData request;
  final bool showActions;

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  bool _loadingJoinState = true;
  bool _joined = false;
  bool _checkedIn = false;

  static const _appBarTitle = 'Request';
  static const _snackBarMsg = "You're helping!";
  static const _arrivedMsg = "You've arrived!";

  @override
  void initState() {
    super.initState();
    _syncJoinState();
  }

  Future<void> _syncJoinState() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty || widget.request.id.isEmpty) {
      if (mounted) setState(() => _loadingJoinState = false);
      return;
    }
    try {
      final req = await RequestService().getById(widget.request.id);
      if (mounted) {
        setState(() {
          _joined = req.assignedVolunteerIds.contains(uid);
          _loadingJoinState = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingJoinState = false);
    }
  }

  bool get _isCreator {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid != null &&
        uid.isNotEmpty &&
        uid == widget.request.createdBy;
  }

  void _openChat({required bool joined}) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ChatRoomScreen(
        requestId: widget.request.id,
        requestTitle: widget.request.title,
        requestCategory: widget.request.category,
        urgencyLabel: widget.request.urgencyLevel.name.toUpperCase(),
        currentUserId: uid,
        otherUserName: _isCreator
            ? 'Volunteer'
            : widget.request.requesterName,
        distanceLabel: formatDistance(widget.request.distanceKm),
        participantCount: 2,
        requestStatus: joined
            ? RequestStatus.matched
            : widget.request.requestStatus,
        messageService: MessageService(),
      ),
    ));
  }

  /// The single place a request joins the volunteer's Active list.
  Future<void> _onHelp() async {
    context.read<JoinedRequestsProvider>().join(widget.request);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && widget.request.id.isNotEmpty) {
      try {
        await RequestService().joinRequest(widget.request.id, uid);
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() => _joined = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(_snackBarMsg),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _confirmCheckIn() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => const CheckInDialog(),
    );
    if (ok != true || !mounted) return;
    await _onCheckIn();
  }

  Future<void> _onCheckIn() async {
    final ok = await performCheckIn(
      context: context,
      requestLat: widget.request.lat,
      requestLng: widget.request.lng,
    );
    if (!mounted || !ok) return;
    setState(() => _checkedIn = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(_arrivedMsg),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final joined = _joined ||
        context.watch<JoinedRequestsProvider>().isJoined(request.id);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_appBarTitle, style: AppTextStyles.appBarTitle),
            Text(request.category, style: AppTextStyles.appBarSubtitle),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _UrgencyBanner(urgencyLevel: request.urgencyLevel),
                  const SizedBox(height: AppSpacing.md),
                  _TitleSection(request: request),
                  const SizedBox(height: AppSpacing.md),
                  _MapPlaceholder(request: request),
                  const SizedBox(height: AppSpacing.md),
                  _RequesterCard(request: request),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
          if (_isCreator)
            _ChatBar(onChat: () => _openChat(joined: false)),
          if (!_isCreator && widget.showActions)
            _BottomBar(
              loading: _loadingJoinState,
              accepted: joined,
              checkedIn: _checkedIn,
              onHelp: _onHelp,
              onCheckIn: _confirmCheckIn,
              onChat: joined ? () => _openChat(joined: true) : null,
            ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _UrgencyBanner extends StatelessWidget {
  const _UrgencyBanner({required this.urgencyLevel});

  final UrgencyLevel urgencyLevel;

  @override
  Widget build(BuildContext context) {
    final String label = switch (urgencyLevel) {
      UrgencyLevel.critical => '● CRITICAL',
      UrgencyLevel.urgent => '▲ URGENT',
      UrgencyLevel.general => '✓ GENERAL',
    };
    final Color bg = switch (urgencyLevel) {
      UrgencyLevel.critical => AppColors.criticalBg,
      UrgencyLevel.urgent => AppColors.urgentBg,
      UrgencyLevel.general => AppColors.generalBg,
    };
    final Color textColor = switch (urgencyLevel) {
      UrgencyLevel.critical => AppColors.critical,
      UrgencyLevel.urgent => AppColors.urgent,
      UrgencyLevel.general => AppColors.general,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _TitleSection extends StatelessWidget {
  const _TitleSection({required this.request});

  final RequestDetailData request;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(request.title, style: AppTextStyles.headlineLarge),
        const SizedBox(height: AppSpacing.sm),
        Text(
          '◎ ${formatDistance(request.distanceKm)}  ·  ⏱ ${formatTimeAgo(request.postedAt)}',
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({required this.request});

  final RequestDetailData request;

  static const _caption = 'Approximate area shown for safety';
  static const _youLabel = 'YOU';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Stack(
          children: [
            NearbyRequestsMap(
              center: LatLng(request.lat, request.lng),
              radiusKm: 0.3,
              requests: [_toRequestModel(request)],
            ),
            Positioned(
              bottom: AppSpacing.sm,
              left: AppSpacing.md,
              right: AppSpacing.md,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_caption, style: AppTextStyles.caption),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                    child: const Text(
                      _youLabel,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
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
}

class _RequesterCard extends StatelessWidget {
  const _RequesterCard({required this.request});

  final RequestDetailData request;

  @override
  Widget build(BuildContext context) {
    final Color avatarColor = request.isAnonymous
        ? AppColors.textMuted
        : _avatarColorFromName(request.requesterName);
    final String? initial = request.isAnonymous
        ? null
        : request.requesterName.isNotEmpty
            ? request.requesterName[0].toUpperCase()
            : null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: avatarColor,
                child: initial != null
                    ? Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          request.requesterName,
                          style: AppTextStyles.titleMedium,
                        ),
                        if (request.isVerified) ...[
                          const SizedBox(width: AppSpacing.sm),
                          const _VerifiedBadge(),
                        ],
                      ],
                    ),
                    Text(
                      request.requesterLocation,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(request.description, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  static const _label = 'VERIFIED';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.successBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: AppColors.success, width: 0.5),
      ),
      child: const Text(
        _label,
        style: TextStyle(
          color: AppColors.success,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.loading,
    required this.accepted,
    required this.checkedIn,
    required this.onHelp,
    required this.onCheckIn,
    this.onChat,
  });

  final bool loading;
  final bool accepted;
  final bool checkedIn;
  final VoidCallback onHelp;
  final VoidCallback onCheckIn;
  final VoidCallback? onChat;

  static const _helpLabel = "I'll help";
  static const _checkInLabel = 'Check in';
  static const _checkedInLabel = 'Checked in';

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    if (loading) {
      return Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md + bottomInset,
        ),
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        ),
        child: SizedBox(
          height: 48,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final Color btnColor = checkedIn
        ? AppColors.successBg
        : accepted
            ? AppColors.primaryAccepted
            : AppColors.primary;

    final VoidCallback? tapAction = checkedIn
        ? null
        : accepted
            ? onCheckIn
            : onHelp;

    final mainBtn = GestureDetector(
      onTap: tapAction,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 48,
        decoration: BoxDecoration(
          color: btnColor,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: checkedIn
                ? Row(
                    key: const ValueKey(2),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text(_checkedInLabel, style: AppTextStyles.button),
                    ],
                  )
                : accepted
                    ? Row(
                        key: const ValueKey(1),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_pin, color: Colors.white, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Text(_checkInLabel, style: AppTextStyles.button),
                        ],
                      )
                    : Row(
                        key: const ValueKey(0),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.volunteer_activism, color: Colors.white, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Text(_helpLabel, style: AppTextStyles.button),
                        ],
                      ),
          ),
        ),
      ),
    );

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md + bottomInset,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: accepted
          ? Row(
              children: [
                GestureDetector(
                  onTap: onChat,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.border, width: 1),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: mainBtn),
              ],
            )
          : Row(
              children: [Expanded(child: mainBtn)],
            ),
    );
  }
}

class _ChatBar extends StatelessWidget {
  const _ChatBar({required this.onChat});

  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md + bottomInset,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: GestureDetector(
        onTap: onChat,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.chat_bubble_outline, color: AppColors.textPrimary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text('Chat', style: AppTextStyles.button),
            ],
          ),
        ),
      ),
    );
  }
}
