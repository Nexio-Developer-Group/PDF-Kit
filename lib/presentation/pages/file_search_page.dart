// file_search_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/presentation/component/document_tile.dart';
import 'package:pdf_kit/presentation/component/folder_tile.dart';
import 'package:pdf_kit/presentation/layouts/selection_layout.dart';
import 'package:pdf_kit/presentation/provider/selection_provider.dart';
import 'package:pdf_kit/providers/file_system_provider.dart'; // [NEW]
import 'package:pdf_kit/service/open_service.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/presentation/sheets/rename_file_sheet.dart';
import 'package:pdf_kit/presentation/sheets/delete_file_sheet.dart';
import 'package:pdf_kit/presentation/pages/home_page.dart';

class SearchFilesScreen extends StatefulWidget {
  final String? initialPath;
  final bool selectable;
  final String? selectionActionText;
  final String? selectionId;
  final bool? isFullscreenRoute;

  const SearchFilesScreen({
    super.key,
    this.initialPath,
    this.selectable = false,
    this.selectionActionText,
    this.selectionId,
    this.isFullscreenRoute,
  });

  @override
  State<SearchFilesScreen> createState() => _SearchFilesScreenState();
}

class _SearchFilesScreenState extends State<SearchFilesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Local history state - could be moved to provider or persistent storage
  List<String> _previousSearches = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    // Clear search results when leaving the screen
    context.read<FileSystemProvider>().clearSearch();
    super.deactivate();
  }

  Timer? _debounce;
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      final query = _searchController.text.trim();
      final path = widget.initialPath;

      if (path != null) {
        context.read<FileSystemProvider>().search(path, query);
      }
    });
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
    final t = AppLocalizations.of(context);
    final provider = context.watch<FileSystemProvider>();
    final results = provider.searchResults;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: const BackButton(),
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          autofocus: true,
          decoration: InputDecoration(
            hintText: t.t('files_search_hint'),
            border: InputBorder.none,
          ),
          textInputAction: TextInputAction.search,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
              },
            ),
        ],
      ),
      body: _buildBody(context, results, _searchController.text.isEmpty),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<FileInfo> results,
    bool isEmptyQuery,
  ) {
    final t = AppLocalizations.of(context);
    final p = _maybeProvider();
    final enabled = widget.selectable && (p?.isEnabled ?? false);

    if (isEmptyQuery) {
      if (_previousSearches.isNotEmpty) {
        return ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                t.t('recent_files_search_previous_header'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            ..._previousSearches.map(
              (s) => ListTile(
                leading: const Icon(Icons.history),
                title: Text(s),
                onTap: () {
                  _searchController.text = s;
                  // Listener will trigger search
                },
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    setState(() {
                      _previousSearches.remove(s);
                    });
                  },
                ),
              ),
            ),
          ],
        );
      }
      // Empty state
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Theme.of(context).disabledColor,
            ),
            const SizedBox(height: 16),
            Text(
              t.t('files_search_type_prompt'),
              style: TextStyle(color: Theme.of(context).disabledColor),
            ),
          ],
        ),
      );
    }

    if (results.isEmpty) {
      return Center(child: Text(t.t('files_search_no_results')));
    }

    return ListView.builder(
      itemCount: results.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final f = results[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          child: f.isDirectory
              ? FolderEntryCard(
                  info: f,
                  onTap: () async {
                    if (widget.isFullscreenRoute == true) {
                      await context.pushNamed(
                        'files.search.fullscreen', // ensure this route is valid or use generic
                        queryParameters: {'path': f.path},
                      );
                    } else {
                      await context.pushNamed(
                        AppRouteName.filesSearch,
                        queryParameters: {'path': f.path},
                      );
                    }
                  },
                )
              : DocEntryCard(
                  info: f,
                  selectable: enabled,
                  selected: (p?.isSelected(f.path) ?? false),
                  onToggleSelected: enabled ? () => p?.toggle(f) : null,
                  onOpen: enabled
                      ? () => p?.toggle(f)
                      : () {
                          _addToRecentSearches(_searchController.text);
                          OpenService.open(f.path);
                        },
                  onLongPress: () {
                    if (widget.selectable && !enabled) {
                      p?.enable();
                      p?.toggle(f);
                    }
                  },
                  onMenu: (action) => _handleFileMenu(action, f),
                ),
        );
      },
    );
  }

  void _addToRecentSearches(String query) {
    if (query.trim().isEmpty) return;
    if (!_previousSearches.contains(query)) {
      setState(() {
        _previousSearches.insert(0, query);
        if (_previousSearches.length > 5) _previousSearches.removeLast();
      });
    }
  }

  Future<void> _handleFileMenu(String action, FileInfo f) async {
    switch (action) {
      case 'open':
        OpenService.open(f.path);
        _addToRecentSearches(_searchController.text);
        break;
      case 'rename':
        await showRenameFileSheet(
          context: context,
          initialName: f.name,
          onRename: (newName) async {
            context.read<FileSystemProvider>().renameFile(f, newName).then((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Renamed successfully')),
              );
            });
          },
        );
        break;
      case 'delete':
        await showDeleteFileSheet(
          context: context,
          fileName: f.name,
          onDelete: () async {
            await context.read<FileSystemProvider>().deleteFile(f);
            RecentFilesSection.refreshNotifier.value++;
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Deleted successfully')),
            );
          },
        );
        break;
    }
  }
}
