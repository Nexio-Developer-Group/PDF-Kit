import 'package:flutter/material.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/core/constants.dart';

class PdfKitSplashPage extends StatefulWidget {
  const PdfKitSplashPage({super.key});

  @override
  State<PdfKitSplashPage> createState() => _PdfKitSplashPageState();
}

class _PdfKitSplashPageState extends State<PdfKitSplashPage> {
  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // If onboarding already completed, go to home; otherwise, show onboarding.
    final completed =
        Prefs.getBool(Constants.prefsOnboardingCompletedKey) ?? false;
    if (completed) {
      context.goNamed(AppRouteName.home);
    } else {
      context.goNamed(AppRouteName.onboardingShell);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Larger centered app icon
            SizedBox(
              width: 140,
              height: 140,
              child: Image.asset(
                'assets/app_icon1.png',
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) =>
                    Icon(Icons.picture_as_pdf, size: 140, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'PDF Kit',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context).t('onboarding_tagline'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            const SizedBox(
              height: 36,
              width: 36,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ],
        ),
      ),
    );
  }
}
