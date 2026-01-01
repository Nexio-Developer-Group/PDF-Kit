// recent_files_search_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/presentation/component/document_tile.dart';
import 'package:pdf_kit/service/recent_file_service.dart';
import 'package:pdf_kit/presentation/sheets/rename_file_sheet.dart';
import 'package:pdf_kit/service/file_service.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/presentation/pages/home_page.dart';
import 'package:pdf_kit/presentation/layouts/layout_export.dart';
import 'package:pdf_kit/presentation/provider/provider_export.dart';

class RecentFilesSearchPage extends StatefulWidget {
  final bool selectable;
  final String? selectionActionText;
  final String? selectionId;
  final bool? isFullscreenRoute;
  final void Function(List<FileInfo> files)? onSelectionAction;

  const RecentFilesSearchPage({
    super.key,
    this.selectable = false,
    this.selectionActionText,
    this.selectionId,
    this.isFullscreenRoute = false,
    this.onSelectionAction,
  });

  @override
  State<RecentFilesSearchPage> createState() => _RecentFilesSearchPageState();
}

class _RecentFilesSearchPageState extends State<RecentFilesSearchPage> {
  final TextEditingController _controller = TextEditingController();
  List<FileInfo> _allRecentFiles = [];
  List<FileInfo> _filteredResults = [];
  String _query = '';
  bool _isLoading = true;

  // Fake “Previous Search” seeds (static for now - can be made dynamic later)
  final List<String> _previous = const [
    'My Home Certificate',
    'Work Documents',
    'Recommendation Letter',
    'Sales Report Documents',
    'Business Plan Proposal',
    'Job Application Letter',
    'Legal & Terms of Reference',
    'My National ID Card',
  ];

  @override
  void initState() {
    super.initState();
    _loadRecentFiles();
  }

  @override
  void dispose() {
    _controller.dispose();
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

  Future<void> _loadRecentFiles() async {
    setState(() => _isLoading = true);
    final result = await RecentFilesService.getRecentFiles();
    result.fold(
      (error) {
        debugPrint('❌ [RecentFilesSearch] Error loading: $error');
        if (mounted) {
          setState(() {
            _allRecentFiles = [];
            _isLoading = false;
          });
        }
      },
      (files) {
        debugPrint('✅ [RecentFilesSearch] Loaded ${files.length} files');
        if (mounted) {
          setState(() {
            _allRecentFiles = files;
            _isLoading = false;
          });
        }
      },
    );
  }

  void _search(String query) {
    setState(() {
      _query = query;
      if (query.isEmpty) {
        _filteredResults = [];
      } else {
        final q = query.toLowerCase();
        _filteredResults = _allRecentFiles.where((f) {
          // Get filename without extension for search
          final nameWithoutExt = f.name.contains('.')
              ? f.name.substring(0, f.name.lastIndexOf('.'))
              : f.name;
          return nameWithoutExt.toLowerCase().contains(q);
        }).toList();
      }
    });
  }

  void _handleFileOpen(FileInfo file) {
    debugPrint('🔓 [RecentFilesSearch] Opening file: ${file.name}');
    if (_selectionEnabled) {
      _maybeProvider()?.toggle(file);
    } else {
      context.pushNamed(
        AppRouteName.showPdf,
        queryParameters: {'path': file.path},
      );
    }
  }

  Future<void> _handleFileDelete(FileInfo file) async {
    final result = await RecentFilesService.removeRecentFile(file.path);
    final t = AppLocalizations.of(context);

    result.fold(
      (error) {
        debugPrint('❌ [RecentFilesSearch] Delete failed: $error');
        if (mounted) {
          final msg = t
              .t('snackbar_error')
              .replaceAll('{message}', error.toString());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      (updatedFiles) {
        debugPrint(
          '✅ [RecentFilesSearch] Delete successful. Remaining: ${updatedFiles.length}',
        );
        // Notify home page to refresh
        RecentFilesSection.refreshNotifier.value++;
        if (mounted) {
          _loadRecentFiles();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.t('snackbar_removed_recent'))),
          );
        }
      },
    );
  }

  Future<void> _handleFileRename(FileInfo file) async {
    debugPrint('✏️ [RecentFilesSearch] Renaming file: ${file.name}');
    await showRenameFileSheet(
      context: context,
      initialName: file.name,
      onRename: (newName) async {
        final result = await FileService.renameFile(file, newName);
        result.fold(
          (exception) {
            debugPrint(
              '❌ [RecentFilesSearch] Rename failed: ${exception.message}',
            );
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
            debugPrint(
              '✅ [RecentFilesSearch] Rename successful: ${renamedFileInfo.name}',
            );
            if (mounted) {
              // Reload all recent files and re-apply search filter
              _loadRecentFiles().then((_) {
                if (_query.isNotEmpty) {
                  _search(_query);
                }
              });
              // Trigger home page refresh
              RecentFilesSection.refreshNotifier.value++;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('File renamed successfully')),
              );
            }
          },
        );
      },
    );
  }

  void _handleFileMenu(FileInfo file, String action) {
    debugPrint(
      '📋 [RecentFilesSearch] Menu action "$action" for: ${file.name}',
    );
    switch (action) {
      case 'open':
        _handleFileOpen(file);
        break;
      case 'delete':
        _handleFileDelete(file);
        break;
      case 'rename':
        _handleFileRename(file);
        break;
      case 'share':
        debugPrint('📤 [RecentFilesSearch] Share handled by DocEntryCard');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _query.isNotEmpty;
    final noResults = hasQuery && !_isLoading && _filteredResults.isEmpty;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _searchBar(context),
            if (!hasQuery) _previousSection(context),
            if (hasQuery && !noResults) Expanded(child: _list()),
            if (noResults) _emptyState(context),
          ],
        ),
      ),
    );
  }

  Widget _previousSection(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Expanded(
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Row(
              children: [
                Text(
                  t.t('recent_files_search_previous_header'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (!_selectionEnabled)
                  IconButton(
                    onPressed: () {}, // optional: clear all later
                    icon: const Icon(Icons.close),
                    tooltip: t.t('recent_files_search_clear_all_tooltip'),
                  ),
              ],
            ),
          ),
          ..._previous.map(
            (label) => ListTile(
              title: Text(label),
              trailing: const Icon(Icons.close, size: 18),
              onTap: () {
                _controller.text = label;
                _controller.selection = TextSelection.collapsed(
                  offset: label.length,
                );
                _search(label);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar(BuildContext context) {
    final t = AppLocalizations.of(context);

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
                controller: _controller,
                autofocus: true,
                onChanged: _search,
                style: Theme.of(context).textTheme.labelLarge,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: t.t('recent_files_search_hint'),
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: (_controller.text.isNotEmpty)
                      ? IconButton(
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          iconSize: 18,
                          padding: const EdgeInsets.all(5),
                          tooltip: t.t('common_clear'),
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _controller.clear();
                            _search('');
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

  Widget _list() {
    return ListView.builder(
      key: const PageStorageKey('recent_search_list'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _filteredResults.length,
      itemBuilder: (context, index) {
        final f = _filteredResults[index];
        return RepaintBoundary(
          key: ValueKey(f.path),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            child: DocEntryCard(
              info: f,
              selectable: _selectionEnabled,
              selected: (_maybeProvider()?.isSelected(f.path) ?? false),
              onToggleSelected: _selectionEnabled
                  ? () => _maybeProvider()?.toggle(f)
                  : null,
              onOpen: () => _handleFileOpen(f),
              onLongPress: () {
                if (!_selectionEnabled) {
                  _maybeProvider()?.enable();
                }
                _maybeProvider()?.toggle(f);
              },
              onMenu: (action) => _handleFileMenu(f, action),
              onRemove: () => _handleFileDelete(f),
              showRemove: !_selectionEnabled,
            ),
          ),
        );
      },
    );
  }

  Widget _emptyState(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/not_found.png'),
              const SizedBox(height: 12),
              Text(
                t.t('recent_files_search_no_results_title'),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                t.t('recent_files_search_no_results_message'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
