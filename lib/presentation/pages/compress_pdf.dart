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

  String get _levelLabel => switch (_level) {
    0 => 'High Compression',
    1 => 'Medium Compression',
    _ => 'Low Compression',
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
    if (sel.files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Select a PDF first'),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Compressed "${p.basename(file.path)}" ($_levelLabel) → ${p.basename(compressed.path)}',
              ),
              action: SnackBarAction(
                label: 'Open',
                onPressed: () {
                  // could implement open logic later
                },
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
    final theme = Theme.of(context);
    return Consumer<SelectionProvider>(
      builder: (context, selection, _) {
        final hasFile = selection.files.isNotEmpty;
        final FileInfo? file = hasFile ? selection.files.first : null;
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
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
                      'Compress PDF',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Reduce PDF size with smart compression, adjust quality, choose your save location, and rename the file. Add PDFs anytime and quickly create a lighter, optimized document.',
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
                                  'No PDF selected. Go back and choose one.',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                    const SizedBox(height: 28),
                    Text(
                      'Select compression level:',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildOption(
                      context,
                      0,
                      'High Compression',
                      'Smallest size, lower quality',
                    ),
                    _buildOption(
                      context,
                      1,
                      'Medium Compression',
                      'Medium size, medium quality',
                    ),
                    _buildOption(
                      context,
                      2,
                      'Low Compression',
                      'Largest size, better quality',
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
                          children: const [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Compressing...'),
                          ],
                        )
                      : const Text('Compress'),
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
