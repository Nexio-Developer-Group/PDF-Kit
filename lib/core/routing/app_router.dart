// app_router.dart
import 'package:flutter/material.dart';
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
  initialLocation: '/',
  errorBuilder: (context, state) =>
      NotFoundPage(routeName: state.uri.toString()),
  routes: [
    GoRoute(
      name: AppRouteName.onboarding,
      path: '/onboarding',
      builder: (context, state) => const OnboardingPage(),
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
      builder: (context, state) => const AddSignaturePage(),
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
      builder: (context, state) => const CompressPdfPage(),
    ),
  ],
);

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Onboarding')));
}

class AllFilesPage extends StatelessWidget {
  const AllFilesPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('All Files & Folders')));
}

class SearchFilePage extends StatelessWidget {
  const SearchFilePage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Search Files')));
}

class PreferencesPage extends StatelessWidget {
  const PreferencesPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Preferences')));
}

class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Language Settings')));
}

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Contact Us')));
}

class AboutAppPage extends StatelessWidget {
  const AboutAppPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('About the App')));
}

class TakeImagePage extends StatelessWidget {
  const TakeImagePage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Take Image')));
}

class ShowPdfPage extends StatelessWidget {
  final String? path; // optional argument example
  const ShowPdfPage({super.key, this.path});
  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text('Show PDF: ${path ?? 'no path'}')));
}

class RecentFilesPage extends StatelessWidget {
  const RecentFilesPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Recent Files')));
}

class AddWatermarkPage extends StatelessWidget {
  const AddWatermarkPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Add Watermark')));
}

class AddSignaturePage extends StatelessWidget {
  const AddSignaturePage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Add Digital Signature')));
}

class CompressPdfPage extends StatelessWidget {
  const CompressPdfPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Compress PDF')));
}

class NotFoundPage extends StatelessWidget {
  final String? routeName;
  const NotFoundPage({super.key, this.routeName});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Page not found')),
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('No route defined for: ${routeName ?? 'unknown'}'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.of(
              context,
            ).pushNamedAndRemoveUntil(AppRouteName.home, (r) => false),
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  );
}
