import 'package:flutter/material.dart';
import 'package:we_are_ready/constants/constants.dart';

enum RoleType { volunteer, requester }

class RolePill extends StatelessWidget {
  const RolePill({
    super.key,
    required this.currentRole,
    required this.onTap,
  });

  final RoleType currentRole;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isVolunteer = currentRole == RoleType.volunteer;
    final accentColor = isVolunteer ? AppColors.success : AppColors.critical;
    final bgColor = isVolunteer ? AppColors.successBg : AppColors.criticalBg;
    final icon = isVolunteer ? Icons.volunteer_activism : Icons.sos;
    final label = isVolunteer ? 'VOLUNTEER' : 'REQUESTER';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: accentColor, size: 13),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: accentColor,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              child: const Icon(
                Icons.swap_vert,
                color: AppColors.textSecondary,
                size: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
