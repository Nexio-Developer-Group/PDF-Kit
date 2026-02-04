import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pdf_kit/core/utility/storage_utility.dart';
import 'package:pdf_kit/core/constants.dart';
import 'package:pdf_kit/service/analytics_service.dart';

class LocaleProvider extends ChangeNotifier {
  static const _key = Constants.prefsLanguageKey;
  Locale? _locale;
  Locale? get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  void _loadLocale() {
    final saved = Prefs.getString(_key);
    debugPrint('LocaleProvider: loaded saved locale -> $saved');
    if (saved != null && saved.isNotEmpty) {
      _locale = Locale(saved);
      notifyListeners();

      final onboardingCompleted =
          Prefs.getBool(Constants.prefsOnboardingCompletedKey) ?? false;
      if (onboardingCompleted) {
        debugPrint(
          'LocaleProvider: onboardingCompleted=true -> set analytics selected_language=$saved',
        );
        unawaited(
          AnalyticsService.setSelectedLanguage(
            saved,
            source: 'LocaleProvider._loadLocale',
          ),
        );
        unawaited(
          AnalyticsService.logLanguageChanged(
            saved,
            source: 'LocaleProvider._loadLocale',
          ),
        );
      } else {
        debugPrint(
          'LocaleProvider: onboardingCompleted=false -> skip analytics user_property update (load)',
        );
      }
    }
  }

  Future<void> setLocale(String code) async {
    debugPrint('LocaleProvider: setLocale -> $code');
    _locale = Locale(code);
    await Prefs.setString(_key, code);
    notifyListeners();

    final onboardingCompleted =
        Prefs.getBool(Constants.prefsOnboardingCompletedKey) ?? false;
    if (onboardingCompleted) {
      debugPrint(
        'LocaleProvider: onboardingCompleted=true -> update analytics selected_language=$code',
      );
      unawaited(
        AnalyticsService.setSelectedLanguage(code, source: 'LocaleProvider'),
      );
      unawaited(
        AnalyticsService.logLanguageChanged(code, source: 'LocaleProvider'),
      );
    } else {
      debugPrint(
        'LocaleProvider: onboardingCompleted=false -> skip analytics user_property update (setLocale)',
      );
    }
  }
}
