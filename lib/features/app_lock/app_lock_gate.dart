import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../constants/constants.dart';
import '../../providers/providers.dart';
import 'app_lock_provider.dart';
import 'lock_screen.dart';
import 'pin_setup_screen.dart';

/// Mandatory gate above [MaterialApp.router].
///
/// Logic (in order):
///   1. User not fully in the app (not authenticated or no profile) → pass
///      through immediately. Phone / OTP / onboarding screens are never gated.
///   2. Not yet initialized → neutral loading splash (in practice never shown
///      because secure-storage reads finish before Firebase auth resolves).
///   3. No PIN set → [PinSetupScreen] (first-time mandatory setup).
///   4. Locked (cold start) → [LockScreen].
///   5. All clear → pass through to [child].
///
/// No lifecycle observer: once unlocked in a session it stays unlocked.
class AppLockGate extends StatelessWidget {
  const AppLockGate({super.key, required this.child});
  final Widget child;

  static ThemeData get _theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.navActive,
          brightness: Brightness.dark,
          surface: AppColors.background,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
      );

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Lock applies only to authenticated users who have completed onboarding.
    // Phone / OTP / name / role screens pass through untouched.
    if (!auth.isAuthenticated || !auth.hasProfile) return child;

    final lock = context.watch<AppLockProvider>();

    if (!lock.initialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _theme,
        home: const Scaffold(
          backgroundColor: AppColors.background,
          body: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.navActive,
              ),
            ),
          ),
        ),
      );
    }

    if (!lock.hasPin) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _theme,
        home: const PinSetupScreen(),
      );
    }

    if (lock.locked) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: _theme,
        home: const LockScreen(),
      );
    }

    return child;
  }
}
