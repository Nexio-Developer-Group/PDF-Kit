import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:ares_defence_labs_lock_smith_pdf/ares_defence_labs_lock_smith_pdf.dart';
import 'package:pdf_kit/core/exception/failures.dart';

class PdfProtectionService {
  PdfProtectionService._();

  static void _report(
    void Function(double progress01, String stage)? onProgress,
    double progress01,
    String stage,
  ) {
    try {
      onProgress?.call(progress01.clamp(0.0, 1.0), stage);
    } catch (_) {}
  }

  /// Protects a PDF file with a password using Syncfusion Flutter PDF
  static Future<Either<Failure, String>> protectPdf({
    required String pdfPath,
    required String password,
    void Function(double progress01, String stage)? onProgress,
  }) async {
    try {
      _report(onProgress, 0.03, 'Validating inputs');
      // Validate password
      if (password.isEmpty) {
        return const Left(InvalidPasswordFailure());
      }

      // Check if file exists
      final File pdfFile = File(pdfPath);
      if (!await pdfFile.exists()) {
        return const Left(FileNotFoundFailure());
      }

      _report(onProgress, 0.18, 'Encrypting PDF');
      // Use ares_defence_labs_lock_smith_pdf to protect the PDF.
      final String outputPath = _outputPathFor(pdfPath, '_protected');

      await AresDefenceLabsLocksmithPdf.protectPdf(
        inputPath: pdfPath,
        outputPath: outputPath,
        password: password,
      );

      _report(onProgress, 0.78, 'Writing output');

      // Replace original with protected output
      final File outFile = File(outputPath);
      if (!await outFile.exists()) {
        return const Left(
          PdfProtectionFailure('Failed to create protected PDF'),
        );
      }

      final List<int> bytes = await outFile.readAsBytes();
      await pdfFile.writeAsBytes(bytes);

      _report(onProgress, 0.92, 'Cleaning up');

      // Clean up temporary file
      try {
        await outFile.delete();
      } catch (_) {}

      _report(onProgress, 1.0, 'Done');
      return Right(pdfPath);
    } on FileSystemException catch (e) {
      return Left(FileReadWriteFailure('File error: ${e.message}'));
    } catch (e) {
      print('Error protecting PDF: $e');
      return Left(
        PdfProtectionFailure('Failed to protect PDF: ${e.toString()}'),
      );
    }
  }

  /// Checks if a PDF is password protected
  /// Optimized to check only PDF metadata without loading entire document
  static Future<Either<Failure, bool>> isPdfProtected({
    required String pdfPath,
  }) async {
    try {
      final File pdfFile = File(pdfPath);
      if (!await pdfFile.exists()) {
        return const Left(FileNotFoundFailure());
      }

      // Fast path: Read first few KB to check for encryption markers
      // Most PDF encryption info is in the header/trailer, not the full content
      final RandomAccessFile raf = await pdfFile.open(mode: FileMode.read);
      try {
        final int fileLength = await raf.length();

        // Read header (first 1KB) and trailer (last 4KB) for encryption markers
        // This is much faster than parsing the entire PDF
        final int headerSize = fileLength < 1024 ? fileLength : 1024;
        final int trailerSize = fileLength < 4096 ? fileLength : 4096;

        await raf.setPosition(0);
        final List<int> header = await raf.read(headerSize);

        await raf.setPosition(
          fileLength > trailerSize ? fileLength - trailerSize : 0,
        );
        final List<int> trailer = await raf.read(trailerSize);

        await raf.close();

        // Quick check: Look for /Encrypt in header or trailer
        // This is a fast heuristic before calling the plugin
        final String headerStr = String.fromCharCodes(header);
        final String trailerStr = String.fromCharCodes(trailer);

        final bool hasEncryptMarker =
            headerStr.contains('/Encrypt') || trailerStr.contains('/Encrypt');

        // If no encryption marker found, it's definitely not encrypted
        if (!hasEncryptMarker) {
          return const Right(false);
        }

        // If marker found, use plugin for definitive check
        final bool isEncrypted =
            await AresDefenceLabsLocksmithPdf.isPdfEncrypted(
              inputPath: pdfPath,
            );

        return Right(isEncrypted);
      } catch (_) {
        await raf.close();
        rethrow;
      }
    } catch (e) {
      // Fallback to plugin if fast check fails
      try {
        final bool isEncrypted =
            await AresDefenceLabsLocksmithPdf.isPdfEncrypted(
              inputPath: pdfPath,
            );
        return Right(isEncrypted);
      } catch (pluginError) {
        return Left(
          PdfProtectionFailure('Failed to check PDF: ${e.toString()}'),
        );
      }
    }
  }

  /// Unlocks a password-protected PDF file using Syncfusion Flutter PDF
  static Future<Either<Failure, String>> unlockPdf({
    required String pdfPath,
    required String password,
    void Function(double progress01, String stage)? onProgress,
  }) async {
    try {
      _report(onProgress, 0.03, 'Validating inputs');
      // Validate password
      if (password.isEmpty) {
        return const Left(InvalidPasswordFailure());
      }

      // Check if file exists
      final File pdfFile = File(pdfPath);
      if (!await pdfFile.exists()) {
        return const Left(FileNotFoundFailure());
      }

      // Try to load the PDF with password
      try {
        _report(onProgress, 0.18, 'Decrypting PDF');
        final String outputPath = _outputPathFor(pdfPath, '_unlocked');

        await AresDefenceLabsLocksmithPdf.decryptPdf(
          inputPath: pdfPath,
          outputPath: outputPath,
          password: password,
        );

        _report(onProgress, 0.78, 'Writing output');

        final File outFile = File(outputPath);
        if (!await outFile.exists()) {
          return const Left(
            PdfProtectionFailure('Failed to create unlocked PDF'),
          );
        }

        final List<int> bytes = await outFile.readAsBytes();
        await pdfFile.writeAsBytes(bytes);

        _report(onProgress, 0.92, 'Cleaning up');

        try {
          await outFile.delete();
        } catch (_) {}

        _report(onProgress, 1.0, 'Done');
        return Right(pdfPath);
      } catch (e) {
        // Handle incorrect password or loading errors
        if (e.toString().toLowerCase().contains('password') ||
            e.toString().toLowerCase().contains('invalid') ||
            e.toString().toLowerCase().contains('encrypted')) {
          return const Left(
            PdfProtectionFailure('Incorrect password. Please try again.'),
          );
        }
        rethrow;
      }
    } on FileSystemException catch (e) {
      return Left(FileReadWriteFailure('File error: ${e.message}'));
    } catch (e) {
      return Left(
        PdfProtectionFailure('Failed to unlock PDF: ${e.toString()}'),
      );
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
