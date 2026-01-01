import 'package:flutter/material.dart';
import 'package:pdf_kit/models/file_model.dart'; // [NEW] for FileInfo
import 'package:pdf_kit/providers/file_system_provider.dart';
import 'package:pdf_kit/presentation/layouts/selection_layout.dart';
import 'package:pdf_kit/presentation/provider/selection_provider.dart';
import 'package:pdf_kit/presentation/sheets/new_folder_sheet.dart';
import 'package:pdf_kit/presentation/sheets/filter_sheet.dart';
import 'package:pdf_kit/presentation/models/filter_models.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_kit/presentation/widgets/breadcrumb_widget.dart';
import 'package:pdf_kit/presentation/layouts/file_browser_filter_scope.dart';

/// Persistent shell layout for file browsing
/// Contains header and folder info bar that don't rebuild on navigation
class FileBrowserShell extends StatefulWidget {
  final Widget child;
  final bool selectable;
  final bool isFullscreenRoute;
  final String? selectionId;
  final String? selectionActionText;

  const FileBrowserShell({
    super.key,
    required this.child,
    this.selectable = false,
    this.isFullscreenRoute = false,
    this.selectionId,
    this.selectionActionText,
  });

  @override
  State<FileBrowserShell> createState() => _FileBrowserShellState();
}

class _FileBrowserShellState extends State<FileBrowserShell> with RouteAware {
  // UI-only state for filters (parent manages these)
  SortOption _sortOption = SortOption.name;
  final Set<TypeFilter> _typeFilters = {};
  bool _typeFiltersInitialized = false;

  // Get current path from route
  String? get _currentPath {
    final uri = GoRouterState.of(context).uri;
    return uri.queryParameters['path'];
  }

  SelectionProvider? _maybeProvider() {
    try {
      return SelectionScope.of(context);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FileSystemProvider>();
    final path = _currentPath;

    // Get data for current path
    final files = path != null ? provider.filesFor(path) : <FileInfo>[];
    final loading = path != null ? provider.isLoading(path) : false;

    // Calculate display name
    final displayName = path != null ? p.basename(path) : '/';

    // Calculate folder and file counts (simple count, filtering handled by child)
    final folderCount = files.where((f) => f.isDirectory).length;
    final fileCount = files.where((f) => !f.isDirectory).length;
    final totalCount = folderCount + fileCount;

    // Get fileType from SelectionProvider if available
    final selectionProvider = _maybeProvider();
    final fileType = selectionProvider?.fileType;

    // Initialize type filters based on fileType (only once)
    if (!_typeFiltersInitialized && fileType != null) {
      _typeFiltersInitialized = true;
      _typeFilters.clear();

      if (fileType == 'pdf') {
        // For PDF-only mode, show folders + PDFs
        _typeFilters.addAll([TypeFilter.folder, TypeFilter.pdf]);
      } else if (fileType == 'images') {
        // For images-only mode, show folders + images
        _typeFilters.addAll([TypeFilter.folder, TypeFilter.image]);
      } else {
        // For 'all', show everything
        _typeFilters.addAll([
          TypeFilter.folder,
          TypeFilter.pdf,
          TypeFilter.image,
        ]);
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Persistent Header
            _buildHeader(context, files, loading),

            // Persistent Folder Info Bar
            _buildFolderInfoBar(context, displayName, totalCount, files),

            // Child content (file list from AndroidFilesScreen)
            Expanded(
              child: FileBrowserFilterScope(
                sortOption: _sortOption,
                typeFilters: Set.from(
                  _typeFilters,
                ), // Create new Set for proper change detection
                fileType: fileType,
                child: widget.child,
              ),
            ),
          ],
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
              color: Theme.of(
                context,
              ).colorScheme.primary.withAlpha((0.15 * 225).toInt()),
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
              // Use correct route based on selection mode
              final routeName = widget.isFullscreenRoute
                  ? AppRouteName.filesSearchFullscreen
                  : AppRouteName.filesSearch;

              final params = <String, String>{'path': _currentPath ?? '/'};
              if (widget.selectionId != null) {
                params['selectionId'] = widget.selectionId!;
              }
              if (widget.selectionActionText != null) {
                params['actionText'] = widget.selectionActionText!;
              }

              context.pushNamed(routeName, queryParameters: params);
            },
            tooltip: t.t('common_search'),
          ),
        ],
      ),
    );
  }

  Widget _buildFolderInfoBar(
    BuildContext context,
    String displayName,
    int totalItems,
    List<FileInfo> visibleFiles,
  ) {
    final t = AppLocalizations.of(context);
    final p = _maybeProvider();
    final enabled = p?.isEnabled ?? false;
    final maxLimitActive = p?.maxSelectable != null;
    final allOnPage = (!maxLimitActive && enabled)
        ? (p?.areAllSelected(visibleFiles) ?? false)
        : false;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Breadcrumb navigation
                if (_currentPath != null)
                  BreadcrumbWidget(
                    path: _currentPath!,
                    isFullscreenRoute: widget.isFullscreenRoute,
                    selectionId: widget.selectionId,
                    selectionActionText: widget.selectionActionText,
                  )
                else
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
                      .replaceAll('{count}', totalItems.toString()),
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
          // Conditionally show bulk selection or create folder based on mode
          if (widget.isFullscreenRoute && !maxLimitActive)
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
          else if (!widget.isFullscreenRoute)
            IconButton(
              onPressed: () {
                showNewFolderSheet(
                  context: context,
                  onCreate: (String folderName) async {
                    if (_currentPath == null || folderName.trim().isEmpty) {
                      return;
                    }
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
    );
  }

  Future<void> _openFilterDialog() async {
    // Get fileType from SelectionProvider if available
    final selectionProvider = _maybeProvider();
    final fileType = selectionProvider?.fileType;

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
            child: SafeArea(
              top: false,
              child: FilterSheet(
                currentSort: _sortOption,
                currentTypes: Set.from(_typeFilters),
                currentFileType: fileType,
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
        );
      },
    );
  }
}
