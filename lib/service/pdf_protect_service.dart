import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:pdf_kit/core/exception/failures.dart';

class PdfProtectionService {
  PdfProtectionService._();

  static const MethodChannel _channel = MethodChannel(
    'com.example.pdf_kit/pdf_protection',
  );

  /// Protects a PDF file with a password using native Android encryption
  static Future<Either<Failure, String>> protectPdf({
    required String pdfPath,
    required String password,
  }) async {
    try {
      // Validate password
      if (password.isEmpty) {
        return const Left(InvalidPasswordFailure());
      }

      // Check platform
      if (!Platform.isAndroid) {
        return const Left(PlatformNotSupportedFailure());
      }

      // Check if file exists
      final File pdfFile = File(pdfPath);
      if (!await pdfFile.exists()) {
        return const Left(FileNotFoundFailure());
      }

      // Get output directory
      final Directory outputDir = await getApplicationDocumentsDirectory();
      final String fileName = path.basenameWithoutExtension(pdfPath);
      final String outputPath = path.join(
        outputDir.path,
        '${fileName}_protected_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );

      // Call native method
      final String? result = await _channel.invokeMethod<String>('protectPdf', {
        'inputPath': pdfPath,
        'outputPath': outputPath,
        'password': password,
      });

      if (result == null || result.isEmpty) {
        return const Left(PdfProtectionFailure('Failed to protect PDF'));
      }

      return Right(result);
    } on PlatformException catch (e) {
      return Left(PdfProtectionFailure('Platform error: ${e.message}'));
    } on FileSystemException catch (e) {
      return Left(FileReadWriteFailure('File error: ${e.message}'));
    } catch (e) {
      print(e.toString());
      return Left(
        PdfProtectionFailure('Failed to protect PDF: ${e.toString()}'),
      );
    }
  }

  /// Checks if a PDF is password protected
  static Future<Either<Failure, bool>> isPdfProtected({
    required String pdfPath,
  }) async {
    try {
      if (!Platform.isAndroid) {
        return const Left(PlatformNotSupportedFailure());
      }

      final File pdfFile = File(pdfPath);
      if (!await pdfFile.exists()) {
        return const Left(FileNotFoundFailure());
      }

      final bool? result = await _channel.invokeMethod<bool>('isPdfProtected', {
        'pdfPath': pdfPath,
      });

      return Right(result ?? false);
    } on PlatformException catch (e) {
      return Left(PdfProtectionFailure('Platform error: ${e.message}'));
    } catch (e) {
      return Left(PdfProtectionFailure('Failed to check PDF: ${e.toString()}'));
    }
  }
}
