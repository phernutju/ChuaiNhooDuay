import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../constants/constants.dart';
import '../widgets/app_widgets.dart';
import 'app_lock_provider.dart';

/// Two-step PIN creation screen — digit-box style (OtpScreen visual).
///
/// Step 1: user enters a 4-digit PIN via square digit boxes + device keyboard.
/// Step 2: user re-enters for confirmation.
/// On match, calls [AppLockProvider.setPin] (which also unlocks the session),
/// then fires [onComplete] if provided.
///
/// Layout is centered; no back button on first-time setup (when Navigator
/// cannot pop); back button shown in change/reset mode.
class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key, this.onComplete});
  final VoidCallback? onComplete;

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  static const _length = 4;

  final List<TextEditingController> _controllers =
      List.generate(_length, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(_length, (_) => FocusNode());

  bool _confirming = false;
  String? _firstPin;
  String? _error;
  bool _saving = false;

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

  void _clearBoxes() {
    for (final c in _controllers) {
      c.clear();
    }
    _nodes[0].requestFocus();
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      _distribute(value);
      return;
    }
    if (value.isNotEmpty && index < _length - 1) {
      _nodes[index + 1].requestFocus();
    }
    setState(() => _error = null);
    if (_complete) _advance();
  }

  void _distribute(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    for (var i = 0; i < _length; i++) {
      _controllers[i].text = i < digits.length ? digits[i] : '';
    }
    _nodes[digits.length.clamp(0, _length - 1)].requestFocus();
    setState(() => _error = null);
    if (_complete) _advance();
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

  void _advance() {
    if (!_confirming) {
      setState(() {
        _firstPin = _code;
        _confirming = true;
      });
      _clearBoxes();
    } else {
      _save();
    }
  }

  Future<void> _save() async {
    if (_firstPin != _code) {
      setState(() {
        _error = 'PINs do not match — try again.';
        _firstPin = null;
        _confirming = false;
      });
      _clearBoxes();
      return;
    }
    setState(() => _saving = true);
    await context.read<AppLockProvider>().setPin(_firstPin!);
    widget.onComplete?.call();
  }

  Widget _pinBox(int index) {
    final filled = _controllers[index].text.isNotEmpty;
    return SizedBox(
      width: 64,
      height: 72,
      child: Focus(
        onKeyEvent: (node, event) => _onKey(index, event, node),
        child: TextField(
          controller: _controllers[index],
          focusNode: _nodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          enabled: !_saving,
          cursorColor: AppColors.primary,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
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
    final canPop = Navigator.canPop(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            // Header stays left-aligned; center alignment applies below header.
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              _header(context, canPop),
              const Divider(color: AppColors.border, height: 32),
              // Centered content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 12),
                    const IconTile(icon: Icons.lock_outline),
                    const SizedBox(height: 24),
                    Text(
                      _confirming ? 'Confirm your PIN' : 'Create your PIN',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _confirming
                          ? 'Re-enter your PIN to confirm.'
                          : "You'll enter this PIN each time you open the app.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(_length, _pinBox),
                    ),
                    const SizedBox(height: 12),
                    if (_error != null)
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.critical,
                          fontSize: 13,
                        ),
                      ),
                    const Spacer(),
                    PrimaryButton(
                      label: _confirming ? 'Save PIN' : 'Continue',
                      trailingIcon: _confirming
                          ? Icons.check_circle_outline
                          : Icons.arrow_forward,
                      loading: _saving,
                      onPressed: (_complete && !_saving) ? _advance : null,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, bool canPop) {
    return Row(
      children: [
        if (canPop) ...[
          BackTile(onTap: () => Navigator.of(context).pop()),
          const SizedBox(width: 14),
        ],
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set PIN',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _confirming ? 'CONFIRM' : 'CHOOSE',
              style: const TextStyle(
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
