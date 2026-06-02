import 'package:flutter/material.dart';

// Requester-mode loose constants (used by requester screens)
const Color kBgColor = Color(0xFF111111);
const Color kSurfaceColor = Color(0xFF1C1C1C);
const Color kCardColor = Color(0xFF222222);
const Color kBorderColor = Color(0xFF333333);

const Color kCriticalColor = Color(0xFFE24B4A);
const Color kUrgentColor = Color(0xFFEF9F27);
const Color kGeneralColor = Color(0xFF639922);

const Color kPrimaryBlue = Color(0xFF4A7CFF);
const Color kTextSecondary = Color(0xFF9E9E9E);

class AppInfo {
  AppInfo._();

  static const String appName = 'ChuayNooDuay';
  static const String tagline = 'CRISIS NETWORK · ALWAYS ON';
  static const String defaultDialCode = '+66';
}

class FirestoreCollections {
  FirestoreCollections._();

  static const String users = 'users';
  static const String requests = 'requests';
  static const String messages = 'messages';
  static const String civilianNotifications = 'civilianNotifications';
  static const String volunteerNotifications = 'volunteerNotifications';
  static const String globalNotifications = 'globalNotifications';
}

class AppRoutes {
  AppRoutes._();

  static const String phone = '/';
  static const String verify = '/verify';
  static const String name = '/name';
  static const String role = '/role';
  static const String home = '/home';
  static const String requesterHome = '/requester-home';
  static const String newRequest = '/new-request';
  static const String requestPosted = '/request-posted';
}

class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0A0B0F);
  static const Color surface = Color(0xFF14161D);
  static const Color surfaceAlt = Color(0xFF1B1E27);
  static const Color border = Color(0xFF2A2E3A);

  static const Color primary = Color(0xFF5B6CF5);
  static const Color primaryDisabled = Color(0xFF2E335C);

  static const Color brand = Color(0xFFF2683C);
  static const Color volunteer = Color(0xFF34C759);
  static const Color requester = Color(0xFFFF453A);

  static const Color critical = Color(0xFFFF453A);
  static const Color urgent = Color(0xFFFF9F0A);

  static const Color textPrimary = Color(0xFFF5F6F8);
  static const Color textSecondary = Color(0xFF9CA1AD);
  static const Color textMuted = Color(0xFF6B7280);
}
