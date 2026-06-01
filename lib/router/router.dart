import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/constants.dart';
import '../features/feature.dart';
import '../features/request_detail/mock/request_mock_data.dart';
import '../features/request_detail/screens/request_detail_screen.dart';
import '../providers/providers.dart';

/// Builds the app router with an auth-aware redirect guard.
///
/// Gating rules (after [AuthProvider.initialized]):
///  - not signed in        → only the phone/verify screens are reachable
///  - signed in, no profile → only the name/role onboarding screens
///  - signed in + profile   → the home feed
GoRouter createRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: AppRoutes.phone,
    refreshListenable: auth,
    redirect: (context, state) {
      // The splash above the router covers the pre-init window.
      if (!auth.initialized) return null;

      // DEV: allow test route without auth — remove before submission
      if (state.matchedLocation == '/request-detail-test') return null;

      final location = state.matchedLocation;
      final loggedIn = auth.isAuthenticated;
      final hasProfile = auth.hasProfile;
      final inAuthFlow =
          location == AppRoutes.phone || location == AppRoutes.verify;
      final inOnboarding =
          location == AppRoutes.name || location == AppRoutes.role;

      if (!loggedIn) {
        return inAuthFlow ? null : AppRoutes.phone;
      }
      if (!hasProfile) {
        return inOnboarding ? null : AppRoutes.name;
      }
      if (inAuthFlow || inOnboarding) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.phone,
        builder: (context, state) => const PhoneScreen(),
      ),
      GoRoute(
        path: AppRoutes.verify,
        builder: (context, state) => const OtpScreen(),
      ),
      GoRoute(
        path: AppRoutes.name,
        builder: (context, state) => const NameScreen(),
      ),
      GoRoute(
        path: AppRoutes.role,
        builder: (context, state) => const RoleScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),

      // Request detail. The feed/active screens push with the model as `extra`;
      // we fall back to an id lookup so a direct `/request/:id` still resolves.
      GoRoute(
        path: '${AppRoutes.requestDetail}/:id',
        builder: (context, state) {
          final extra = state.extra;
          final request = extra is RequestDetailData
              ? extra
              : requestById(state.pathParameters['id'] ?? '');
          if (request == null) {
            return const Scaffold(
              backgroundColor: AppColors.background,
              body: Center(
                child: Text(
                  'Request not found',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            );
          }
          return RequestDetailScreen(request: request);
        },
      ),

      // DEV: test route for Request Detail screen — remove before submission
      GoRoute(
        path: '/request-detail-test',
        builder: (context, state) =>
            RequestDetailScreen(request: mockRequest1),
      ),
    ],
  );
}