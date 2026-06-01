import 'package:flutter/material.dart';

/// App-wide brand identity.
class AppInfo {
  AppInfo._();

  static const String appName = 'VolunteerReady';
  static const String tagline = 'CRISIS NETWORK · ALWAYS ON';
  static const String defaultDialCode = '+66';
}

/// Firestore collection names.
class FirestoreCollections {
  FirestoreCollections._();

  static const String users = 'users';
  static const String requests = 'requests';
  static const String messages = 'messages';
  static const String civilianNotifications = 'civilianNotifications';
  static const String volunteerNotifications = 'volunteerNotifications';
  static const String globalNotifications = 'globalNotifications';
}

/// go_router path constants.
class AppRoutes {
  AppRoutes._();

  static const String phone = '/';
  static const String verify = '/verify';
  static const String name = '/name';
  static const String role = '/role';
  static const String home = '/home';
}

class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0F1115);
  static const Color surface = Color(0xFF1A1E26);
  static const Color surfaceElevated = Color(0xFF22272F);
  static const Color surfaceAlt = Color(0xFF1B1E27);
  static const Color border = Color(0xFF2C3340);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8B95A8);
  static const Color textMuted = Color(0xFF505868);
  static const Color textBody = Color(0xCCFFFFFF);

  static const Color critical = Color(0xFFE04040);
  static const Color criticalBg = Color(0xFF3D1616);
  static const Color urgent = Color(0xFFE6A535);
  static const Color urgentBg = Color(0xFF3D2808);
  static const Color general = Color(0xFF8B95A8);
  static const Color generalBg = Color(0xFF2A2D35);

  static const Color success = Color(0xFF4CAF50);
  static const Color successBg = Color(0xFF1A3320);

  static const Color primary = Color(0xFFE04040);
  static const Color primaryDisabled = Color(0xFF2E335C);
  static const Color primaryAccepted = Color(0xFF4CAF50);

  static const Color brand = Color(0xFFF2683C);
  static const Color volunteer = Color(0xFF34C759);
  static const Color requester = Color(0xFFFF453A);
}

class AppConstants {
  AppConstants._();

  static const double checkInRadiusMeters = 100;
}

class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  static const double radiusSm = 6.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusPill = 100.0;
}

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle headlineLarge = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static const TextStyle titleMedium = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle bodyMedium = TextStyle(
    color: AppColors.textBody,
    fontSize: 14,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
  );

  static const TextStyle labelSmall = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
  );

  static const TextStyle caption = TextStyle(
    color: AppColors.textMuted,
    fontSize: 11,
  );

  static const TextStyle button = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle appBarTitle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle appBarSubtitle = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
  );
}
