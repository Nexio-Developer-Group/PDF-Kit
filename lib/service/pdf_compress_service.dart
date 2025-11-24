// lib/service/pdf_compress_service.dart
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/service/pdf_merge_service.dart' show CustomException;

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

      File outputFile;

      if (isPdf) {
        // Compress PDF using Syncfusion
        outputFile = await _compressPdf(
          file: File(fileInfo.path),
          level: level,
          targetDir: targetDir,
          baseName: '${originalBase}_$suffix',
        );
      } else {
        // Compress image using flutter_image_compress
        outputFile = await _compressImage(
          file: File(fileInfo.path),
          level: level,
          targetDir: targetDir,
          baseName: '${originalBase}_$suffix',
          extension: fileInfo.extension.toLowerCase(),
        );
      }

      // Gather stats
      final stats = await outputFile.stat();
      final resultInfo = FileInfo(
        name: p.basename(outputFile.path),
        path: outputFile.path,
        extension: isPdf ? 'pdf' : fileInfo.extension.toLowerCase(),
        size: stats.size,
        lastModified: stats.modified,
        mimeType: isPdf ? 'application/pdf' : fileInfo.mimeType,
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

  /// Compress PDF using Syncfusion Flutter PDF
  static Future<File> _compressPdf({
    required File file,
    required int level,
    required Directory targetDir,
    required String baseName,
  }) async {
    // Load the existing PDF document
    final sf.PdfDocument document = sf.PdfDocument(
      inputBytes: await file.readAsBytes(),
    );

    // Disable incremental update so the file is fully rewritten (smaller output)
    document.fileStructure.incrementalUpdate = false;

    // Map your level (0/1/2) to Syncfusion compression levels
    if (level == 0) {
      // High compression (slower, smaller)
      document.compressionLevel = sf.PdfCompressionLevel.best;
    } else if (level == 1) {
      // Medium
      document.compressionLevel = sf.PdfCompressionLevel.normal;
    } else {
      // Low compression (faster, bigger)
      document.compressionLevel = sf.PdfCompressionLevel.bestSpeed;
    }

    // Save compressed bytes
    final List<int> bytes = await document.save();
    document.dispose();

    // Generate unique filename and save
    final newName = _uniqueFileName(
      baseDir: targetDir.path,
      baseName: baseName,
    );
    final targetPath = p.join(targetDir.path, newName);
    final outputFile = File(targetPath);
    await outputFile.writeAsBytes(bytes);

    return outputFile;
  }

  /// Compress image using flutter_image_compress
  static Future<File> _compressImage({
    required File file,
    required int level,
    required Directory targetDir,
    required String baseName,
    required String extension,
  }) async {
    // Determine quality (0..100) -> higher number = less compression
    int quality;
    if (level == 0) {
      quality = 10; // High compression
    } else if (level == 1) {
      quality = 60; // Medium
    } else {
      quality = 80; // Low compression (retain more quality)
    }

    // Generate unique filename
    final String ext = extension.toLowerCase();
    var candidate = '$baseName.$ext';
    var idx = 1;
    while (File(p.join(targetDir.path, candidate)).existsSync()) {
      candidate = '${baseName}_$idx.$ext';
      idx++;
    }
    final targetPath = p.join(targetDir.path, candidate);

    // Compress the image
    final XFile? result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: quality,
      format: _getCompressFormat(ext),
    );

    if (result == null) {
      throw Exception('Image compression failed');
    }

    return File(result.path);
  }

  /// Get compression format based on file extension
  static CompressFormat _getCompressFormat(String ext) {
    switch (ext) {
      case 'png':
        return CompressFormat.png;
      case 'webp':
        return CompressFormat.webp;
      case 'heic':
        return CompressFormat.heic;
      case 'jpg':
      case 'jpeg':
      default:
        return CompressFormat.jpeg;
    }
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
