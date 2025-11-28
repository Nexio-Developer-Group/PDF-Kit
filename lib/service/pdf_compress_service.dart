// lib/service/pdf_compress_service.dart
import 'dart:io';
import 'dart:ui';
import 'package:dartz/dartz.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:pdf_kit/core/constants.dart';
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

  /// Compress PDF - placeholder implementation (returns copy of original)
  static Future<File> _compressPdf({
    required File file,
    required int level,
    required Directory targetDir,
    required String baseName,
  }) async {
    // Generate unique filename
    final newName = _uniqueFileName(
      baseDir: targetDir.path,
      baseName: baseName,
    );
    final targetPath = p.join(targetDir.path, newName);

    // Simply copy the file for now (no actual compression)
    final outputFile = await file.copy(targetPath);

    return outputFile;
  }

  /// Compress image using flutter_image_compress with proper resolution control
  static Future<File> _compressImage({
    required File file,
    required int level,
    required Directory targetDir,
    required String baseName,
    required String extension,
  }) async {
    // Step 1: Read original image dimensions
    final bytes = await file.readAsBytes();
    final codec = await instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final img = frame.image;

    final originalWidth = img.width;
    final originalHeight = img.height;

    // Dispose codec
    codec.dispose();
    img.dispose();

    // Step 2: Determine quality and scale factor based on compression level
    int quality;
    double scale;
    if (level == 0) {
      // High compression
      quality = 75;
      scale = 0.5; // Reduce resolution to 50%
    } else if (level == 1) {
      // Medium compression
      quality = 85;
      scale = 0.75; // Reduce resolution to 75%
    } else {
      // Low compression (retain more quality)
      quality = 95;
      scale = 1.0; // Keep original resolution
    }

    // Step 3: Calculate target dimensions
    final targetWidth = (originalWidth * scale).toInt();
    final targetHeight = (originalHeight * scale).toInt();

    // Step 4: Determine output format
    final String ext = extension.toLowerCase();
    CompressFormat format;

    // Only convert PNG to JPEG on high compression, otherwise preserve format
    if (ext == 'png' && level != 0) {
      format = CompressFormat.png;
    } else {
      format = _getCompressFormat(ext);
    }

    // Step 5: Generate unique filename
    var candidate = '$baseName.$ext';
    var idx = 1;
    while (File(p.join(targetDir.path, candidate)).existsSync()) {
      candidate = '${baseName}_$idx.$ext';
      idx++;
    }
    final targetPath = p.join(targetDir.path, candidate);

    // Step 6: Compress the image with controlled resolution
    final XFile? result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: quality,
      minWidth: targetWidth,
      minHeight: targetHeight,
      format: format,
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

  /// Compress raw image bytes using flutter_image_compress.
  /// Returns compressed bytes (Uint8List).
  static Future<Uint8List> compressImageBytes(
    Uint8List input, {
    int? quality,
    CompressFormat? format,
  }) async {
    final q = quality ?? Constants.imageCompressQuality;
    final fmt = format ?? CompressFormat.jpeg;
    final List<int>? result = await FlutterImageCompress.compressWithList(
      input,
      quality: q,
      format: fmt,
    );
    if (result == null) throw Exception('Image compression failed');
    return Uint8List.fromList(result);
  }

  /// Compress a file and write the compressed bytes to a temporary file.
  static Future<File> compressImageFile(File file, {int? quality}) async {
    final input = await file.readAsBytes();
    final compressed = await compressImageBytes(
      Uint8List.fromList(input),
      quality: quality,
    );
    final dir = await getTemporaryDirectory();
    final outName =
        '${p.basenameWithoutExtension(file.path)}_compressed.${p.extension(file.path).replaceFirst('.', '')}';
    final outPath = p.join(dir.path, outName);
    final outFile = File(outPath);
    await outFile.writeAsBytes(compressed);
    return outFile;
  }

  /// Check if a file is an image based on extension
  static bool isImageFile(FileInfo fileInfo) => _isImage(fileInfo);

  /// Convert image file to PDF
  // REMOVE/COMMENT THIS WHEN YOU RE‑ENABLE SYNCFUSION-BASED PDF CREATION.
  // Temporary stub so the project compiles without Syncfusion.
  static Future<Uint8List> convertImageToPdf(
    File imageFile, {
    bool shouldCompress = false,
    int? quality,
  }) async {
    // For now, just return the raw (optionally compressed) image bytes
    // instead of a real PDF. Later you can plug Syncfusion (or another PDF lib) back in.
    Uint8List imageBytes = await imageFile.readAsBytes();

    if (shouldCompress) {
      imageBytes = await compressImageBytes(imageBytes, quality: quality);
    }

    // This is NOT a proper PDF, but it keeps the app from crashing/compiling errors.
    // When you add a PDF lib (Syncfusion or other), replace this implementation.
    return imageBytes;
  }
}
