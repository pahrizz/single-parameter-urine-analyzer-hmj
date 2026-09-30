import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';
import 'services/database_platform_init.dart';
import 'utils/constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  initDatabasePlatform();
  runApp(const UrineAnalyzerApp());
}

class UrineAnalyzerApp extends StatelessWidget {
  const UrineAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: AppConstants.clinicalPrimary,
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'Single Parameter Urine Analyzer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: baseScheme.copyWith(
          surface: AppConstants.clinicalBackground,
        ),
        scaffoldBackgroundColor: AppConstants.clinicalBackground,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: AppConstants.clinicalSurface,
          foregroundColor: AppConstants.clinicalPrimary,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}
