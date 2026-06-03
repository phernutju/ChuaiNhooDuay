import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/constants.dart';
import 'app_lock_provider.dart';
import 'change_pin_screen.dart';

/// Embeddable App Lock settings section.
/// Drop into any settings page — requires a Navigator ancestor
/// (satisfied by being inside the main MaterialApp.router).
///
/// App Lock is now mandatory — the enable/disable toggle has been removed.
/// This section exposes biometric settings and PIN change only.
class AppLockSettings extends StatelessWidget {
  const AppLockSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final lock = context.watch<AppLockProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('SETTING', style: AppTextStyles.labelSmall),
        const SizedBox(height: AppSpacing.sm),
        if (lock.biometricAvailable) ...[
          _SettingsTile(
            icon: Icons.fingerprint,
            title: 'Biometric Unlock',
            subtitle: 'Use fingerprint or face as a shortcut',
            trailing: Switch.adaptive(
              value: lock.biometricEnabled,
              activeThumbColor: AppColors.navActive,
              activeTrackColor: AppColors.navActiveBg,
              onChanged: lock.setBiometricEnabled,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        _SettingsTile(
          icon: Icons.pin_outlined,
          title: 'Change PIN',
          subtitle: 'Update your 4-digit unlock PIN',
          trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute(
              builder: (_) => const ChangePinScreen(),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleMedium.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
