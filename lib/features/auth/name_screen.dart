import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../constants/constants.dart';
import '../../providers/providers.dart';
import '../widgets/app_widgets.dart';

/// Profile step 1: capture the user's name.
class NameScreen extends StatefulWidget {
  const NameScreen({super.key});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Restore any draft if the user steps back from the role screen.
    final auth = context.read<AuthProvider>();
    _firstName.text = auth.draftFirstName ?? '';
    _lastName.text = auth.draftLastName ?? '';
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  bool get _canContinue => _firstName.text.trim().isNotEmpty;

  void _continue() {
    if (!_canContinue) return;
    context.read<AuthProvider>().setName(
          firstName: _firstName.text,
          lastName: _lastName.text,
        );
    context.push(AppRoutes.role);
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
              _header(),
              const SizedBox(height: 20),
              const StepProgress(total: 3, current: 1),
              const SizedBox(height: 28),
              const IconTile(icon: Icons.person_outline),
              const SizedBox(height: 24),
              const Text(
                "What's your name?",
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 30,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'This is how volunteers and civilians will see you in the app.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              _fieldLabel('First name'),
              const SizedBox(height: 8),
              _textField(
                controller: _firstName,
                hint: 'Enter first name',
                autofocus: true,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 20),
              _fieldLabel('Last name'),
              const SizedBox(height: 8),
              _textField(
                controller: _lastName,
                hint: 'Enter last name',
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.lock_outline, size: 14, color: AppColors.textMuted),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Your last name is optional and only shown to confirmed '
                      'volunteers on your posts.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Continue',
                trailingIcon: Icons.arrow_forward,
                onPressed: _canContinue ? _continue : null,
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Your profile stays private · No tracking, no ads.',
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

  Widget _header() {
    return Row(
      children: [
        BackTile(onTap: () => context.read<AuthProvider>().signOut()),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'STEP 1 OF 3 · YOUR PROFILE',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Almost there',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    bool autofocus = false,
    VoidCallback? onChanged,
  }) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      textCapitalization: TextCapitalization.words,
      onChanged: (_) => onChanged?.call(),
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        prefixIcon: const Icon(
          Icons.person_outline,
          color: AppColors.textMuted,
          size: 20,
        ),
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
      ),
    );
  }
}
