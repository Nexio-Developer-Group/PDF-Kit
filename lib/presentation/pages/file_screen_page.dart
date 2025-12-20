// android_files_screen.dart
import 'dart:async';
import 'dart:io';
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
import 'package:pdf_kit/presentation/sheets/new_folder_sheet.dart';
import 'package:pdf_kit/presentation/sheets/filter_sheet.dart';
import 'package:pdf_kit/presentation/sheets/delete_file_sheet.dart';
import 'package:pdf_kit/presentation/sheets/rename_file_sheet.dart';
import 'package:path/path.dart' as p;

import 'package:pdf_kit/presentation/models/filter_models.dart';

class AndroidFilesScreen extends StatefulWidget {
  final String? initialPath;
  final bool selectable;
  final String? selectionActionText;
  final String? selectionId;
  final bool? isFullscreenRoute;
  final void Function(List<FileInfo> files)? onSelectionAction;

  const AndroidFilesScreen({
    super.key,
    this.initialPath,
    this.selectable = false,
    this.selectionActionText,
    this.onSelectionAction,
    this.selectionId,
    this.isFullscreenRoute = false,
  });
  @override
  State<AndroidFilesScreen> createState() => _AndroidFilesScreenState();
}

class _AndroidFilesScreenState extends State<AndroidFilesScreen> {
  // Removed local state: _roots, _currentPath, _entries
  // Removed: _searchSub, _fileDeleted

  // Keep UI-only state
  SortOption _sortOption = SortOption.name;
  final Set<TypeFilter> _typeFilters = {};
  bool _filterSheetOpen = false;
  final ScrollController _listingScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _boot();
    _listingScrollController.addListener(() {
      if (!_filterSheetOpen) return;
      try {
        if (_listingScrollController.hasClients &&
            _listingScrollController.position.isScrollingNotifier.value) {
          if (mounted) Navigator.of(context).maybePop();
        }
      } catch (_) {}
    });
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

        final provider = context.read<FileSystemProvider>();

        // Load roots if no path
        if (widget.initialPath == null) {
          await provider.loadRoots();
        } else {
          // Load target path
          await provider.load(widget.initialPath!);
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
      await context.read<FileSystemProvider>().loadRoots();
    }
  }

  List<FileInfo> _getVisibleEntries(List<FileInfo> allFiles) {
    final list = List<FileInfo>.from(allFiles);

    List<FileInfo> filtered = list.where((e) {
      if (_typeFilters.isEmpty) return true;
      if (_typeFilters.contains(TypeFilter.folder) &&
          (e.isDirectory || e.extension.isEmpty)) // assuming dir logic
        return true;
      if (_typeFilters.contains(TypeFilter.pdf) &&
          e.extension.toLowerCase() == 'pdf')
        return true;
      if (_typeFilters.contains(TypeFilter.image)) {
        const imgExt = {
          'jpg',
          'jpeg',
          'png',
          'gif',
          'webp',
          'bmp',
          'tif',
          'tiff',
          'heic',
          'heif',
          'svg',
        };
        if (imgExt.contains(e.extension.toLowerCase())) return true;
      }
      return false;
    }).toList();

    // Apply sort
    switch (_sortOption) {
      case SortOption.name:
        filtered.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
      case SortOption.modified:
        filtered.sort(
          (a, b) => (b.lastModified ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(
                a.lastModified ?? DateTime.fromMillisecondsSinceEpoch(0),
              ),
        );
        break;
      case SortOption.type:
        filtered.sort((a, b) {
          if (a.isDirectory && !b.isDirectory) return -1;
          if (!a.isDirectory && b.isDirectory) return 1;
          final ae = a.extension.toLowerCase();
          final be = b.extension.toLowerCase();
          final c = ae.compareTo(be);
          if (c != 0) return c;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        break;
    }

    return filtered;
  }

  Future<void> _openFilterDialog() async {
    _filterSheetOpen =
        true; // Use local var, set state not needed for this flag alone unless widely used
    await showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              child: SafeArea(
                top: false,
                child: FilterSheet(
                  currentSort: _sortOption,
                  currentTypes: Set.from(_typeFilters),
                  onSortChanged: (s) => setState(() => _sortOption = s),
                  onTypeFiltersChanged: (set) {
                    setState(() {
                      _typeFilters.clear();
                      _typeFilters.addAll(set);
                    });
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
    _filterSheetOpen = false;
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
    // Determine data based on path
    final provider = context.watch<FileSystemProvider>();

    // Logic: if currentPath is null, we show roots. Else files.
    final isRoot = _currentPath == null;

    // Get raw data
    final List<FileInfo> rawFiles = isRoot
        ? [] // Roots are handled separately
        : provider.filesFor(_currentPath!);

    final List<Directory> rootDirs = provider.roots;

    final bool loading = isRoot
        ? (rootDirs.isEmpty && provider.roots.isEmpty) // simple check
        : provider.isLoading(_currentPath!);

    print(
      '🖼️ [AndroidFilesScreen] build. Path: $_currentPath, Loading: $loading, Roots: ${rootDirs.length}, Files: ${rawFiles.length}',
    );

    // Filter/Sort
    final visibleItems = _getVisibleEntries(rawFiles);
    final folders = visibleItems.where((e) => e.isDirectory).toList();
    final files = visibleItems.where((e) => !e.isDirectory).toList();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              _buildHeader(context, files, loading),

              Expanded(
                child: isRoot
                    ? _buildRoots(rootDirs)
                    : _buildListing(folders, files, context, loading),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    List<FileInfo> visibleFiles,
    bool loading,
  ) {
    final t = AppLocalizations.of(context);
    final p = _maybeProvider();
    final enabled = widget.selectable && (p?.isEnabled ?? false);
    final maxLimitActive = p?.maxSelectable != null;
    final allOnPage = (!maxLimitActive && enabled)
        ? (p?.areAllSelected(visibleFiles) ?? false)
        : false;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: SizedBox(
                width: 40,
                height: 40,
                child: Image.asset(
                  'assets/app_icon.png',
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Icon(
                    Icons.widgets_rounded,
                    size: 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            t.t('files_header_title'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (loading) ...[
            const SizedBox(width: 12),
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Navigation logic remains same
              if (widget.isFullscreenRoute == true) {
                context.pushNamed(
                  'files.search.fullscreen', // ensure route exists
                  queryParameters: {'path': _currentPath},
                );
              } else {
                context.pushNamed(
                  AppRouteName.filesSearch,
                  queryParameters: {'path': _currentPath},
                );
              }
            },
            tooltip: t.t('common_search'),
          ),
          if (widget.selectable && !maxLimitActive)
            IconButton(
              icon: Icon(
                !enabled
                    ? Icons.check_box_outline_blank
                    : (allOnPage
                          ? Icons.check_box
                          : Icons.check_box_outline_blank),
              ),
              tooltip: !enabled
                  ? t.t('files_enable_selection_tooltip')
                  : (allOnPage
                        ? t.t('files_clear_page_tooltip')
                        : t.t('files_select_all_page_tooltip')),
              onPressed: () {
                final prov = _maybeProvider();
                if (prov == null) return;
                prov.cyclePage(visibleFiles);
              },
            )
          else if (widget.selectable && maxLimitActive)
            const SizedBox.shrink()
          else
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {},
              tooltip: t.t('files_more_tooltip'),
            ),
        ],
      ),
    );
  }

  Widget _buildRoots(List<Directory> roots) {
    print('🎨 [AndroidFilesScreen] _buildRoots: ${roots.length} items');
    return ListView(
      children: roots.map((d) {
        print('  - Root: ${d.path}');
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.sd_storage, size: 32, color: Colors.blue),
            title: Text(
              d.path,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Storage Root'),
            onTap: () => _openFolder(d.path),
          ),
        );
      }).toList(),
    );
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

    final t = AppLocalizations.of(context);
    final String displayName;
    // ... Display name logic ...
    // Simplified for brevity, reusing generic basename or just "path"
    if (_currentPath != null) {
      displayName = p.basename(_currentPath!);
      // You can re-add the "root detection" logic here if needed
    } else {
      displayName = "/";
    }

    final pvd = _maybeProvider();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t
                          .t('files_total_items')
                          .replaceAll(
                            '{count}',
                            (folders.length + files.length).toString(),
                          ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                tooltip: t.t('files_sort_filter_tooltip'),
                icon: const Icon(Icons.tune),
                onPressed: () => _openFilterDialog(),
              ),
              IconButton(
                onPressed: () {
                  showNewFolderSheet(
                    context: context,
                    onCreate: (String folderName) async {
                      if (_currentPath == null || folderName.trim().isEmpty)
                        return;
                      await context.read<FileSystemProvider>().createFolder(
                        _currentPath!,
                        folderName,
                      );
                    },
                  );
                },
                icon: const Icon(Icons.create_new_folder_outlined),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              controller: _listingScrollController,
              padding: const EdgeInsets.only(bottom: 16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                ...folders.map(
                  (f) => Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 12,
                    ),
                    child: FolderEntryCard(
                      info: f,
                      onTap: () => _openFolder(f.path),
                      onMenuSelected: (v) => _handleFolderMenu(v, f),
                    ),
                  ),
                ),
                ...files.map(
                  (f) => Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 12,
                    ),
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
          ),
        ),
      ],
    );
  }

  // --- Actions delegates to Provider ---

  void _handleFolderMenu(String v, FileInfo f) {
    // Implement folder rename/delete via provider if needed
    switch (v) {
      case 'open':
        _openFolder(f.path);
        break;
      // ...
    }
  }

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
            context.read<FileSystemProvider>().deleteFile(f).then((_) {
              RecentFilesSection.refreshNotifier.value++;
            });
          },
        );
        break;
    }
  }
}
