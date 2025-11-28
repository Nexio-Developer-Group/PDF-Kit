import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import 'package:pdf_kit/service/pdf_rasterization_service.dart';

/// High-level watermark service that delegates to [PdfRasterizationService].
class WatermarkService {
  WatermarkService._();

  /// Adds a text or image watermark to the given PDF file by:
  /// - Rasterizing the PDF
  /// - Compressing pages
  /// - Applying watermark (grid or single)
  /// - Rebuilding and saving a new flattened PDF
  static Future<Either<String, String>> addWatermark({
    required String pdfPath,
    String? text,
    String? imagePath,
    bool isGridPattern = false,
  }) async {
    debugPrint('🎨 [WatermarkService] Starting watermark pipeline');
    debugPrint('   📄 PDF: $pdfPath');
    debugPrint('   📝 Text: $text');
    debugPrint('   🖼️ Image: $imagePath');

    try {
      if (text == null && imagePath == null) {
        return const Left('Either text or image must be provided');
      }
      if (text != null && imagePath != null) {
        return const Left(
          'Cannot apply both text and image watermark simultaneously',
        );
      }

      final sourceFile = File(pdfPath);
      if (!await sourceFile.exists()) {
        return const Left('PDF file not found');
      }

      final outputFile =
          await PdfRasterizationService.rasterizeCompressWatermarkPdf(
            inputPdf: sourceFile,
            watermarkText: text,
            watermarkImagePath: imagePath,
            isGridPattern: isGridPattern,
          );

      return Right(outputFile.path);
    } catch (e, stack) {
      debugPrint('❌ [WatermarkService] Error: $e');
      debugPrint('   Stack trace: $stack');
      return Left('Failed to add watermark: ${e.toString()}');
    }
  }
}
