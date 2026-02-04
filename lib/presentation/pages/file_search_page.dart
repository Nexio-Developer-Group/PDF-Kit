// file_search_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/presentation/component/document_tile.dart';
import 'package:pdf_kit/presentation/layouts/selection_layout.dart';
import 'package:pdf_kit/presentation/provider/selection_provider.dart';
import 'package:pdf_kit/providers/file_system_provider.dart';
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

  static const int _maxPreviousTerms = 12;

  List<String> _previousSearches = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadPreviousSearches();
  }

  @override
  void dispose() {
    _debounce?.cancel();
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
  void _onQueryChanged(String value) {
    setState(() => _query = value);

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;

      final query = _searchController.text.trim();
      final path = widget.initialPath;

      if (path == null) return;

      if (query.isEmpty) {
        context.read<FileSystemProvider>().clearSearch();
        return;
      }

      // Optimized search: current folder first, then nested.
      context.read<FileSystemProvider>().searchOptimized(path, query);
    });
  }

  String _termFromFileName(String name) {
    final dot = name.lastIndexOf('.');
    if (dot > 0) return name.substring(0, dot);
    return name;
  }

  void _loadPreviousSearches() {
    try {
      final list =
          Prefs.getStringList(Constants.fileSearchPreviousTermsKey) ??
          const <String>[];
      setState(() => _previousSearches = List<String>.from(list));
    } catch (_) {
      // Prefs might not be ready yet; fail silently.
    }
  }

  Future<void> _persistPreviousSearches() async {
    try {
      await Prefs.setStringList(
        Constants.fileSearchPreviousTermsKey,
        _previousSearches,
      );
    } catch (_) {
      // ignore
    }
  }

  Future<void> _rememberTerm(String term) async {
    final t = term.trim();
    if (t.isEmpty) return;

    setState(() {
      _previousSearches.removeWhere((e) => e.toLowerCase() == t.toLowerCase());
      _previousSearches.insert(0, t);
      if (_previousSearches.length > _maxPreviousTerms) {
        _previousSearches = _previousSearches.take(_maxPreviousTerms).toList();
      }
    });

    await _persistPreviousSearches();
  }

  Future<void> _deleteTerm(String term) async {
    setState(() {
      _previousSearches.remove(term);
    });
    await _persistPreviousSearches();
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
    final hasQuery = _query.trim().isNotEmpty;
    final noResults = hasQuery && !provider.isSearching && results.isEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _searchBar(context, t),
            if (!hasQuery) _previousOrPrompt(context),
            if (hasQuery && !noResults) Expanded(child: _resultsList(results)),
            if (noResults) _emptyState(context),
          ],
        ),
      ),
    );
  }

  Widget _searchBar(BuildContext context, AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.arrow_back),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest
                    .withAlpha((0.6 * 225).toInt()),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autofocus: true,
                onChanged: _onQueryChanged,
                style: Theme.of(context).textTheme.labelLarge,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: t.t('files_search_hint'),
                  border: InputBorder.none,
                  suffixIcon: _query.trim().isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _searchController.clear();
                            _onQueryChanged('');
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previousOrPrompt(BuildContext context) {
    final t = AppLocalizations.of(context);

    if (_previousSearches.isEmpty) {
      return Expanded(
        child: Center(
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
        ),
      );
    }

    return Expanded(
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Text(
              t.t('recent_files_search_previous_header'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ..._previousSearches.map(
            (s) => ListTile(
              leading: const Icon(Icons.history),
              title: Text(s),
              onTap: () {
                _searchController.text = s;
                _searchController.selection = TextSelection.collapsed(
                  offset: _searchController.text.length,
                );
                _onQueryChanged(s);
              },
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => _deleteTerm(s),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultsList(List<FileInfo> results) {
    final p = _maybeProvider();
    final enabled = widget.selectable && (p?.isEnabled ?? false);
    final provider = context.watch<FileSystemProvider>();

    final docs = results.where((f) => !f.isDirectory).toList();

    if (provider.isSearching && docs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: docs.length,
      padding: const EdgeInsets.only(bottom: 16),
      itemBuilder: (context, index) {
        final f = docs[index];
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          child: DocEntryCard(
            info: f,
            showViewerOptionsSheet:
                !(widget.selectable || widget.isFullscreenRoute == true),
            selectable: enabled,
            selected: (p?.isSelected(f.path) ?? false),
            onInteract: () {
              _rememberTerm(_termFromFileName(f.name));
            },
            onMenuOpened: () {
              _rememberTerm(_termFromFileName(f.name));
            },
            onToggleSelected: enabled
                ? () {
                    _rememberTerm(_termFromFileName(f.name));
                    p?.toggle(f);
                  }
                : null,
            onOpen: enabled
                ? () {
                    _rememberTerm(_termFromFileName(f.name));
                    p?.toggle(f);
                  }
                : () {
                    _rememberTerm(_termFromFileName(f.name));
                    OpenService.open(f.path);
                  },
            onLongPress: () {
              _rememberTerm(_termFromFileName(f.name));
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

  Widget _emptyState(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Expanded(child: Center(child: Text(t.t('files_search_no_results'))));
  }

  Future<void> _handleFileMenu(String action, FileInfo f) async {
    switch (action) {
      case 'open':
        _rememberTerm(_termFromFileName(f.name));
        OpenService.open(f.path);
        break;
      case 'rename':
        _rememberTerm(_termFromFileName(f.name));
        await showRenameFileSheet(
          context: context,
          initialName: f.name,
          onRename: (newName) async {
            await context.read<FileSystemProvider>().renameFile(f, newName);
            if (!mounted) return;
            AppSnackbar.show('Renamed successfully');
          },
        );
        break;
      case 'delete':
        _rememberTerm(_termFromFileName(f.name));
        await showDeleteFileSheet(
          context: context,
          fileName: f.name,
          onDelete: () async {
            await context.read<FileSystemProvider>().deleteFile(f);
            RecentFilesSection.refreshNotifier.value++;
            if (!mounted) return;
            AppSnackbar.show('Deleted successfully');
          },
        );
        break;
    }
  }
}
