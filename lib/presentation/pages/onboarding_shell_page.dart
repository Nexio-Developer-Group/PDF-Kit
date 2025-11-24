import 'package:flutter/material.dart';
import 'package:pdf_kit/models/onboarding_model.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/core/constants.dart';
import 'package:pdf_kit/providers/locale_provider.dart';

class OnboardingShellPage extends StatefulWidget {
  const OnboardingShellPage({super.key});

  @override
  State<OnboardingShellPage> createState() => _OnboardingShellPageState();
}

class _OnboardingShellPageState extends State<OnboardingShellPage> {
  final PageController _pageController = PageController();

  int _currentIndex = 0;

  List<OnboardingPageModel> _buildPages(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    return [
      OnboardingPageModel(
        title: t('onboarding_screen1_title'),
        subtitle: t('onboarding_screen1_subtitle'),
        content: const OnboardingContentView(child: OnboardingImage1()),
      ),
      OnboardingPageModel(
        title: t('onboarding_screen2_title'),
        subtitle: t('onboarding_screen2_subtitle'),
        content: const OnboardingContentView(child: OnboardingImage2()),
      ),
      OnboardingPageModel(
        title: t('onboarding_screen3_title'),
        subtitle: t('onboarding_screen3_subtitle'),
        content: const OnboardingContentView(child: OnboardingImage3()),
      ),
      OnboardingPageModel(
        title: t('onboarding_screen4_title'),
        subtitle: t('onboarding_screen4_subtitle'),
        content: const OnboardingContentView(child: LanguageSelectionContent()),
      ),
    ];
  }

  void _goNext(BuildContext context) {
    final pages = _buildPages(context);
    if (_currentIndex < pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() {
    if (!mounted) return;

    // Mark onboarding as completed and navigate to home
    Prefs.setBool(Constants.prefsOnboardingCompletedKey, true);
    context.goNamed(AppRouteName.home);
  }

  // Skip button removed — navigation handled via the Next/Get started and Back buttons.

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context).t;
    final pages = _buildPages(context);

    return Scaffold(
      body: Stack(
        children: [
          // Large central circle in upper portion
          // Positioned(
          //   top: size.height * 0.15,
          //   left: size.width * 0.22,
          //   child: _circle(size.width * 0.55, Colors.blue.withOpacity(0.2)),
          // ),
          // // Scattered smaller circles - mostly in upper part
          // Positioned(
          //   top: size.height * 0.08,
          //   left: size.width * 0.15,
          //   child: _circle(60, Colors.blue.withOpacity(0.15)),
          // ),
          // Positioned(
          //   top: size.height * 0.12,
          //   right: size.width * 0.1,
          //   child: _circle(35, Colors.blue.withOpacity(0.25)),
          // ),
          // Positioned(
          //   top: size.height * 0.25,
          //   left: size.width * 0.05,
          //   child: _circle(28, Colors.blue.withOpacity(0.18)),
          // ),
          // Positioned(
          //   top: size.height * 0.32,
          //   right: size.width * 0.15,
          //   child: _circle(42, Colors.blue.withOpacity(0.22)),
          // ),
          // Positioned(
          //   top: size.height * 0.35,
          //   left: size.width * 0.08,
          //   child: _circle(32, Colors.blue.withOpacity(0.17)),
          // ),
          // // Few small circles at bottom
          // Positioned(
          //   bottom: size.height * 0.15,
          //   right: size.width * 0.2,
          //   child: _circle(22, Colors.blue.withOpacity(0.2)),
          // ),
          // Positioned(
          //   bottom: size.height * 0.12,
          //   left: size.width * 0.18,
          //   child: _circle(18, Colors.blue.withOpacity(0.15)),
          // ),

          // content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: pages.length,
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);
                    },
                    itemBuilder: (context, index) {
                      final page = pages[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            Expanded(flex: 65, child: page.content),
                            Expanded(
                              flex: 35,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    page.title,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    page.subtitle,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // page indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(pages.length, (index) {
                    final isActive = index == _currentIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      height: 6,
                      width: isActive ? 20 : 6,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.blue
                            : Colors.blue.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 24),

                // buttons
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      // Replace 'Skip' with a back/previous button on pages after the first.
                      if (_currentIndex == 0)
                        const Expanded(child: SizedBox())
                      else
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              if (_currentIndex > 0) {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                );
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Text(t('onboarding_button_back')),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _goNext(context),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            backgroundColor: Colors.blue,
                          ),
                          child: Text(
                            _currentIndex == pages.length - 1
                                ? t('onboarding_button_get_started')
                                : t('onboarding_button_next'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingContentView extends StatelessWidget {
  final Widget child;

  const OnboardingContentView({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class OnboardingImage1 extends StatelessWidget {
  const OnboardingImage1({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.6;
    return Center(
      child: Image.asset(
        'assets/onboarding1.png',
        width: width,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.shield_outlined,
            size: 120,
            color: Colors.blue,
          );
        },
      ),
    );
  }
}

class OnboardingImage2 extends StatelessWidget {
  const OnboardingImage2({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.6;
    return Center(
      child: Image.asset(
        'assets/onboarding2.png',
        width: width,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.build_circle_outlined,
            size: 120,
            color: Colors.blue,
          );
        },
      ),
    );
  }
}

class OnboardingImage3 extends StatelessWidget {
  const OnboardingImage3({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.6;
    return Center(
      child: Image.asset(
        'assets/onboarding3.png',
        width: width,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.lock_outline, size: 120, color: Colors.blue);
        },
      ),
    );
  }
}

class LanguageSelectionContent extends StatefulWidget {
  const LanguageSelectionContent({super.key});

  @override
  State<LanguageSelectionContent> createState() =>
      _LanguageSelectionContentState();
}

class _LanguageSelectionContentState extends State<LanguageSelectionContent> {
  static const _languages = [
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'hi', 'name': 'हिन्दी', 'flag': '🇮🇳'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
    {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦'},
    {'code': 'bn', 'name': 'বাংলা', 'flag': '🇧🇩'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'ja', 'name': '日本語', 'flag': '🇯🇵'},
    {'code': 'pt', 'name': 'Português', 'flag': '🇵🇹'},
    {'code': 'zh', 'name': '中文', 'flag': '🇨🇳'},
  ];

  String? _selectedLanguage;

  @override
  void initState() {
    super.initState();
    // Get current language from provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<LocaleProvider>();
      setState(() {
        _selectedLanguage = provider.locale?.languageCode ?? 'en';
      });
    });
  }

  void _selectLanguage(String code) {
    setState(() {
      _selectedLanguage = code;
    });
    // Update language in provider
    final provider = context.read<LocaleProvider>();
    provider.setLocale(code);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemCount: _languages.length,
          itemBuilder: (context, index) {
            final lang = _languages[index];
            final code = lang['code']!;
            final isSelected = _selectedLanguage == code;

            return InkWell(
              onTap: () => _selectLanguage(code),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.1),
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        lang['name']!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          // color: isSelected ? Colors.blue : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.check_circle,
                        color: Colors.blue,
                        size: 18,
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
