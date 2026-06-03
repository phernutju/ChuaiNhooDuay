import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/constants.dart';
import '../../models/user_model.dart';
import '../../providers/providers.dart';
import '../../widgets/role_pill.dart';
import '../../widgets/role_switch_sheet.dart';
import '../app_lock/app_lock_settings.dart';

/// Stable per-name avatar tint, matching the feed/detail palette.
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

/// PROFILE tab — view-only account details with inline name editing.
///
/// Phone and role are read-only here; role changes go through the existing
/// [RoleSwitchSheet] (which re-routes the shell via [AuthProvider.switchRole]).
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final name = context.read<AuthProvider>().userModel?.name ?? '';
    _nameController = TextEditingController(text: name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<AuthProvider>().updateName(newName);
      if (!mounted) return;
      setState(() {
        _editing = false;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name updated'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save: $e'),
          backgroundColor: AppColors.critical,
        ),
      );
    }
  }

  void _showRoleSheet(UserRole currentRole) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => RoleSwitchSheet(
        currentRole: currentRole == UserRole.volunteer
            ? RoleType.volunteer
            : RoleType.requester,
        onRoleSelected: (role) {
          final target = role == RoleType.volunteer
              ? UserRole.volunteer
              : UserRole.civilian;
          context.read<AuthProvider>().switchRole(target);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().userModel;
    final name = (user?.name?.isNotEmpty ?? false) ? user!.name! : 'Volunteer';
    final phone = user?.phone ?? '—';
    final role = user?.role ?? UserRole.volunteer;
    final roleLabel = role == UserRole.volunteer ? 'Volunteer' : 'Requester';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.lg),
                child: Text('Profile', style: AppTextStyles.headlineLarge),
              ),
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: _avatarColorFromName(name),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: Text(name, style: AppTextStyles.headlineLarge),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Editable name.
              const Text('NAME', style: AppTextStyles.labelSmall),
              const SizedBox(height: AppSpacing.sm),
              _editing
                  ? _NameEditor(
                      controller: _nameController,
                      saving: _saving,
                      onSave: _save,
                      onCancel: () => setState(() {
                        _nameController.text = name == 'Volunteer'
                            ? (user?.name ?? '')
                            : name;
                        _editing = false;
                      }),
                    )
                  : _InfoTile(
                      icon: Icons.person_outline,
                      value: name,
                      trailing: TextButton(
                        onPressed: () => setState(() => _editing = true),
                        child: const Text(
                          'Edit',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: AppSpacing.md),

              // Read-only phone.
              const Text('PHONE', style: AppTextStyles.labelSmall),
              const SizedBox(height: AppSpacing.sm),
              _InfoTile(icon: Icons.phone_outlined, value: phone),
              const SizedBox(height: AppSpacing.md),

              // Read-only role.
              const Text('ROLE', style: AppTextStyles.labelSmall),
              const SizedBox(height: AppSpacing.sm),
              _InfoTile(
                icon: Icons.badge_outlined,
                value: roleLabel,
                trailing: TextButton(
                  onPressed: () => _showRoleSheet(role),
                  child: const Text(
                    'Switch role',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const AppLockSettings(),
              const SizedBox(height: AppSpacing.xl),

              TextButton(
                onPressed: () => context.read<AuthProvider>().signOut(),
                child: const Text(
                  'Sign out',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: AppSpacing.sm + 2),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _NameEditor extends StatelessWidget {
  const _NameEditor({
    required this.controller,
    required this.saving,
    required this.onSave,
    required this.onCancel,
  });

  final TextEditingController controller;
  final bool saving;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          autofocus: true,
          enabled: !saving,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            hintText: 'Your name',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 2,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(color: AppColors.success),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: saving ? null : onCancel,
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ElevatedButton(
                onPressed: saving ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
                child: saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
