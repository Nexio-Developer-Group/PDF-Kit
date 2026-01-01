import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:flutter/foundation.dart';

/// 📝 Service for manipulating PDF pages: reordering, rotating, removing.
class PdfManipulationService {
  PdfManipulationService._();

  static void _report(
    void Function(double progress01, String stage)? onProgress,
    double progress01,
    String stage,
  ) {
    try {
      onProgress?.call(progress01.clamp(0.0, 1.0), stage);
    } catch (_) {}
  }

  /// Rearranges PDF pages to new order (1-based indices), rotates specified pages, removes unwanted pages
  static Future<Either<String, String>> manipulatePdf({
    required String pdfPath,
    List<int>? reorderPages,
    Map<int, double>? pagesToRotate,
    List<int>? pagesToRemove,
    String?
    destinationPath, // 🆕 Optional: Save specific path instead of overwrite
    void Function(double progress01, String stage)? onProgress,
  }) async {
    try {
      _report(onProgress, 0.03, 'Validating inputs');
      // Validate inputs
      if (reorderPages != null && reorderPages.isEmpty) {
        return const Left('Reorder pages list cannot be empty');
      }

      // Check if file exists
      final File pdfFile = File(pdfPath);
      if (!await pdfFile.exists()) {
        return const Left('PDF file not found');
      }

      _report(onProgress, 0.10, 'Reading PDF');

      // Determine temporary output path
      // final String outputPath = _outputPathFor(pdfPath, '_manipulated');

      // Load PDF document using pdfx to get page count and render pages
      final pdfxDoc = await pdfx.PdfDocument.openFile(pdfPath);
      final totalPages = pdfxDoc.pagesCount;

      debugPrint('📄 [PdfManipulationService] Total pages: $totalPages');

      // Determine which pages to keep (not removed)
      final Set<int> removeSet = pagesToRemove != null
          ? pagesToRemove.map((e) => e).toSet()
          : {};

      // Determine final page order
      List<int> finalOrder;
      if (reorderPages != null && reorderPages.isNotEmpty) {
        // Use custom order, filter out removed pages
        finalOrder = reorderPages.where((p) => !removeSet.contains(p)).toList();
      } else {
        // Use original order 1..totalPages, filter out removed
        finalOrder = List.generate(
          totalPages,
          (i) => i + 1,
        ).where((p) => !removeSet.contains(p)).toList();
      }

      if (finalOrder.isEmpty) {
        await pdfxDoc.close();
        return const Left('All pages were removed, PDF cannot be empty');
      }

      _report(
        onProgress,
        0.15,
        'Processing ${finalOrder.length} page${finalOrder.length == 1 ? '' : 's'}',
      );

      // Create new PDF document
      final pw.Document newPdf = pw.Document();

      // Render and add each page in the desired order
      for (var i = 0; i < finalOrder.length; i++) {
        final pageNum = finalOrder[i];
        if (pageNum < 1 || pageNum > totalPages) {
          continue;
        }

        final p = 0.18 + (0.72 * ((i + 1) / finalOrder.length));
        _report(
          onProgress,
          p,
          'Rendering page $pageNum (${i + 1}/${finalOrder.length})',
        );

        try {
          final pdfxPage = await pdfxDoc.getPage(pageNum);

          // Render page to image at high quality
          final pageImage = await pdfxPage.render(
            width: pdfxPage.width * 2,
            height: pdfxPage.height * 2,
            format: pdfx.PdfPageImageFormat.png,
            backgroundColor: '#FFFFFF',
          );

          await pdfxPage.close();

          if (pageImage == null) continue;

          // Get rotation angle for this page (default 0)
          final rotationAngle = pagesToRotate?[pageNum] ?? 0.0;

          // Convert rendered image to PDF image
          final image = pw.MemoryImage(pageImage.bytes);

          // Determine page size based on rotation
          double pageWidth = pdfxPage.width;
          double pageHeight = pdfxPage.height;

          if (rotationAngle == 90 || rotationAngle == 270) {
            final temp = pageWidth;
            pageWidth = pageHeight;
            pageHeight = temp;
          }

          // Add page with rotation
          newPdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat(pageWidth, pageHeight),
              build: (pw.Context context) {
                return pw.Transform.rotate(
                  angle: rotationAngle * 3.14159 / 180,
                  child: pw.Image(image, fit: pw.BoxFit.contain),
                );
              },
            ),
          );
        } catch (e) {
          await pdfxDoc.close();
          return Left('Error processing page $pageNum: ${e.toString()}');
        }
      }

      await pdfxDoc.close();

      // Save logic:
      // If destinationPath provided -> Save there.
      // Else -> Overwrite original.

      final bytes = await newPdf.save();

      _report(onProgress, 0.92, 'Writing output');

      if (destinationPath != null && destinationPath.isNotEmpty) {
        // Save to specific destination (copy mode)
        final destFile = File(destinationPath);
        // ensure parent exists
        if (!await destFile.parent.exists()) {
          await destFile.parent.create(recursive: true);
        }
        await destFile.writeAsBytes(bytes);
        debugPrint('💾 [PdfManipulationService] Saved to: $destinationPath');
        _report(onProgress, 1.0, 'Done');
        return Right(destinationPath);
      } else {
        // Overwrite original
        // Write to temp first for safety
        final String tempPath = _outputPathFor(pdfPath, '_manipulated');
        await File(tempPath).writeAsBytes(bytes);

        // Replace original
        await pdfFile.writeAsBytes(bytes);

        // Cleanup temp
        try {
          await File(tempPath).delete();
        } catch (_) {}

        debugPrint('✅ [PdfManipulationService] Overwrote original: $pdfPath');
        _report(onProgress, 1.0, 'Done');
        return Right(pdfPath);
      }
    } on FileSystemException catch (e) {
      return Left('File error: ${e.message}');
    } catch (e) {
      return Left('Failed to manipulate PDF: ${e.toString()}');
    }
  }

  /// Gets total page count of PDF
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

      return Right(count);
    } catch (e) {
      return Left('Failed to get page count: ${e.toString()}');
    }
  }

  static String _outputPathFor(String inputPath, String suffix) {
    final lower = inputPath.toLowerCase();
    if (lower.endsWith('.pdf')) {
      return inputPath.substring(0, inputPath.length - 4) + suffix + '.pdf';
    }
    return inputPath + suffix + '.pdf';
  }
}
