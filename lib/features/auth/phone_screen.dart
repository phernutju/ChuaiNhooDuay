import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../constants/constants.dart';
import '../../providers/providers.dart';
import '../widgets/app_widgets.dart';

/// Brand orange accent used across the landing hero.
const Color _kAccent = Color(0xFFE8471A);

/// Hero landing screen: brand, network pill, feature highlights, and phone-number entry.
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
              const SizedBox(height: 28),
              const _NetworkPill(),
              const SizedBox(height: 20),
              Text.rich(
                TextSpan(
                  children: const [
                    TextSpan(text: 'Help someone within '),
                    TextSpan(
                      text: 'walking',
                      style: TextStyle(color: _kAccent),
                    ),
                    TextSpan(text: ' range.'),
                  ],
                ),
                style: const TextStyle(
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
              const _FeatureRow(
                icon: Icons.people_outline,
                bold: 'Switch roles anytime',
                rest: ' — volunteer or civilian',
              ),
              const SizedBox(height: 18),
              const _FeatureRow(
                icon: Icons.location_on_outlined,
                bold: 'Live map',
                rest: ' — see requests near you',
              ),
              const SizedBox(height: 18),
              const _FeatureRow(
                icon: Icons.chat_bubble_outline,
                bold: 'In-app chat',
                rest: ' — coordinate in real time',
              ),
              const SizedBox(height: 28),
              const Divider(color: AppColors.border, height: 1, thickness: 1),
              const SizedBox(height: 28),
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

/// Pill/tag at the top of the hero with a softly pulsing orange dot.
class _NetworkPill extends StatefulWidget {
  const _NetworkPill();

  @override
  State<_NetworkPill> createState() => _NetworkPillState();
}

class _NetworkPillState extends State<_NetworkPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween<double>(begin: 0.35, end: 1).animate(_pulse),
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: _kAccent,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Real-time volunteer network',
            style: TextStyle(
              color: _kAccent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// A single feature highlight: small icon box followed by bold + muted text.
class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.bold,
    required this.rest,
  });

  final IconData icon;
  final String bold;
  final String rest;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: _kAccent, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: bold,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: rest,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 14, height: 1.3),
          ),
        ),
      ],
    );
  }
}