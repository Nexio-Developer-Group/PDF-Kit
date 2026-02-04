import 'package:flutter/material.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/providers/locale_provider.dart';

class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({super.key});

  static const _languages = [
    {'code': 'en', 'key': 'language_option_english', 'flag': '🇺🇸'},
    {'code': 'hi', 'key': 'language_option_hindi', 'flag': '🇮🇳'},
    {'code': 'es', 'key': 'language_option_spanish', 'flag': '🇪🇸'},
    {'code': 'ar', 'key': 'language_option_arabic', 'flag': '🇸🇦'},
    {'code': 'bn', 'key': 'language_option_bengali', 'flag': '🇧🇩'},
    {'code': 'de', 'key': 'language_option_german', 'flag': '🇩🇪'},
    {'code': 'fr', 'key': 'language_option_french', 'flag': '🇫🇷'},
    {'code': 'ja', 'key': 'language_option_japanese', 'flag': '🇯🇵'},
    {'code': 'pt', 'key': 'language_option_portuguese', 'flag': '🇵🇹'},
    {'code': 'zh', 'key': 'language_option_chinese', 'flag': '🇨🇳'},
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final provider = context.watch<LocaleProvider>();
    final current = provider.locale?.languageCode ?? 'en';
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: screenPadding,
          children: [
            Text(
              t.t('language_settings_page_title'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              t.t('language_settings_choose_label'),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 16),
            ..._languages.map((lang) {
              final code = lang['code']!;
              final isSelected = code == current;
              final colorScheme = Theme.of(context).colorScheme;
              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  selected: isSelected,
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    radius: 16,
                    child: Text(
                      (lang['flag'] ?? '🌐'),
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  title: Text(
                    t.t(lang['key']!),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    code.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: Icon(
                    isSelected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: isSelected ? colorScheme.primary : null,
                  ),
                  onTap: () async {
                    if (isSelected) return;
                    await provider.setLocale(code);

                    // IMPORTANT:
                    // `context` here may still be under the old `Localizations`
                    // because the locale change rebuilds the app above this page.
                    // Show the snackbar using the app-level context from
                    // `snackbarKey`, after it reflects the new locale.
                    for (var i = 0; i < 10; i++) {
                      final appCtx = snackbarKey.currentContext;
                      final appLocale = appCtx != null && appCtx.mounted
                          ? Localizations.maybeLocaleOf(appCtx)
                          : null;

                      if (appCtx != null &&
                          context.mounted &&
                          appLocale?.languageCode == code) {
                        final msg = AppLocalizations.of(
                          appCtx,
                        ).t('language_settings_applied_snackbar');
                        AppSnackbar.show(msg);
                        return;
                      }

                      // Wait ~1 frame and try again.
                      await Future<void>.delayed(
                        const Duration(milliseconds: 16),
                      );
                    }

                    // Fallback: show using whatever app context is available.
                    final appCtx = snackbarKey.currentContext;
                    if (appCtx == null || !appCtx.mounted) return;
                    final msg = AppLocalizations.of(
                      appCtx,
                    ).t('language_settings_applied_snackbar');
                    AppSnackbar.show(msg);
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
