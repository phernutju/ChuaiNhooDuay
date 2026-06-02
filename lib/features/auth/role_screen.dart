import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../constants/constants.dart';
import '../../models/user_model.dart';
import '../../providers/providers.dart';
import '../widgets/app_widgets.dart';

/// Profile step 2: choose between volunteer ("I can help") and civilian
/// ("I need help"). Selecting a card finalizes onboarding.
class RoleScreen extends StatefulWidget {
  const RoleScreen({super.key});

  @override
  State<RoleScreen> createState() => _RoleScreenState();
}

class _RoleScreenState extends State<RoleScreen> {
  UserRole? _submitting;

  Future<void> _choose(UserRole role) async {
    if (_submitting != null) return;
    setState(() => _submitting = role);
    try {
      await context.read<AuthProvider>().completeOnboarding(role);
      // Success → router redirect sends the user to the home feed.
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save your profile: $e'),
          backgroundColor: AppColors.critical,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  BackTile(onTap: () => context.pop()),
                  const SizedBox(width: 14),
                  const Text(
                    'STEP 2 OF 2 · CHOOSE YOUR ROLE',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'How are you here today?',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "You can swap anytime — there's a one-tap toggle in the nav bar.",
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              _RoleCard(
                accent: AppColors.volunteer,
                icon: Icons.favorite_outline,
                title: 'I can help',
                mode: 'VOLUNTEER MODE',
                description:
                    'See requests near you and respond to ones you can take '
                    'in minutes.',
                tags: const ['First aid', 'Transport', 'Food', 'Shelter', '+4 more'],
                loading: _submitting == UserRole.volunteer,
                disabled: _submitting != null,
                onTap: () => _choose(UserRole.volunteer),
              ),
              const SizedBox(height: 16),
              _RoleCard(
                accent: AppColors.requester,
                icon: Icons.support_outlined,
                title: 'I need help',
                mode: 'REQUESTER MODE',
                description:
                    'Post a request in 3 taps. Nearby volunteers see it within '
                    '10 seconds.',
                liveLabel: '147 volunteers online within 2 km',
                loading: _submitting == UserRole.civilian,
                disabled: _submitting != null,
                onTap: () => _choose(UserRole.civilian),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Tap the swap icon (top-right) anytime to switch roles '
                  'instantly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.accent,
    required this.icon,
    required this.title,
    required this.mode,
    required this.description,
    required this.onTap,
    required this.loading,
    required this.disabled,
    this.tags,
    this.liveLabel,
  });

  final Color accent;
  final IconData icon;
  final String title;
  final String mode;
  final String description;
  final VoidCallback onTap;
  final bool loading;
  final bool disabled;
  final List<String>? tags;
  final String? liveLabel;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled && !loading ? 0.5 : 1,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: loading ? accent : AppColors.border,
              width: loading ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconTile(icon: icon, color: accent),
                  if (loading)
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: accent,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                mode,
                style: TextStyle(
                  color: accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              if (tags != null) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags!.map(_tag).toList(),
                ),
              ],
              if (liveLabel != null) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.critical,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      liveLabel!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _tag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
    );
  }
}