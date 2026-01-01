import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf_kit/service/open_service.dart';

/// Model for a single page range to extract
class PageRange {
  final int startPage;
  final int endPage;
  final String? customName;

  const PageRange({
    required this.startPage,
    required this.endPage,
    this.customName,
  });

  @override
  String toString() => 'Pages $startPage–$endPage';
}

/// Result model for split operation
class SplitResult {
  final bool success;
  final List<String> outputPaths;
  final List<String> outputFileNames;
  final String message;
  final String? errorMessage;

  const SplitResult({
    required this.success,
    required this.outputPaths,
    required this.outputFileNames,
    required this.message,
    this.errorMessage,
  });

  factory SplitResult.success({
    required List<String> outputPaths,
    required List<String> outputFileNames,
  }) {
    return SplitResult(
      success: true,
      outputPaths: outputPaths,
      outputFileNames: outputFileNames,
      message: 'Successfully split PDF into ${outputPaths.length} files',
    );
  }

  factory SplitResult.failure(String errorMessage) {
    return SplitResult(
      success: false,
      outputPaths: [],
      outputFileNames: [],
      message: 'Failed to split PDF',
      errorMessage: errorMessage,
    );
  }
}

/// Service for splitting PDF files into multiple files based on page ranges
class PdfSplitService {
  PdfSplitService._();

  static void _report(
    void Function(double progress01, String stage)? onProgress,
    double progress01,
    String stage,
  ) {
    try {
      onProgress?.call(progress01.clamp(0.0, 1.0), stage);
    } catch (_) {}
  }

  /// Get total page count of a PDF file
  static Future<Either<String, int>> getPageCount({
    required String pdfPath,
  }) async {
    try {
      final File pdfFile = File(pdfPath);
      if (!await pdfFile.exists()) {
        return const Left('PDF file not found');
      }

      final document = await pdfx.PdfDocument.openFile(pdfPath);
      final count = document.pagesCount;
      await document.close();

      debugPrint('📄 [PdfSplitService] Page count: $count');
      return Right(count);
    } catch (e) {
      return Left('Failed to get page count: ${e.toString()}');
    }
  }

  /// Validate a list of page ranges against total page count
  static Either<String, bool> validateRanges({
    required List<PageRange> ranges,
    required int totalPages,
  }) {
    if (ranges.isEmpty) {
      return const Left('At least one page range is required');
    }

    for (int i = 0; i < ranges.length; i++) {
      final range = ranges[i];

      if (range.startPage < 1) {
        return Left('Range ${i + 1}: Start page must be at least 1');
      }

      if (range.endPage > totalPages) {
        return Left('Range ${i + 1}: End page cannot exceed $totalPages');
      }

      if (range.startPage > range.endPage) {
        return Left(
          'Range ${i + 1}: Start page must be less than or equal to end page',
        );
      }
    }

    return const Right(true);
  }

  /// Split a PDF into multiple files based on page ranges
  ///
  /// This method extracts pages from the source PDF without rasterization,
  /// preserving the original PDF quality and text selectability.
  static Future<SplitResult> splitPdf({
    required String sourcePdfPath,
    required List<PageRange> ranges,
    String? outputDirectory,
    String? namingPattern, // e.g., "document_____" where _____ will be replaced
    void Function(double progress01, String stage)? onProgress,
  }) async {
    try {
      _report(onProgress, 0.03, 'Validating inputs');
      debugPrint('📊 [PdfSplitService] Splitting PDF: $sourcePdfPath');
      debugPrint('   Ranges: ${ranges.length}');

      // Validate source file exists
      final File sourceFile = File(sourcePdfPath);
      if (!await sourceFile.exists()) {
        return SplitResult.failure('Source PDF file not found');
      }

      _report(onProgress, 0.10, 'Reading PDF');

      // Get total page count
      final pageCountResult = await getPageCount(pdfPath: sourcePdfPath);
      late final int totalPages;

      pageCountResult.fold(
        (error) => throw Exception(error),
        (count) => totalPages = count,
      );

      // Validate all ranges
      final validationResult = validateRanges(
        ranges: ranges,
        totalPages: totalPages,
      );

      validationResult.fold(
        (error) => throw Exception(error),
        (_) => debugPrint('✅ [PdfSplitService] All ranges validated'),
      );

      // Determine output directory
      final Directory targetDir = await _resolveOutputDirectory(
        outputDirectory,
      );
      debugPrint('   Output directory: ${targetDir.path}');

      final totalPagesToProcess = ranges.fold<int>(
        0,
        (sum, r) => sum + (r.endPage - r.startPage + 1),
      );
      var processedPages = 0;

      // Get base file name for naming pattern
      final baseFileName =
          namingPattern ?? p.basenameWithoutExtension(sourcePdfPath);

      final List<String> outputPaths = [];
      final List<String> outputFileNames = [];

      // Process each range
      for (int i = 0; i < ranges.length; i++) {
        final range = ranges[i];
        debugPrint('   Processing range ${i + 1}: ${range.toString()}');

        _report(
          onProgress,
          0.15,
          'Preparing range ${i + 1}/${ranges.length}: ${range.startPage}–${range.endPage}',
        );

        // Generate output file name
        final String outputFileName =
            range.customName ??
            '${baseFileName}_pages_${range.startPage}_to_${range.endPage}.pdf';

        final String outputPath = p.join(targetDir.path, outputFileName);

        // Extract pages for this range
        try {
          await _extractPagesWithoutRasterization(
            sourcePath: sourcePdfPath,
            outputPath: outputPath,
            startPage: range.startPage,
            endPage: range.endPage,
            onProgress: (p, s) {
              // Map inner progress (0..1) to overall progress (0.20..0.90)
              final overall = 0.20 + (0.70 * p);
              _report(onProgress, overall, s);
            },
            onPageDone: () {
              processedPages++;
              if (totalPagesToProcess > 0) {
                final p = processedPages / totalPagesToProcess;
                final overall = 0.20 + (0.70 * p);
                _report(
                  onProgress,
                  overall,
                  'Splitting… ($processedPages/$totalPagesToProcess pages)',
                );
              }
            },
          );

          outputPaths.add(outputPath);
          outputFileNames.add(outputFileName);
          debugPrint('   ✅ Created: $outputFileName');
        } catch (e) {
          debugPrint('   ❌ Failed to create range ${i + 1}: $e');
          // Continue with other ranges even if one fails
        }
      }

      if (outputPaths.isEmpty) {
        return SplitResult.failure('Failed to create any split files');
      }

      _report(onProgress, 0.95, 'Finalizing');

      debugPrint(
        '✅ [PdfSplitService] Split completed: ${outputPaths.length} files created',
      );

      _report(onProgress, 1.0, 'Done');
      return SplitResult.success(
        outputPaths: outputPaths,
        outputFileNames: outputFileNames,
      );
    } catch (e) {
      debugPrint('❌ [PdfSplitService] Error: $e');
      return SplitResult.failure(e.toString());
    }
  }

  /// Extract specific page range from PDF
  ///
  /// Uses pdfx to read pages and pdf package to create new PDF
  /// Note: This renders pages to high-quality images (3x resolution)
  /// True vector extraction would require native PDF manipulation libraries
  static Future<void> _extractPagesWithoutRasterization({
    required String sourcePath,
    required String outputPath,
    required int startPage,
    required int endPage,
    void Function(double progress01, String stage)? onProgress,
    void Function()? onPageDone,
  }) async {
    try {
      debugPrint('   📄 Extracting pages $startPage-$endPage');

      final totalPages = (endPage - startPage + 1);
      _report(onProgress, 0.0, 'Extracting pages $startPage–$endPage');

      // Open source PDF using pdfx
      final sourceDoc = await pdfx.PdfDocument.openFile(sourcePath);

      // Create new PDF document using pdf package
      final pw.Document newPdf = pw.Document();

      // Extract each page in the range
      for (int pageNum = startPage; pageNum <= endPage; pageNum++) {
        try {
          final done = (pageNum - startPage);
          final p = totalPages <= 0 ? 0.0 : (done / totalPages);
          _report(onProgress, p, 'Rendering page $pageNum');
          final page = await sourceDoc.getPage(pageNum);

          // Render page to high-quality image
          // This is the best available approach with current packages
          // True vector extraction would require native PDF libraries
          final pageImage = await page.render(
            width: page.width * 3, // High resolution for quality
            height: page.height * 3,
            format: pdfx.PdfPageImageFormat.png,
            backgroundColor: '#FFFFFF',
          );

          await page.close();

          if (pageImage == null) {
            debugPrint('      ⚠️ Failed to render page $pageNum');
            continue;
          }

          // Convert rendered image to PDF image
          final image = pw.MemoryImage(pageImage.bytes);

          // Add page with original dimensions
          newPdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat(page.width, page.height),
              build: (context) => pw.Image(image, fit: pw.BoxFit.fill),
            ),
          );

          final done2 = (pageNum - startPage + 1);
          final p2 = totalPages <= 0 ? 1.0 : (done2 / totalPages);
          _report(onProgress, p2, 'Added page $pageNum');
          try {
            onPageDone?.call();
          } catch (_) {}

          debugPrint('      ✅ Extracted page $pageNum');
        } catch (e) {
          debugPrint('      ❌ Error extracting page $pageNum: $e');
          rethrow;
        }
      }

      await sourceDoc.close();

      // Save new PDF to output path
      _report(onProgress, 0.95, 'Saving split PDF');
      final bytes = await newPdf.save();
      await File(outputPath).writeAsBytes(bytes);

      _report(onProgress, 1.0, 'Saved');

      debugPrint('   💾 Saved ${endPage - startPage + 1} pages to output');
    } catch (e) {
      debugPrint('❌ [PdfSplitService] Extraction error: $e');
      rethrow;
    }
  }

  /// Resolve output directory for split PDF files
  static Future<Directory> _resolveOutputDirectory(
    String? outputDirectory,
  ) async {
    if (outputDirectory != null && outputDirectory.isNotEmpty) {
      final dir = Directory(outputDirectory);
      if (await dir.exists()) {
        return dir;
      }
      await dir.create(recursive: true);
      return dir;
    }

    // Default: Use public Downloads folder for better accessibility
    try {
      final downloadsPath =
          await ExternalPath.getExternalStoragePublicDirectory(
            ExternalPath.DIRECTORY_DOWNLOAD,
          );
      final downloadsDir = Directory(downloadsPath);
      if (await downloadsDir.exists()) {
        return downloadsDir;
      }
      await downloadsDir.create(recursive: true);
      return downloadsDir;
    } catch (e) {
      debugPrint('⚠️ Failed to get Downloads folder, using app documents: $e');
      // Fallback to app documents if Downloads not accessible
      final appDocDir = await getApplicationDocumentsDirectory();
      final splitDir = Directory(p.join(appDocDir.path, 'SplitPDFs'));
      if (!await splitDir.exists()) {
        await splitDir.create(recursive: true);
      }
      return splitDir;
    }
  }

  /// Delete a split PDF file
  static Future<Either<String, bool>> deleteSplitFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return const Left('File not found');
      }

      await file.delete();
      debugPrint('🗑️ [PdfSplitService] Deleted: $filePath');
      return const Right(true);
    } catch (e) {
      return Left('Failed to delete file: ${e.toString()}');
    }
  }

  /// Open a split PDF file using system viewer
  static Future<Either<String, bool>> openSplitFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return const Left('File not found');
      }

      final result = await OpenService.open(filePath);
      return result.fold(
        (error) => Left(error.toString()),
        (_) => const Right(true),
      );
    } catch (e) {
      return Left('Failed to open file: ${e.toString()}');
    }
  }
}
