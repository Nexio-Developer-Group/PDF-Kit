// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/app_export.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ✅ Initialize SharedPreferences through your Prefs utility
  await Prefs.init();

  // Optional: Set preferred orientations or other initialization
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await initDI(); // register SelectionManager or pre-warm anything
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PDF Kit',
      darkTheme: AppTheme.lightTheme,
      theme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}
