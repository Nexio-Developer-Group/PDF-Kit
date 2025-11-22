// lib/service/pdf_compress_service.dart
import 'dart:io';
import 'dart:ui' as ui;
import 'package:dartz/dartz.dart';
import 'package:path/path.dart' as p;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:simple_pdf_compression/simple_pdf_compression.dart'
    as pdf_compress;
import 'package:path_provider/path_provider.dart';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/service/pdf_merge_service.dart'
    show CustomException; // reuse exception

/// Service for compressing a single selected file (PDF or image).
/// If an image is provided it is first converted into a one-page PDF, then compressed.
class PdfCompressService {
  PdfCompressService._();

  /// Compress the provided [fileInfo].
  /// [level] maps: 0=High Compression (low quality), 1=Medium, 2=Low Compression (higher quality).
  /// Returns a [FileInfo] of the compressed PDF on success.
  static Future<Either<CustomException, FileInfo>> compressFile({
    required FileInfo fileInfo,
    required int level,
    String? destinationPath, // optional destination folder for final file
  }) async {
    try {
      // Validate input
      final isPdf = fileInfo.extension.toLowerCase() == 'pdf';
      final isImg = _isImage(fileInfo);
      if (!(isPdf || isImg)) {
        return Left(
          CustomException(
            message: 'Unsupported file type. Select a PDF or image.',
            code: 'UNSUPPORTED_TYPE',
          ),
        );
      }

      // Determine quality (0..100) -> higher number = less compression
      int quality;
      if (level == 0) {
        quality = 40; // High compression
      } else if (level == 1) {
        quality = 60; // Medium
      } else {
        quality = 80; // Low compression (retain more quality)
      }

      // Convert image to a temporary PDF if needed
      File sourcePdfFile;
      if (isPdf) {
        sourcePdfFile = File(fileInfo.path);
      } else {
        sourcePdfFile = await _imageToSinglePagePdf(File(fileInfo.path));
      }

      // Perform compression (library returns a File saved to temp directory)
      final compressor = pdf_compress.PDFCompression();
      final compressedPdf = await compressor.compressPdf(
        sourcePdfFile,
        thresholdSize: 200 * 1024, // avoid compressing tiny PDFs aggressively
        quality: quality, // mapped from level
      );

      // Decide destination
      final Directory targetDir = await _resolveDestination(
        destinationPath: destinationPath,
        fallbackOriginalParent: fileInfo.parentDirectory,
      );

      // Build new filename
      final originalBase = p.basenameWithoutExtension(fileInfo.name);
      String suffix;
      if (level == 0) {
        suffix = 'compressed_high';
      } else if (level == 1) {
        suffix = 'compressed_medium';
      } else {
        suffix = 'compressed_low';
      }
      final newName = _uniqueFileName(
        baseDir: targetDir.path,
        baseName: '${originalBase}_$suffix',
      );

      final targetPath = p.join(targetDir.path, newName);

      // Move (copy + delete) compressed file to destination
      final outputFile = await File(compressedPdf.path).copy(targetPath);

      // Gather stats
      final stats = await outputFile.stat();
      final resultInfo = FileInfo(
        name: p.basename(outputFile.path),
        path: outputFile.path,
        extension: 'pdf',
        size: stats.size,
        lastModified: stats.modified,
        mimeType: 'application/pdf',
        parentDirectory: p.dirname(outputFile.path),
      );

      return Right(resultInfo);
    } catch (e) {
      return Left(
        CustomException(
          message: 'Compression failed: ${e.toString()}',
          code: 'COMPRESSION_ERROR',
        ),
      );
    }
  }

  /// Convert a single image file into a one-page PDF and return the temp PDF [File].
  static Future<File> _imageToSinglePagePdf(File imageFile) async {
    final bytes = await imageFile.readAsBytes();

    // Obtain dimensions using dart:ui descriptor
    final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(
      bytes,
    );
    final ui.ImageDescriptor descriptor = await ui.ImageDescriptor.encoded(
      buffer,
    );
    final width = descriptor.width.toDouble();
    final height = descriptor.height.toDouble();
    descriptor.dispose();
    buffer.dispose();

    final pdfDoc = pw.Document();
    final image = pw.MemoryImage(bytes);

    // Convert pixel dimensions to PDF points (approx 72/96 multiplier)
    final pageWidth = width * 72 / 96;
    final pageHeight = height * 72 / 96;

    pdfDoc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(pageWidth, pageHeight),
        build: (_) => pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain)),
      ),
    );

    final tempDir = await getTemporaryDirectory();
    final outPath = p.join(
      tempDir.path,
      'img_to_pdf_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    final outFile = File(outPath);
    await outFile.writeAsBytes(await pdfDoc.save());
    return outFile;
  }

  static bool _isImage(FileInfo f) {
    const exts = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'};
    return exts.contains(f.extension.toLowerCase());
  }

  static Future<Directory> _resolveDestination({
    String? destinationPath,
    String? fallbackOriginalParent,
  }) async {
    if (destinationPath != null && destinationPath.isNotEmpty) {
      final dir = Directory(destinationPath);
      if (await dir.exists()) return dir;
    }
    if (fallbackOriginalParent != null && fallbackOriginalParent.isNotEmpty) {
      final dir = Directory(fallbackOriginalParent);
      if (await dir.exists()) return dir;
    }
    return getTemporaryDirectory();
  }

  /// Generate a unique filename avoiding clashes.
  static String _uniqueFileName({
    required String baseDir,
    required String baseName,
  }) {
    var candidate = '$baseName.pdf';
    var idx = 1;
    while (File(p.join(baseDir, candidate)).existsSync()) {
      candidate = '${baseName}_$idx.pdf';
      idx++;
    }
    return candidate;
  }
}
