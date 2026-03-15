import 'package:flutter/material.dart';
import 'pages/main_shell.dart';

class BatteryMonitorApp extends StatelessWidget {
  const BatteryMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Battery Monitor',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0814),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE8E1F8),
          secondary: Color(0xFFE8E1F8),
        ),
      ),
      home: const MainShell(),
    );
  }
}