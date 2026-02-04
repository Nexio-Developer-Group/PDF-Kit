import 'package:flutter/material.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/service/remote_config_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  Future<void> _launchUri(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      AppSnackbar.show('Could not open the link');
    }
  }

  Widget _headerCard(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final t = AppLocalizations.of(context);

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.t('about_us_org_name'),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.brightness == Brightness.dark
                      ? Colors.white
                      : cs.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    'assets/logo-light-full.png',
                    height: 72,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => Image.asset(
                      'assets/logo-light-full.png',
                      height: 72,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) =>
                          Icon(Icons.business, size: 56, color: cs.primary),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
            Text(
              t.t('about_us_description'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 2),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _linkTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(t.t('settings_about_us_title'))),
      body: SafeArea(
        child: Padding(
          padding: screenPadding,
          child: FutureBuilder<AppRemoteConfig>(
            future: RemoteConfigService.instance.getConfig(),
            builder: (context, snapshot) {
              final cfg = snapshot.data ?? AppRemoteConfig.defaults;

              return ListView(
                children: [
                  _headerCard(context),
                  const SizedBox(height: 12),
                  _sectionCard(
                    context,
                    title: t.t('about_us_links_section_title'),
                    children: [
                      _linkTile(
                        context,
                        icon: Icons.language,
                        title: t.t('about_us_link_website_title'),
                        subtitle: cfg.orgWebsiteLink,
                        onTap: () =>
                            _launchUri(context, Uri.parse(cfg.orgWebsiteLink)),
                      ),
                      _linkTile(
                        context,
                        icon: Icons.help_outline,
                        title: t.t('about_us_link_help_title'),
                        subtitle: cfg.orgHelpMail,
                        onTap: () => _launchUri(
                          context,
                          Uri(scheme: 'mailto', path: cfg.orgHelpMail),
                        ),
                      ),
                      _linkTile(
                        context,
                        icon: Icons.connect_without_contact,
                        title: t.t('about_us_link_connect_title'),
                        subtitle: cfg.orgConnectMail,
                        onTap: () => _launchUri(
                          context,
                          Uri(scheme: 'mailto', path: cfg.orgConnectMail),
                        ),
                      ),
                      _linkTile(
                        context,
                        icon: Icons.call,
                        title: t.t('about_us_link_call_title'),
                        subtitle: cfg.orgContactNumber,
                        onTap: () => _launchUri(
                          context,
                          Uri(scheme: 'tel', path: cfg.orgContactNumber),
                        ),
                      ),
                      _linkTile(
                        context,
                        icon: Icons.code,
                        title: t.t('about_us_link_github_title'),
                        subtitle: cfg.orgGithubLink,
                        onTap: () =>
                            _launchUri(context, Uri.parse(cfg.orgGithubLink)),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
