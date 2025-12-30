import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf_kit/providers/file_system_provider.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:provider/provider.dart';
import 'package:pdf_kit/service/recent_file_service.dart';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/presentation/component/document_tile.dart';
import 'package:pdf_kit/service/open_service.dart';
import 'package:pdf_kit/presentation/sheets/rename_file_sheet.dart';
import 'package:pdf_kit/service/file_service.dart';
import 'package:pdf_kit/presentation/provider/selection_provider.dart';
import 'package:pdf_kit/presentation/layouts/selection_layout.dart';

/// Page displaying storage volumes (Internal Storage, SD Card, etc.)
/// This is the root page of the file browser at /files
class FilesRootPage extends StatefulWidget {
  final bool isFullscreenRoute;
  final String? selectionId;
  final String? selectionActionText;

  const FilesRootPage({
    super.key,
    this.isFullscreenRoute = false,
    this.selectionId,
    this.selectionActionText,
  });

  @override
  State<FilesRootPage> createState() => _FilesRootPageState();
}

class _FilesRootPageState extends State<FilesRootPage> {
  List<FileInfo>? _cachedRecentFiles;
  bool _isLoadingRecent = true;

  @override
  void initState() {
    super.initState();
    // Load storage roots when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FileSystemProvider>().loadRoots();
      _loadRecentFiles();
    });
  }

  Future<void> _loadRecentFiles() async {
    setState(() => _isLoadingRecent = true);
    final result = await RecentFilesService.getRecentFiles();
    result.fold(
      (error) {
        if (mounted) {
          setState(() {
            _cachedRecentFiles = [];
            _isLoadingRecent = false;
          });
        }
      },
      (files) {
        if (mounted) {
          setState(() {
            _cachedRecentFiles = files.take(5).toList();
            _isLoadingRecent = false;
          });
        }
      },
    );
  }

  SelectionProvider? _maybeProvider() {
    try {
      return SelectionScope.of(context);
    } catch (_) {
      return null;
    }
  }

  bool get _selectionEnabled =>
      widget.isFullscreenRoute && (_maybeProvider()?.isEnabled ?? false);

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final provider = context.watch<FileSystemProvider>();
    final roots = provider.roots;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: screenPadding,
          child: Column(
            children: [
              // Header
              Container(
                height: 56,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/app_icon.png',
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Icon(
                            Icons.widgets_rounded,
                            size: 24,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      t.t('files_header_title'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick access cards in grid
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Padding(
                          //   padding: const EdgeInsets.symmetric(horizontal: 12),
                          //   child:
                          Text(
                            t.t('files_quick_access_title'),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          // ),
                          const SizedBox(height: 8),
                          Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildQuickAccessGridItem(
                                      context,
                                      icon: Icons.history,
                                      label: t.t('recent_files_title'),
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      onTap: () {
                                        final routeName =
                                            widget.isFullscreenRoute
                                            ? AppRouteName.recentFilesFullscreen
                                            : AppRouteName.recentFiles;
                                        final params = <String, String>{};
                                        if (widget.selectionId != null) {
                                          params['selectionId'] =
                                              widget.selectionId!;
                                        }
                                        if (widget.selectionActionText !=
                                            null) {
                                          params['actionText'] =
                                              widget.selectionActionText!;
                                        }
                                        context.pushNamed(
                                          routeName,
                                          queryParameters: params,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildQuickAccessGridItem(
                                      context,
                                      icon: Icons.download,
                                      label: t.t('files_downloads_folder'),
                                      color: Colors.blue,
                                      onTap: () {
                                        final routeName =
                                            widget.isFullscreenRoute
                                            ? AppRouteName.filesFolderFullScreen
                                            : AppRouteName.filesFolder;
                                        final params = <String, String>{
                                          'path':
                                              '/storage/emulated/0/Download',
                                        };
                                        if (widget.selectionId != null) {
                                          params['selectionId'] =
                                              widget.selectionId!;
                                        }
                                        if (widget.selectionActionText !=
                                            null) {
                                          params['actionText'] =
                                              widget.selectionActionText!;
                                        }
                                        context.pushNamed(
                                          routeName,
                                          queryParameters: params,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildQuickAccessGridItem(
                                      context,
                                      icon: Icons.picture_as_pdf,
                                      label: t.t('files_pdfs_folder'),
                                      color: Colors.red,
                                      onTap: () {
                                        final routeName =
                                            widget.isFullscreenRoute
                                            ? AppRouteName.filesFolderFullScreen
                                            : AppRouteName.filesFolder;
                                        final params = <String, String>{
                                          'path':
                                              '/storage/emulated/0/Download',
                                        };
                                        if (widget.selectionId != null) {
                                          params['selectionId'] =
                                              widget.selectionId!;
                                        }
                                        if (widget.selectionActionText !=
                                            null) {
                                          params['actionText'] =
                                              widget.selectionActionText!;
                                        }
                                        context.pushNamed(
                                          routeName,
                                          queryParameters: params,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _buildQuickAccessGridItem(
                                      context,
                                      icon: Icons.photo_library,
                                      label: t.t('files_images_folder'),
                                      color: Colors.purple,
                                      onTap: () {
                                        final routeName =
                                            widget.isFullscreenRoute
                                            ? AppRouteName.filesFolderFullScreen
                                            : AppRouteName.filesFolder;
                                        final params = <String, String>{
                                          'path':
                                              '/storage/emulated/0/DCIM/Camera',
                                        };
                                        if (widget.selectionId != null) {
                                          params['selectionId'] =
                                              widget.selectionId!;
                                        }
                                        if (widget.selectionActionText !=
                                            null) {
                                          params['actionText'] =
                                              widget.selectionActionText!;
                                        }
                                        context.pushNamed(
                                          routeName,
                                          queryParameters: params,
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildQuickAccessGridItem(
                                      context,
                                      icon: Icons.screenshot,
                                      label: t.t('files_screenshots_folder'),
                                      color: Colors.green,
                                      onTap: () {
                                        final routeName =
                                            widget.isFullscreenRoute
                                            ? AppRouteName.filesFolderFullScreen
                                            : AppRouteName.filesFolder;
                                        final params = <String, String>{
                                          'path':
                                              '/storage/emulated/0/DCIM/Screenshots',
                                        };
                                        if (widget.selectionId != null) {
                                          params['selectionId'] =
                                              widget.selectionId!;
                                        }
                                        if (widget.selectionActionText !=
                                            null) {
                                          params['actionText'] =
                                              widget.selectionActionText!;
                                        }
                                        context.pushNamed(
                                          routeName,
                                          queryParameters: params,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Expanded(child: SizedBox()),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Storage volumes list
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Padding(
                          //   padding: const EdgeInsets.symmetric(horizontal: 12),
                          //   child:
                          Text(
                            t.t('files_storage_title'),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          // ),
                          const SizedBox(height: 8),

                          roots.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const CircularProgressIndicator(),
                                      const SizedBox(height: 16),
                                      Text(t.t('files_loading_storage')),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  padding: EdgeInsets.zero,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: roots.length,
                                  itemBuilder: (context, index) {
                                    final root = roots[index];
                                    return _buildStorageCard(context, root);
                                  },
                                ),
                        ],
                      ),

                      // Recent Files section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Padding(
                          //   padding: const EdgeInsets.symmetric(horizontal: 12),
                          //   child:
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                t.t('recent_files_title'),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                ),
                                tooltip: t.t('recent_files_view_all_tooltip'),
                                onPressed: () {
                                  final routeName = widget.isFullscreenRoute
                                      ? AppRouteName.recentFilesFullscreen
                                      : AppRouteName.recentFiles;
                                  final params = <String, String>{};
                                  if (widget.selectionId != null) {
                                    params['selectionId'] = widget.selectionId!;
                                  }
                                  if (widget.selectionActionText != null) {
                                    params['actionText'] =
                                        widget.selectionActionText!;
                                  }
                                  context.pushNamed(
                                    routeName,
                                    queryParameters: params,
                                  );
                                },
                              ),
                            ],
                            // ),
                          ),
                          // const SizedBox(height: 4),
                          _buildRecentFilesPreview(context),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStorageCard(BuildContext context, Directory root) {
    final t = AppLocalizations.of(context);

    // Determine storage type from path
    final isInternal = root.path.contains('emulated');
    final storageName = isInternal
        ? t.t('files_internal_storage')
        : t.t('files_sd_card');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          // Navigate to folder browser with this root path
          // Use correct route based on selection mode
          final routeName = widget.isFullscreenRoute
              ? AppRouteName.filesFolderFullScreen
              : AppRouteName.filesFolder;

          final params = <String, String>{'path': root.path};
          if (widget.selectionId != null) {
            params['selectionId'] = widget.selectionId!;
          }
          if (widget.selectionActionText != null) {
            params['actionText'] = widget.selectionActionText!;
          }

          context.pushNamed(routeName, queryParameters: params);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isInternal ? Icons.phone_android : Icons.sd_card,
                  size: 28,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storageName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      root.path,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccessGridItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildRecentFilesCard(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Card(
      elevation: 2,
      child: Column(
        children: [
          InkWell(
            onTap: () {
              // Navigate to recent files (fullscreen if in selection mode)
              final routeName = widget.isFullscreenRoute
                  ? AppRouteName.recentFilesFullscreen
                  : AppRouteName.recentFiles;

              final params = <String, String>{};
              if (widget.selectionId != null) {
                params['selectionId'] = widget.selectionId!;
              }
              if (widget.selectionActionText != null) {
                params['actionText'] = widget.selectionActionText!;
              }

              context.pushNamed(routeName, queryParameters: params);
            },
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.history,
                    size: 28,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    t.t('recent_files_title'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Theme.of(context).dividerColor),
          InkWell(
            onTap: () {
              // Navigate to recent files search (fullscreen if in selection mode)
              final routeName = widget.isFullscreenRoute
                  ? AppRouteName.recentFilesSearchFullscreen
                  : AppRouteName.recentFilesSearch;

              final params = <String, String>{};
              if (widget.selectionId != null) {
                params['selectionId'] = widget.selectionId!;
              }
              if (widget.selectionActionText != null) {
                params['actionText'] = widget.selectionActionText!;
              }

              context.pushNamed(routeName, queryParameters: params);
            },
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.search,
                    size: 28,
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    t.t('recent_files_search_title'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDownloadsFolderCard(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Navigate to Downloads folder
          // Use correct route based on selection mode
          final routeName = widget.isFullscreenRoute
              ? AppRouteName.filesFolderFullScreen
              : AppRouteName.filesFolder;

          // Downloads folder path on Android
          final downloadsPath = '/storage/emulated/0/Download';

          final params = <String, String>{'path': downloadsPath};
          if (widget.selectionId != null) {
            params['selectionId'] = widget.selectionId!;
          }
          if (widget.selectionActionText != null) {
            params['actionText'] = widget.selectionActionText!;
          }

          context.pushNamed(routeName, queryParameters: params);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.download,
                  size: 28,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.t('files_downloads_folder'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '/storage/emulated/0/Download',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildPDFsCard(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Navigate to Downloads folder (for now, later can be PDF-specific location)
          final routeName = widget.isFullscreenRoute
              ? AppRouteName.filesFolderFullScreen
              : AppRouteName.filesFolder;

          // Navigate to Downloads folder for PDFs
          final pdfsPath = '/storage/emulated/0/Download';

          final params = <String, String>{'path': pdfsPath};
          if (widget.selectionId != null) {
            params['selectionId'] = widget.selectionId!;
          }
          if (widget.selectionActionText != null) {
            params['actionText'] = widget.selectionActionText!;
          }

          context.pushNamed(routeName, queryParameters: params);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.picture_as_pdf,
                  size: 28,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  t.t('files_pdfs_folder'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildImagesCard(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Navigate to DCIM/Camera folder
          final routeName = widget.isFullscreenRoute
              ? AppRouteName.filesFolderFullScreen
              : AppRouteName.filesFolder;

          // Try Camera folder first, fallback to DCIM if needed
          final imagesPath = '/storage/emulated/0/DCIM/Camera';

          final params = <String, String>{'path': imagesPath};
          if (widget.selectionId != null) {
            params['selectionId'] = widget.selectionId!;
          }
          if (widget.selectionActionText != null) {
            params['actionText'] = widget.selectionActionText!;
          }

          context.pushNamed(routeName, queryParameters: params);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.photo_library,
                  size: 28,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  t.t('files_images_folder'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildScreenshotsCard(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Navigate to Screenshots folder
          final routeName = widget.isFullscreenRoute
              ? AppRouteName.filesFolderFullScreen
              : AppRouteName.filesFolder;

          // Screenshots folder path on Android
          final screenshotsPath = '/storage/emulated/0/DCIM/Screenshots';

          final params = <String, String>{'path': screenshotsPath};
          if (widget.selectionId != null) {
            params['selectionId'] = widget.selectionId!;
          }
          if (widget.selectionActionText != null) {
            params['actionText'] = widget.selectionActionText!;
          }

          context.pushNamed(routeName, queryParameters: params);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.screenshot,
                  size: 28,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  t.t('files_screenshots_folder'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentFilesPreview(BuildContext context) {
    if (_isLoadingRecent) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final files = _cachedRecentFiles ?? [];

    if (files.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            AppLocalizations.of(context).t('recent_files_empty'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
          ),
        ),
      );
    }

    final pvd = _maybeProvider();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: files.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final file = files[index];
        return DocEntryCard(
          info: file,
          selectable: _selectionEnabled,
          selected: (pvd?.isSelected(file.path) ?? false),
          onToggleSelected: _selectionEnabled ? () => pvd?.toggle(file) : null,
          onOpen: _selectionEnabled
              ? () => pvd?.toggle(file)
              : () => OpenService.open(file.path),
          onLongPress: () {
            if (!_selectionEnabled) {
              pvd?.enable();
            }
            pvd?.toggle(file);
          },
          onMenu: (action) => _handleFileMenu(file, action),
        );
      },
    );
  }

  Future<void> _handleFileMenu(FileInfo file, String action) async {
    switch (action) {
      case 'open':
        OpenService.open(file.path);
        break;
      case 'delete':
        final result = await RecentFilesService.removeRecentFile(file.path);
        result.fold(
          (error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $error'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          },
          (updatedFiles) {
            if (mounted) {
              _loadRecentFiles();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Removed from recent files')),
              );
            }
          },
        );
        break;
      case 'rename':
        await showRenameFileSheet(
          context: context,
          initialName: file.name,
          onRename: (newName) async {
            final result = await FileService.renameFile(file, newName);
            result.fold(
              (exception) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(exception.message),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              },
              (renamedFileInfo) {
                if (mounted) {
                  _loadRecentFiles();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('File renamed successfully')),
                  );
                }
              },
            );
          },
        );
        break;
    }
  }
}
