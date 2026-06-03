import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/constants.dart';
import 'app_lock_provider.dart';
import 'forgot_pin_screen.dart';

/// Lock screen with a circular PIN-pad keypad and 4-dot indicator.
///
/// No device keyboard — digits come from the on-screen pad.
/// Auto-triggers biometric on mount if enabled and available.
/// 5 wrong attempts → 30-second cooldown (never a permanent lockout).
class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _pin = '';
  bool _verifying = false;
  bool _cooldown = false;
  int _wrongAttempts = 0;
  String? _error;

  bool get _disabled => _cooldown || _verifying;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  Future<void> _tryBiometric() async {
    if (!mounted) return;
    final lock = context.read<AppLockProvider>();
    if (!lock.biometricEnabled || !lock.biometricAvailable) return;
    await lock.unlockWithBiometric();
    // On success the gate rebuilds. On failure, PIN pad is already visible.
  }

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

    final ok = await context.read<AppLockProvider>().unlockWithPin(_pin);
    if (!mounted) return;

    if (!ok) {
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
    // On success the gate rebuilds automatically.
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

  Widget _padKey({
    required String label,
    VoidCallback? onTap,
    Widget? icon,
  }) {
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
                    color: active
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
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
          .map(
            (d) => _padKey(
              label: d,
              onTap: _disabled ? null : () => _onDigit(d),
            ),
          )
          .toList(),
    );
  }

  Widget _keypad(bool canBiometric) {
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
            // Bottom-left: biometric shortcut or invisible placeholder
            canBiometric
                ? _padKey(
                    label: '',
                    onTap: _verifying ? null : _tryBiometric,
                    icon: Icon(
                      Icons.fingerprint,
                      size: 28,
                      color: _verifying
                          ? AppColors.textMuted
                          : AppColors.textSecondary,
                    ),
                  )
                : const SizedBox(width: 72, height: 72),
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
    final lock = context.watch<AppLockProvider>();
    final canBiometric = lock.biometricEnabled && lock.biometricAvailable;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // App label
              const Text(
                AppInfo.appName,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(flex: 1),
              // Lock icon
              const Icon(
                Icons.lock_rounded,
                size: 40,
                color: AppColors.primary,
              ),
              const SizedBox(height: 14),
              // Heading
              const Text(
                'Enter your PIN',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              // Subtitle
              const Text(
                'Enter your PIN to unlock',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 28),
              // 4 progress dots
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
              // Error slot (fixed height to avoid layout jump)
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
              // PIN pad
              _keypad(canBiometric),
              const Spacer(flex: 1),
              // Forgot PIN
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
}
