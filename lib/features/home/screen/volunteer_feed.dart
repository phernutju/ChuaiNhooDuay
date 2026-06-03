import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as pkg_provider;

import '../../../constants/constants.dart';
import '../../../models/request_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/providers.dart';
import '../../../widgets/request_card.dart';
import '../../../widgets/role_pill.dart';
import '../../../widgets/role_switch_sheet.dart';
import '../../request_detail/mock/request_mock_data.dart';
import '../../requester/requester_controller.dart';

/// Stable per-name avatar tint so the same requester always reads the same
/// colour across the feed and the detail screen.
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

/// Feed filters shown as horizontally scrollable chips.
enum _FeedFilter { all, critical, urgent, general }

extension on _FeedFilter {
  String get label => switch (this) {
        _FeedFilter.all => 'All',
        _FeedFilter.critical => 'Critical',
        _FeedFilter.urgent => 'Urgent',
        _FeedFilter.general => 'General',
      };

  /// Leading dot colour; null for "All" (no dot).
  Color? get dotColor => switch (this) {
        _FeedFilter.all => null,
        _FeedFilter.critical => AppColors.critical,
        _FeedFilter.urgent => AppColors.urgent,
        _FeedFilter.general => AppColors.general,
      };

  bool matches(RequestModel r) => switch (this) {
        _FeedFilter.all => true,
        _FeedFilter.critical => r.urgencyLevel == UrgencyLevel.critical,
        _FeedFilter.urgent => r.urgencyLevel == UrgencyLevel.urgent,
        _FeedFilter.general => r.urgencyLevel == UrgencyLevel.general,
      };
}

/// "Nearby Requests" — the volunteer-facing feed of open help requests.
///
/// Layout follows .claude/volunteer_screen: profile-avatar header, filter
/// chips, and a pull-to-refresh request list. Cards reuse [RequestDetailData]
/// and route into the existing request-detail feature.
class VolunteerFeedScreen extends ConsumerStatefulWidget {
  const VolunteerFeedScreen({super.key});

  @override
  ConsumerState<VolunteerFeedScreen> createState() =>
      _VolunteerFeedScreenState();
}

class _VolunteerFeedScreenState extends ConsumerState<VolunteerFeedScreen> {
  _FeedFilter _filter = _FeedFilter.all;

  RequestDetailData _toDetailData(RequestModel r) => RequestDetailData(
        id: r.id,
        category: r.requestType.name,
        urgencyLevel: r.urgencyLevel,
        title: r.title,
        distanceKm: 0,
        minutesAgo: DateTime.now().difference(r.createdAt).inMinutes,
        requesterName: r.isAnonymous
            ? 'Anonymous'
            : (r.requesterName.isNotEmpty ? r.requesterName : 'Requester'),
        requesterLocation: r.location.address,
        isAnonymous: r.isAnonymous,
        isVerified: false,
        description: r.description,
        skillsNeeded: const [],
        lat: r.location.coordinates.latitude,
        lng: r.location.coordinates.longitude,
      );

  void _showRoleSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => RoleSwitchSheet(
        currentRole: RoleType.volunteer,
        onRoleSelected: (role) {
          if (role == RoleType.requester) {
            context
                .read<AuthProvider>()
                .switchRole(UserRole.civilian);
          }
        },
      ),
    );
  }

  void _openRequest(RequestDetailData data) {
    context.push('${AppRoutes.requestDetail}/${data.id}', extra: data);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    final requestsAsync = ref.watch(openRequestsProvider);

    return requestsAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.success),
        ),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Text('Error: $e',
              style: const TextStyle(color: AppColors.critical)),
        ),
      ),
      data: (requests) {
        final visible = requests.where(_filter.matches).toList();
        final detailList = visible.map(_toDetailData).toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                _FeedHeader(
                  user: user,
                  currentRole: RoleType.volunteer,
                  onRoleTap: _showRoleSheet,
                  onBellTap: () => context.go(AppRoutes.notifications),
                ),
                _FilterBar(
                  selected: _filter,
                  countFor: (f) => requests.where(f.matches).length,
                  onSelected: (f) => setState(() => _filter = f),
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {},
                    color: AppColors.success,
                    backgroundColor: AppColors.surface,
                    child: detailList.isEmpty
                        ? const _EmptyState()
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.md,
                              AppSpacing.xs,
                              AppSpacing.md,
                              AppSpacing.md,
                            ),
                            itemCount: detailList.length,
                            separatorBuilder: (_, i) =>
                                const SizedBox(height: AppSpacing.md - 4),
                            itemBuilder: (_, i) => RequestCard(
                              request: detailList[i],
                              onTap: () => _openRequest(detailList[i]),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Header ─────────────────────────────────────────────────────────────────

class _FeedHeader extends StatelessWidget {
  const _FeedHeader({
    required this.user,
    required this.currentRole,
    required this.onRoleTap,
    required this.onBellTap,
  });

  final UserModel? user;
  final RoleType currentRole;
  final VoidCallback onRoleTap;
  final VoidCallback onBellTap;

  @override
  Widget build(BuildContext context) {
    final name = (user?.name?.isNotEmpty ?? false) ? user!.name! : null;
    // UserModel stores one full name; split it into first / last lines.
    final parts = (name ?? '').split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final firstName = parts.isNotEmpty ? parts.first : 'Volunteer';
    final lastName = parts.length > 1 ? parts.skip(1).join(' ') : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          _ProfileAvatar(name: name),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  firstName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                if (lastName != null)
                  Text(
                    lastName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _NotificationBell(hasUnread: true, onTap: onBellTap),
          const SizedBox(width: AppSpacing.sm),
          RolePill(currentRole: currentRole, onTap: onRoleTap),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.name});

  final String? name;

  @override
  Widget build(BuildContext context) {
    // UserModel has no photoUrl yet, so we always render the name initial.
    final initial = (name != null && name!.isNotEmpty)
        ? name![0].toUpperCase()
        : '?';
    final color =
        name != null ? _avatarColorFromName(name!) : AppColors.textMuted;

    return GestureDetector(
      onTap: () {}, // No profile route yet.
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.hasUnread, required this.onTap});

  final bool hasUnread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
            if (hasUnread)
              Positioned(
                top: 10,
                right: 11,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.critical,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Filter bar ───────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.countFor,
    required this.onSelected,
  });

  final _FeedFilter selected;
  final int Function(_FeedFilter) countFor;
  final ValueChanged<_FeedFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: _FeedFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final filter = _FeedFilter.values[i];
          return _FilterChip(
            label: filter.label,
            count: countFor(filter),
            dotColor: filter.dotColor,
            selected: filter == selected,
            onTap: () => onSelected(filter),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.dotColor,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color? dotColor;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = selected ? AppColors.background : AppColors.textSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md - 2,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.textPrimary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          border: Border.all(
            color: selected ? Colors.transparent : AppColors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$count',
              style: TextStyle(
                color: selected
                    ? AppColors.background.withValues(alpha: 0.6)
                    : AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        const Icon(
          Icons.inbox_outlined,
          color: AppColors.textMuted,
          size: 48,
        ),
        const SizedBox(height: AppSpacing.md),
        const Center(
          child: Text(
            'No requests match this filter',
            style: AppTextStyles.bodySmall,
          ),
        ),
      ],
    );
  }
}
