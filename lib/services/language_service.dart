import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf_kit/core/constants.dart';

class LanguageService {
  static const _key = Constants.prefsLanguageKey;

  Future<String?> getSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  Future<void> saveLocale(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
  }
}
