import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/presentation/component/document_tile.dart';
import 'package:pdf_kit/presentation/provider/selection_provider.dart';
import 'package:pdf_kit/presentation/layouts/selection_layout.dart';
import 'package:pdf_kit/presentation/pages/home_page.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_kit/service/pdf_compress_service.dart';
import 'package:pdf_kit/service/recent_file_service.dart';
import 'package:dartz/dartz.dart' show Either;
import 'package:pdf_kit/service/pdf_merge_service.dart' show CustomException;

import 'package:pdf_kit/service/path_service.dart';
import 'package:pdf_kit/presentation/widgets/non_dismissible_progress_dialog.dart';
import 'dart:async';
import 'dart:io';

class CompressPdfPage extends StatefulWidget {
  final String? selectionId;
  const CompressPdfPage({super.key, this.selectionId});

  @override
  State<CompressPdfPage> createState() => _CompressPdfPageState();
}

class _CompressPdfPageState extends State<CompressPdfPage> {
  bool _isWorking = false;
  int? _originalFileSize;
  FileInfo? _selectedDestinationFolder;

  final ProgressDialogController _progressDialog = ProgressDialogController();

  /// Load default destination folder (User Pref -> Downloads)
  Future<void> _loadDefaultDestination() async {
    try {
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

      // Fallback
      final publicDirsResult = await PathService.publicDirs();
      publicDirsResult.fold((error) {}, (publicDirs) {
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
      });
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _loadDefaultDestination();
    // Ensure minimum required selection for compress is 1
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        SelectionScope.of(context).setMinSelectable(1);
      } catch (_) {}
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Future<void> _handleCompress(
    BuildContext context,
    SelectionProvider sel,
  ) async {
    final t = AppLocalizations.of(context);
    if (sel.files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t.t('compress_pdf_select_first_error')),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    setState(() => _isWorking = true);
    final file = sel.files.first;

    final progress = ValueNotifier<double>(0.02);
    final stage = ValueNotifier<String>('Preparing…');
    Timer? smoothTimer;

    void bumpProgress(double value01) {
      final next = value01.clamp(0.0, 1.0);
      if (next > progress.value) progress.value = next;
    }

    _progressDialog.show(
      context: context,
      title: 'Compress PDF',
      progress: progress,
      stage: stage,
    );

    smoothTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (progress.value < 0.92) {
        bumpProgress(progress.value + 0.01);
      }

      // Keep a single realtime "currently doing…" line even when the
      // underlying service can't report granular progress.
      final p = progress.value;
      if (p < 0.15) {
        stage.value = 'Analyzing PDF…';
      } else if (p < 0.85) {
        stage.value = 'Compressing…';
      } else {
        stage.value = 'Finalizing…';
      }
    });

    try {
      final Either<CustomException, FileInfo> result =
          await PdfCompressService.compressFile(
            fileInfo: file,
            destinationPath: _selectedDestinationFolder?.path,
          );
      if (!mounted) return;
      result.fold(
        (err) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(err.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        },
        (compressed) async {
          // Store resulting compressed file to recent files
          debugPrint(
            '📝 [CompressPDF] Storing compressed file: ${compressed.name}',
          );
          final storeResult = await RecentFilesService.addRecentFile(
            compressed,
          );
          storeResult.fold(
            (error) => debugPrint('❌ [CompressPDF] Failed to store: $error'),
            (_) => debugPrint(
              '✅ [CompressPDF] Compressed file stored successfully',
            ),
          );

          if (!mounted) return;

          // Navigate to home and clear all routes
          sel.disable();
          context.go('/');

          // Trigger home page reload
          RecentFilesSection.refreshNotifier.value++;

          // Show success message after navigation
          Future.delayed(const Duration(milliseconds: 300), () {
            if (context.mounted) {
              final originalName = p.basename(file.path);
              final resultName = p.basename(compressed.path);
              final pattern = t
                  .t('compress_pdf_result_pattern')
                  .replaceFirst('{original}', originalName)
                  .replaceFirst('{level}', 'optimized')
                  .replaceFirst('{result}', resultName);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(pattern),
                  action: SnackBarAction(
                    label: t.t('common_open_snackbar'),
                    onPressed: () {},
                  ),
                ),
              );
            }
          });
        },
      );
    } finally {
      try {
        bumpProgress(1.0);
        stage.value = 'Done';
      } catch (_) {}

      smoothTimer.cancel();
      if (mounted) {
        _progressDialog.dismiss(context);
      }
      progress.dispose();
      stage.dispose();

      if (mounted) setState(() => _isWorking = false);
    }
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    print(AppLocalizations.of(context).t('compress_pdf_title'));

    final theme = Theme.of(context);
    return Consumer<SelectionProvider>(
      builder: (context, selection, _) {
        final hasFile = selection.files.isNotEmpty;
        final FileInfo? file = hasFile ? selection.files.first : null;
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18),
              onPressed: _isWorking ? null : () => context.pop(),
            ),
          ),
          body: SafeArea(
            child: AbsorbPointer(
              absorbing: _isWorking,
              child: SingleChildScrollView(
                padding: screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).t('compress_pdf_title'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(
                        context,
                      ).t('compress_pdf_description'),
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    hasFile
                        ? Builder(
                            builder: (context) {
                              // Update original file size when file changes
                              if (_originalFileSize != file!.size) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  setState(() {
                                    _originalFileSize = file.size;
                                  });
                                });
                              }
                              return DocEntryCard(
                                info: file,
                                showEdit: false,
                                showRemove: true,
                                selectable: false,
                                reorderable: false,
                                onOpen: null,
                              );
                            },
                          )
                        : Row(
                            children: [
                              const Icon(
                                Icons.picture_as_pdf_outlined,
                                size: 32,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  AppLocalizations.of(
                                    context,
                                  ).t('compress_pdf_no_pdf_selected'),
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(height: 28),
                    if (hasFile && _originalFileSize != null) ...[
                      Text(
                        'Compression Info',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Original Size:',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                Text(
                                  _formatFileSize(_originalFileSize!),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Display actual compression factors from the service
                            Builder(
                              builder: (context) {
                                final preset =
                                    PdfCompressService.getDefaultPreset();
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInfoRow(
                                      context,
                                      'Pipeline',
                                      'Rasterize → JPEG → PDF',
                                    ),
                                    const SizedBox(height: 4),
                                    _buildInfoRow(
                                      context,
                                      'Default preset',
                                      'DPI ${preset.dpi}, Q ${preset.jpegQuality}%, Max ${preset.maxLongSidePx}px',
                                    ),
                                    const SizedBox(height: 8),
                                    _buildInfoRow(
                                      context,
                                      'JPEG Quality',
                                      '${preset.jpegQuality}%',
                                    ),
                                    const SizedBox(height: 4),
                                    _buildInfoRow(
                                      context,
                                      'DPI',
                                      '${preset.dpi}',
                                    ),
                                    const SizedBox(height: 4),
                                    _buildInfoRow(
                                      context,
                                      'Max Resolution',
                                      '${preset.maxLongSidePx} px',
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 18,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'These values come from the compression/rasterization services. If the output is not smaller than the original, the compressor may retry once with a stronger preset.',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: hasFile && !_isWorking
                      ? () => _handleCompress(context, selection)
                      : null,
                  child: _isWorking
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text(
                              AppLocalizations.of(
                                context,
                              ).t('compress_pdf_compressing'),
                            ),
                          ],
                        )
                      : Text(
                          AppLocalizations.of(context).t('compress_pdf_button'),
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
