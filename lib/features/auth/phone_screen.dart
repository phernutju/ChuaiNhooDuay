import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../constants/constants.dart';
import '../../providers/providers.dart';
import '../widgets/app_widgets.dart';

/// Hero landing screen: brand, stats, and phone-number entry.
class PhoneScreen extends StatefulWidget {
  const PhoneScreen({super.key});

  @override
  State<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends State<PhoneScreen> {
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Converts locally entered digits to E.164 (Thai +66, dropping a leading 0).
  String _toE164(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) digits = digits.substring(1);
    return '${AppInfo.defaultDialCode}$digits';
  }

  Future<void> _sendCode() async {
    final digits = _controller.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 9) {
      _showError('Please enter a valid phone number.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);

    final auth = context.read<AuthProvider>();
    await auth.sendCode(_toE164(_controller.text));
    if (!mounted) return;
    setState(() => _submitting = false);

    if (auth.status == PhoneAuthStatus.error) {
      _showError(auth.errorMessage ?? 'Could not send the code.');
    } else {
      context.push(AppRoutes.verify);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.critical),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _brandHeader(),
              const SizedBox(height: 36),
              const Text(
                'Help someone within walking range.',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 32,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'A real-time volunteer network. Match people who need help '
                'with people who can show up — sorted by urgency, ranked by '
                'distance.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: const [
                  _StatCard(value: '12,847', label: 'Volunteers\nonline'),
                  SizedBox(width: 12),
                  _StatCard(value: '283', label: 'Requests\ntoday'),
                  SizedBox(width: 12),
                  _StatCard(value: '< 4 min', label: 'Median\nresponse'),
                ],
              ),
              const SizedBox(height: 36),
              const Text(
                'Enter your phone number to continue',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              _phoneField(),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Send verification code',
                trailingIcon: Icons.arrow_forward,
                loading: _submitting,
                onPressed: _sendCode,
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'Your number stays private. No tracking, no ads.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _brandHeader() {
    return Row(
      children: [
        const BrandLogo(),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              AppInfo.appName,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 2),
            Text(
              AppInfo.tagline,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _phoneField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.phone_outlined, color: AppColors.textMuted, size: 20),
          const SizedBox(width: 12),
          const Text(
            AppInfo.defaultDialCode,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.phone,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d ]')),
                LengthLimitingTextInputFormatter(12),
              ],
              decoration: const InputDecoration(
                hintText: '812345678',
                hintStyle: TextStyle(color: AppColors.textMuted),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 18),
              ),
              onSubmitted: (_) => _sendCode(),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}