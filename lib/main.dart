// main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/app_export.dart';
import 'providers/locale_provider.dart';
import 'package:pdf_kit/providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Prefs.init();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await initDI();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer2<LocaleProvider, ThemeProvider>(
        builder: (context, localeProvider, themeProvider, _) {
          return MaterialApp.router(
            title: 'PDF Kit',
            locale: localeProvider.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizationDelegates.all,
            darkTheme: AppTheme.darkTheme,
            theme: AppTheme.lightTheme,
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            routerConfig: appRouter,
            builder: (context, child) {
              return Directionality(
                textDirection: TextDirection.ltr,
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
