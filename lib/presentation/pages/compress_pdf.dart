import 'package:flutter/material.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/presentation/component/document_tile.dart';
import 'package:pdf_kit/presentation/provider/selection_provider.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_kit/service/pdf_compress_service.dart';
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
  int _level = 1; // 0=High,1=Medium,2=Low
  bool _isWorking = false;

  String _levelLabel(AppLocalizations t) => switch (_level) {
    0 => t.t('compress_pdf_high'),
    1 => t.t('compress_pdf_medium'),
    _ => t.t('compress_pdf_low'),
  };

  // String get _levelSubtitle => switch (_level) {
  //   0 => 'Smallest size, lower quality',
  //   1 => 'Medium size, medium quality',
  //   _ => 'Largest size, better quality',
  // };

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
          await PdfCompressService.compressFile(fileInfo: file, level: _level);
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
        (compressed) {
          final originalName = p.basename(file.path);
          final resultName = p.basename(compressed.path);
          final levelName = _levelLabel(t);
          final pattern = t
              .t('compress_pdf_result_pattern')
              .replaceFirst('{original}', originalName)
              .replaceFirst('{level}', levelName)
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
          sel.disable();
          context.pop(true); // signal refresh
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
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(
                        context,
                      ).t('compress_pdf_description'),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    hasFile
                        ? DocEntryCard(
                            info: file!,
                            showActions: false,
                            selectable: false,
                            reorderable: false,
                            onOpen: null,
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
                    Text(
                      AppLocalizations.of(
                        context,
                      ).t('compress_pdf_select_level_label'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildOption(
                      context,
                      0,
                      AppLocalizations.of(context).t('compress_pdf_high'),
                      AppLocalizations.of(context).t('compress_pdf_high_sub'),
                    ),
                    _buildOption(
                      context,
                      1,
                      AppLocalizations.of(context).t('compress_pdf_medium'),
                      AppLocalizations.of(context).t('compress_pdf_medium_sub'),
                    ),
                    _buildOption(
                      context,
                      2,
                      AppLocalizations.of(context).t('compress_pdf_low'),
                      AppLocalizations.of(context).t('compress_pdf_low_sub'),
                    ),
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

  Widget _buildOption(
    BuildContext context,
    int value,
    String title,
    String subtitle,
  ) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: _isWorking ? null : () => setState(() => _level = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Radio<int>(
              value: value,
              groupValue: _level,
              onChanged: _isWorking ? null : (v) => setState(() => _level = v!),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
