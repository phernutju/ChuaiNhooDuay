import 'package:flutter/material.dart';
import 'package:we_are_ready/constants/constants.dart';

class NotificationIconBadge extends StatelessWidget {
  const NotificationIconBadge({
    super.key,
    required this.recipientType,
    required this.notificationType,
  });

  final String recipientType;
  final String notificationType;

  static const double _size = 40;
  static const double _radius = 10;

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(_radius),
      ),
      child: Icon(_icon(), color: color, size: 20),
    );
  }

  Color _color() {
    switch (notificationType) {
      case 'critical':
        return AppColors.critical;
      case 'urgent':
        return AppColors.urgent;
      case 'request_assigned':
        return const Color(0xFF1565C0);
      case 'request_created':
        return AppColors.brand;
      case 'chat_message':
        return const Color(0xFF00695C);
      case 'evacuation_notice':
        return const Color(0xFFB71C1C);
      default:
        return AppColors.textMuted;
    }
  }

  IconData _icon() {
    switch (notificationType) {
      case 'critical':
      case 'urgent':
        return Icons.warning_amber_rounded;
      case 'request_assigned':
        return Icons.check_circle_outline;
      case 'request_created':
        return Icons.assignment_outlined;
      case 'chat_message':
        return Icons.chat_bubble_outline;
      case 'evacuation_notice':
        return Icons.crisis_alert;
      default:
        return Icons.info_outline;
    }
  }
}
