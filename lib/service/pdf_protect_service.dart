import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sf;
import 'package:pdf_kit/core/exception/failures.dart';

class PdfProtectionService {
  PdfProtectionService._();

  /// Protects a PDF file with a password using Syncfusion Flutter PDF
  static Future<Either<Failure, String>> protectPdf({
    required String pdfPath,
    required String password,
  }) async {
    try {
      // Validate password
      if (password.isEmpty) {
        return const Left(InvalidPasswordFailure());
      }

      // Check if file exists
      final File pdfFile = File(pdfPath);
      if (!await pdfFile.exists()) {
        return const Left(FileNotFoundFailure());
      }

      // Load the PDF document
      final sf.PdfDocument document = sf.PdfDocument(
        inputBytes: await pdfFile.readAsBytes(),
      );

      // Create security instance and set password
      final sf.PdfSecurity security = document.security;
      security.userPassword = password;
      security.ownerPassword = password;

      // Set permissions (allow all operations with password)
      security.permissions.addAll([
        sf.PdfPermissionsFlags.print,
        sf.PdfPermissionsFlags.editContent,
        sf.PdfPermissionsFlags.copyContent,
        sf.PdfPermissionsFlags.editAnnotations,
        sf.PdfPermissionsFlags.fillFields,
        sf.PdfPermissionsFlags.accessibilityCopyContent,
        sf.PdfPermissionsFlags.assembleDocument,
        sf.PdfPermissionsFlags.fullQualityPrint,
      ]);

      // Save the protected PDF
      final List<int> bytes = await document.save();
      document.dispose();

      // Overwrite the original file with the protected version
      await pdfFile.writeAsBytes(bytes);

      return Right(pdfPath);
    } on FileSystemException catch (e) {
      return Left(FileReadWriteFailure('File error: ${e.message}'));
    } catch (e) {
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
      final File pdfFile = File(pdfPath);
      if (!await pdfFile.exists()) {
        return const Left(FileNotFoundFailure());
      }

      // Try to load the PDF without password
      try {
        final sf.PdfDocument document = sf.PdfDocument(
          inputBytes: await pdfFile.readAsBytes(),
        );

        // Check if document has security
        final bool isProtected =
            document.security.userPassword.isNotEmpty ||
            document.security.ownerPassword.isNotEmpty;

        document.dispose();
        return Right(isProtected);
      } catch (e) {
        // If loading fails, it might be encrypted
        if (e.toString().contains('password') ||
            e.toString().contains('encrypted') ||
            e.toString().contains('security')) {
          return const Right(true);
        }
        rethrow;
      }
    } catch (e) {
      return Left(PdfProtectionFailure('Failed to check PDF: ${e.toString()}'));
    }
  }

  /// Unlocks a password-protected PDF file using Syncfusion Flutter PDF
  static Future<Either<Failure, String>> unlockPdf({
    required String pdfPath,
    required String password,
  }) async {
    try {
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
        final sf.PdfDocument document = sf.PdfDocument(
          inputBytes: await pdfFile.readAsBytes(),
          password: password,
        );

        // Remove security by creating a new document without password
        final sf.PdfSecurity security = document.security;
        security.userPassword = '';
        security.ownerPassword = '';

        // Save the unlocked PDF
        final List<int> bytes = await document.save();
        document.dispose();

        // Overwrite the original file with the unlocked version
        await pdfFile.writeAsBytes(bytes);

        return Right(pdfPath);
      } catch (e) {
        // Handle incorrect password or loading errors
        if (e.toString().contains('password') ||
            e.toString().contains('Invalid') ||
            e.toString().contains('encrypted')) {
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
}
