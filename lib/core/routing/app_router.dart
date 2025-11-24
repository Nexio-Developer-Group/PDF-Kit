// app_router.dart
import 'package:flutter/material.dart';
import 'package:pdf_kit/providers/locale_provider.dart';
import 'package:pdf_kit/core/routing/file_selection_shell.dart';
import 'package:pdf_kit/core/routing/home_shell.dart';
import 'package:pdf_kit/presentation/pages/page_export.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/presentation/provider/provider_export.dart';

// Navigator keys
final _rootNavKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _homeNavKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _filesNavKey = GlobalKey<NavigatorState>(debugLabel: 'files');
final _settingsNavKey = GlobalKey<NavigatorState>(debugLabel: 'settings');

final appRouter = GoRouter(
  navigatorKey: _rootNavKey,
  initialLocation: '/splash',
  errorBuilder: (context, state) =>
      NotFoundPage(routeName: state.uri.toString()),
  routes: [
    GoRoute(
      name: AppRouteName.splash,
      path: '/splash',
      parentNavigatorKey: _rootNavKey,
      builder: (context, state) => const PdfKitSplashPage(),
    ),
    GoRoute(
      name: AppRouteName.onboardingShell,
      path: '/onboarding-shell',
      parentNavigatorKey: _rootNavKey,
      builder: (context, state) => const OnboardingShellPage(),
    ),
    GoRoute(
      name: AppRouteName.recentFiles,
      path: '/recent-files',
      parentNavigatorKey: _rootNavKey,
      builder: (context, state) => const RecentFilesPage(),
    ),
    GoRoute(
      name: AppRouteName.onboarding,
      path: '/onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),

    GoRoute(
      name: 'language-settings',
      path: '/settings/language',
      parentNavigatorKey: _rootNavKey,
      builder: (context, state) => const LanguageSettingsPage(),
    ),

    GoRoute(
      name: 'theme-settings',
      path: '/settings/theme',
      parentNavigatorKey: _rootNavKey,
      builder: (context, state) => const ThemeSettingsPage(),
    ),

    buildHomeShellRoute(
      homeNavKey: _homeNavKey,
      fileNavKey: _filesNavKey,
      settingsNavKey: _settingsNavKey,
    ),

    buildSelectionShellRoute(rootNavKey: _rootNavKey),

    // App-wide overlays (above shell)
    GoRoute(
      name: AppRouteName.showPdf,
      path: '/pdf/view',
      parentNavigatorKey: _rootNavKey,
      builder: (context, state) =>
          ShowPdfPage(path: state.uri.queryParameters['path']),
    ),
    GoRoute(
      name: AppRouteName.addWatermark,
      path: '/pdf/watermark',
      parentNavigatorKey: _rootNavKey,
      builder: (context, state) => const AddWatermarkPage(),
    ),
    GoRoute(
      name: AppRouteName.addSignature,
      path: '/pdf/signature',
      parentNavigatorKey: _rootNavKey,
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Add Signature')),
        body: const Center(
          child: Text('Please use the Sign PDF feature from the home page.'),
        ),
      ),
    ),

    GoRoute(
      name: AppRouteName.mergePdf,
      path: '/pdf/merge',
      parentNavigatorKey: _rootNavKey,
      builder: (context, state) {
        final selectionId = state.uri.queryParameters['selectionId'];
        if (selectionId != null) {
          // reuse provider from SelectionManager cache
          final provider = Get.find<SelectionManager>().of(selectionId);
          return ChangeNotifierProvider<SelectionProvider>.value(
            value: provider,
            child: MergePdfPage(selectionId: selectionId),
          );
        }
        // fallback: create a fresh provider scoped to this route
        return ChangeNotifierProvider(
          create: (_) => SelectionProvider(),
          child: MergePdfPage(),
        );
      },
    ),
    GoRoute(
      name: AppRouteName.protectPdf,
      path: '/pdf/protect',
      parentNavigatorKey: _rootNavKey,
      builder: (context, state) {
        final selectionId = state.uri.queryParameters['selectionId'];
        if (selectionId != null) {
          // reuse provider from SelectionManager cache
          final provider = Get.find<SelectionManager>().of(selectionId);
          return ChangeNotifierProvider<SelectionProvider>.value(
            value: provider,
            child: ProtectPdfPage(selectionId: selectionId),
          );
        }
        // fallback: create a fresh provider scoped to this route
        return ChangeNotifierProvider(
          create: (_) => SelectionProvider(),
          child: const ProtectPdfPage(),
        );
      },
    ),

    GoRoute(
      name: AppRouteName.unlockPdf,
      path: '/pdf/unlock',
      parentNavigatorKey: _rootNavKey,
      builder: (context, state) {
        final selectionId = state.uri.queryParameters['selectionId'];
        if (selectionId != null) {
          // reuse provider from SelectionManager cache
          final provider = Get.find<SelectionManager>().of(selectionId);
          return ChangeNotifierProvider<SelectionProvider>.value(
            value: provider,
            child: UnlockPdfPage(selectionId: selectionId),
          );
        }
        // fallback: create a fresh provider scoped to this route
        return ChangeNotifierProvider(
          create: (_) => SelectionProvider(),
          child: const UnlockPdfPage(),
        );
      },
    ),

    GoRoute(
      // explicit URL path for the folder picker
      path: '/folder-picker',
      name: AppRouteName.folderPickScreen,
      pageBuilder: (context, state) {
        return MaterialPage(
          key: state.pageKey,
          child: const FolderPickerPage(),
        );
      },
    ),

    GoRoute(
      name: AppRouteName.compressPdf,
      path: '/pdf/compress',
      parentNavigatorKey: _rootNavKey,
      builder: (context, state) {
        final selectionId = state.uri.queryParameters['selectionId'];
        if (selectionId != null) {
          try {
            final provider = Get.find<SelectionManager>().of(selectionId);
            return ChangeNotifierProvider<SelectionProvider>.value(
              value: provider,
              child: CompressPdfPage(selectionId: selectionId),
            );
          } catch (_) {}
        }
        return ChangeNotifierProvider(
          create: (_) => SelectionProvider(),
          child: const CompressPdfPage(),
        );
      },
    ),

    GoRoute(
      name: AppRouteName.signPdf,
      path: '/pdf/sign',
      parentNavigatorKey: _rootNavKey,
      builder: (context, state) {
        final selectionId = state.uri.queryParameters['selectionId'];
        if (selectionId != null) {
          try {
            final provider = Get.find<SelectionManager>().of(selectionId);
            return ChangeNotifierProvider<SelectionProvider>.value(
              value: provider,
              child: SignPdfPage(selectionId: selectionId),
            );
          } catch (_) {}
        }
        return ChangeNotifierProvider(
          create: (_) => SelectionProvider(),
          child: const SignPdfPage(),
        );
      },
    ),

    GoRoute(
      name: AppRouteName.recentFilesSearch,
      path: '/recent-files/search',
      parentNavigatorKey: _rootNavKey,
      builder: (context, state) => const RecentFilesSearchPage(),
    ),
  ],
);

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(body: Center(child: Text(t.t('onboarding_title'))));
  }
}

class AllFilesPage extends StatelessWidget {
  const AllFilesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(body: Center(child: Text(t.t('all_files_title'))));
  }
}

class SearchFilePage extends StatelessWidget {
  const SearchFilePage({super.key});
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(body: Center(child: Text(t.t('search_files_title'))));
  }
}

class PreferencesPage extends StatelessWidget {
  const PreferencesPage({super.key});
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(body: Center(child: Text(t.t('preferences_title'))));
  }
}

class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({super.key});

  static const _languages = [
    {'code': 'en', 'key': 'language_option_english'},
    {'code': 'hi', 'key': 'language_option_hindi'},
    {'code': 'es', 'key': 'language_option_spanish'},
    {'code': 'ar', 'key': 'language_option_arabic'},
    {'code': 'bn', 'key': 'language_option_bengali'},
    {'code': 'de', 'key': 'language_option_german'},
    {'code': 'fr', 'key': 'language_option_french'},
    {'code': 'ja', 'key': 'language_option_japanese'},
    {'code': 'pt', 'key': 'language_option_portuguese'},
    {'code': 'zh', 'key': 'language_option_chinese'},
  ];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final provider = context.watch<LocaleProvider>();
    final current = provider.locale?.languageCode ?? 'en';
    return Scaffold(
      appBar: AppBar(title: Text(t.t('language_settings_page_title'))),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              t.t('language_settings_choose_label'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ..._languages.map(
            (lang) => RadioListTile<String>(
              title: Text(t.t(lang['key']!)),
              value: lang['code']!,
              groupValue: current,
              onChanged: (v) {
                provider.setLocale(lang['code']!);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(t.t('language_settings_applied_snackbar')),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(body: Center(child: Text(t.t('contact_us_title'))));
  }
}

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(body: Center(child: Text(t.t('about_app_title'))));
  }
}

class TakeImagePage extends StatelessWidget {
  const TakeImagePage({super.key});
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(body: Center(child: Text(t.t('take_image_title'))));
  }
}

class ShowPdfPage extends StatelessWidget {
  final String? path; // optional argument example
  const ShowPdfPage({super.key, this.path});
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final safePath = path ?? t.t('show_pdf_no_path');
    final text = t.t('show_pdf_prefix').replaceFirst('{path}', safePath);
    return Scaffold(body: Center(child: Text(text)));
  }
}

class AddWatermarkPage extends StatelessWidget {
  const AddWatermarkPage({super.key});
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(body: Center(child: Text(t.t('add_watermark_title'))));
  }
}

// Removed placeholder AddSignaturePage; real implementation lives in pages/add_signature_page.dart
// Removed placeholder CompressPdfPage; real implementation lives in pages/compress_pdf.dart
// Removed placeholder SignPdfPage; real implementation lives in pages/sign_pdf_page.dart

class NotFoundPage extends StatelessWidget {
  final String? routeName;
  const NotFoundPage({super.key, this.routeName});
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final routeText = t
        .t('not_found_page_route_undefined')
        .replaceFirst('{route}', routeName ?? t.t('show_pdf_no_path'));
    return Scaffold(
      appBar: AppBar(title: Text(t.t('not_found_page_title'))),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(routeText),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AppRouteName.home, (r) => false),
              child: Text(t.t('not_found_go_home_button')),
            ),
          ],
        ),
      ),
    );
  }
}
