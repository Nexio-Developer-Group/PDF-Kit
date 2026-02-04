// app_router.dart
import 'package:flutter/material.dart';
import 'package:pdf_kit/presentation/pages/language_setting_page.dart';
import 'package:pdf_kit/core/routing/file_selection_shell.dart';
import 'package:pdf_kit/core/routing/home_shell.dart';
import 'package:pdf_kit/presentation/pages/page_export.dart';
import 'package:pdf_kit/presentation/pages/images_to_pdf_page.dart';
import 'package:pdf_kit/presentation/pages/reorder_pdf_page.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/presentation/provider/provider_export.dart';

// Navigator keys

/// Global route observer to track page visibility
final routeObserver = RouteObserver<ModalRoute>();

final appRouter = GoRouter(
  navigatorKey: rootNavKey,
  initialLocation: '/splash',
  observers: [routeObserver],
  errorBuilder: (context, state) =>
      NotFoundPage(routeName: state.uri.toString()),
  routes: [
    GoRoute(
      name: AppRouteName.splash,
      path: '/splash',
      parentNavigatorKey: rootNavKey,
      builder: (context, state) => const PdfKitSplashPage(),
    ),
    GoRoute(
      name: AppRouteName.onboardingShell,
      path: '/onboarding-shell',
      parentNavigatorKey: rootNavKey,
      builder: (context, state) => const OnboardingShellPage(),
    ),
    GoRoute(
      name: AppRouteName.recentFiles,
      path: '/recent-files',
      parentNavigatorKey: rootNavKey,
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
      parentNavigatorKey: rootNavKey,
      builder: (context, state) => LanguageSettingsPage(),
    ),

    GoRoute(
      name: 'theme-settings',
      path: '/settings/theme',
      parentNavigatorKey: rootNavKey,
      builder: (context, state) => const ThemeSettingsPage(),
    ),

    GoRoute(
      name: 'pdf-content-fit-settings',
      path: '/settings/pdf-content-fit',
      parentNavigatorKey: rootNavKey,
      builder: (context, state) => const PdfContentFitSettingsPage(),
    ),

    GoRoute(
      name: 'help-support',
      path: '/settings/help-support',
      parentNavigatorKey: rootNavKey,
      builder: (context, state) => const HelpSupportPage(),
    ),

    GoRoute(
      name: 'about-pdfkit',
      path: '/settings/about-pdf-kit',
      parentNavigatorKey: rootNavKey,
      builder: (context, state) => const AboutPdfKitPage(),
    ),

    GoRoute(
      name: AppRouteName.aboutUs,
      path: '/settings/about-us',
      parentNavigatorKey: rootNavKey,
      builder: (context, state) => const AboutUsPage(),
    ),

    GoRoute(
      name: AppRouteName.filterOptions,
      path: '/settings/filter-options',
      parentNavigatorKey: rootNavKey,
      builder: (context, state) => const FilterOptionsPage(),
    ),

    buildHomeShellRoute(
      homeNavKey: homeNavKey,
      fileNavKey: filesNavKey,
      settingsNavKey: settingsNavKey,
    ),

    buildSelectionShellRoute(rootNavKey: rootNavKey),

    // App-wide overlays (above shell)
    GoRoute(
      name: AppRouteName.showPdf,
      path: '/pdf/view',
      parentNavigatorKey: rootNavKey,
      builder: (context, state) =>
          ShowPdfPage(path: state.uri.queryParameters['path']),
    ),
    // Full featured file viewer (dark-themed page, supports PDFs and images)
    GoRoute(
      name: AppRouteName.pdfViewer,
      path: '/pdf/viewer',
      parentNavigatorKey: rootNavKey,
      builder: (context, state) {
        final raw = state.uri.queryParameters['showOptionsSheet'];
        final showOptionsSheet =
            raw == null || (raw != '0' && raw.toLowerCase() != 'false');

        return FileViewerPage(
          path: state.uri.queryParameters['path'],
          showOptionsSheet: showOptionsSheet,
        );
      },
    ),
    GoRoute(
      name: AppRouteName.mergePdf,
      path: '/pdf/merge',
      parentNavigatorKey: rootNavKey,
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
      parentNavigatorKey: rootNavKey,
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
      parentNavigatorKey: rootNavKey,
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
        String? initialPath;
        String? title;
        String? description;

        if (state.extra is Map<String, dynamic>) {
          final args = state.extra as Map<String, dynamic>;
          initialPath = args['path'] as String?;
          title = args['title'] as String?;
          description = args['description'] as String?;
        } else if (state.extra is String) {
          initialPath = state.extra as String?;
        }

        return MaterialPage(
          key: state.pageKey,
          child: FolderPickerPage(
            initialPath: initialPath,
            title: title,
            description: description,
          ),
        );
      },
    ),

    GoRoute(
      name: AppRouteName.compressPdf,
      path: '/pdf/compress',
      parentNavigatorKey: rootNavKey,
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
      name: AppRouteName.pdfToImage,
      path: '/pdf/to-image',
      parentNavigatorKey: rootNavKey,
      builder: (context, state) {
        final selectionId = state.uri.queryParameters['selectionId'];
        if (selectionId != null) {
          try {
            final provider = Get.find<SelectionManager>().of(selectionId);
            return ChangeNotifierProvider<SelectionProvider>.value(
              value: provider,
              child: PdfToImagePage(selectionId: selectionId),
            );
          } catch (_) {}
        }
        return ChangeNotifierProvider(
          create: (_) => SelectionProvider(),
          child: const PdfToImagePage(),
        );
      },
    ),
    GoRoute(
      name: AppRouteName.imagesToPdf,
      path: '/images/to-pdf',
      parentNavigatorKey: rootNavKey,
      builder: (context, state) {
        final selectionId = state.uri.queryParameters['selectionId'];
        if (selectionId != null) {
          // reuse provider from SelectionManager cache
          final provider = Get.find<SelectionManager>().of(selectionId);
          return ChangeNotifierProvider<SelectionProvider>.value(
            value: provider,
            child: ImagesToPdfPage(selectionId: selectionId),
          );
        }
        // fallback: create a fresh provider scoped to this route
        return ChangeNotifierProvider(
          create: (_) => SelectionProvider(),
          child: const ImagesToPdfPage(),
        );
      },
    ),
    GoRoute(
      name: AppRouteName.reorderPdf,
      path: '/pdf/reorder',
      parentNavigatorKey: rootNavKey,
      builder: (context, state) {
        final selectionId = state.uri.queryParameters['selectionId'];
        if (selectionId != null) {
          try {
            final provider = Get.find<SelectionManager>().of(selectionId);
            return ChangeNotifierProvider<SelectionProvider>.value(
              value: provider,
              child: ReorderPdfPage(selectionId: selectionId),
            );
          } catch (_) {}
        }
        return ChangeNotifierProvider(
          create: (_) => SelectionProvider(),
          child: const ReorderPdfPage(),
        );
      },
    ),
    GoRoute(
      name: AppRouteName.splitPdf,
      path: '/pdf/split',
      parentNavigatorKey: rootNavKey,
      builder: (context, state) {
        final selectionId = state.uri.queryParameters['selectionId'];
        if (selectionId != null) {
          try {
            final provider = Get.find<SelectionManager>().of(selectionId);
            return ChangeNotifierProvider<SelectionProvider>.value(
              value: provider,
              child: SplitPdfPage(selectionId: selectionId),
            );
          } catch (_) {}
        }
        return ChangeNotifierProvider(
          create: (_) => SelectionProvider(),
          child: const SplitPdfPage(),
        );
      },
    ),
    GoRoute(
      name: AppRouteName.recentFilesSearch,
      path: '/recent-files/search',
      parentNavigatorKey: rootNavKey,
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
