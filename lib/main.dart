import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'constants/constants.dart';
import 'features/notification/datasources/firestore_notification_data_source.dart';
import 'features/notification/datasources/mock_notification_data_source.dart';
import 'features/notification/datasources/notification_data_source.dart';
import 'features/widgets/app_widgets.dart';
import 'firebase_options.dart';
import 'providers/providers.dart';
import 'router/router.dart';
import 'services/notification_service.dart';

// ← flip to false when Firestore backend is ready
const bool useMock = true;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const VolunteerReadyApp());
}

class VolunteerReadyApp extends StatefulWidget {
  const VolunteerReadyApp({super.key});

  @override
  State<VolunteerReadyApp> createState() => _VolunteerReadyAppState();
}

class _VolunteerReadyAppState extends State<VolunteerReadyApp> {
  // Eagerly initialized — no dependency on other fields.
  final NotificationDataSource _notificationSource = useMock
      ? MockNotificationDataSource()
      : FirestoreNotificationDataSource(NotificationService());

  AuthProvider? _auth;
  GoRouter? _router;
  NotificationProvider? _notifications;

  @override
  void initState() {
    super.initState();
    _auth = AuthProvider();
    _router = createRouter(_auth!);
    _notifications = NotificationProvider(_notificationSource);
  }

  @override
  void dispose() {
    _auth?.dispose();
    _notifications?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = _auth!;
    final notifications = _notifications!;
    final router = _router!;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<NotificationProvider>.value(value: notifications),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (!auth.initialized) {
            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: _theme,
              home: const _SplashScreen(),
            );
          }
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: AppInfo.appName,
            theme: _theme,
            routerConfig: router,
          );
        },
      ),
    );
  }

  ThemeData get _theme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
          surface: AppColors.background,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
      );
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BrandLogo(size: 64),
            SizedBox(height: 24),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
