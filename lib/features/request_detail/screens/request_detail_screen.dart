import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:we_are_ready/constants/constants.dart';
import 'package:we_are_ready/features/request_detail/mock/request_mock_data.dart';
import 'package:we_are_ready/providers/providers.dart';
import 'package:we_are_ready/widgets/role_pill.dart';
import 'package:we_are_ready/widgets/role_switch_sheet.dart';
import 'package:we_are_ready/models/request_model.dart';

Color _avatarColorFromName(String name) {
  const colors = [
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFF9C27B0),
    Color(0xFFFF9800),
    Color(0xFF00BCD4),
    Color(0xFFE91E63),
  ];
  final hash = name.codeUnits.fold(0, (sum, e) => sum + e);
  return colors[hash % colors.length];
}

class RequestDetailScreen extends StatefulWidget {
  const RequestDetailScreen({super.key, required this.request});

  final RequestDetailData request;

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  RoleType _currentRole = RoleType.volunteer;

  static const _appBarTitle = 'Request';
  static const _snackBarMsg = "You're helping — added to Active";

  /// The single place a request joins the volunteer's Active list.
  void _onHelp() {
    context.read<JoinedRequestsProvider>().join(widget.request);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(_snackBarMsg),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showRoleSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => RoleSwitchSheet(
        currentRole: _currentRole,
        onRoleSelected: (role) => setState(() => _currentRole = role),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final joined = context.watch<JoinedRequestsProvider>().isJoined(request.id);
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
        actions: [
          IconButton(
            icon: const Icon(
              Icons.share_outlined,
              color: AppColors.textPrimary,
            ),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: RolePill(
                currentRole: _currentRole,
                onTap: _showRoleSheet,
              ),
            ),
          ),
        ],
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
                  const _MapPlaceholder(),
                  const SizedBox(height: AppSpacing.md),
                  _RequesterCard(request: request),
                  const SizedBox(height: AppSpacing.md),
                  _SkillsSection(skills: request.skillsNeeded),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
          _BottomBar(
            accepted: joined,
            onHelp: _onHelp,
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
          '◎ ${request.distanceKm} km away  ·  ⏱ ${request.minutesAgo}m ago',
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  static const _caption = 'Approximate area shown for safety';
  static const _youLabel = 'YOU';

  @override
  Widget build(BuildContext context) {
    // TODO: replace with MapWidget from Feature E (Shayanis)
    // MapWidget(lat: request.lat, lng: request.lng)
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Stack(
        children: [
          const Center(
            child: Icon(
              Icons.location_pin,
              color: AppColors.critical,
              size: 40,
            ),
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
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
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

class _SkillsSection extends StatelessWidget {
  const _SkillsSection({required this.skills});

  final List<String> skills;

  static const _sectionLabel = 'SKILLS NEEDED';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(_sectionLabel, style: AppTextStyles.labelSmall),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: skills.map((s) => _SkillChip(skill: s)).toList(),
        ),
      ],
    );
  }
}

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.skill});

  final String skill;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm - 2,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            skill,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.accepted, required this.onHelp});

  final bool accepted;
  final VoidCallback onHelp;

  static const _acceptedLabel = '✓  Joined';

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
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.chat_bubble_outline,
                color: AppColors.textPrimary,
                size: 20,
              ),
              onPressed: () {},
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: GestureDetector(
              onTap: accepted ? null : onHelp,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 48,
                decoration: BoxDecoration(
                  color: accepted
                      ? AppColors.primaryAccepted
                      : const Color(0xFFE8453C),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: accepted
                        ? Text(
                            _acceptedLabel,
                            key: const ValueKey(true),
                            style: AppTextStyles.button,
                          )
                        : Row(
                            key: const ValueKey(false),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.volunteer_activism, color: Colors.white, size: 20),
                              const SizedBox(width: AppSpacing.sm),
                              Text("I'll help", style: AppTextStyles.button),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
