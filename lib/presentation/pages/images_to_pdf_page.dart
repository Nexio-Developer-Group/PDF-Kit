// lib/presentation/pages/images_to_pdf_page.dart

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
import 'package:pdf_kit/presentation/widgets/non_dismissible_progress_dialog.dart';

import 'package:path/path.dart' as p;
// import 'dart:io'; // Assuming it's already there or needed
import 'dart:ui';

class ImagesToPdfPage extends StatefulWidget {
  final String? selectionId;

  const ImagesToPdfPage({super.key, this.selectionId});

  @override
  State<ImagesToPdfPage> createState() => _ImagesToPdfPageState();
}

class _ImagesToPdfPageState extends State<ImagesToPdfPage> {
  late final TextEditingController _nameCtrl;
  bool _isConverting = false;
  FileInfo? _selectedDestinationFolder;

  bool _reorderMode = false;

  final ProgressDialogController _progressDialog = ProgressDialogController();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _loadDefaultDestination();
    // Images to PDF requires at least 2 selected files
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

  String _displayName(FileInfo f) {
    try {
      final dynamic maybeName = (f as dynamic).name;
      if (maybeName is String && maybeName.trim().isNotEmpty) return maybeName;
    } catch (_) {}
    return p.basenameWithoutExtension(f.path);
  }

  String _suggestDefaultName(List<FileInfo> files) {
    if (files.isEmpty) return 'Images Document';
    final List<String> first = _displayName(files.first).split('.');
    first.removeLast();
    return '${first.isEmpty ? "Images Document" : first.join('.')} - Images';
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

  Future<void> _handleConvert(
    BuildContext context,
    SelectionProvider selection,
  ) async {
    if (_isConverting) return;

    setState(() => _isConverting = true);

    final progress = ValueNotifier<double>(0.02);
    final stage = ValueNotifier<String>('Preparing…');

    Timer? smoothTimer;
    void bumpProgress(double value01) {
      final next = value01.clamp(0.0, 1.0);
      if (next > progress.value) progress.value = next;
    }

    _progressDialog.show(
      context: context,
      title: 'Images to PDF',
      progress: progress,
      stage: stage,
    );

    smoothTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      // Smoothly creep forward between real updates (never reach 100%).
      if (progress.value < 0.92) {
        bumpProgress(progress.value + 0.01);
      }
    });

    final t = AppLocalizations.of(context);
    final defaultName = t.t('images_to_pdf_default_file_name');

    final outName = _nameCtrl.text.trim().isEmpty
        ? defaultName
        : _nameCtrl.text.trim();

    final files = selection.files;

    late final result;
    try {
      // Pass destination folder to merge service
      result = await PdfMergeService.mergePdfs(
        files: files,
        outputFileName: outName,
        destinationPath: _selectedDestinationFolder?.path,
        onProgress: (p01, s) {
          stage.value = s;
          bumpProgress(p01);
        },
      );
    } finally {
      try {
        bumpProgress(1.0);
        stage.value = 'Done';
      } catch (_) {}

      smoothTimer.cancel();
      if (mounted) {
        setState(() => _isConverting = false);
      } else {
        _isConverting = false;
      }

      if (mounted) {
        _progressDialog.dismiss(context);
      }

      smoothTimer = null;
      progress.dispose();
      stage.dispose();
    }

    result.fold(
      (error) {
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
      (convertedFile) async {
        // Store the converted PDF in recent files
        debugPrint(
          '📝 [ImagesToPDF] Storing converted file: ${convertedFile.name}',
        );
        final storeResult = await RecentFilesService.addRecentFile(
          convertedFile,
        );
        storeResult.fold(
          (error) => debugPrint('❌ [ImagesToPDF] Failed to store: $error'),
          (_) =>
              debugPrint('✅ [ImagesToPDF] Converted file stored successfully'),
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
                .t('snackbar_success_images_to_pdf')
                .replaceAll('{fileName}', convertedFile.name);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(msg),
                backgroundColor: Colors.green,
                action: SnackBarAction(
                  label: t.t('common_open_snackbar'),
                  onPressed: () {
                    context.pushNamed(
                      AppRouteName.showPdf,
                      queryParameters: {'path': convertedFile.path},
                    );
                  },
                ),
              ),
            );
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    final theme = Theme.of(context);

    return Consumer<SelectionProvider>(
      builder: (context, selection, _) {
        final files = selection.files;

        final defaultName = t.t('images_to_pdf_default_file_name');

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
                          t.t('images_to_pdf_title'),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          t.t('images_to_pdf_description'),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // File Name section
                        Text(
                          t.t('images_to_pdf_file_name_label'),
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameCtrl,
                          textInputAction: TextInputAction.done,
                          readOnly: _isConverting,
                          decoration: InputDecoration(
                            hintText: t.t('images_to_pdf_file_name_hint'),
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

                        // Destination Folder Section
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                t
                                    .t('images_to_pdf_files_selected')
                                    .replaceAll(
                                      '{count}',
                                      files.length.toString(),
                                    ),
                                style: theme.textTheme.titleSmall,
                              ),
                            ),
                            FilledButton(
                              onPressed: _isConverting
                                  ? null
                                  : () {
                                      setState(
                                        () => _reorderMode = !_reorderMode,
                                      );
                                    },
                              child: Text(
                                _reorderMode
                                    ? t.t('images_to_pdf_done')
                                    : t.t('images_to_pdf_reorder'),
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
                          disabled: _isConverting,
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
                      onPressed: _isConverting
                          ? null
                          : () {
                              context.pop();
                            },
                      icon: const Icon(Icons.add_rounded),
                      label: Text(
                        t.t('images_to_pdf_add_more_files'),
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
                  // Convert Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: (files.length >= 2 && !_isConverting)
                          ? () => _handleConvert(context, selection)
                          : null,
                      child: _isConverting
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
                          : Text(t.t('images_to_pdf_button')),
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

// Remove _DestinationFolderSelector since we use the shared one
