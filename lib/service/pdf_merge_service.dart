// lib/services/pdf_merge_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:dartz/dartz.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:pdf_kit/models/file_model.dart';
import 'package:path/path.dart' as p;
import 'dart:ui' as ui;

class PdfMergeService {
  PdfMergeService._();

  /// Merges multiple PDFs and images with optional rotation
  /// [destinationPath] - Optional custom destination folder path. If null, uses Downloads.
  static Future<Either<CustomException, FileInfo>> mergePdfs({
    required List<MapEntry<FileInfo, int>> filesWithRotation,
    required String outputFileName,
    String? destinationPath, // 🆕 Optional destination parameter
  }) async {
    try {
      if (filesWithRotation.isEmpty) {
        return Left(
          CustomException(
            message: 'No files provided for merging',
            code: 'NO_FILES',
          ),
        );
      }

      // Create a new PDF document
      final pdf = pw.Document();

      for (final entry in filesWithRotation) {
        final fileInfo = entry.key;
        final rotation = entry.value;

        if (fileInfo.extension.toLowerCase() == 'pdf') {
          // Handle PDF files - render each page as image
          await _addPdfPagesAsImages(pdf, fileInfo, rotation);
        } else if (_isImageFile(fileInfo)) {
          // Handle image files
          await _addImagePage(pdf, fileInfo, rotation);
        }
      }

      // Get output path using custom destination or default Downloads
      final outputPath = await _getOutputPath(
        outputFileName,
        customDestination: destinationPath, // Pass custom destination
      );

      // Save the PDF
      final File outputFile = File(outputPath);
      final bytes = await pdf.save();
      await outputFile.writeAsBytes(bytes);

      // Create FileInfo for the merged PDF
      final fileStats = await outputFile.stat();
      final mergedFileInfo = FileInfo(
        name: p.basename(outputPath),
        path: outputPath,
        extension: 'pdf',
        size: fileStats.size,
        lastModified: fileStats.modified,
        mimeType: 'application/pdf',
        parentDirectory: p.dirname(outputPath),
      );

      return Right(mergedFileInfo);
    } catch (e) {
      return Left(
        CustomException(
          message: 'Failed to merge PDFs: ${e.toString()}',
          code: 'MERGE_ERROR',
        ),
      );
    }
  }

  /// Convert PDF pages to images and add to the new PDF with rotation
  static Future<void> _addPdfPagesAsImages(
    pw.Document pdf,
    FileInfo pdfFile,
    int rotation,
  ) async {
    try {
      // Open the PDF using pdfx (note the prefix)
      final document = await pdfx.PdfDocument.openFile(pdfFile.path);
      final pageCount = document.pagesCount;

      // Process each page
      for (int i = 1; i <= pageCount; i++) {
        final page = await document.getPage(i);
        
        // Render page at higher resolution for better quality
        const scale = 2.0;
        final pageWidth = page.width * scale;
        final pageHeight = page.height * scale;
        
        final pageImage = await page.render(
          width: pageWidth,
          height: pageHeight,
          format: pdfx.PdfPageImageFormat.png,
        );
        
        await page.close();
        
        if (pageImage != null) {
          // Convert to pw.Image
          final image = pw.MemoryImage(pageImage.bytes);
          
          // Calculate page size based on rotation
          double pdfWidth, pdfHeight;
          if (rotation == 90 || rotation == 270) {
            // Swap dimensions for 90/270 rotation
            pdfWidth = (page.height * 72 / 96); // Convert pixels to points
            pdfHeight = (page.width * 72 / 96);
          } else {
            pdfWidth = (page.width * 72 / 96);
            pdfHeight = (page.height * 72 / 96);
          }
          
          // Add page with appropriate size
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat(pdfWidth, pdfHeight),
              build: (context) {
                if (rotation == 0) {
                  return pw.Image(image, fit: pw.BoxFit.contain);
                }
                
                return pw.Center(
                  child: pw.Transform.rotate(
                    angle: rotation * 3.14159 / 180,
                    child: pw.Image(image, fit: pw.BoxFit.contain),
                  ),
                );
              },
            ),
          );
        }
      }
      
      await document.close();
    } catch (e) {
      throw Exception('Error processing PDF pages: $e');
    }
  }

  /// Add image page to PDF with rotation
  static Future<void> _addImagePage(
    pw.Document pdf,
    FileInfo imageFile,
    int rotation,
  ) async {
    try {
      // Read image bytes
      final File file = File(imageFile.path);
      final Uint8List imageBytes = await file.readAsBytes();

      // Get image dimensions
      final ui.ImmutableBuffer buffer =
          await ui.ImmutableBuffer.fromUint8List(imageBytes);
      final ui.ImageDescriptor descriptor =
          await ui.ImageDescriptor.encoded(buffer);
      
      double imageWidth = descriptor.width.toDouble();
      double imageHeight = descriptor.height.toDouble();
      
      descriptor.dispose();
      buffer.dispose();

      // Convert to pw.Image
      final image = pw.MemoryImage(imageBytes);

      // Calculate page size based on rotation (convert pixels to points)
      double pdfWidth, pdfHeight;
      if (rotation == 90 || rotation == 270) {
        pdfWidth = (imageHeight * 72 / 96);
        pdfHeight = (imageWidth * 72 / 96);
      } else {
        pdfWidth = (imageWidth * 72 / 96);
        pdfHeight = (imageHeight * 72 / 96);
      }

      // Add page with image and rotation
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(pdfWidth, pdfHeight),
          build: (context) {
            if (rotation == 0) {
              return pw.Image(image, fit: pw.BoxFit.contain);
            }
            
            return pw.Center(
              child: pw.Transform.rotate(
                angle: rotation * 3.14159 / 180,
                child: pw.Image(image, fit: pw.BoxFit.contain),
              ),
            );
          },
        ),
      );
    } catch (e) {
      throw Exception('Error adding image page: $e');
    }
  }

  /// Check if file is an image
  static bool _isImageFile(FileInfo file) {
    const imageExtensions = {
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'bmp',
    };
    return imageExtensions.contains(file.extension.toLowerCase());
  }

  /// Get output path in specified destination or Downloads directory
  /// [customDestination] - Optional custom folder path. If null, uses Downloads.
  static Future<String> _getOutputPath(
    String fileName, {
    String? customDestination,
  }) async {
    try {
      Directory? directory;

      // 🆕 Use custom destination if provided
      if (customDestination != null && customDestination.isNotEmpty) {
        directory = Directory(customDestination);
        
        // Verify directory exists and is accessible
        if (!await directory.exists()) {
          throw Exception('Destination folder does not exist: $customDestination');
        }
        
        // Try to test write access
        try {
          final testFile = File(p.join(directory.path, '.test_write'));
          await testFile.writeAsString('test');
          await testFile.delete();
        } catch (e) {
          throw Exception('No write permission for destination: $customDestination');
        }
      } else {
        // Fall back to default Downloads directory
        if (Platform.isAndroid) {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        } else {
          directory = await getApplicationDocumentsDirectory();
        }
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      // Ensure .pdf extension
      String finalFileName = fileName.endsWith('.pdf')
          ? fileName
          : '$fileName.pdf';

      // Handle duplicate names
      String outputPath = p.join(directory.path, finalFileName);
      int counter = 1;
      while (await File(outputPath).exists()) {
        final nameWithoutExt = p.basenameWithoutExtension(finalFileName);
        finalFileName = '${nameWithoutExt}_$counter.pdf';
        outputPath = p.join(directory.path, finalFileName);
        counter++;
      }

      return outputPath;
    } catch (e) {
      throw Exception('Error getting output path: $e');
    }
  }
}

// lib/core/exceptions/custom_exception.dart
class CustomException implements Exception {
  final String message;
  final String code;
  final dynamic details;

  CustomException({
    required this.message,
    required this.code,
    this.details,
  });

  @override
  String toString() => 'CustomException($code): $message';
}
