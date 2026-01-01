import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/service/pdf_merge_service.dart' show CustomException;
import 'package:pdf_kit/service/pdf_rasterization_service.dart';

class PdfCompressService {
  PdfCompressService._();

  static Future<Either<CustomException, FileInfo>> compressFile({
    required FileInfo fileInfo,
    int level = 1,
    String? destinationPath,
  }) async {
    try {
      final isPdf = fileInfo.extension.toLowerCase() == 'pdf';
      if (!isPdf) {
        return left(
          CustomException(
            message: 'Unsupported file type. Only PDF is allowed.',
            code: 'UNSUPPORTED_TYPE',
          ),
        );
      }

      final inputFile = File(fileInfo.path);
      if (!await inputFile.exists()) {
        return left(
          CustomException(
            message: 'Input file does not exist.',
            code: 'FILE_NOT_FOUND',
          ),
        );
      }

      final targetDir = await _resolveDestination(
        destinationPath: destinationPath,
        fallbackOriginalParent: fileInfo.parentDirectory,
      );

      // Ensure directory exists (your older code required it to already exist).
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final originalBase = p.basenameWithoutExtension(fileInfo.name);
      final baseName = '${originalBase}_compressed';

      final newName = _uniqueFileName(
        baseDir: targetDir.path,
        baseName: baseName,
      );
      final finalPath = p.join(targetDir.path, newName);

      final preset = _presetForLevel(level);

      // 1st pass with requested level
      final first = await PdfRasterizationService.rasterizeAndCompressPdf(
        inputPdf: inputFile,
        outputPath: finalPath,
        dpi: preset.dpi,
        jpegQuality: preset.jpegQuality,
        maxLongSidePx: preset.maxLongSidePx,
      );

      // If success but not smaller, auto-retry once with stronger preset.
      final Either<CustomException, File> finalResult = await first.fold(
        (e) async => left(e),
        (outFile) async {
          final inSize = (await inputFile.stat()).size;
          final outSize = (await outFile.stat()).size;

          if (outSize >= inSize) {
            // Stronger fallback (one retry max).
            final strong = _presetForLevel(3);
            try {
              await outFile.delete();
            } catch (_) {}

            return PdfRasterizationService.rasterizeAndCompressPdf(
              inputPdf: inputFile,
              outputPath: finalPath,
              dpi: strong.dpi,
              jpegQuality: strong.jpegQuality,
              maxLongSidePx: strong.maxLongSidePx,
            );
          }
          return right(outFile);
        },
      );

      return await finalResult.fold(
        (failure) async => left(
          CustomException(
            message: failure.message,
            code: failure.code ?? 'RASTERIZATION_FAILED',
          ),
        ),
        (finalFile) async {
          final stats = await finalFile.stat();
          return right(
            FileInfo(
              name: p.basename(finalFile.path),
              path: finalFile.path,
              extension: 'pdf',
              size: stats.size,
              lastModified: stats.modified,
              mimeType: 'application/pdf',
              parentDirectory: p.dirname(finalFile.path),
            ),
          );
        },
      );
    } catch (e) {
      return left(
        CustomException(
          message: 'PDF compression failed: ${e.toString()}',
          code: 'COMPRESSION_ERROR',
        ),
      );
    }
  }

  static Future<Directory> _resolveDestination({
    String? destinationPath,
    String? fallbackOriginalParent,
  }) async {
    if (destinationPath != null && destinationPath.isNotEmpty) {
      final dir = Directory(destinationPath);
      return dir;
    }

    if (fallbackOriginalParent != null && fallbackOriginalParent.isNotEmpty) {
      final dir = Directory(fallbackOriginalParent);
      return dir;
    }

    return getTemporaryDirectory();
  }

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

  static CompressPreset getDefaultPreset() {
    return _presetForLevel(1);
  }

  static CompressPreset _presetForLevel(int level) {
    // Tuned for "smaller + faster" defaults.
    switch (level) {
      case 3: // strong
        return const CompressPreset(
          dpi: 96,
          jpegQuality: 55,
          maxLongSidePx: 1400,
        );
      case 2: // medium
        return const CompressPreset(
          dpi: 120,
          jpegQuality: 65,
          maxLongSidePx: 1800,
        );
      case 1: // light (still optimized)
      default:
        return const CompressPreset(
          dpi: 144,
          jpegQuality: 75,
          maxLongSidePx: 2200,
        );
    }
  }
}

class CompressPreset {
  final int dpi;
  final int jpegQuality;
  final int maxLongSidePx;
  const CompressPreset({
    required this.dpi,
    required this.jpegQuality,
    required this.maxLongSidePx,
  });
}
