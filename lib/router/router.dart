import 'package:go_router/go_router.dart';

import '../constants/constants.dart';
import '../features/feature.dart';
import '../features/requester/new_request_screen.dart';
import '../features/requester/post_confirmation_screen.dart';
import '../features/requester/requester_home_screen.dart';
import '../providers/providers.dart';

GoRouter createRouter(AuthProvider auth) {
  return GoRouter(
    initialLocation: AppRoutes.phone,
    refreshListenable: auth,
    redirect: (context, state) {
      if (!auth.initialized) return null;

      final location = state.matchedLocation;
      final loggedIn = auth.isAuthenticated;
      final hasProfile = auth.hasProfile;

      final inAuthFlow =
          location == AppRoutes.phone || location == AppRoutes.verify;
      final inOnboarding =
          location == AppRoutes.name || location == AppRoutes.role;

      if (!loggedIn) return inAuthFlow ? null : AppRoutes.phone;
      if (!hasProfile) return inOnboarding ? null : AppRoutes.name;
      if (inAuthFlow || inOnboarding) return AppRoutes.home;
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
      GoRoute(
        path: AppRoutes.requesterHome,
        name: 'requester-home',
        builder: (context, state) => const RequesterHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.newRequest,
        name: 'new-request',
        builder: (context, state) => const NewRequestScreen(),
      ),
      GoRoute(
        path: AppRoutes.requestPosted,
        name: 'request-posted',
        builder: (context, state) {
          final count = state.extra as int? ?? 0;
          return PostConfirmationScreen(volunteerCount: count);
        },
      ),
    ],
  );
}
