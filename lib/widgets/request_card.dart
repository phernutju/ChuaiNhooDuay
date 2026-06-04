import 'package:flutter/material.dart';
import 'package:we_are_ready/constants/constants.dart';
import 'package:we_are_ready/features/request_detail/mock/request_mock_data.dart';
import 'package:we_are_ready/models/request_model.dart';
import 'package:we_are_ready/utils/time_ago.dart';

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

const _kLabelRespond = 'Respond';
const _kLabelView = 'View';
const _kLabelYourPost = 'Your Post';

enum _CardAction { respond, view, yourPost }

/// Reusable request card for the volunteer feed (and any future request list).
///
/// Renders a [RequestDetailData] as a tappable card: severity badge,
/// distance/elapsed meta, category, title, requester chip, and a context-aware
/// action button:
///   - "Your Post"  — [isOwner] is true; taps open detail only
///   - "View"       — user has already joined ([isJoined] is true)
///   - "Respond"    — user has not joined and is not the owner
///
/// [onTap] fires when the card body is tapped (open detail). [onRespond], when
/// provided, fires instead for the action button so the feed can "join" the
/// request; it falls back to [onTap] when omitted.
class RequestCard extends StatelessWidget {
  const RequestCard({
    super.key,
    required this.request,
    required this.onTap,
    this.onRespond,
    this.isJoined = false,
    this.isOwner = false,
  });

  final RequestDetailData request;
  final VoidCallback onTap;
  final VoidCallback? onRespond;
  /// True when the current user's id is in the request's assignedVolunteerIds.
  final bool isJoined;
  /// True when the current user is the request creator (createdBy == currentUserId).
  /// Takes priority over [isJoined]; shows "Your Post" and taps open detail only.
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final action = isOwner
        ? _CardAction.yourPost
        : isJoined
            ? _CardAction.view
            : _CardAction.respond;

    // Owner always opens detail; others use onRespond if provided.
    final actionTap = action == _CardAction.yourPost
        ? onTap
        : (onRespond ?? onTap);

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
                _SeverityBadge(level: request.urgencyLevel),
                const Spacer(),
                _MetaText(
                  icon: Icons.place_outlined,
                  text: formatDistance(request.distanceKm),
                ),
                const SizedBox(width: AppSpacing.sm + 2),
                _MetaText(
                  icon: Icons.access_time_rounded,
                  text: formatTimeAgo(request.postedAt),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md - 4),
            Text(
              request.category.toUpperCase(),
              style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1.0),
            ),
            const SizedBox(height: 6),
            Text(
              request.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            if (request.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                request.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall,
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _RequesterChip(request: request),
                const SizedBox(width: AppSpacing.sm),
                switch (action) {
                  _CardAction.yourPost => _YourPostButton(onTap: actionTap),
                  _CardAction.view => _ViewButton(onTap: actionTap),
                  _CardAction.respond => _RespondButton(onTap: actionTap),
                },
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge({required this.level});

  final UrgencyLevel level;

  @override
  Widget build(BuildContext context) {
    final (label, fg, bg) = switch (level) {
      UrgencyLevel.critical => ('CRITICAL', AppColors.critical, AppColors.criticalBg),
      UrgencyLevel.urgent => ('URGENT', AppColors.urgent, AppColors.urgentBg),
      UrgencyLevel.general => ('GENERAL', AppColors.general, AppColors.generalBg),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(text, style: AppTextStyles.bodySmall),
      ],
    );
  }
}

class _RequesterChip extends StatelessWidget {
  const _RequesterChip({required this.request});

  final RequestDetailData request;

  @override
  Widget build(BuildContext context) {
    final color = request.isAnonymous
        ? AppColors.textMuted
        : _avatarColorFromName(request.requesterName);
    final initial = request.isAnonymous || request.requesterName.isEmpty
        ? null
        : request.requesterName[0].toUpperCase();

    return Expanded(
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color,
            child: initial != null
                ? Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : const Icon(Icons.person, color: Colors.white, size: 16),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.requesterName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  request.requesterLocation,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RespondButton extends StatelessWidget {
  const _RespondButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.critical,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _kLabelRespond,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 6),
            Icon(Icons.arrow_forward, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}

class _ViewButton extends StatelessWidget {
  const _ViewButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _kLabelView,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 6),
            Icon(Icons.arrow_forward, color: AppColors.textSecondary, size: 16),
          ],
        ),
      ),
    );
  }
}

class _YourPostButton extends StatelessWidget {
  const _YourPostButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline, color: AppColors.textMuted, size: 14),
            SizedBox(width: 4),
            Text(
              _kLabelYourPost,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
