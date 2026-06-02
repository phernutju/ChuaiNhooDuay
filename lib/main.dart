import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'constants/constants.dart';
import 'router/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: WeAreReadyApp()));
}

class WeAreReadyApp extends StatelessWidget {
  const WeAreReadyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ChuayNooDuay',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      theme: ThemeData(
        scaffoldBackgroundColor: kBgColor,
        colorScheme: const ColorScheme.dark(
          surface: kSurfaceColor,
          primary: kPrimaryBlue,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: kBgColor,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}