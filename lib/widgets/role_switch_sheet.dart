import 'package:flutter/material.dart';
import 'package:we_are_ready/constants/constants.dart';
import 'package:we_are_ready/widgets/role_pill.dart';

class RoleSwitchSheet extends StatelessWidget {
  const RoleSwitchSheet({
    super.key,
    required this.currentRole,
    required this.onRoleSelected,
  });

  final RoleType currentRole;
  final ValueChanged<RoleType> onRoleSelected;

  static const _title = 'Switch role';
  static const _subtitle = 'No re-login. Your history stays intact.';
  static const _footer = 'One account, both modes. Your history stays.';

  static const _volunteerTitle = 'Volunteer mode';
  static const _volunteerSubtitle = 'Browse requests, accept tasks';
  static const _requesterTitle = 'Requester mode';
  static const _requesterSubtitle = 'Post a request, chat with helpers';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: _DragHandle()),
              const SizedBox(height: AppSpacing.lg),
              Text(_title, style: AppTextStyles.headlineLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(_subtitle, style: AppTextStyles.bodySmall),
              const SizedBox(height: AppSpacing.lg),
              _RoleOptionCard(
                title: _volunteerTitle,
                subtitle: _volunteerSubtitle,
                icon: Icons.volunteer_activism,
                isCurrentRole: currentRole == RoleType.volunteer,
                accentColor: AppColors.success,
                iconBgColor: AppColors.successBg,
                onTap: () {
                  onRoleSelected(RoleType.volunteer);
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              _RoleOptionCard(
                title: _requesterTitle,
                subtitle: _requesterSubtitle,
                icon: Icons.sos,
                isCurrentRole: currentRole == RoleType.requester,
                accentColor: AppColors.critical,
                iconBgColor: AppColors.criticalBg,
                onTap: () {
                  onRoleSelected(RoleType.requester);
                  Navigator.of(context).pop();
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              Center(
                child: Text(_footer, style: AppTextStyles.caption),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
    );
  }
}

class _RoleOptionCard extends StatelessWidget {
  const _RoleOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isCurrentRole,
    required this.accentColor,
    required this.iconBgColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isCurrentRole;
  final Color accentColor;
  final Color iconBgColor;
  final VoidCallback onTap;

  static const _currentLabel = 'CURRENT';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: isCurrentRole
                  ? Border.all(color: accentColor, width: 1.5)
                  : Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(icon, color: accentColor, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.titleMedium),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppTextStyles.bodySmall),
                    ],
                  ),
                ),
                if (!isCurrentRole)
                  const Icon(
                    Icons.arrow_forward,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
              ],
            ),
          ),
          if (isCurrentRole)
            Positioned(
              top: AppSpacing.sm,
              right: AppSpacing.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: const Text(
                  _currentLabel,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
