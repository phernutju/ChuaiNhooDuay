import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:we_are_ready/constants/constants.dart';
import 'package:we_are_ready/features/request_detail/mock/request_mock_data.dart';
import 'package:we_are_ready/features/request_detail/screens/request_detail_screen.dart';

void main() {
  runApp(const WeAreReadyApp());
}

class WeAreReadyApp extends StatelessWidget {
  const WeAreReadyApp({super.key});

  static const _appTitle = 'WeAreReady';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.dark,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(
          ThemeData(brightness: Brightness.dark).textTheme,
        ),
      ),
      home: const RequestDetailScreen(request: mockRequest1),
    );
  }
}
