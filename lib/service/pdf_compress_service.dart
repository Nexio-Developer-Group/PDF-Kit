import 'dart:io';
import 'dart:math';

import 'package:dartz/dartz.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/service/pdf_merge_service.dart' show CustomException;
import 'package:pdf_kit/service/pdf_rasterization_service.dart';

class PdfCompressService {
  PdfCompressService._();

  static void _report(
    void Function(double progress01, String stage)? onProgress,
    double progress01,
    String stage,
  ) {
    try {
      onProgress?.call(progress01.clamp(0.0, 1.0), stage);
    } catch (_) {}
  }

  // Tuning defaults (adjust once based on your typical PDFs):
  static const int _targetKbPerPage = 220; // ~220KB per page target
  static const double _targetFractionOfOriginal = 0.55; // 55% of original

  static int get targetKbPerPage => _targetKbPerPage;
  static double get targetFractionOfOriginal => _targetFractionOfOriginal;

  /// Returns the effective preset used for a given compression level.
  ///
  /// Note: `level` matches the `compressFile(level: ...)` ladder.
  static PdfCompressPreset getPresetForLevel({int level = 1}) {
    final preset = _buildPresetLadder(startLevel: level).first;
    return PdfCompressPreset(
      dpi: preset.dpi,
      maxLongSidePx: preset.maxLongSidePx,
      jpegQuality: preset.jpegQuality,
      grayscale: preset.grayscale,
      postReencode: preset.postReencode,
    );
  }

  /// Convenience for the default `compressFile()` preset (level 1).
  static PdfCompressPreset getDefaultPreset() => getPresetForLevel(level: 1);

  static Future<Either<CustomException, FileInfo>> compressFile({
    required FileInfo fileInfo,
    int level = 1,
    String? destinationPath,
    void Function(double progress01, String stage)? onProgress,
  }) async {
    try {
      _report(onProgress, 0.03, 'Validating input');
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

      _report(onProgress, 0.10, 'Analyzing document');

      final inSize = (await inputFile.stat()).size;

      final pageCountEither = await PdfRasterizationService.getPageCount(
        inputPdf: inputFile,
      );

      final int? pageCount = pageCountEither.fold((_) => null, (c) => c);
      final int targetBytesByPages = pageCount == null
          ? (1 << 62)
          : pageCount * _targetKbPerPage * 1024;

      final int targetBytes = min(
        (inSize * _targetFractionOfOriginal).round(),
        targetBytesByPages,
      );

      _report(onProgress, 0.18, 'Preparing output');

      final targetDir = await _resolveDestination(
        destinationPath: destinationPath,
        fallbackOriginalParent: fileInfo.parentDirectory,
      );
      await targetDir.create(recursive: true);

      final originalBase = p.basenameWithoutExtension(fileInfo.name);
      final baseName = '${originalBase}_compressed';
      final newName = _uniqueFileName(
        baseDir: targetDir.path,
        baseName: baseName,
      );
      final finalPath = p.join(targetDir.path, newName);

      // Multi-pass ladder (starts at requested `level`, escalates if needed).
      final presets = _buildPresetLadder(startLevel: level);

      _report(
        onProgress,
        0.22,
        'Compressing (starting at level $level, up to ${presets.length} pass${presets.length == 1 ? '' : 'es'})',
      );

      File? bestFile;
      int bestSize = 1 << 62;

      for (
        var attemptIndex0 = 0;
        attemptIndex0 < presets.length;
        attemptIndex0++
      ) {
        final preset = presets[attemptIndex0];
        final attemptIndex = attemptIndex0 + 1;
        final attemptProgress = 0.25 + (0.60 * (attemptIndex / presets.length));

        _report(
          onProgress,
          attemptProgress,
          'Compressing pass $attemptIndex/${presets.length} (DPI ${preset.dpi}, quality ${preset.jpegQuality})',
        );

        // Always overwrite the same output path for simplicity.
        final existing = File(finalPath);
        if (await existing.exists()) {
          try {
            await existing.delete();
          } catch (_) {}
        }

        final attempt = await PdfRasterizationService.rasterizeAndCompressPdf(
          inputPdf: inputFile,
          outputPath: finalPath,
          dpi: preset.dpi,
          maxLongSidePx: preset.maxLongSidePx,
          jpegQuality: preset.jpegQuality,
          grayscale: preset.grayscale,
          postReencode: preset.postReencode,
          optimizeForSpeed: true,
        );

        final ok = await attempt.fold(
          (err) async {
            // If an attempt fails, try next preset (don’t abort immediately).
            return false;
          },
          (outFile) async {
            final outSize = (await outFile.stat()).size;

            if (outSize < bestSize) {
              bestSize = outSize;
              bestFile = outFile;
            }

            // Stop early if it’s smaller and meets target.
            final bool smallerThanOriginal = outSize < inSize;
            final bool meetsTarget = outSize <= targetBytes;
            return smallerThanOriginal && meetsTarget;
          },
        );

        if (ok) break;
      }

      if (bestFile == null) {
        return left(
          CustomException(
            message: 'Compression failed.',
            code: 'COMPRESSION_FAILED',
          ),
        );
      }

      // If it never got smaller, treat as “not beneficial”.
      if (bestSize >= inSize) {
        return left(
          CustomException(
            message:
                'Compression not beneficial for this PDF (output >= original). Try a higher level.',
            code: 'NOT_BENEFICIAL',
          ),
        );
      }

      _report(onProgress, 0.92, 'Finalizing output');

      final stats = await bestFile!.stat();
      final resultInfo = FileInfo(
        name: p.basename(bestFile!.path),
        path: bestFile!.path,
        extension: 'pdf',
        size: stats.size,
        lastModified: stats.modified,
        mimeType: 'application/pdf',
        parentDirectory: p.dirname(bestFile!.path),
      );

      return right(resultInfo);
    } catch (e) {
      return left(
        CustomException(
          message: 'PDF compression failed: ${e.toString()}',
          code: 'COMPRESSION_ERROR',
        ),
      );
    }
  }

  static List<_CompressPreset> _buildPresetLadder({required int startLevel}) {
    // Aggressive by default because you explicitly want much smaller files.
    final all = <_CompressPreset>[
      // Level 1 (balanced, already strong)
      const _CompressPreset(
        dpi: 110,
        maxLongSidePx: 1600,
        jpegQuality: 55,
        grayscale: false,
        postReencode: true,
      ),
      // Level 2 (strong)
      const _CompressPreset(
        dpi: 96,
        maxLongSidePx: 1400,
        jpegQuality: 45,
        grayscale: false,
        postReencode: true,
      ),
      // Level 3 (very strong)
      const _CompressPreset(
        dpi: 82,
        maxLongSidePx: 1200,
        jpegQuality: 38,
        grayscale: true,
        postReencode: true,
      ),
      // Extra “extreme” fallback (still readable for many scans)
      const _CompressPreset(
        dpi: 72,
        maxLongSidePx: 1050,
        jpegQuality: 32,
        grayscale: true,
        postReencode: true,
      ),
    ];

    final idx = (startLevel - 1).clamp(0, all.length - 1);
    return all.sublist(idx);
  }

  static Future<Directory> _resolveDestination({
    String? destinationPath,
    String? fallbackOriginalParent,
  }) async {
    if (destinationPath != null && destinationPath.isNotEmpty) {
      return Directory(destinationPath);
    }
    if (fallbackOriginalParent != null && fallbackOriginalParent.isNotEmpty) {
      return Directory(fallbackOriginalParent);
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
}

class _CompressPreset {
  final int dpi;
  final int maxLongSidePx;
  final int jpegQuality;
  final bool grayscale;
  final bool postReencode;

  const _CompressPreset({
    required this.dpi,
    required this.maxLongSidePx,
    required this.jpegQuality,
    required this.grayscale,
    required this.postReencode,
  });
}

/// Public view model for displaying the configured compression factors.
class PdfCompressPreset {
  final int dpi;
  final int maxLongSidePx;
  final int jpegQuality;
  final bool grayscale;
  final bool postReencode;

  const PdfCompressPreset({
    required this.dpi,
    required this.maxLongSidePx,
    required this.jpegQuality,
    required this.grayscale,
    required this.postReencode,
  });
}
