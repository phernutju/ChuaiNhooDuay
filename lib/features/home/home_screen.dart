import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../constants/constants.dart';
import '../../models/user_model.dart';
import '../../providers/providers.dart';
import '../widgets/app_widgets.dart';

/// Placeholder home feed shown after onboarding completes.
///
/// The fully styled "Nearby requests" feed (see main_screen.png) is a later
/// pass; this confirms the auth flow lands the user correctly.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    final isVolunteer = user?.role == UserRole.volunteer;
    final displayName = (user?.name?.isNotEmpty ?? false) ? user!.name! : 'there';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  const BrandLogo(size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Nearby requests',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '2 KM RADIUS · LIVE',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.go(AppRoutes.notifications),
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.textPrimary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  _RolePill(isVolunteer: isVolunteer),
                ],
              ),
              const Spacer(),
              Center(
                child: Column(
                  children: [
                    IconTile(
                      icon: Icons.explore_outlined,
                      color: isVolunteer
                          ? AppColors.volunteer
                          : AppColors.requester,
                      size: 64,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Welcome, $displayName!',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isVolunteer
                          ? "You're in volunteer mode. The live request feed "
                              'lands here next.'
                          : "You're in requester mode. Posting a request lands "
                              'here next.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Sign out',
                onPressed: () => context.read<AuthProvider>().signOut(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  const _RolePill({required this.isVolunteer});

  final bool isVolunteer;

  @override
  Widget build(BuildContext context) {
    final color = isVolunteer ? AppColors.volunteer : AppColors.requester;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        isVolunteer ? 'VOLUNTEER' : 'REQUESTER',
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}