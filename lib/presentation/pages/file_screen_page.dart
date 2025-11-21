// android_files_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/presentation/component/document_tile.dart';
import 'package:pdf_kit/presentation/component/folder_tile.dart';
import 'package:pdf_kit/presentation/layouts/selection_layout.dart';
import 'package:pdf_kit/presentation/provider/selection_provider.dart';
import 'package:pdf_kit/service/file_system_serevice.dart';
import 'package:pdf_kit/service/folder_service.dart';
import 'package:pdf_kit/service/open_service.dart';
import 'package:pdf_kit/service/path_service.dart';
import 'package:pdf_kit/service/permission_service.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/presentation/sheets/new_folder_sheet.dart';
import 'package:pdf_kit/presentation/sheets/filter_sheet.dart';
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
  List<Directory> _roots = [];
  String? _currentPath;
  List<FileInfo> _entries = [];
  StreamSubscription? _searchSub;
  // Sorting and filtering state
  SortOption _sortOption = SortOption.name;
  final Set<TypeFilter> _typeFilters = {}; // empty = all
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
      } catch (_) {
        // ignore any position/access glitches
      }
    });
  }

  Future<void> _boot() async {
    final perm = await PermissionService.requestStoragePermission();
    perm.fold((_) {}, (ok) async {
      if (!ok) return;
      final vols = await PathService.volumes();
      vols.fold((_) {}, (dirs) async {
        setState(() => _roots = dirs);
        final startPath =
            widget.initialPath ?? (dirs.isNotEmpty ? dirs.first.path : null);
        if (startPath != null) await _open(startPath);
      });
    });
  }

  @override
  void dispose() {
    _searchSub?.cancel();
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

  Future<void> _open(String path) async {
    _cancelSearch();
    final res = await FileSystemService.list(path);
    res.fold((_) {}, (items) {
      setState(() {
        _currentPath = path;
        _entries = items;
      });
    });
  }

  List<FileInfo> _getVisibleEntries() {
    final list = List<FileInfo>.from(_entries);

    // Apply type filter (multi-select). If none selected => all
    List<FileInfo> filtered = list.where((e) {
      if (_typeFilters.isEmpty) return true;
      if (_typeFilters.contains(TypeFilter.folder) && e.isDirectory)
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
    _filterSheetOpen = true;

    await showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent, // Important for transparent overlay
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            12,
            16,
            16,
          ), // margin with top inset too
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              // color: Theme.of(context).dialogBackgroundColor, // or cardColor
              padding: const EdgeInsets.all(0),
              child: SafeArea(
                bottom: true,
                top: false,
                left: false,
                right: false,
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

  void _cancelSearch() {
    _searchSub?.cancel();
    _searchSub = null;
  }

  // Fix fullscreen folder navigation
  Future<void> _openFolder(String path) async {
    if (!mounted) return;
    if (widget.isFullscreenRoute == true) {
      // Preserve selection-related params we received when this fullscreen
      // screen was created (selectionId, actionText) and forward them
      // along with the folder `path` when navigating deeper.
      final params = <String, String>{'path': path};
      if (widget.selectionId != null)
        params['selectionId'] = widget.selectionId!;
      if (widget.selectionActionText != null)
        params['actionText'] = widget.selectionActionText!;

      context.pushNamed(
        AppRouteName.filesFolderFullScreen,
        queryParameters: params,
      );
    } else {
      context.pushNamed(
        AppRouteName.filesFolder,
        queryParameters: {'path': path},
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _getVisibleEntries();
    final folders = visibleItems.where((e) => e.isDirectory).toList();
    final files = visibleItems.where((e) => !e.isDirectory).toList();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: screenPadding,
          child: Column(
            children: [
              _buildHeader(context, files),

              // Make the listing the scrollable area
              Expanded(
                child: _currentPath == null
                    ? _buildRoots()
                    : _buildListing(folders, files, context),
              ),
            ],
          ),
        ),
      ),
      // bottom bar is drawn by SelectionScaffold when in fullscreen selection flow
    );
  }

  Widget _buildHeader(BuildContext context, List<FileInfo> visibleFiles) {
    final p = _maybeProvider();
    final enabled = widget.selectable && (p?.isEnabled ?? false);
    final maxLimitActive =
        p?.maxSelectable != null; // hide select-all when limit imposed
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
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.widgets_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Files',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              if (widget.isFullscreenRoute == true) {
                context.pushNamed(
                  'files.search.fullscreen',
                  queryParameters: {'path': _currentPath},
                );
              } else {
                context.pushNamed(
                  AppRouteName.filesSearch,
                  queryParameters: {'path': _currentPath},
                );
              }
            },
            tooltip: 'Search',
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
                  ? 'Enable selection'
                  : (allOnPage ? 'Clear this page' : 'Select all on page'),
              onPressed: () {
                final prov = _maybeProvider();
                if (prov == null) return;
                prov.cyclePage(visibleFiles);
              },
            )
          else if (widget.selectable && maxLimitActive)
            SizedBox.shrink()
          else
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {},
              tooltip: 'More',
            ),
        ],
      ),
    );
  }

  Widget _buildRoots() => ListView(
    children: _roots
        .map(
          (d) => ListTile(
            leading: const Icon(Icons.sd_storage),
            title: Text(d.path),
            onTap: () => _openFolder(d.path),
          ),
        )
        .toList(),
  );

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () => _open(_currentPath!),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 56),
          Center(child: Image.asset('assets/not_found.png')),
          const SizedBox(height: 12),
          Text(
            'This folder is empty',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
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
  ) {
    final isEmpty = folders.isEmpty && files.isEmpty;

    final String displayName;
    if (_currentPath == null) {
      displayName = '/';
    } else {
      final normalizedCurrent = p.normalize(_currentPath!);
      final exactRoot = _roots.firstWhere(
        (r) => p.normalize(r.path) == normalizedCurrent,
        orElse: () => Directory(''),
      );
      if (exactRoot.path.isNotEmpty) {
        displayName = 'root';
      } else {
        Directory? parentRoot;
        for (final r in _roots) {
          final rp = p.normalize(r.path);
          if (normalizedCurrent.startsWith(rp)) {
            parentRoot = r;
            break;
          }
        }
        if (parentRoot != null) {
          var rel = p.relative(_currentPath!, from: parentRoot.path);
          rel = rel.replaceAll(Platform.pathSeparator, '/');
          displayName = '/$rel';
        } else {
          displayName = p.basename(_currentPath!);
        }
      }
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
                      'Total: ${folders.length + files.length} items',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                tooltip: 'Sort / Filter',
                icon: const Icon(Icons.import_export_rounded),
                onPressed: () => _openFilterDialog(),
              ),
              IconButton(
                onPressed: () {
                  showNewFolderSheet(
                    context: context,
                    onCreate: (String folderName) async {
                      if (_currentPath == null || folderName.trim().isEmpty)
                        return;

                      final base = _currentPath!;

                      // Determine if this path is inside app-specific external storage.
                      // If not, request "All files access" for public/shared folders.
                      final appBase = await FolderServiceAndroid.appFilesPath();
                      final requireAll = !p.isWithin(
                        appBase,
                        base,
                      ); // true for e.g. Downloads/Pictures [public] [web:47]

                      final res = await FolderServiceAndroid.createFolder(
                        basePath: base,
                        folderName: folderName,
                        requireAllFilesAccess: requireAll,
                        recursive: true,
                      );

                      res.fold(
                        (err) => ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(err))),
                        (_) async => await _open(base), // refresh listing
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
          child: isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () => _open(_currentPath!),
                  child: ListView(
                    controller: _listingScrollController,
                    padding: const EdgeInsets.only(bottom: 16),
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
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  void _handleFolderMenu(String v, FileInfo f) {
    switch (v) {
      case 'open':
        _openFolder(f.path);
        break;
      case 'rename':
        break;
      case 'delete':
        break;
    }
  }

  void _handleFileMenu(String v, FileInfo f) {
    switch (v) {
      case 'open':
        OpenService.open(f.path);
        break;
      case 'rename':
        break;
      case 'delete':
        break;
    }
  }
}
