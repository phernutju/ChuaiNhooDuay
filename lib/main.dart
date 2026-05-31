import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'constants/constants.dart';
import 'features/widgets/app_widgets.dart';
import 'firebase_options.dart';
import 'providers/providers.dart';
import 'router/router.dart';

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
  late final AuthProvider _auth;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _auth = AuthProvider();
    _router = createRouter(_auth);
  }

  @override
  void dispose() {
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthProvider>.value(
      value: _auth,
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
            routerConfig: _router,
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
