import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../constants/constants.dart';
import '../../providers/providers.dart';
import '../widgets/app_widgets.dart';

/// SMS code verification screen (6-digit input).
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  static const _length = 6;

  final List<TextEditingController> _controllers =
      List.generate(_length, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(_length, (_) => FocusNode());

  bool _verifying = false;

  String get _code => _controllers.map((c) => c.text).join();
  bool get _complete => _code.length == _length;

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      // Handle paste / autofill of the full code.
      _distribute(value);
      return;
    }
    if (value.isNotEmpty && index < _length - 1) {
      _nodes[index + 1].requestFocus();
    }
    setState(() {});
    if (_complete) _verify();
  }

  void _distribute(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    for (var i = 0; i < _length; i++) {
      _controllers[i].text = i < digits.length ? digits[i] : '';
    }
    final next = digits.length.clamp(0, _length - 1);
    _nodes[next].requestFocus();
    setState(() {});
    if (_complete) _verify();
  }

  KeyEventResult _onKey(int index, KeyEvent event, FocusNode node) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _controllers[index - 1].clear();
      _nodes[index - 1].requestFocus();
      setState(() {});
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _verify() async {
    if (!_complete || _verifying) return;
    FocusScope.of(context).unfocus();
    setState(() => _verifying = true);

    final auth = context.read<AuthProvider>();
    final ok = await auth.verifyOtp(_code);
    if (!mounted) return;
    setState(() => _verifying = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Invalid code.'),
          backgroundColor: AppColors.critical,
        ),
      );
    }
    // On success the auth-state listener + router redirect take over.
  }

  Future<void> _resend() async {
    final auth = context.read<AuthProvider>();
    await auth.sendCode(auth.pendingPhone, resend: true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('A new code has been sent.')),
    );
  }

  /// Formats the pending E.164 number as "+66 81-234-5678".
  String _prettyPhone(String e164) {
    final m = RegExp(r'^(\+\d{2})(\d{2})(\d{3})(\d{4})$').firstMatch(e164);
    if (m == null) return e164;
    return '${m[1]} ${m[2]}-${m[3]}-${m[4]}';
  }

  @override
  Widget build(BuildContext context) {
    final phone = context.select<AuthProvider, String>((a) => a.pendingPhone);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _header(),
              const Divider(color: AppColors.border, height: 32),
              const SizedBox(height: 12),
              const IconTile(icon: Icons.verified_user_outlined),
              const SizedBox(height: 24),
              const Text(
                'Enter the 6-digit code',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  text: 'Sent to ',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                  children: [
                    TextSpan(
                      text: _prettyPhone(phone),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_length, _otpBox),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: _resend,
                  child: const Text(
                    'Resend code',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Verify',
                trailingIcon: Icons.check_circle_outline,
                loading: _verifying,
                onPressed: _complete ? _verify : null,
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
        BackTile(onTap: () => context.pop()),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Verify',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'STEP 1 OF 2',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _otpBox(int index) {
    final filled = _controllers[index].text.isNotEmpty;
    return SizedBox(
      width: 48,
      height: 60,
      child: Focus(
        onKeyEvent: (node, event) => _onKey(index, event, node),
        child: TextField(
          controller: _controllers[index],
          focusNode: _nodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          cursorColor: AppColors.primary,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            counterText: '',
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: filled ? AppColors.primary : AppColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          onChanged: (v) => _onChanged(index, v),
        ),
      ),
    );
  }
}
