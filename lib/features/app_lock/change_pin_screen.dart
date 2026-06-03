import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/constants.dart';
import '../widgets/app_widgets.dart';
import 'app_lock_provider.dart';
import 'forgot_pin_screen.dart';
import 'pin_setup_screen.dart';

/// "Verify current PIN before changing" screen.
///
/// Same PIN-pad style as [LockScreen]. On a correct PIN navigates to
/// [PinSetupScreen] to choose a new PIN, then pops both screens back to
/// settings. Provides a "Forgot PIN?" escape hatch via [ForgotPinScreen].
class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  String _pin = '';
  bool _verifying = false;
  bool _cooldown = false;
  int _wrongAttempts = 0;
  String? _error;

  bool get _disabled => _cooldown || _verifying;

  void _onDigit(String d) {
    if (_disabled || _pin.length >= 4) return;
    setState(() {
      _pin += d;
      _error = null;
    });
    if (_pin.length == 4) _verify();
  }

  void _onBackspace() {
    if (_disabled || _pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = null;
    });
  }

  Future<void> _verify() async {
    if (_verifying || _cooldown) return;
    setState(() => _verifying = true);

    final ok =
        await context.read<AppLockProvider>().verifyCurrentPin(_pin);
    if (!mounted) return;

    if (ok) {
      // Correct PIN → go to new-PIN setup.
      // onComplete pops PinSetupScreen then this screen, landing on settings.
      setState(() => _verifying = false);
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => PinSetupScreen(
            onComplete: () => Navigator.of(context)
              ..pop() // PinSetupScreen
              ..pop(), // ChangePinScreen
          ),
        ),
      );
    } else {
      _wrongAttempts++;
      setState(() {
        _pin = '';
        _verifying = false;
        if (_wrongAttempts >= 5) {
          _cooldown = true;
          _error = 'Too many attempts — wait 30 s.';
          Future.delayed(const Duration(seconds: 30), () {
            if (mounted) {
              setState(() {
                _cooldown = false;
                _wrongAttempts = 0;
                _error = null;
              });
            }
          });
        } else {
          _error = 'Wrong PIN · ${5 - _wrongAttempts} tries left';
        }
      });
    }
  }

  // ── Widgets ───────────────────────────────────────────────────────────────

  Widget _dot(bool filled) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? AppColors.primary : Colors.transparent,
        border: Border.all(
          color: filled ? AppColors.primary : AppColors.textMuted,
          width: 2,
        ),
      ),
    );
  }

  Widget _padKey({required String label, VoidCallback? onTap, Widget? icon}) {
    final active = onTap != null;
    return Material(
      color: AppColors.surfaceElevated,
      shape: const CircleBorder(),
      elevation: active ? 3 : 0,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 72,
          height: 72,
          child: Center(
            child: icon ??
                Text(
                  label,
                  style: TextStyle(
                    color:
                        active ? AppColors.textPrimary : AppColors.textMuted,
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          ),
        ),
      ),
    );
  }

  Widget _digitRow(List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits
          .map((d) => _padKey(
                label: d,
                onTap: _disabled ? null : () => _onDigit(d),
              ))
          .toList(),
    );
  }

  Widget _keypad() {
    return Column(
      children: [
        _digitRow(['1', '2', '3']),
        const SizedBox(height: 10),
        _digitRow(['4', '5', '6']),
        const SizedBox(height: 10),
        _digitRow(['7', '8', '9']),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 72, height: 72),
            _padKey(
              label: '0',
              onTap: _disabled ? null : () => _onDigit('0'),
            ),
            _padKey(
              label: '',
              onTap: _disabled ? null : _onBackspace,
              icon: Icon(
                Icons.backspace_outlined,
                size: 24,
                color: _disabled ? AppColors.textMuted : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 8),
              _header(),
              const Divider(color: AppColors.border, height: 32),
              const SizedBox(height: 20),
              const Icon(
                Icons.lock_outlined,
                size: 40,
                color: AppColors.primary,
              ),
              const SizedBox(height: 14),
              const Text(
                'Enter your current PIN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Confirm it's you before changing your PIN",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 4; i++) ...[
                    _dot(i < _pin.length),
                    if (i < 3) const SizedBox(width: 20),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 18,
                child: _error != null
                    ? Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.critical,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : null,
              ),
              const Spacer(flex: 2),
              _keypad(),
              const Spacer(flex: 1),
              TextButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => const ForgotPinScreen(),
                  ),
                ),
                child: const Text(
                  'Forgot PIN?',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
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
        BackTile(onTap: () => Navigator.of(context).pop()),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Change PIN',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'VERIFY CURRENT',
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
