import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/constants.dart';
import '../../models/request_model.dart';
import '../../providers/providers.dart';
import '../request_detail/mock/request_mock_data.dart';
import '../request_detail/screens/request_detail_screen.dart';

/// ACTIVE tab — the requests the volunteer has tapped "Respond" on. Sourced
/// from [JoinedRequestsProvider]; empty until the volunteer joins something.
///
/// Each row can be "checked-in" (confirms the volunteer arrived on-site) behind
/// a confirmation dialog to avoid accidental taps.
class ActiveScreen extends StatefulWidget {
  const ActiveScreen({super.key});

  @override
  State<ActiveScreen> createState() => _ActiveScreenState();
}

class _ActiveScreenState extends State<ActiveScreen> {
  void _openRequest(RequestDetailData request) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RequestDetailScreen(request: request),
      ),
    );
  }

  /// Confirms before checking in, so a stray tap doesn't change state.
  Future<void> _confirmCheckIn(RequestDetailData request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => const _CheckInDialog(),
    );

    if (confirmed != true || !mounted) return;
    context.read<JoinedRequestsProvider>().checkIn(request.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Checked in — you're on your way"),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = context.watch<JoinedRequestsProvider>().all;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Text('Active', style: AppTextStyles.headlineLarge),
            ),
            Expanded(
              child: items.isEmpty
                  ? const _EmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        AppSpacing.md,
                      ),
                      itemCount: items.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm + 2),
                      itemBuilder: (_, i) => _JoinedRow(
                        joined: items[i],
                        onTap: () => _openRequest(items[i].request),
                        onCheckIn: items[i].status == JoinedStatus.active
                            ? () => _confirmCheckIn(items[i].request)
                            : null,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A compact summary row for a joined request: severity dot, title, location,
/// status pill, the time the volunteer joined, and a check-in action.
class _JoinedRow extends StatelessWidget {
  const _JoinedRow({
    required this.joined,
    required this.onTap,
    this.onCheckIn,
  });

  final JoinedRequest joined;
  final VoidCallback onTap;
  final VoidCallback? onCheckIn;

  static String _timeAgo(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final request = joined.request;
    final dotColor = switch (request.urgencyLevel) {
      UrgencyLevel.critical => AppColors.critical,
      UrgencyLevel.urgent => AppColors.urgent,
      UrgencyLevel.general => AppColors.general,
    };
    final checkedIn = joined.status == JoinedStatus.checkedIn;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    request.category.toUpperCase(),
                    style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1.0),
                  ),
                ),
                _StatusPill(status: joined.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              request.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(
                  Icons.place_outlined,
                  size: 14,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 3),
                Expanded(
                  child: Text(
                    request.requesterLocation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Joined ${_timeAgo(joined.joinedAt)}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm + 2),
            if (checkedIn)
              const _CheckedInChip()
            else
              _CheckInButton(onTap: onCheckIn),
          ],
        ),
      ),
    );
  }
}

class _CheckInButton extends StatelessWidget {
  const _CheckInButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 14, 173, 9),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: const Text(
          'Check-in',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CheckedInChip extends StatelessWidget {
  const _CheckedInChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.navActiveBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.navActive, width: 1),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: AppColors.navActive, size: 16),
          SizedBox(width: 6),
          Text(
            'Checked in',
            style: TextStyle(
              color: AppColors.navActive,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Polished dark confirmation dialog for checking in. Pops `true` on confirm,
/// `false`/null on cancel — the caller performs the actual state change.
class _CheckInDialog extends StatelessWidget {
  const _CheckInDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: AppColors.navActiveBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.where_to_vote_rounded,
                color: AppColors.navActive,
                size: 28,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Check in?',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              "Confirm you've arrived to help with this request.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navActive,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: const Text(
                  'Check in',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final JoinedStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (status) {
      JoinedStatus.active => ('ACTIVE', AppColors.success, AppColors.successBg),
      JoinedStatus.checkedIn =>
        ('CHECKED IN', AppColors.navActive, AppColors.navActiveBg),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.bolt_outlined, color: AppColors.textMuted, size: 48),
            SizedBox(height: AppSpacing.md),
            Text(
              "You haven't joined any requests yet.\nTap “Respond” on the feed to help out.",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
