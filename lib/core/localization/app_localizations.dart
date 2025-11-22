import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Lightweight custom localization loader using ARB files in assets/l10n.
/// Fallback: English (en) when key missing.
class AppLocalizations {
  final Locale locale;
  late final Map<String, dynamic> _localized;
  static Map<String, dynamic>? _englishCache; // cache English for fallback

  AppLocalizations(this.locale);

  static const supportedLocales = [
    Locale('en'), // English
    Locale('hi'), // Hindi
    Locale('es'), // Spanish
    Locale('ar'), // Arabic
    Locale('bn'), // Bengali
    Locale('de'), // German
    Locale('fr'), // French
    Locale('ja'), // Japanese
    Locale('pt'), // Portuguese
    Locale('zh'), // Chinese
  ];

  static const _folder = 'assets/l10n';

  static Future<AppLocalizations> load(Locale locale) async {
    final instance = AppLocalizations(locale);

    // Always load English once for fallback
    if (_englishCache == null) {
      debugPrint(
        'AppLocalizations: loading English fallback from $_folder/en.arb',
      );
      final enString = await rootBundle.loadString('$_folder/en.arb');
      final decoded = json.decode(enString) as Map<String, dynamic>;
      // Filter out metadata keys (those starting with @)
      _englishCache = Map.fromEntries(
        decoded.entries.where((e) => !e.key.startsWith('@')),
      );
      debugPrint(
        'AppLocalizations: English fallback loaded; ${_englishCache!.length} keys',
      );
      debugPrint(
        'AppLocalizations: Sample key action_watermark_label = ${_englishCache!['action_watermark_label']}',
      );
    }

    // Load target locale (if not English)
    if (locale.languageCode == 'en') {
      instance._localized = Map<String, dynamic>.from(_englishCache!);
    } else {
      try {
        final path = '$_folder/${locale.languageCode}.arb';
        debugPrint('AppLocalizations: attempting to load $path');
        final data = await rootBundle.loadString(path);
        final decoded = json.decode(data) as Map<String, dynamic>;
        // Filter out metadata keys (those starting with @)
        instance._localized = Map.fromEntries(
          decoded.entries.where((e) => !e.key.startsWith('@')),
        );
        debugPrint(
          'AppLocalizations: loaded ${locale.languageCode}; ${instance._localized.length} keys',
        );
      } catch (e) {
        debugPrint(
          'AppLocalizations: failed to load ${locale.languageCode} arb, falling back to English. Error: $e',
        );
        // Fallback entirely to English if file missing or parse error
        instance._localized = Map<String, dynamic>.from(_englishCache!);
      }
    }

    return instance;
  }

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  String t(String key) {
    final val = _localized[key];
    if (val is String) return val;

    // Fallback to English cache
    final fallback = _englishCache?[key];
    if (fallback is String) return fallback;

    // Final fallback: return key
    debugPrint('AppLocalizations.t: missing key "$key"');
    return key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (l) => l.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) => AppLocalizations.load(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

class AppLocalizationDelegates {
  static const delegate = _AppLocalizationsDelegate();

  static final List<LocalizationsDelegate<dynamic>> all = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
}
