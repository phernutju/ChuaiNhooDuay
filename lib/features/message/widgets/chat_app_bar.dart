import 'package:flutter/material.dart';
import 'package:we_are_ready/constants/constants.dart';
import 'package:we_are_ready/models/request_model.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChatAppBar({
    super.key,
    required this.roomTitle,
    required this.roomSubtitle,
    required this.urgencyLevel,
    required this.isClosed,
    this.onBack,
    this.onMore,
  });

  final String roomTitle;
  final String roomSubtitle;
  final UrgencyLevel urgencyLevel;
  final bool isClosed;
  final VoidCallback? onBack;
  final VoidCallback? onMore;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: onBack ?? () => Navigator.maybePop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          _AppBarAvatar(initial: roomTitle.isNotEmpty ? roomTitle[0] : '?'),
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    isClosed
                        ? const _ClosedBadge()
                        : _UrgencyBadge(level: urgencyLevel),
                  ],
                ),
                Text(
                  roomSubtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: onMore,
        ),
      ],
    );
  }
}

// ─── Avatar circle in app bar ─────────────────────────────────────────────────

class _AppBarAvatar extends StatelessWidget {
  const _AppBarAvatar({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: AppColors.border,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Urgency badge ────────────────────────────────────────────────────────────

class _UrgencyBadge extends StatelessWidget {
  const _UrgencyBadge({required this.level});

  final UrgencyLevel level;

  Color get _bg {
    switch (level) {
      case UrgencyLevel.critical:
        return AppColors.volunteer;
      case UrgencyLevel.urgent:
        return AppColors.urgent;
      case UrgencyLevel.general:
        return AppColors.border;
    }
  }

  String get _label {
    switch (level) {
      case UrgencyLevel.critical:
        return 'CRITICAL';
      case UrgencyLevel.urgent:
        return 'URGENT';
      case UrgencyLevel.general:
        return 'GENERAL';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── Closed badge ─────────────────────────────────────────────────────────────

class _ClosedBadge extends StatelessWidget {
  const _ClosedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'CLOSED',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
