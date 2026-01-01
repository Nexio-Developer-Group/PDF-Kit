import 'package:flutter/material.dart';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/presentation/component/document_tile.dart';
import 'package:pdf_kit/presentation/layouts/layout_export.dart';
import 'package:pdf_kit/presentation/provider/provider_export.dart';
import 'package:pdf_kit/service/recent_file_service.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/presentation/sheets/clear_recent_files_sheet.dart';
import 'package:pdf_kit/presentation/sheets/rename_file_sheet.dart';
import 'package:pdf_kit/service/file_service.dart';
import 'package:pdf_kit/presentation/pages/home_page.dart';

class RecentFilesPage extends StatefulWidget {
  final bool selectable;
  final String? selectionActionText;
  final String? selectionId;
  final bool? isFullscreenRoute;
  final void Function(List<FileInfo> files)? onSelectionAction;

  const RecentFilesPage({
    Key? key,
    this.selectable = false,
    this.selectionActionText,
    this.selectionId,
    this.isFullscreenRoute = false,
    this.onSelectionAction,
  }) : super(key: key);

  @override
  State<RecentFilesPage> createState() => _RecentFilesPageState();
}

class _RecentFilesPageState extends State<RecentFilesPage> {
  List<FileInfo> _files = [];
  bool _isLoading = true;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    debugPrint('📱 [RecentFilesPage] initState called');
    _loadRecentFiles();
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
    debugPrint('🔄 [RecentFilesPage] Loading recent files...');
    setState(() => _isLoading = true);

    final result = await RecentFilesService.getRecentFiles();
    result.fold(
      (error) {
        debugPrint('❌ [RecentFilesPage] Error loading: $error');
        if (mounted) {
          setState(() {
            _files = [];
            _isLoading = false;
          });
        }
      },
      (files) {
        debugPrint('✅ [RecentFilesPage] Loaded ${files.length} files');
        if (mounted) {
          setState(() {
            _files = files;
            _isLoading = false;
          });
        }
      },
    );
  }

  void _handleFileOpen(FileInfo file) {
    debugPrint('🔓 [RecentFilesPage] Opening file: ${file.name}');
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
    debugPrint('🗑️ [RecentFilesPage] Deleting file: ${file.name}');
    final t = AppLocalizations.of(context);

    // Optimistically remove from UI immediately
    final index = _files.indexWhere((f) => f.path == file.path);
    if (index == -1) return;

    setState(() {
      _files.removeAt(index);
    });

    // Then update storage
    final result = await RecentFilesService.removeRecentFile(file.path);

    result.fold(
      (error) {
        debugPrint('❌ [RecentFilesPage] Delete failed: $error');
        // Restore the file on error
        if (mounted) {
          setState(() {
            _files.insert(index, file);
          });
          // final msg = t
          //     .t('snackbar_error')
          //     .replaceAll('{message}', error.toString());
          // ScaffoldMessenger.of(context).showSnackBar(
          //   SnackBar(
          //     content: Text(msg),
          //     backgroundColor: Theme.of(context).colorScheme.error,
          //   ),
          // );
        }
      },
      (updatedFiles) {
        debugPrint(
          '✅ [RecentFilesPage] Delete successful. Remaining: ${updatedFiles.length}',
        );
        // Notify home page to refresh
        RecentFilesSection.refreshNotifier.value++;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(t.t('snackbar_removed_recent'))),
          );
        }
      },
    );
  }

  Future<void> _handleFileRename(FileInfo file) async {
    debugPrint('✏️ [RecentFilesPage] Renaming file: ${file.name}');
    await showRenameFileSheet(
      context: context,
      initialName: file.name,
      onRename: (newName) async {
        final result = await FileService.renameFile(file, newName);
        result.fold(
          (exception) {
            debugPrint(
              '❌ [RecentFilesPage] Rename failed: ${exception.message}',
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
              '✅ [RecentFilesPage] Rename successful: ${renamedFileInfo.name}',
            );
            if (mounted) {
              // Reload recent files
              _loadRecentFiles();
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
    debugPrint('📋 [RecentFilesPage] Menu action "$action" for: ${file.name}');
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
        debugPrint('📤 [RecentFilesPage] Share handled by DocEntryCard');
        break;
    }
  }

  Future<void> _openClearRecentFilesSheet() async {
    await showClearRecentFilesSheet(
      context: context,
      onClear: () async {
        debugPrint('🧹 [RecentFilesPage] Clear All pressed');
        final result = await RecentFilesService.clearRecentFiles();
        final t = AppLocalizations.of(context);

        result.fold(
          (error) {
            debugPrint('❌ [RecentFilesPage] Clear All failed: $error');
            if (mounted) {
              final msg = t
                  .t('snackbar_error')
                  .replaceAll('{message}', error.toString());
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(msg)));
            }
          },
          (_) {
            debugPrint('✅ [RecentFilesPage] Clear All successful');
            // Notify home page to refresh
            RecentFilesSection.refreshNotifier.value++;
            if (mounted) {
              setState(() {
                _files.clear();
              });
            }
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, ThemeData theme) {
    final t = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            t.t('recent_files_empty_title'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t.t('recent_files_empty_message'),
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: screenPadding,
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 8),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _files.isEmpty
                    ? _buildEmptyState(context, theme)
                    : AnimatedList(
                        key: _listKey,
                        padding: const EdgeInsets.only(bottom: 16),
                        initialItemCount: _files.length,
                        itemBuilder: (context, i, animation) {
                          if (i >= _files.length)
                            return const SizedBox.shrink();

                          return SlideTransition(
                            position: animation.drive(
                              Tween<Offset>(
                                begin: const Offset(1, 0),
                                end: Offset.zero,
                              ).chain(CurveTween(curve: Curves.easeOut)),
                            ),
                            child: FadeTransition(
                              opacity: animation,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 8,
                                  // left: 4,
                                  // right: 4,
                                ),
                                child: DocEntryCard(
                                  info: _files[i],
                                  selectable: _selectionEnabled,
                                  selected:
                                      (_maybeProvider()?.isSelected(
                                        _files[i].path,
                                      ) ??
                                      false),
                                  onToggleSelected: _selectionEnabled
                                      ? () =>
                                            _maybeProvider()?.toggle(_files[i])
                                      : null,
                                  onOpen: () => _handleFileOpen(_files[i]),
                                  onLongPress: () {
                                    if (!_selectionEnabled) {
                                      _maybeProvider()?.enable();
                                    }
                                    _maybeProvider()?.toggle(_files[i]);
                                  },
                                  onMenu: (action) =>
                                      _handleFileMenu(_files[i], action),
                                  onRemove: () => _handleFileDelete(_files[i]),
                                  showRemove: !_selectionEnabled,
                                  showEdit: false,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Container(
      height: 56,
      // padding: const EdgeInsets.symmetric(horizontal: 12),
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
            t.t('recent_files_title'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Navigate to appropriate search route based on mode
              final routeName = widget.isFullscreenRoute == true
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
            tooltip: t.t('common_search'),
          ),
          if (!_selectionEnabled)
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.more_vert),
              tooltip: t.t('files_more_tooltip'),
              onSelected: (value) {
                if (value == 'clear_all') {
                  _openClearRecentFilesSheet();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'clear_all',
                  child: Text(t.t('recent_files_clear_menu')),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
