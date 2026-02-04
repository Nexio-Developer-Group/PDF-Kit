import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/service/permission_service.dart';
import 'package:pdf_kit/service/remote_config_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPdfKitPage extends StatelessWidget {
  const AboutPdfKitPage({super.key});

  static const _appName = 'PDF Seva';

  Future<List<_AboutPermissionItem>> _loadPermissionItems(
    BuildContext context,
  ) async {
    if (kIsWeb) return const [];
    if (defaultTargetPlatform != TargetPlatform.android) return const [];

    final t = AppLocalizations.of(context);

    final items = <_AboutPermissionItem>[
      _AboutPermissionItem(
        title: t.t('about_pdf_kit_permission_all_files_title'),
        purpose: t.t('about_pdf_kit_permission_all_files_purpose'),
        permission: Permission.manageExternalStorage,
      ),
      _AboutPermissionItem(
        title: t.t('about_pdf_kit_permission_photos_title'),
        purpose: t.t('about_pdf_kit_permission_photos_purpose'),
        permission: Permission.photos,
      ),
      _AboutPermissionItem(
        title: t.t('about_pdf_kit_permission_videos_title'),
        purpose: t.t('about_pdf_kit_permission_videos_purpose'),
        permission: Permission.videos,
      ),
    ];

    for (final item in items) {
      item.status = await item.permission.status;
    }

    return items;
  }

  Future<void> _handlePermissionTap(
    BuildContext context,
    _AboutPermissionItem item,
  ) async {
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android) return;

    await item.permission.request();
    if (!context.mounted) return;

    // Android doesn't provide a consistent deep-link to a single permission page
    // across OEMs. Best-available behavior is to open the app's permissions screen.
    if (item.permission == Permission.manageExternalStorage) {
      await PermissionService.openAllFilesAccessPage();
    } else {
      await PermissionService.openAppPermissionsPage();
    }
  }

  Future<void> _openPrivacyPolicy(BuildContext context, String url) async {
    final t = AppLocalizations.of(context);
    final uri = Uri.tryParse(url);
    if (uri == null) {
      AppSnackbar.show(t.t('about_pdf_kit_error_invalid_privacy_url'));
      return;
    }

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      AppSnackbar.show(t.t('about_pdf_kit_error_could_not_open_link'));
    }
  }

  Widget _headerCard(BuildContext context, {required String versionText}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(
          20,
        ), // Increased padding for better spacing
        child: Column(
          children: [
            Container(
              width: 72, // Slightly larger icon container
              height: 72,
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  'assets/app_icon.png',
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Icon(
                    Icons.picture_as_pdf_rounded,
                    size: 36,
                    color: cs.onPrimary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _appName,
              style: theme.textTheme.headlineSmall?.copyWith(
                // Larger title
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: cs.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                versionText,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // const SizedBox(height: 12),
            // Text(
            //   'Lightweight PDF utilities — local processing, no accounts.',
            //   textAlign: TextAlign.center,
            //   style: theme.textTheme.bodyMedium?.copyWith(
            //     color: cs.onSurfaceVariant,
            //     height: 1.5,
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
    Widget? headerAction,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 56,
                          height: 3,
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (headerAction != null) ...[
                  const SizedBox(width: 8),
                  headerAction,
                ],
              ],
            ),
            // const SizedBox(height: 8),
            // Align(
            //   alignment: Alignment.centerLeft,
            //   child: Container(
            //     width: 56,
            //     height: 3,
            //     decoration: BoxDecoration(
            //       color: cs.primary,
            //       borderRadius: BorderRadius.circular(99),
            //     ),
            //   ),
            // ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  // Widget _simpleTile(
  //   BuildContext context, {
  //   required IconData icon,
  //   required String title,
  //   String? subtitle,
  //   VoidCallback? onTap,
  //   Widget? trailing,
  // }) {
  //   final theme = Theme.of(context);
  //   final cs = theme.colorScheme;

  //   return Material(
  //     color: Colors.transparent,
  //     child: InkWell(
  //       onTap: onTap,
  //       borderRadius: BorderRadius.circular(10),
  //       child: Padding(
  //         padding: const EdgeInsets.symmetric(vertical: 6),
  //         child: Row(
  //           children: [
  //             Container(
  //               padding: const EdgeInsets.all(8),
  //               decoration: BoxDecoration(
  //                 color: cs.primaryContainer.withValues(alpha: 0.45),
  //                 borderRadius: BorderRadius.circular(8),
  //               ),
  //               child: Icon(icon, size: 18, color: cs.primary),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     title,
  //                     style: theme.textTheme.bodyMedium?.copyWith(
  //                       fontWeight: FontWeight.w600,
  //                     ),
  //                   ),
  //                   if (subtitle != null) ...[
  //                     const SizedBox(height: 2),
  //                     Text(
  //                       subtitle,
  //                       style: theme.textTheme.bodyMedium?.copyWith(
  //                         color: cs.onSurfaceVariant,
  //                       ),
  //                     ),
  //                   ],
  //                 ],
  //               ),
  //             ),
  //             if (trailing != null) ...[
  //               const SizedBox(width: 8),
  //               trailing,
  //             ] else if (onTap != null) ...[
  //               const SizedBox(width: 8),
  //               Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 18),
  //             ],
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _paragraph(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        height: 1.4,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }

  // Widget _subTitle(BuildContext context, String text) {
  //   final theme = Theme.of(context);
  //   final cs = theme.colorScheme;

  //   return Padding(
  //     padding: const EdgeInsets.only(top: 12, bottom: 6),
  //     child: Row(
  //       children: [
  //         Expanded(
  //           child: Text(
  //             text,
  //             style: theme.textTheme.titleSmall?.copyWith(
  //               fontWeight: FontWeight.bold,
  //               color: cs.onSurface,
  //             ),
  //           ),
  //         ),
  //         const SizedBox(width: 12),
  //         Expanded(
  //           child: Divider(
  //             height: 1,
  //             color: cs.outlineVariant.withValues(alpha: 0.4),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _permissionCard(BuildContext context, _AboutPermissionItem item) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      // color: cs.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: Theme.of(context).brightness == Brightness.light
            ? BorderSide(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.15),
                width: 1,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _handlePermissionTap(context, item),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.security_rounded,
                  size: 18,
                  color: cs.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _statusPill(context, item.status),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.purpose,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bullet(BuildContext context, String text, {Color? color}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final effectiveColor = color ?? cs.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(
              Icons.check_circle_rounded,
              size: 14,
              color: cs.primary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: effectiveColor,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kvRow(BuildContext context, {required String k, required String v}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              k,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              v,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _wrapBlock(BuildContext context, String text) {
  //   final theme = Theme.of(context);
  //   final cs = theme.colorScheme;

  //   return Container(
  //     width: double.infinity,
  //     padding: const EdgeInsets.all(12),
  //     decoration: BoxDecoration(
  //       color: cs.surface,
  //       borderRadius: BorderRadius.circular(12),
  //     ),
  //     child: SelectableText(
  //       text,
  //       style: theme.textTheme.bodyMedium?.copyWith(
  //         height: 1.3,
  //         color: cs.onSurfaceVariant,
  //       ),
  //     ),
  //   );
  // }

  Widget _permissionStatusTile(
    BuildContext context,
    _AboutPermissionItem item,
  ) {
    return _permissionCard(context, item);
  }

  Widget _statusPill(BuildContext context, PermissionStatus? status) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final text = _statusText(context, status);

    final Color bg;
    final Color fg;
    final Color border;

    switch (status) {
      case PermissionStatus.granted:
      case PermissionStatus.limited:
        bg = cs.surface;
        fg = cs.primary;
        border = cs.primary.withValues(alpha: 0.45);
        break;
      case PermissionStatus.permanentlyDenied:
        bg = cs.errorContainer;
        fg = cs.onErrorContainer;
        border = cs.error.withValues(alpha: 0.4);
        break;
      case PermissionStatus.denied:
      case PermissionStatus.provisional:
      case PermissionStatus.restricted:
      case null:
        bg = cs.surface;
        fg = cs.onSurfaceVariant;
        border = cs.outlineVariant.withValues(alpha: 0.6);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  String _statusText(BuildContext context, PermissionStatus? status) {
    final t = AppLocalizations.of(context);
    return switch (status) {
      PermissionStatus.granted => t.t(
        'about_pdf_kit_permission_status_granted',
      ),
      PermissionStatus.limited => t.t(
        'about_pdf_kit_permission_status_limited',
      ),
      PermissionStatus.denied => t.t('about_pdf_kit_permission_status_denied'),
      PermissionStatus.restricted => t.t(
        'about_pdf_kit_permission_status_restricted',
      ),
      PermissionStatus.permanentlyDenied => t.t(
        'about_pdf_kit_permission_status_blocked',
      ),
      PermissionStatus.provisional => t.t(
        'about_pdf_kit_permission_status_provisional',
      ),
      null => t.t('about_pdf_kit_permission_status_unknown'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    const buildNumber = String.fromEnvironment(
      'FLUTTER_BUILD_NUMBER',
      defaultValue: '1',
    );

    final defaultCfg = AppRemoteConfig.defaults;

    return FutureBuilder<AppRemoteConfig>(
      future: RemoteConfigService.instance.getConfig(),
      builder: (context, snapshot) {
        final cfg = snapshot.data ?? defaultCfg;

        final versionText = 'v${cfg.appVersion}+$buildNumber';

        return Scaffold(
          appBar: AppBar(
            title: Text(
              t.t('settings_about_pdf_kit_title'),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: screenPadding,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _headerCard(context, versionText: versionText),

                  // const SizedBox(height: 8),
                  _sectionCard(
                    context,
                    title: t.t('about_pdf_kit_section_app_info'),
                    children: [
                      _kvRow(
                        context,
                        k: t.t('about_pdf_kit_app_name_label'),
                        v: _appName,
                      ),
                      _kvRow(
                        context,
                        k: t.t('about_pdf_kit_package_name_label'),
                        v: 'cloud.nexiotech.pdfseva',
                      ),
                      _kvRow(
                        context,
                        k: t.t('about_pdf_kit_version_label'),
                        v: versionText,
                      ),
                      _kvRow(
                        context,
                        k: t.t('about_pdf_kit_api_levels_label'),
                        v: '${cfg.apiLevel}+',
                      ),
                      _kvRow(
                        context,
                        k: t.t('about_pdf_kit_target_sdk_label'),
                        v: cfg.targetSdkVersion,
                      ),
                    ],
                  ),

                  // const SizedBox(height: 16),
                  _sectionCard(
                    context,
                    title: t.t('about_pdf_kit_section_what_is'),
                    children: [
                      _paragraph(context, t.t('about_pdf_kit_description_1')),
                      const SizedBox(height: 12),
                      _paragraph(context, t.t('about_pdf_kit_description_2')),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _sectionCard(
                    context,
                    title: t.t('about_pdf_kit_section_features'),
                    children: [
                      _bullet(context, t.t('about_pdf_kit_feature_1')),
                      _bullet(context, t.t('about_pdf_kit_feature_2')),
                      _bullet(context, t.t('about_pdf_kit_feature_3')),
                      _bullet(context, t.t('about_pdf_kit_feature_4')),
                      _bullet(context, t.t('about_pdf_kit_feature_5')),
                      _bullet(context, t.t('about_pdf_kit_feature_6')),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _sectionCard(
                    context,
                    title: t.t('about_pdf_kit_section_permissions'),
                    headerAction: !isAndroid
                        ? null
                        : IconButton(
                            onPressed: () => openAppSettings(),
                            icon: const Icon(Icons.settings, size: 20),
                            // label: Text('Settings', style: Theme.of(context).textTheme.labelMedium,),
                            // style: OutlinedButton.styleFrom(
                            //   shape: const StadiumBorder(),
                            //   padding: const EdgeInsets.symmetric(
                            //     horizontal: 12,
                            //     vertical: 8,
                            //   ),
                            //   side: BorderSide(
                            //     color: Theme.of(
                            //       context,
                            //     ).colorScheme.primary.withValues(alpha: 0.35),
                            //   ),
                            //   foregroundColor: Theme.of(
                            //     context,
                            //   ).colorScheme.primary,
                            // ),
                          ),
                    children: [
                      _paragraph(
                        context,
                        t.t('about_pdf_kit_permissions_description'),
                      ),
                      const SizedBox(height: 12),
                      if (!isAndroid)
                        _paragraph(
                          context,
                          t.t('about_pdf_kit_permissions_android_only'),
                        )
                      else
                        FutureBuilder<List<_AboutPermissionItem>>(
                          future: _loadPermissionItems(context),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const LinearProgressIndicator();
                            }

                            final items = snapshot.data ?? const [];
                            if (items.isEmpty) {
                              return _paragraph(
                                context,
                                t.t('about_pdf_kit_permissions_read_error'),
                              );
                            }

                            return Column(
                              children: [
                                for (var i = 0; i < items.length; i++) ...[
                                  _permissionStatusTile(context, items[i]),
                                  if (i != items.length - 1)
                                    const SizedBox(height: 10),
                                ],
                              ],
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _sectionCard(
                    context,
                    title: t.t('about_pdf_kit_section_privacy'),
                    children: [
                      _bullet(context, t.t('about_pdf_kit_privacy_bullet_1')),
                      _bullet(context, t.t('about_pdf_kit_privacy_bullet_2')),
                      _bullet(context, t.t('about_pdf_kit_privacy_bullet_3')),
                      _bullet(context, t.t('about_pdf_kit_privacy_bullet_4')),
                      const SizedBox(height: 12),
                      Card(
                        margin: EdgeInsets.zero,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: Theme.of(context).brightness == Brightness.light
                              ? BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.outline.withValues(alpha: 0.15),
                                  width: 1,
                                )
                              : BorderSide.none,
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _openPrivacyPolicy(
                            context,
                            cfg.privacyPolicyLink,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                        .withValues(alpha: 0.45),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.privacy_tip_outlined,
                                    size: 18,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.t(
                                          'about_pdf_kit_privacy_policy_title',
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        t.t(
                                          'about_pdf_kit_privacy_policy_subtitle',
                                        ),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                              height: 1.3,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.open_in_new,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AboutPermissionItem {
  _AboutPermissionItem({
    required this.title,
    required this.permission,
    required this.purpose,
  });

  final String title;
  final Permission permission;
  final String purpose;

  PermissionStatus? status;
}
