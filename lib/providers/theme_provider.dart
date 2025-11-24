import 'package:flutter/material.dart';
import 'package:pdf_kit/core/utility/storage_utility.dart';
import 'package:pdf_kit/core/constants.dart';

class ThemeProvider extends ChangeNotifier {
  String _selected = 'system'; // 'light', 'dark', 'system'

  String get selectedTheme => _selected;

  ThemeMode get themeMode {
    switch (_selected) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  ThemeProvider() {
    _load();
  }

  void _load() {
    final saved = Prefs.getString(Constants.prefsThemeKey);
    if (saved != null && saved.isNotEmpty) {
      _selected = saved;
    }
    notifyListeners();
  }

  Future<void> setTheme(String value) async {
    _selected = value;
    await Prefs.setString(Constants.prefsThemeKey, value);
    notifyListeners();
  }
}
