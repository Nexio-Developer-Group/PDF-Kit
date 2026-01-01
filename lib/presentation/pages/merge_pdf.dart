// lib/presentation/pages/merge_pdf_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/presentation/component/document_tile.dart';
import 'package:pdf_kit/presentation/provider/selection_provider.dart';
import 'package:pdf_kit/service/pdf_merge_service.dart';
import 'package:pdf_kit/service/recent_file_service.dart';
import 'package:pdf_kit/service/path_service.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/presentation/layouts/selection_layout.dart';
import 'package:pdf_kit/presentation/pages/home_page.dart';

import 'package:path/path.dart' as p;
import 'dart:ui';

class MergePdfPage extends StatefulWidget {
  final String? selectionId;

  const MergePdfPage({super.key, this.selectionId});

  @override
  State<MergePdfPage> createState() => _MergePdfPageState();
}

class _MergePdfPageState extends State<MergePdfPage> {
  late final TextEditingController _nameCtrl;
  bool _isMerging = false;
  FileInfo? _selectedDestinationFolder;

  bool _reorderMode = false; // toggles UI indication only
  bool _mergeProgressDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _loadDefaultDestination();
    // Merge requires at least 2 selected files
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        SelectionScope.of(context).setMinSelectable(2);
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  /// Load default destination folder (User Pref -> Downloads)
  Future<void> _loadDefaultDestination() async {
    try {
      // 1. Check for saved preference
      final savedPath = Prefs.getString(Constants.pdfOutputFolderPathKey);
      if (savedPath != null) {
        final dir = Directory(savedPath);
        if (await dir.exists()) {
          setState(() {
            _selectedDestinationFolder = FileInfo(
              name: p.basename(savedPath),
              path: savedPath,
              extension: '',
              size: 0,
              isDirectory: true,
              lastModified: DateTime.now(),
            );
          });
          return;
        }
      }

      // 2. Fallback to public Downloads directory
      final publicDirsResult = await PathService.publicDirs();

      publicDirsResult.fold(
        (error) {
          debugPrint('Failed to load default destination: $error');
        },
        (publicDirs) {
          final downloadsDir = publicDirs['Downloads'];
          if (downloadsDir != null) {
            setState(() {
              _selectedDestinationFolder = FileInfo(
                name: 'Downloads',
                path: downloadsDir.path,
                extension: '',
                size: 0,
                isDirectory: true,
                lastModified: DateTime.now(),
              );
            });
          }
        },
      );
    } catch (e) {
      debugPrint('Error loading default destination: $e');
    }
  }

  /// Open folder picker and update destination
  // lib/presentation/pages/merge_pdf_page.dart

  /// Open folder picker and update destination

  String _displayName(FileInfo f) {
    try {
      final dynamic maybeName = (f as dynamic).name;
      if (maybeName is String && maybeName.trim().isNotEmpty) return maybeName;
    } catch (_) {}
    return p.basenameWithoutExtension(f.path);
  }

  String _suggestDefaultName(List<FileInfo> files) {
    if (files.isEmpty) return 'Merged Document';
    final List<String> first = _displayName(files.first).split('.');
    first.removeLast();
    return '${first.isEmpty ? "Merged Document" : first.join('.')} - Merged';
  }

  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double animValue = Curves.easeInOut.transform(animation.value);
        final double elevation = lerpDouble(0, 6, animValue)!;
        return Material(
          elevation: elevation,
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: child,
        );
      },
      child: child,
    );
  }

  void _showMergeProgressDialog({
    required ValueListenable<double> progress,
    required ValueListenable<String> stage,
  }) {
    if (_mergeProgressDialogOpen) return;
    _mergeProgressDialogOpen = true;

    // Fire-and-forget; we close it manually when merge completes.
    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (dialogContext) {
          return PopScope(
            canPop: false,
            child: AlertDialog(
              title: const Text('Merging PDF'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ValueListenableBuilder<double>(
                      valueListenable: progress,
                      builder: (_, value, __) {
                        final pct = (value * 100)
                            .clamp(0, 100)
                            .toStringAsFixed(0);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LinearProgressIndicator(
                              value: value.clamp(0.0, 1.0),
                            ),
                            const SizedBox(height: 8),
                            Text('$pct%'),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<String>(
                      valueListenable: stage,
                      builder: (_, value, __) {
                        return Text(
                          value,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('Please keep the app open while we finish.'),
                  ],
                ),
              ),
            ),
          );
        },
      ).whenComplete(() {
        _mergeProgressDialogOpen = false;
      }),
    );
  }

  void _dismissMergeProgressDialog() {
    if (!_mergeProgressDialogOpen) return;
    // Use root navigator because the dialog is shown on it.
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) {
      nav.pop();
    }
    _mergeProgressDialogOpen = false;
  }

  Future<void> _handleMerge(
    BuildContext context,
    SelectionProvider selection,
  ) async {
    if (_isMerging) return;

    final progress = ValueNotifier<double>(0.02);
    final stage = ValueNotifier<String>('Preparing…');

    Timer? smoothTimer;
    void startSmoothProgress() {
      smoothTimer?.cancel();
      smoothTimer = Timer.periodic(const Duration(milliseconds: 180), (_) {
        // Slowly creep forward between real updates, but never reach 100%.
        final current = progress.value;
        final next = (current + 0.003).clamp(0.0, 0.95);
        if (next > current) progress.value = next;
      });
    }

    void stopSmoothProgress() {
      smoothTimer?.cancel();
      smoothTimer = null;
    }

    _showMergeProgressDialog(progress: progress, stage: stage);
    startSmoothProgress();

    setState(() => _isMerging = true);

    try {
      final t = AppLocalizations.of(context);
      final defaultName = t.t('merge_pdf_default_file_name');

      final outName = _nameCtrl.text.trim().isEmpty
          ? defaultName
          : _nameCtrl.text.trim();

      final files = selection.files;

      // Pass destination folder to merge service
      final result = await PdfMergeService.mergePdfs(
        files: files,
        outputFileName: outName,
        destinationPath: _selectedDestinationFolder?.path,
        onProgress: (p01, s) {
          // Keep UI smooth: never jump backwards.
          if (p01 > progress.value) progress.value = p01;
          stage.value = s;
        },
      );

      if (!mounted) return;

      result.fold(
        (error) {
          progress.value = 1.0;
          stage.value = 'Failed';
          _dismissMergeProgressDialog();
          if (!mounted) return;
          final t = AppLocalizations.of(context);
          final msg = t
              .t('snackbar_error')
              .replaceAll('{message}', error.message);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        },
        (mergedFile) async {
          progress.value = 1.0;
          stage.value = 'Done';
          _dismissMergeProgressDialog();

          // Only store the merged PDF in recent files, not the source files
          debugPrint('📝 [MergePDF] Storing merged file: ${mergedFile.name}');
          final storeResult = await RecentFilesService.addRecentFile(
            mergedFile,
          );
          storeResult.fold(
            (error) => debugPrint('❌ [MergePDF] Failed to store: $error'),
            (_) => debugPrint('✅ [MergePDF] Merged file stored successfully'),
          );

          if (!mounted) return;

          // Navigate to home and clear all routes, then reload home page
          selection.disable();
          context.go('/');

          // Trigger home page reload
          RecentFilesSection.refreshNotifier.value++;

          // Show success message after navigation
          Future.delayed(const Duration(milliseconds: 300), () {
            if (context.mounted) {
              final t = AppLocalizations.of(context);
              final msg = t
                  .t('snackbar_success_merge')
                  .replaceAll('{fileName}', mergedFile.name);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(msg),
                  backgroundColor: Colors.green,
                  action: SnackBarAction(
                    label: t.t('common_open_snackbar'),
                    onPressed: () {
                      context.pushNamed(
                        AppRouteName.showPdf,
                        queryParameters: {'path': mergedFile.path},
                      );
                    },
                  ),
                ),
              );
            }
          });
        },
      );
    } finally {
      stopSmoothProgress();
      if (mounted) {
        setState(() => _isMerging = false);
        _dismissMergeProgressDialog();
      }
      // Avoid leaks.
      progress.dispose();
      stage.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    final theme = Theme.of(context);

    return Consumer<SelectionProvider>(
      builder: (context, selection, _) {
        final files = selection.files;

        final defaultName = t.t('merge_pdf_default_file_name');

        if ((_nameCtrl.text.isEmpty || _nameCtrl.text == defaultName) &&
            files.isNotEmpty) {
          _nameCtrl.text = _suggestDefaultName(files);
          _nameCtrl.selection = TextSelection.fromPosition(
            TextPosition(offset: _nameCtrl.text.length),
          );
        }

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
          ),
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: screenPadding,
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.t('merge_pdf_title'), // "Merge PDF"
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          t.t('merge_pdf_description'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // File Name section
                        Text(
                          t.t('merge_pdf_file_name_label'),
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameCtrl,
                          textInputAction: TextInputAction.done,
                          readOnly: _isMerging,
                          decoration: InputDecoration(
                            hintText: t.t('merge_pdf_file_name_hint'),
                            border: const UnderlineInputBorder(),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary.withOpacity(
                                  0.3,
                                ),
                              ),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                t
                                    .t('merge_pdf_files_selected')
                                    .replaceAll(
                                      '{count}',
                                      files.length.toString(),
                                    ),
                                style: theme.textTheme.titleSmall,
                              ),
                            ),
                            FilledButton(
                              onPressed: _isMerging
                                  ? null
                                  : () {
                                      setState(
                                        () => _reorderMode = !_reorderMode,
                                      );
                                    },
                              child: Text(
                                _reorderMode
                                    ? t.t('merge_pdf_done')
                                    : t.t('merge_pdf_reorder'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),

                // Reorderable files list
                SliverReorderableList(
                  itemCount: files.length,
                  onReorder: (oldIndex, newIndex) {
                    selection.reorderFiles(oldIndex, newIndex);
                  },
                  proxyDecorator: _proxyDecorator,
                  itemBuilder: (context, index) {
                    final f = files[index];
                    return ReorderableDelayedDragStartListener(
                      key: ValueKey(f.path),
                      index: index,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: DocEntryCard(
                          info: f,
                          showEdit: true,
                          showRemove: true,
                          reorderable: _reorderMode,
                          disabled: _isMerging,
                          onEdit: () => null,
                          onRemove: () => selection.removeFile(f.path),
                          onOpen: () => context.pushNamed(
                            AppRouteName.showPdf,
                            queryParameters: {'path': f.path},
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          bottomNavigationBar: Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(color: Colors.transparent),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Add More Files Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _isMerging
                          ? null
                          : () {
                              context.pop();
                            },
                      icon: const Icon(Icons.add_rounded),
                      label: Text(
                        t.t('merge_pdf_add_more_files'),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withAlpha(15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Merge Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: (files.length >= 2 && !_isMerging)
                          ? () => _handleMerge(context, selection)
                          : null,
                      child: _isMerging
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(t.t('merge_pdf_button')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Remove _DestinationFolderSelector class
