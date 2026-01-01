import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf_kit/providers/file_system_provider.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/core/constants.dart';
import 'package:pdf_kit/core/utility/storage_utility.dart';
import 'package:pdf_kit/service/recent_file_service.dart';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/presentation/component/document_tile.dart';
import 'package:pdf_kit/service/open_service.dart';
import 'package:pdf_kit/presentation/sheets/rename_file_sheet.dart';
import 'package:pdf_kit/service/file_service.dart';
import 'package:pdf_kit/presentation/provider/selection_provider.dart';
import 'package:pdf_kit/presentation/layouts/selection_layout.dart';
import 'package:pdf_kit/presentation/models/filter_models.dart';

/// Page displaying storage volumes (Internal Storage, SD Card, etc.)
/// This is the root page of the file browser at /files
class FilesRootPage extends StatefulWidget {
  final bool isFullscreenRoute;
  final String? selectionId;
  final String? selectionActionText;
  final String? fileType;

  const FilesRootPage({
    super.key,
    this.isFullscreenRoute = false,
    this.selectionId,
    this.selectionActionText,
    this.fileType,
  });

  @override
  State<FilesRootPage> createState() => _FilesRootPageState();
}

class _FilesRootPageState extends State<FilesRootPage> with RouteAware {
  List<FileInfo>? _cachedRecentFiles;
  bool _isLoadingRecent = true;

  @override
  void initState() {
    super.initState();
    // Load storage roots when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to RouteObserver
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Called when the top route has been popped off, and this route shows up.
    print('🔄 [FilesRootPage] Returning to page, refreshing data...');
    _refresh();
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

  /// Get stored folder path from preferences, or return default path
  String? _getStoredPath(String prefsKey) {
    return Prefs.getString(prefsKey);
  }

  /// Check if a folder exists on the file system
  Future<bool> _folderExists(String path) async {
    return context.read<FileSystemProvider>().directoryExists(path);
  }

  /// Navigate to folder if it exists, otherwise navigate to folder picker
  Future<void> _navigateToFolderOrPicker({
    required String prefsKey,
    required String defaultPath,
    required String pickerTitle,
    required String pickerDescription,
  }) async {
    // 1. Check if user has a stored path
    String? storedPath = _getStoredPath(prefsKey);

    print('🔍 [Folder Navigation] Checking folder access');
    print('📁 [Folder Navigation] Stored path: ${storedPath ?? "none"}');
    print('📂 [Folder Navigation] Default path: $defaultPath');

    // 2. Validate stored path if it exists
    if (storedPath != null) {
      bool storedExists = await _folderExists(storedPath);
      if (storedExists) {
        print(
          '✅ [Folder Navigation] Stored folder exists. Navigating to: $storedPath',
        );
        _navigateToFolder(storedPath);
        return;
      } else {
        print('❌ [Folder Navigation] Stored folder not found. Falling back.');
        // Optional: clear invalid stored path?
        // Prefs.remove(prefsKey);
      }
    }

    // 3. Check default path
    bool defaultExists = await _folderExists(defaultPath);
    if (defaultExists) {
      print(
        '✅ [Folder Navigation] Default folder exists. Navigating to: $defaultPath',
      );
      // We don't necessarily force-save the default path unless we want to lock it in.
      // But if the user later changes directories on their phone, checking default dynamically is better.
      // However, if we want consistency, we can save it.
      // For now, just navigate.
      _navigateToFolder(defaultPath);
      return;
    }

    // 4. Default also missing -> Show Picker
    print(
      '🎯 [Folder Navigation] Default folder missing. Showing folder picker.',
    );

    _navigateToFolderPicker(prefsKey, pickerTitle, pickerDescription);
  }

  Future<void> _refresh() async {
    // Reload storage roots
    context.read<FileSystemProvider>().loadRoots();
    // Reload recent files
    await _loadRecentFiles();
  }

  /// Navigate to folder picker and handle result
  Future<void> _navigateToFolderPicker(
    String prefsKey,
    String title,
    String description,
  ) async {
    // Navigate to picker and wait for result
    final selectedPath = await context.pushNamed<String>(
      AppRouteName.folderPickScreen,
      extra: {'title': title, 'description': description},
    );

    // If user selected a path
    if (selectedPath != null && selectedPath.isNotEmpty) {
      print('💾 [Folder Navigation] User selected path: $selectedPath');

      // Save to storage
      await Prefs.setString(prefsKey, selectedPath);

      // Navigate to the selected folder
      _navigateToFolder(selectedPath);
    } else {
      print('🚫 [Folder Navigation] User cancelled folder selection');
    }
  }

  /// Navigate to a specific folder path
  void _navigateToFolder(String path) {
    final routeName = widget.isFullscreenRoute
        ? AppRouteName.filesFolderFullScreen
        : AppRouteName.filesFolder;

    final params = <String, String>{'path': path};
    if (widget.selectionId != null) {
      params['selectionId'] = widget.selectionId!;
    }
    if (widget.selectionActionText != null) {
      params['actionText'] = widget.selectionActionText!;
    }
    if (widget.fileType != null) {
      params['fileType'] = widget.fileType!;
    }

    context.pushNamed(routeName, queryParameters: params);
  }

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
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                                              ? AppRouteName
                                                    .recentFilesFullscreen
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
                                          _navigateToFolderOrPicker(
                                            prefsKey: Constants
                                                .downloadsFolderPathKey,
                                            defaultPath:
                                                '/storage/emulated/0/Download_INVALID',
                                            pickerTitle:
                                                'Select Downloads Folder',
                                            pickerDescription: t.t(
                                              'folder_picker_description_downloads',
                                            ),
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
                                          _navigateToFolderOrPicker(
                                            prefsKey: Constants
                                                .pdfOutputFolderPathKey,
                                            defaultPath:
                                                '/storage/emulated/0/Download_INVALID',
                                            pickerTitle:
                                                'Select PDF Output Folder',
                                            pickerDescription: t.t(
                                              'folder_picker_description_pdfs',
                                            ),
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
                                          _navigateToFolderOrPicker(
                                            prefsKey:
                                                Constants.imagesFolderPathKey,
                                            defaultPath:
                                                '/storage/emulated/0/DCIM/Camera_INVALID',
                                            pickerTitle: 'Select Images Folder',
                                            pickerDescription: t.t(
                                              'folder_picker_description_images',
                                            ),
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
                                          _navigateToFolderOrPicker(
                                            prefsKey: Constants
                                                .screenshotsFolderPathKey,
                                            defaultPath:
                                                '/storage/emulated/0/DCIM/Screenshots_INVALID',
                                            pickerTitle:
                                                'Select Screenshots Folder',
                                            pickerDescription: t.t(
                                              'folder_picker_description_screenshots',
                                            ),
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
                                    physics:
                                        const NeverScrollableScrollPhysics(),
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
                                    size: 14,
                                  ),
                                  tooltip: t.t('recent_files_view_all_tooltip'),
                                  onPressed: () {
                                    final routeName = widget.isFullscreenRoute
                                        ? AppRouteName.recentFilesFullscreen
                                        : AppRouteName.recentFiles;
                                    final params = <String, String>{};
                                    if (widget.selectionId != null) {
                                      params['selectionId'] =
                                          widget.selectionId!;
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
            crossAxisAlignment: CrossAxisAlignment.center,
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
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storageName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // const SizedBox(height: 4),
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
          _navigateToFolderOrPicker(
            prefsKey: Constants.downloadsFolderPathKey,
            defaultPath: '/storage/emulated/0/Download_INVALID',
            pickerTitle: 'Select Downloads Folder',
            pickerDescription: t.t('folder_picker_description_downloads'),
          );
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
          _navigateToFolderOrPicker(
            prefsKey: Constants.pdfOutputFolderPathKey,
            defaultPath: '/storage/emulated/0/Download_INVALID',
            pickerTitle: 'Select PDF Output Folder',
            pickerDescription: t.t('folder_picker_description_pdfs'),
          );
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
          _navigateToFolderOrPicker(
            prefsKey: Constants.imagesFolderPathKey,
            defaultPath: '/storage/emulated/0/DCIM/Cameraaaa',
            pickerTitle: 'Select Images Folder',
            pickerDescription: t.t('folder_picker_description_images'),
          );
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
          _navigateToFolderOrPicker(
            prefsKey: Constants.screenshotsFolderPathKey,
            defaultPath: '/storage/emulated/0/DCIM/Screenshooooots',
            pickerTitle: 'Select Screenshots Folder',
            pickerDescription: t.t('folder_picker_description_screenshots'),
          );
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
    final t = AppLocalizations.of(context);

    // Get fileType from SelectionProvider and apply TypeFilter-based filtering
    final fileType = pvd?.fileType;
    Set<TypeFilter> typeFilters = {};

    // Initialize type filters based on fileType
    if (fileType == 'pdf') {
      typeFilters = {TypeFilter.folder, TypeFilter.pdf};
    } else if (fileType == 'images') {
      typeFilters = {TypeFilter.folder, TypeFilter.image};
    } else if (fileType == 'all') {
      typeFilters = {TypeFilter.folder, TypeFilter.pdf, TypeFilter.image};
    }

    // Apply TypeFilter-based filtering
    List<FileInfo> filteredFiles = files;
    if (typeFilters.isNotEmpty) {
      filteredFiles = files.where((file) {
        if (file.isDirectory) {
          return typeFilters.contains(TypeFilter.folder);
        }

        final ext = file.extension.toLowerCase();
        if (ext == 'pdf') {
          return typeFilters.contains(TypeFilter.pdf);
        }

        // Common image extensions
        const imageExts = {
          'jpg',
          'jpeg',
          'png',
          'gif',
          'bmp',
          'webp',
          'svg',
          'heic',
          'heif',
        };
        if (imageExts.contains(ext)) {
          return typeFilters.contains(TypeFilter.image);
        }

        // For other file types, don't show them if filtering is active
        return false;
      }).toList();
    }

    // Show filter-specific empty message if files exist but all filtered out
    if (filteredFiles.isEmpty && files.isNotEmpty) {
      String message;
      if (fileType == 'pdf') {
        message = t.t('recent_files_filter_empty_pdf');
      } else if (fileType == 'images') {
        message = t.t('recent_files_filter_empty_images');
      } else {
        message = t.t('recent_files_empty');
      }

      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withOpacity(0.7),
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: filteredFiles.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final file = filteredFiles[index];
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
