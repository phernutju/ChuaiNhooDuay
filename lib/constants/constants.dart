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

/// Design-system colors derived from the VolunteerReady mockups (dark theme).
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0A0B0F);
  static const Color surface = Color(0xFF14161D);
  static const Color surfaceAlt = Color(0xFF1B1E27);
  static const Color border = Color(0xFF2A2E3A);

  static const Color primary = Color(0xFF5B6CF5);
  static const Color primaryDisabled = Color(0xFF2E335C);

  static const Color brand = Color(0xFFF2683C); // orange logo tile
  static const Color volunteer = Color(0xFF34C759); // green "I can help"
  static const Color requester = Color(0xFFFF453A); // red "I need help"

  static const Color critical = Color(0xFFFF453A);
  static const Color urgent = Color(0xFFFF9F0A);

  static const Color textPrimary = Color(0xFFF5F6F8);
  static const Color textSecondary = Color(0xFF9CA1AD);
  static const Color textMuted = Color(0xFF6B7280);
}
