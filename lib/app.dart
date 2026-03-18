import 'package:flutter/material.dart';
import 'pages/main_shell.dart';
import 'theme/app_colors.dart';

class BatteryMonitorApp extends StatelessWidget {
  const BatteryMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Battery Monitor',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.accent,
          secondary: AppColors.accent,
          surface: AppColors.panel,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.navBackground,
          selectedItemColor: AppColors.primaryText,
          unselectedItemColor: AppColors.secondaryText,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
        ),
      ),
      home: const MainShell(),
    );
  }
}
