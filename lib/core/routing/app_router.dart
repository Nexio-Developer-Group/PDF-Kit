import 'package:flutter/material.dart';

// Route name constants
class AppRoutes {
  static const String home = '/';
  static const String onboarding = '/onboarding';
  static const String allFiles = '/files';
  static const String search = '/search';
  static const String preferences = '/preferences';
  static const String language = '/language';
  static const String contactUs = '/contact';
  static const String aboutApp = '/about';
  static const String takeImage = '/camera';
  static const String showPdf = '/pdf/view';
  static const String recent = '/recent';
  static const String addWatermark = '/pdf/watermark';
  static const String addSignature = '/pdf/signature';
  static const String mergePdf = '/pdf/merge';
  static const String protectPdf = '/pdf/protect';
  static const String compressPdf = '/pdf/compress';
}

// Stub pages (replace with your real screens)
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Onboarding')));
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Home')));
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

class MergePdfPage extends StatelessWidget {
  const MergePdfPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Merge PDFs')));
}

class ProtectPdfPage extends StatelessWidget {
  const ProtectPdfPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Protect PDF')));
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
            ).pushNamedAndRemoveUntil(AppRoutes.home, (r) => false),
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  );
}

// Centralized route generator
class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return _material(const HomePage(), settings);
      case AppRoutes.onboarding:
        return _material(const OnboardingPage(), settings);
      case AppRoutes.allFiles:
        return _material(const AllFilesPage(), settings);
      case AppRoutes.search:
        return _material(const SearchFilePage(), settings);
      case AppRoutes.preferences:
        return _material(const PreferencesPage(), settings);
      case AppRoutes.language:
        return _material(const LanguageSettingsPage(), settings);
      case AppRoutes.contactUs:
        return _material(const ContactUsPage(), settings);
      case AppRoutes.aboutApp:
        return _material(const AboutAppPage(), settings);
      case AppRoutes.takeImage:
        return _material(const TakeImagePage(), settings);
      case AppRoutes.showPdf:
        // Example: accept an argument map with 'path'
        final args = settings.arguments;
        String? path;
        if (args is Map && args['path'] is String) {
          path = args['path'] as String;
        }
        return _material(ShowPdfPage(path: path), settings);
      case AppRoutes.recent:
        return _material(const RecentFilesPage(), settings);
      case AppRoutes.addWatermark:
        return _material(const AddWatermarkPage(), settings);
      case AppRoutes.addSignature:
        return _material(const AddSignaturePage(), settings);
      case AppRoutes.mergePdf:
        return _material(const MergePdfPage(), settings);
      case AppRoutes.protectPdf:
        return _material(const ProtectPdfPage(), settings);
      case AppRoutes.compressPdf:
        return _material(const CompressPdfPage(), settings);
      default:
        // Let onUnknownRoute handle anything not matched here
        return _unknown(settings);
    }
  }

  static Route<dynamic> onUnknownRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => NotFoundPage(routeName: settings.name),
    );
  }

  static MaterialPageRoute _material(Widget page, RouteSettings settings) {
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }

  static Route<dynamic> _unknown(RouteSettings settings) =>
      onUnknownRoute(settings);
}
