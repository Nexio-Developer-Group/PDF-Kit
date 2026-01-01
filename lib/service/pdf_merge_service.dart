// lib/service/pdf_merge_service.dart
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// Keep pdf_combiner only for PDF <-> PDF merging
import 'package:pdf_combiner/pdf_combiner.dart';

import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/core/constants.dart';
import 'package:pdf_kit/core/utility/storage_utility.dart';
import 'package:pdf_kit/core/enums/pdf_content_fit_mode.dart';

// dart_pdf
import 'package:pdf/pdf.dart' as pw_pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;

typedef MergeProgressCallback = void Function(double progress01, String stage);

/// Parameters for image-to-PDF conversion in isolate
class _ImageToPdfParams {
  final List<String> imagePaths;
  final String fitModeString;
  final String outputPath;

  const _ImageToPdfParams({
    required this.imagePaths,
    required this.fitModeString,
    required this.outputPath,
  });
}

/// Top-level function for converting images to PDF in a separate isolate
/// Returns the output path on success, null on failure
Future<String?> _imagesToPdfIsolate(_ImageToPdfParams params) async {
  try {
    debugPrint(
      '🖼️ [Isolate] Converting ${params.imagePaths.length} images to PDF',
    );

    final fitMode = PdfContentFitMode.fromString(params.fitModeString);
    debugPrint('   Fit mode: ${fitMode.value}');

    final doc = pw.Document();
    const a4PageFormat = pw_pdf.PdfPageFormat.a4;

    int index = 0;
    for (final imagePath in params.imagePaths) {
      index++;
      final imageFile = File(imagePath);
      if (!await imageFile.exists()) {
        debugPrint('   ⚠️ Image file does not exist: $imagePath');
        continue;
      }

      debugPrint('   ➡️ Processing image #$index (${p.basename(imagePath)})');

      // Read and decode image
      final Uint8List bytes = await imageFile.readAsBytes();
      debugPrint(
        '      File size: ${(bytes.length / 1024 / 1024).toStringAsFixed(2)} MB',
      );

      // Decode image to get dimensions
      final decodedImage = img.decodeImage(bytes);
      if (decodedImage == null) {
        debugPrint('      ❌ Failed to decode image, skipping');
        continue;
      }

      final imgWidth = decodedImage.width.toDouble();
      final imgHeight = decodedImage.height.toDouble();
      debugPrint(
        '      Dimensions: ${imgWidth.toInt()}×${imgHeight.toInt()} pixels',
      );

      final image = pw.MemoryImage(bytes);

      // Determine page format based on fit mode
      late pw_pdf.PdfPageFormat pageFormat;

      switch (fitMode) {
        case PdfContentFitMode.original:
          // Page size matches image dimensions (72 dpi)
          // Convert pixels to PDF points (1 point = 1/72 inch, so 1 pixel ≈ 1 point at 72 dpi)
          pageFormat = pw_pdf.PdfPageFormat(
            imgWidth,
            imgHeight,
          ); // 1:1 pixel-to-point
          debugPrint('      Page format: Original ($imgWidth×$imgHeight pt)');
          break;

        case PdfContentFitMode.fit:
          // Always A4, image will be fitted inside with padding
          pageFormat = a4PageFormat;
          debugPrint('      Page format: A4 (with fit padding)');
          break;

        case PdfContentFitMode.crop:
          // Always A4, image will cover it (cropped if needed)
          pageFormat = a4PageFormat;
          debugPrint('      Page format: A4 (with crop)');
          break;
      }

      // Add page with appropriate fit mode
      doc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (context) {
            switch (fitMode) {
              case PdfContentFitMode.original:
                return _buildOriginalMode(image, pageFormat);
              case PdfContentFitMode.fit:
                return _buildFitMode(image, pageFormat);
              case PdfContentFitMode.crop:
                return _buildCropMode(image, pageFormat);
            }
          },
        ),
      );

      debugPrint('      ✓ Page added');
    }

    // Serialize document
    debugPrint('   📦 Serializing PDF document...');
    final pdfBytes = await doc.save();
    debugPrint(
      '      PDF size: ${(pdfBytes.length / 1024 / 1024).toStringAsFixed(2)} MB',
    );

    // Write to disk
    final outFile = File(params.outputPath);
    await outFile.writeAsBytes(pdfBytes, flush: true);

    debugPrint('   ✅ PDF created at: ${params.outputPath}');
    return params.outputPath;
  } catch (e, stackTrace) {
    debugPrint('   ❌ Exception in isolate: $e');
    debugPrint('   Stack trace: $stackTrace');
    return null;
  }
}

/// Helper functions for building PDF pages with different fit modes

/// Original mode: image at native size, no padding or cropping
pw.Widget _buildOriginalMode(
  pw.ImageProvider image,
  pw_pdf.PdfPageFormat pageFormat,
) {
  return pw.Image(image, fit: pw.BoxFit.none);
}

/// Fit mode: image scaled to fit within A4 page with padding (letterbox)
pw.Widget _buildFitMode(
  pw.ImageProvider image,
  pw_pdf.PdfPageFormat pageFormat,
) {
  return pw.Container(
    width: pageFormat.width,
    height: pageFormat.height,
    child: pw.FittedBox(fit: pw.BoxFit.contain, child: pw.Image(image)),
  );
}

/// Crop mode: image scaled to fill entire A4 page, cropped if needed
pw.Widget _buildCropMode(
  pw.ImageProvider image,
  pw_pdf.PdfPageFormat pageFormat,
) {
  return pw.Container(
    width: pageFormat.width,
    height: pageFormat.height,
    child: pw.FittedBox(fit: pw.BoxFit.cover, child: pw.Image(image)),
  );
}

/// Custom exception for PDF merge operations
class CustomException {
  final String message;
  final String code;

  const CustomException({required this.message, required this.code});

  @override
  String toString() => 'CustomException($code): $message';
}

/// Service for merging multiple PDF files using pdf_combiner + dart_pdf
class PdfMergeService {
  PdfMergeService._();

  /// Check if the file is a supported image type
  static bool _isImageFile(FileInfo fileInfo) {
    const supportedImageExtensions = [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'bmp',
      'webp',
    ];
    final ext = fileInfo.extension.toLowerCase();
    return supportedImageExtensions.contains(ext);
  }

  static Future<Either<CustomException, FileInfo>> mergePdfs({
    required List<FileInfo> files,
    required String outputFileName,
    String? destinationPath,
    MergeProgressCallback? onProgress,
  }) async {
    try {
      void report(double progress01, String stage) {
        try {
          final clamped = progress01.clamp(0.0, 1.0);
          onProgress?.call(clamped, stage);
        } catch (_) {}
      }

      report(0.03, 'Validating files');
      if (files.isEmpty) {
        return const Left(
          CustomException(
            message: 'No files provided for merging',
            code: 'NO_FILES',
          ),
        );
      }

      if (files.length < 2) {
        return const Left(
          CustomException(
            message: 'At least 2 files are required for merging',
            code: 'INSUFFICIENT_FILES',
          ),
        );
      }

      final totalFiles = files.length;
      for (var i = 0; i < files.length; i++) {
        final fileInfo = files[i];
        report(
          0.03 + (0.07 * ((i + 1) / totalFiles)),
          'Validating ${i + 1}/$totalFiles: ${fileInfo.name}',
        );
        final file = File(fileInfo.path);
        if (!await file.exists()) {
          return Left(
            CustomException(
              message: 'File not found: ${fileInfo.name}',
              code: 'FILE_NOT_FOUND',
            ),
          );
        }

        final isPdf = fileInfo.extension.toLowerCase() == 'pdf';
        final isImage = _isImageFile(fileInfo);

        if (!isPdf && !isImage) {
          return Left(
            CustomException(
              message:
                  'Only PDF files and images can be merged: ${fileInfo.name}',
              code: 'INVALID_FILE_TYPE',
            ),
          );
        }
      }

      report(0.12, 'Preparing output');

      final Directory targetDir = await _resolveDestination(destinationPath);

      String finalFileName = outputFileName.trim();
      if (!finalFileName.toLowerCase().endsWith('.pdf')) {
        finalFileName = '$finalFileName.pdf';
      }

      final outputPath = p.join(targetDir.path, finalFileName);

      debugPrint('📊 [MergeService] Merging ${files.length} files');

      final fitModeString =
          Prefs.getString(Constants.pdfContentFitModeKey) ??
          Constants.defaultPdfContentFitMode;
      final fitMode = PdfContentFitMode.fromString(fitModeString);
      debugPrint(
        '🎨 [MergeService] Using fit mode from prefs: "$fitModeString" -> ${fitMode.value}',
      );

      final pdfFiles = <FileInfo>[];
      final imageFiles = <FileInfo>[];

      for (final fileInfo in files) {
        if (fileInfo.extension.toLowerCase() == 'pdf') {
          pdfFiles.add(fileInfo);
        } else if (_isImageFile(fileInfo)) {
          imageFiles.add(fileInfo);
        }
      }

      debugPrint('   PDFs: ${pdfFiles.length}, Images: ${imageFiles.length}');
      report(
        0.16,
        'Preparing inputs (${pdfFiles.length} PDF${pdfFiles.length == 1 ? '' : 's'}, ${imageFiles.length} image${imageFiles.length == 1 ? '' : 's'})',
      );

      List<String> inputPaths;

      if (imageFiles.isNotEmpty && pdfFiles.isNotEmpty) {
        // Mixed: images -> temp PDF (dart_pdf in isolate), then merge
        debugPrint('   Processing mixed content (PDFs + images)');
        debugPrint('   🚀 Launching isolate for image conversion...');

        report(
          0.30,
          'Converting ${imageFiles.length} image${imageFiles.length == 1 ? '' : 's'} to PDF',
        );

        final tempOutputPath = p.join(
          targetDir.path,
          'temp_images_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );

        final tempImagePdf = await compute(
          _imagesToPdfIsolate,
          _ImageToPdfParams(
            imagePaths: imageFiles.map((f) => f.path).toList(),
            fitModeString: fitMode.value,
            outputPath: tempOutputPath,
          ),
        );

        if (tempImagePdf == null) {
          return const Left(
            CustomException(
              message: 'Failed to convert images to PDF',
              code: 'IMAGE_CONVERSION_ERROR',
            ),
          );
        }

        debugPrint('   ✅ Isolate completed, temp PDF created');
        report(0.55, 'Image conversion complete');
        report(0.58, 'Preparing merge');
        inputPaths = [...pdfFiles.map((f) => f.path), tempImagePdf];
      } else if (imageFiles.isNotEmpty) {
        // Images only -> final PDF using dart_pdf in isolate
        debugPrint('   Processing images only (dart_pdf in isolate)');
        debugPrint('   🚀 Launching isolate for image conversion...');

        report(
          0.35,
          'Converting ${imageFiles.length} image${imageFiles.length == 1 ? '' : 's'} to PDF',
        );

        final imagesOnlyPdfPath = await compute(
          _imagesToPdfIsolate,
          _ImageToPdfParams(
            imagePaths: imageFiles.map((f) => f.path).toList(),
            fitModeString: fitMode.value,
            outputPath: outputPath,
          ),
        );

        if (imagesOnlyPdfPath == null) {
          return const Left(
            CustomException(
              message: 'Failed to convert images to PDF',
              code: 'IMAGE_CONVERSION_ERROR',
            ),
          );
        }

        debugPrint('   ✅ Isolate completed');
        report(0.92, 'Finalizing output');
        final fileInfoResult = await _createFileInfoFromPath(imagesOnlyPdfPath);
        report(1.0, 'Done');
        return fileInfoResult;
      } else {
        // PDFs only: do not touch PDF pages at all
        debugPrint('   Processing PDFs only (no image conversion)');
        report(
          0.30,
          'Preparing ${pdfFiles.length} PDF${pdfFiles.length == 1 ? '' : 's'} for merge',
        );
        inputPaths = pdfFiles.map((f) => f.path).toList();
      }

      report(
        0.65,
        'Merging ${inputPaths.length} document${inputPaths.length == 1 ? '' : 's'}',
      );

      debugPrint(
        '🔧 [MergeService] Calling PdfCombiner.generatePDFFromDocuments',
      );
      debugPrint('   Input paths count: ${inputPaths.length}');
      debugPrint('   Output path: $outputPath');

      final docResponse = await PdfCombiner.generatePDFFromDocuments(
        inputPaths: inputPaths,
        outputPath: outputPath,
      );

      debugPrint('📦 [MergeService] Response received');
      debugPrint('   Status: ${docResponse.status}');
      debugPrint('   Message: ${docResponse.message}');
      debugPrint('   Output path: ${docResponse.outputPath}');

      if (docResponse.status.toString().toLowerCase().contains('success')) {
        debugPrint('✅ [MergeService] Merge successful, creating FileInfo');
        report(0.92, 'Finalizing output');
        final fileInfoResult = await _createFileInfoFromPath(
          docResponse.outputPath,
        );
        report(1.0, 'Done');
        return fileInfoResult;
      } else {
        final errorMessage = docResponse.message;
        debugPrint('❌ [MergeService] Merge failed: $errorMessage');
        return Left(
          CustomException(message: errorMessage, code: 'MERGE_ERROR'),
        );
      }
    } catch (e) {
      return Left(
        CustomException(
          message: 'Failed to merge files: ${e.toString()}',
          code: 'MERGE_ERROR',
        ),
      );
    }
  }

  static Future<Directory> _resolveDestination(String? destinationPath) async {
    if (destinationPath != null && destinationPath.isNotEmpty) {
      final dir = Directory(destinationPath);
      if (await dir.exists()) {
        return dir;
      }
      await dir.create(recursive: true);
      return dir;
    }

    final appDocDir = await getApplicationDocumentsDirectory();
    final mergedDir = Directory(p.join(appDocDir.path, 'MergedPDFs'));
    if (!await mergedDir.exists()) {
      await mergedDir.create(recursive: true);
    }
    return mergedDir;
  }

  static Future<Either<CustomException, FileInfo>> _createFileInfoFromPath(
    String path,
  ) async {
    try {
      debugPrint('📝 [MergeService] Creating FileInfo from path: $path');
      final file = File(path);

      if (!await file.exists()) {
        return const Left(
          CustomException(
            message: 'Output file not found',
            code: 'OUTPUT_NOT_FOUND',
          ),
        );
      }

      final stats = await file.stat();
      final fileInfo = FileInfo(
        name: p.basename(path),
        path: path,
        extension: p.extension(path).replaceFirst('.', ''),
        size: stats.size,
        lastModified: stats.modified,
        mimeType: 'application/pdf',
        parentDirectory: p.dirname(path),
        isDirectory: false,
      );

      return Right(fileInfo);
    } catch (e) {
      return Left(
        CustomException(
          message: 'Failed to create file info: ${e.toString()}',
          code: 'FILE_INFO_ERROR',
        ),
      );
    }
  }
}
