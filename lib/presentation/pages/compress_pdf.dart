import 'package:flutter/material.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/presentation/component/document_tile.dart';
import 'package:pdf_kit/presentation/provider/selection_provider.dart';
import 'package:pdf_kit/presentation/layouts/selection_layout.dart';
import 'package:pdf_kit/presentation/pages/home_page.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_kit/service/pdf_compress_service.dart';
import 'package:pdf_kit/service/recent_file_service.dart';
import 'package:dartz/dartz.dart' show Either; // avoid State name clash
import 'package:pdf_kit/service/pdf_merge_service.dart'
    show CustomException; // for Either left type

class CompressPdfPage extends StatefulWidget {
  final String? selectionId;
  const CompressPdfPage({super.key, this.selectionId});

  @override
  State<CompressPdfPage> createState() => _CompressPdfPageState();
}

class _CompressPdfPageState extends State<CompressPdfPage> {
  @override
  void initState() {
    super.initState();
    // Ensure minimum required selection for compress is 1
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        SelectionScope.of(context).setMinSelectable(1);
      } catch (_) {}
    });
  }

  bool _isWorking = false;
  int? _originalFileSize;

  String get _estimatedReduction {
    // Rasterization typically achieves 40-60% compression
    return '40-60%';
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
    try {
      final Either<CustomException, FileInfo> result =
          await PdfCompressService.compressFile(fileInfo: file);
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
      if (mounted) setState(() => _isWorking = false);
    }
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
                padding: const EdgeInsets.all(24.0),
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
                                    'This will compress your PDF by rasterizing pages at optimized quality (80%). Expected reduction: $_estimatedReduction',
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
