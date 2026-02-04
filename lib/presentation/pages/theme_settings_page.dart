import 'package:flutter/material.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/providers/theme_provider.dart';

class ThemeSettingsPage extends StatefulWidget {
  const ThemeSettingsPage({super.key});

  @override
  State<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends State<ThemeSettingsPage> {
  String _selectedTheme = 'system'; // 'light', 'dark', 'system'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ThemeProvider>();
      setState(() {
        _selectedTheme = provider.selectedTheme;
      });
    });
  }

  Future<void> _saveThemePreference(String theme) async {
    setState(() {
      _selectedTheme = theme;
    });
    final provider = context.read<ThemeProvider>();
    await provider.setTheme(theme);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.t('theme_settings_page_title'),
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                t.t('theme_settings_info_message'),
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
              ),
              const SizedBox(height: 16),

              // // Theme options
              // Text(
              //   t.t('theme_settings_choose_label'),
              //   style: theme.textTheme.titleMedium?.copyWith(
              //     fontWeight: FontWeight.w600,
              //   ),
              // ),
              // const SizedBox(height: 16),

              // Light theme option
              _buildThemeOption(
                context: context,
                value: 'light',
                title: t.t('theme_settings_light_title'),
                subtitle: t.t('theme_settings_light_subtitle'),
                icon: Icons.light_mode,
                iconColor: Colors.amber,
              ),

              const SizedBox(height: 12),

              // Dark theme option
              _buildThemeOption(
                context: context,
                value: 'dark',
                title: t.t('theme_settings_dark_title'),
                subtitle: t.t('theme_settings_dark_subtitle'),
                icon: Icons.dark_mode,
                iconColor: Colors.indigo,
              ),

              const SizedBox(height: 12),

              // System theme option
              _buildThemeOption(
                context: context,
                value: 'system',
                title: t.t('theme_settings_system_title'),
                subtitle: t.t('theme_settings_system_subtitle'),
                icon: Icons.settings_suggest,
                iconColor: Colors.teal,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);
    final isSelected = _selectedTheme == value;

    return InkWell(
      onTap: () => _saveThemePreference(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.08)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.dividerColor.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.textTheme.titleMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 18),
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.dividerColor, width: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
