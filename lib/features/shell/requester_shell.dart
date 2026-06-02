import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/constants.dart';
import '../../models/user_model.dart';
import '../../providers/providers.dart';
import '../../widgets/role_pill.dart';
import '../../widgets/role_switch_sheet.dart';
import '../widgets/app_widgets.dart';

/// PLACEHOLDER requester home.
///
/// The requester (civilian) side is out of scope for this pass — a teammate
/// builds the posting flow. This only confirms the role gate routes correctly
/// and lets the user switch back to volunteer mode.
class RequesterShell extends StatelessWidget {
  const RequesterShell({super.key});

  void _showRoleSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => RoleSwitchSheet(
        currentRole: RoleType.requester,
        onRoleSelected: (role) {
          if (role == RoleType.volunteer) {
            context.read<AuthProvider>().switchRole(UserRole.volunteer);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            children: [
              const Spacer(),
              const IconTile(
                icon: Icons.sos_outlined,
                color: AppColors.requester,
                size: 64,
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Requester home — coming soon',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'Posting help requests lands here next. For now you can switch '
                'back to volunteer mode.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Switch to volunteer',
                onPressed: () => _showRoleSheet(context),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => context.read<AuthProvider>().signOut(),
                child: const Text(
                  'Sign out',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
