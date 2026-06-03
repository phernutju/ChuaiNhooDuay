import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../constants/constants.dart';
import '../../providers/providers.dart';
import '../widgets/app_widgets.dart';
import 'pin_setup_screen.dart';

/// PIN-reset recovery screen — visually mirrors OtpScreen.
///
/// Immediately calls [AuthProvider.sendCode] on mount (no manual "Send code"
/// step). Shows a masked phone number, 6 OTP boxes, a resend link, and a
/// Verify button. On success navigates to [PinSetupScreen] to set a new PIN.
/// The Firebase session is preserved (no sign-out).
class ForgotPinScreen extends StatefulWidget {
  const ForgotPinScreen({super.key});

  @override
  State<ForgotPinScreen> createState() => _ForgotPinScreenState();
}

class _ForgotPinScreenState extends State<ForgotPinScreen> {
  static const _otpLength = 6;

  final List<TextEditingController> _controllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _nodes =
      List.generate(_otpLength, (_) => FocusNode());

  bool _sending = true; // true while the initial sendCode call is in progress
  bool _verifying = false;
  String _phone = '';

  String get _code => _controllers.map((c) => c.text).join();
  bool get _complete => _code.length == _otpLength;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoSend());
  }

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

  Future<void> _autoSend() async {
    final auth = context.read<AuthProvider>();
    final phone = auth.userModel?.phone ?? '';
    setState(() => _phone = phone);
    if (phone.isEmpty) {
      setState(() => _sending = false);
      return;
    }
    await auth.sendCode(phone);
    if (!mounted) return;
    setState(() => _sending = false);
    _nodes[0].requestFocus();
  }

  Future<void> _resend() async {
    final auth = context.read<AuthProvider>();
    setState(() => _sending = true);
    await auth.sendCode(_phone, resend: true);
    if (!mounted) return;
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('A new code has been sent.')),
    );
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      _distribute(value);
      return;
    }
    if (value.isNotEmpty && index < _otpLength - 1) {
      _nodes[index + 1].requestFocus();
    }
    setState(() {});
    if (_complete) _verify();
  }

  void _distribute(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    for (var i = 0; i < _otpLength; i++) {
      _controllers[i].text = i < digits.length ? digits[i] : '';
    }
    _nodes[digits.length.clamp(0, _otpLength - 1)].requestFocus();
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

    if (ok) {
      // OTP verified — let the user set a new PIN.
      // PinSetupScreen.setPin unlocks the gate automatically.
      Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute(
          builder: (_) => const PinSetupScreen(),
        ),
      );
    } else {
      for (final c in _controllers) {
        c.clear();
      }
      setState(() {});
      _nodes[0].requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage ?? 'Invalid code.'),
          backgroundColor: AppColors.critical,
        ),
      );
    }
  }

  Widget _otpBox(int index) {
    final filled = _controllers[index].text.isNotEmpty;
    final disabled = _sending || _verifying;
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
          enabled: !disabled,
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
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
          onChanged: (v) => _onChanged(index, v),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

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
                  text: _sending ? 'Sending code to ' : 'Sent to ',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                  children: [
                    TextSpan(
                      text: _phone.isEmpty ? '…' : _phone,
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
                children: List.generate(_otpLength, _otpBox),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: (auth.isBusy || _sending || _verifying)
                      ? null
                      : _resend,
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
                onPressed: (_complete && !_verifying && !_sending) ? _verify : null,
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
        BackTile(onTap: () => Navigator.of(context).pop()),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Reset PIN',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'RECOVERY',
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
}
