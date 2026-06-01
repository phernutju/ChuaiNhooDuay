import 'package:go_router/go_router.dart';
import '../constants/constants.dart';
import '../features/feature.dart';
import '../providers/providers.dart';

// DEV: imports for test routes — remove before submission
import '../features/request_detail/screens/request_detail_screen.dart';
import '../features/request_detail/mock/request_mock_data.dart';
import '../features/chat/chat_room_screen.dart';
import '../mock/mock_messages.dart';

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

      // DEV: allow test routes without auth — remove before submission
      if (state.matchedLocation == '/request-detail-test') return null;
      if (state.matchedLocation == '/chat-test') return null;
      if (state.matchedLocation == '/chat-test-closed') return null;

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
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationPage(),
      ),

      // DEV: test route for Request Detail screen — remove before submission
      GoRoute(
        path: '/request-detail-test',
        builder: (context, state) =>
            RequestDetailScreen(request: mockRequest1),
      ),

      // DEV: test routes for Chat screen — remove before submission
      GoRoute(
        path: '/chat-test',
        builder: (context, state) => ChatRoomScreen(
          requestId: MockMessages.requestId,
          requestTitle: 'Help needed at market',
          requestCategory: 'MEDICAL AID',
          urgencyLabel: 'CRITICAL',
          currentUserId: MockMessages.currentUserId,
          otherUserName:
              MockMessages.participantNames[MockMessages.civilianId]!,
          distanceLabel: '0.3 km away',
          etaLabel: 'ETA 9 min',
          participantCount: 2,
          isReadOnly: false,
          useMockData: true,
        ),
      ),
      GoRoute(
        path: '/chat-test-closed',
        builder: (context, state) => ChatRoomScreen(
          requestId: MockMessages.requestId,
          requestTitle: 'Help needed at market',
          requestCategory: 'MEDICAL AID',
          urgencyLabel: 'CRITICAL',
          currentUserId: MockMessages.currentUserId,
          otherUserName:
              MockMessages.participantNames[MockMessages.civilianId]!,
          distanceLabel: '0.3 km away',
          participantCount: 2,
          isReadOnly: true,
          useMockData: true,
        ),
      ),
    ],
  );
}