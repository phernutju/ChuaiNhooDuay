import 'package:go_router/go_router.dart';
import '../features/requester/requester_home_screen.dart';
import '../features/requester/new_request_screen.dart';
import '../features/requester/post_confirmation_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/requester-home',
  routes: [
    GoRoute(
      path: '/requester-home',
      name: 'requester-home',
      builder: (context, state) => const RequesterHomeScreen(),
    ),
    GoRoute(
      path: '/new-request',
      name: 'new-request',
      builder: (context, state) => const NewRequestScreen(),
    ),
    GoRoute(
      path: '/request-posted',
      name: 'request-posted',
      builder: (context, state) {
        final count = state.extra as int? ?? 0;
        return PostConfirmationScreen(volunteerCount: count);
      },
    ),
  ],
);
