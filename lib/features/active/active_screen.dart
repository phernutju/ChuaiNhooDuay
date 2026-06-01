import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/constants.dart';
import '../../models/request_model.dart';
import '../../providers/providers.dart';
import '../request_detail/mock/request_mock_data.dart';
import '../request_detail/screens/request_detail_screen.dart';
import '../widgets/app_widgets.dart';
import '../../utils/check_in_service.dart';

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

  static const _arrivedMsg = "Checked in — you're on your way";

  /// Confirms then verifies location before marking checked-in.
  Future<void> _confirmCheckIn(RequestDetailData request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => const CheckInDialog(),
    );
    if (confirmed != true || !mounted) return;

    final ok = await performCheckIn(
      context: context,
      requestLat: request.lat,
      requestLng: request.lng,
    );
    if (!mounted || !ok) return;
    context.read<JoinedRequestsProvider>().checkIn(request.id);
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
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.primaryAccepted,
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
        color: AppColors.successBg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.success, width: 1),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle, color: AppColors.success, size: 16),
          SizedBox(width: 6),
          Text(
            'Checked in',
            style: TextStyle(
              color: AppColors.success,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
        ('CHECKED IN', AppColors.success, AppColors.successBg),
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
