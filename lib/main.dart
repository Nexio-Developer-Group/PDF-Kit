import 'package:flutter/material.dart';
import 'core/app_export.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PDF Kit',
      darkTheme: AppTheme.lightTheme, // light theme
      theme: AppTheme.darkTheme, // dark theme
      themeMode: ThemeMode.system, // pick based on system
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter, // go_router integration
    );
  }
}
