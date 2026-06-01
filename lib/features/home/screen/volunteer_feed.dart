import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../constants/constants.dart';
import '../../../models/request_model.dart';
import '../../../models/user_model.dart';
import '../../../providers/providers.dart';
import '../../../widgets/request_card.dart';
import '../../../widgets/role_pill.dart';
import '../../../widgets/role_switch_sheet.dart';
import '../../request_detail/mock/request_mock_data.dart';

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

  bool matches(RequestDetailData r) => switch (this) {
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
class VolunteerFeedScreen extends StatefulWidget {
  const VolunteerFeedScreen({super.key});

  @override
  State<VolunteerFeedScreen> createState() => _VolunteerFeedScreenState();
}

class _VolunteerFeedScreenState extends State<VolunteerFeedScreen> {
  _FeedFilter _filter = _FeedFilter.all;
  RoleType _currentRole = RoleType.volunteer;
  late List<RequestDetailData> _requests = List.of(mockFeedRequests);

  Future<void> _refresh() async {
    // No backend yet — reseed from the mock source so pull-to-refresh feels live.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() => _requests = List.of(mockFeedRequests));
  }

  void _showRoleSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => RoleSwitchSheet(
        currentRole: _currentRole,
        onRoleSelected: (role) {
          // Persisting the role flips the root gate to the matching shell.
          if (role == RoleType.requester) {
            context.read<AuthProvider>().switchRole(UserRole.civilian);
          } else {
            setState(() => _currentRole = role);
          }
        },
      ),
    );
  }

  /// Card tap and "Respond" both open the detail screen — the join action
  /// lives there now, so the feed only navigates (no Active mutation here).
  /// The id goes through the router; the model rides along as `extra` so the
  /// detail screen renders instantly without a re-fetch.
  void _openRequest(RequestDetailData request) {
    context.push('${AppRoutes.requestDetail}/${request.id}', extra: request);
  }

  int _countFor(_FeedFilter filter) =>
      _requests.where(filter.matches).length;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    final visible = _requests.where(_filter.matches).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _FeedHeader(
              user: user,
              currentRole: _currentRole,
              onRoleTap: _showRoleSheet,
              onBellTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications')),
              ),
            ),
            _FilterBar(
              selected: _filter,
              countFor: _countFor,
              onSelected: (f) => setState(() => _filter = f),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                color: AppColors.success,
                backgroundColor: AppColors.surface,
                child: visible.isEmpty
                    ? const _EmptyState()
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.xs,
                          AppSpacing.md,
                          AppSpacing.md,
                        ),
                        itemCount: visible.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.md - 4),
                        itemBuilder: (_, i) => RequestCard(
                          request: visible[i],
                          onTap: () => _openRequest(visible[i]),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
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
