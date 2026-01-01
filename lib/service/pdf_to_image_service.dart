import 'dart:io';
// import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:external_path/external_path.dart';
import 'package:pdfx/pdfx.dart' as pdfx;

/// Reuse your existing failure type from the rasterization service.
class PdfRasterizationFailure {
  final String message;
  final Object? error;
  final StackTrace? stackTrace;

  const PdfRasterizationFailure(this.message, {this.error, this.stackTrace});

  @override
  String toString() =>
      'PdfRasterizationFailure(message: $message, error: $error)';
}

/// Service for exporting selected PDF pages as image files.
/// Uses pdfx for rasterization and path_provider for storage. [web:1][web:49][web:46][web:50]
class PdfSelectedPagesToImagesService {
  PdfSelectedPagesToImagesService._();

  static void _report(
    void Function(double progress01, String stage)? onProgress,
    double progress01,
    String stage,
  ) {
    try {
      onProgress?.call(progress01.clamp(0.0, 1.0), stage);
    } catch (_) {}
  }

  /// Rasterize the selected pages of [inputPdf] and store them as image files
  /// in [outputDirectory]. If [outputDirectory] is null, a default folder
  /// inside the app documents directory is used.
  ///
  /// [pageNumbers] are 1-based indices (same as pdfx). [web:1][web:49]
  /// [fileNamePrefix] optional custom prefix for the output files.
  static Future<Either<PdfRasterizationFailure, List<File>>>
  exportSelectedPagesToImages({
    required File inputPdf,
    required List<int> pageNumbers,
    Directory? outputDirectory,
    String? fileNamePrefix,
    void Function(double progress01, String stage)? onProgress,
  }) async {
    try {
      _report(onProgress, 0.03, 'Validating inputs');
      if (pageNumbers.isEmpty) {
        return left(
          const PdfRasterizationFailure('No page numbers provided for export'),
        );
      }

      // Normalize: unique + sorted 1-based page indices.
      final pagesToExport = pageNumbers.toSet().toList()..sort();

      final doc = await pdfx.PdfDocument.openFile(
        inputPdf.path,
      ); // [web:1][web:49]

      try {
        final totalPages = doc.pagesCount;
        debugPrint(
          '📄 [SelectedPagesToImages] Total pages: $totalPages, requested: $pagesToExport',
        );

        // Validate requested pages.
        final invalid = pagesToExport
            .where((p) => p < 1 || p > totalPages)
            .toList(growable: false);
        if (invalid.isNotEmpty) {
          return left(
            PdfRasterizationFailure(
              'Invalid page indices requested: $invalid (valid range: 1..$totalPages)',
            ),
          );
        }

        // Resolve target directory.
        final Directory baseDir =
            outputDirectory ?? await _defaultOutputDirectoryForPdf(inputPdf);

        if (!await baseDir.exists()) {
          await baseDir.create(recursive: true);
        }

        // Use custom prefix if provided, otherwise use PDF base name
        final baseName =
            fileNamePrefix ?? p.basenameWithoutExtension(inputPdf.path);
        final List<File> exportedFiles = [];

        _report(
          onProgress,
          0.12,
          'Exporting ${pagesToExport.length} page${pagesToExport.length == 1 ? '' : 's'} to images',
        );

        // Render and save each requested page.
        for (var i = 0; i < pagesToExport.length; i++) {
          final pageIndex = pagesToExport[i];
          final progress01 = 0.15 + (0.75 * ((i + 1) / pagesToExport.length));
          _report(onProgress, progress01, 'Rendering page $pageIndex');
          final page = await doc.getPage(pageIndex);

          try {
            const targetWidth = 1240;
            final targetHeight = (targetWidth * page.height / page.width)
                .round();

            final pageImage = await page.render(
              width: targetWidth.toDouble(),
              height: targetHeight.toDouble(),
              format: pdfx.PdfPageImageFormat.jpeg,
              backgroundColor: '#FFFFFF',
              quality: 90,
            ); // PdfPageImage?[web:1][web:49]

            if (pageImage == null) {
              debugPrint(
                '⚠️ [SelectedPagesToImages] Render returned null for page $pageIndex',
              );
              continue;
            }

            final bytes = pageImage.bytes; // Uint8List JPEG bytes. [web:1]

            final fileName =
                '${baseName}_page_${pageIndex.toString().padLeft(3, '0')}.jpg';
            final filePath = p.join(baseDir.path, fileName);
            final file = File(filePath);
            _report(onProgress, progress01, 'Saving $fileName');
            await file.writeAsBytes(bytes, flush: true);

            exportedFiles.add(file);
          } finally {
            await page.close();
          }
        }

        if (exportedFiles.isEmpty) {
          return left(
            const PdfRasterizationFailure(
              'No pages were successfully exported to images',
            ),
          );
        }

        _report(onProgress, 0.95, 'Finalizing');

        debugPrint(
          '✅ [SelectedPagesToImages] Exported ${exportedFiles.length} pages to ${baseDir.path}',
        );
        _report(onProgress, 1.0, 'Done');
        return right(exportedFiles);
      } finally {
        await doc.close();
      }
    } catch (e, st) {
      return left(
        PdfRasterizationFailure(
          'Failed to export selected PDF pages to images',
          error: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Default folder: public Downloads directory.
  static Future<Directory> _defaultOutputDirectoryForPdf(File inputPdf) async {
    try {
      // Use public Downloads folder so files are visible in file browser
      final downloadsPath =
          await ExternalPath.getExternalStoragePublicDirectory(
            ExternalPath.DIRECTORY_DOWNLOAD,
          );
      return Directory(downloadsPath);
    } catch (e) {
      debugPrint('⚠️ Failed to get Downloads folder, using app documents: $e');
      // Fallback to app documents if Downloads not accessible
      final docsDir = await getApplicationDocumentsDirectory();
      return docsDir;
    }
  }
}
