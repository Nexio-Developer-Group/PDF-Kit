// android_files_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/presentation/component/document_tile.dart';
import 'package:pdf_kit/presentation/component/folder_tile.dart';
import 'package:pdf_kit/presentation/layouts/selection_layout.dart';
import 'package:pdf_kit/presentation/provider/selection_provider.dart';
import 'package:pdf_kit/providers/file_system_provider.dart'; // [NEW]
import 'package:pdf_kit/service/open_service.dart';
import 'package:pdf_kit/service/permission_service.dart';
import 'package:pdf_kit/presentation/pages/home_page.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/presentation/sheets/delete_file_sheet.dart';
import 'package:pdf_kit/presentation/sheets/rename_file_sheet.dart';
import 'package:pdf_kit/presentation/layouts/file_browser_filter_scope.dart';
import 'package:pdf_kit/presentation/models/filter_models.dart';

class AndroidFilesScreen extends StatefulWidget {
  final String? initialPath;
  final bool selectable;
  final String? selectionActionText;
  final String? selectionId;
  final bool? isFullscreenRoute;
  final void Function(List<FileInfo> files)? onSelectionAction;
  final String? fileType;

  const AndroidFilesScreen({
    super.key,
    this.initialPath,
    this.selectable = false,
    this.selectionActionText,
    this.onSelectionAction,
    this.selectionId,
    this.isFullscreenRoute = false,
    this.fileType,
  });
  @override
  State<AndroidFilesScreen> createState() => _AndroidFilesScreenState();
}

class _AndroidFilesScreenState extends State<AndroidFilesScreen> {
  // Removed local state: _roots, _currentPath, _entries
  // Removed: _searchSub, _fileDeleted
  // Removed: _sortOption, _typeFilters, _filterSheetOpen (moved to shell)

  // Keep only scroll controller for list
  final ScrollController _listingScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _boot();
    // Simple scroll controller for the list
  }

  Future<void> _boot() async {
    print(
      '🚀 [AndroidFilesScreen] _boot called. InitialPath: ${widget.initialPath}',
    );
    final perm = await PermissionService.requestStoragePermission();
    perm.fold(
      (_) {
        print('❌ [AndroidFilesScreen] Permission failed');
      },
      (ok) async {
        print('✅ [AndroidFilesScreen] Permission: $ok');
        if (!ok) return;

        // Always load the provided path (no null handling)
        if (widget.initialPath != null) {
          await context.read<FileSystemProvider>().load(widget.initialPath!);
        }
      },
    );
  }

  @override
  void dispose() {
    _listingScrollController.dispose();
    super.dispose();
  }

  SelectionProvider? _maybeProvider() {
    try {
      return SelectionScope.of(context);
    } catch (_) {
      return null;
    }
  }

  bool get _selectionEnabled =>
      widget.selectable && (_maybeProvider()?.isEnabled ?? false);

  String? get _currentPath => widget.initialPath; // Only use widget.initialPath

  Future<void> _refresh() async {
    if (_currentPath != null) {
      await context.read<FileSystemProvider>().load(
        _currentPath!,
        forceRefresh: true,
      );
    } else {
      // If initialPath is null, there's nothing to refresh in this simplified view
      // This case should ideally not be reached if initialPath is always provided
      // or if this screen is only used for specific paths.
      print(
        '⚠️ [AndroidFilesScreen] _refresh called with null _currentPath. No action taken.',
      );
    }
  }

  // Navigate deeper
  Future<void> _openFolder(String path) async {
    if (!mounted) return;
    if (widget.isFullscreenRoute == true) {
      final params = <String, String>{'path': path};
      if (widget.selectionId != null)
        params['selectionId'] = widget.selectionId!;
      if (widget.selectionActionText != null)
        params['actionText'] = widget.selectionActionText!;
      if (widget.fileType != null) params['fileType'] = widget.fileType!;

      await context.pushNamed(
        AppRouteName.filesFolderFullScreen,
        queryParameters: params,
      );
    } else {
      await context.pushNamed(
        AppRouteName.filesFolder,
        queryParameters: {'path': path},
      );
    }
    // No need to "refresh" manually on return, provider handles cache.
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FileSystemProvider>();

    // Get file data for current path
    final List<FileInfo> rawFiles = _currentPath != null
        ? provider.filesFor(_currentPath!)
        : [];

    final bool loading = _currentPath != null
        ? provider.isLoading(_currentPath!)
        : false;

    print(
      '🖼️ [AndroidFilesScreen] build. Path: $_currentPath, Loading: $loading, Files: ${rawFiles.length}',
    );

    // Get filter settings from shell (if available)
    final filterScope = FileBrowserFilterScope.maybeOf(context);
    final sortOption = filterScope?.sortOption ?? SortOption.name;
    final typeFilters = filterScope?.typeFilters ?? {};

    // Apply type filters
    List<FileInfo> filteredFiles = rawFiles;
    if (typeFilters.isNotEmpty) {
      filteredFiles = filteredFiles.where((file) {
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
          'webp',
          'bmp',
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

    // Apply sorting
    filteredFiles.sort((a, b) {
      switch (sortOption) {
        case SortOption.name:
          // Folders first, then files, alphabetically within each group
          if (a.isDirectory && !b.isDirectory) return -1;
          if (!a.isDirectory && b.isDirectory) return 1;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());

        case SortOption.modified:
          // Most recent first
          final aTime = a.lastModified ?? DateTime(0);
          final bTime = b.lastModified ?? DateTime(0);
          return bTime.compareTo(aTime);

        case SortOption.type:
          // Sort by extension: folders first, then by extension, then by name
          if (a.isDirectory && !b.isDirectory) return -1;
          if (!a.isDirectory && b.isDirectory) return 1;
          if (a.isDirectory && b.isDirectory) {
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          }
          // For files, compare extensions first
          final extCompare = a.extension.toLowerCase().compareTo(
            b.extension.toLowerCase(),
          );
          if (extCompare != 0) return extCompare;
          // Same extension - sort by name
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
    });

    // Separate folders and files from filtered/sorted list
    final folders = filteredFiles.where((e) => e.isDirectory).toList();
    final files = filteredFiles.where((e) => !e.isDirectory).toList();

    return _buildListing(folders, files, context, loading);
  }

  Widget _buildEmptyState() {
    final t = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 56),
          Center(child: Image.asset('assets/not_found.png')),
          const SizedBox(height: 12),
          Text(
            t.t('files_empty_folder_title'),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildListing(
    List<FileInfo> folders,
    List<FileInfo> files,
    BuildContext context,
    bool isLoading,
  ) {
    if (folders.isEmpty && files.isEmpty && !isLoading) {
      return _buildEmptyState();
    }

    final pvd = _maybeProvider();

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        controller: _listingScrollController,
        padding: const EdgeInsets.only(bottom: 16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          ...folders.map(
            (f) => Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              child: FolderEntryCard(info: f, onTap: () => _openFolder(f.path)),
            ),
          ),
          ...files.map(
            (f) => Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              child: DocEntryCard(
                info: f,
                selectable: _selectionEnabled,
                selected: (pvd?.isSelected(f.path) ?? false),
                onToggleSelected: _selectionEnabled
                    ? () => pvd?.toggle(f)
                    : null,
                onOpen: _selectionEnabled
                    ? () => pvd?.toggle(f)
                    : () => OpenService.open(f.path),
                onLongPress: () {
                  if (!_selectionEnabled) {
                    pvd?.enable();
                  }
                  pvd?.toggle(f);
                },
                onMenu: (v) => _handleFileMenu(v, f),
              ),
            ),
          ),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  // --- Actions delegates to Provider ---

  Future<void> _handleFileRename(FileInfo file) async {
    await showRenameFileSheet(
      context: context,
      initialName: file.name,
      onRename: (newName) async {
        context.read<FileSystemProvider>().renameFile(file, newName).then((_) {
          RecentFilesSection.refreshNotifier.value++;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File renamed successfully')),
          );
        });
      },
    );
  }

  Future<void> _handleFileMenu(String v, FileInfo f) async {
    switch (v) {
      case 'open':
        OpenService.open(f.path);
        break;
      case 'rename':
        await _handleFileRename(f);
        break;
      case 'delete':
        await showDeleteFileSheet(
          context: context,
          fileName: f.name,
          onDelete: () async {
            await context.read<FileSystemProvider>().deleteFile(f);
            RecentFilesSection.refreshNotifier.value++;
          },
        );
        break;
    }
  }
}
