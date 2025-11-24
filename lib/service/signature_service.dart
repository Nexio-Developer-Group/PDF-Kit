import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:dartz/dartz.dart';
import 'package:pdf_kit/service/pdf_merge_service.dart' show CustomException;
import 'package:pdf_kit/models/file_model.dart';
import 'package:path/path.dart' as p;

/// Service for adding digital signatures to PDFs and images
class SignatureService {
  /// Build signed PDF bytes with signature overlay on specific page
  static Future<Uint8List> buildSignedPdfBytes({
    required Uint8List originalPdfBytes,
    required int pageNumber,
    required Uint8List signatureBytes,
    required double sigLeftFrac,
    required double sigTopFrac,
    required double sigWidthFrac,
  }) async {
    final doc = await pdfx.PdfDocument.openData(originalPdfBytes);
    final pdf = pw.Document();

    final sigImage = pw.MemoryImage(signatureBytes);

    // Process each page
    for (int i = 1; i <= doc.pagesCount; i++) {
      final page = await doc.getPage(i);
      final pageImage = await page.render(
        width: page.width,
        height: page.height,
        format: pdfx.PdfPageImageFormat.png,
      );
      await page.close();

      if (pageImage == null) continue;

      final bgImage = pw.MemoryImage(pageImage.bytes);
      final pageWidth = pageImage.width!.toDouble();
      final pageHeight = pageImage.height!.toDouble();

      if (i == pageNumber) {
        // Add signature to this page
        final sigWidth = sigWidthFrac * pageWidth;
        final sigLeft = sigLeftFrac * pageWidth;
        final sigTop = sigTopFrac * pageHeight;

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(pageWidth, pageHeight),
            build: (context) {
              return pw.Stack(
                children: [
                  pw.Positioned.fill(
                    child: pw.Image(bgImage, fit: pw.BoxFit.fill),
                  ),
                  pw.Positioned(
                    left: sigLeft,
                    top: sigTop,
                    child: pw.Image(sigImage, width: sigWidth),
                  ),
                ],
              );
            },
          ),
        );
      } else {
        // Keep page as is
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(pageWidth, pageHeight),
            build: (context) {
              return pw.Image(bgImage, fit: pw.BoxFit.fill);
            },
          ),
        );
      }
    }

    await doc.close();
    return pdf.save();
  }

  /// Build signed image bytes with signature overlay
  static Future<Uint8List> buildSignedImageBytes({
    required Uint8List imageBytes,
    required Uint8List signatureBytes,
    required double sigLeftFrac,
    required double sigTopFrac,
    required double sigWidthFrac,
  }) async {
    // Decode the base image
    final ui.Codec baseCodec = await ui.instantiateImageCodec(imageBytes);
    final ui.FrameInfo baseFrame = await baseCodec.getNextFrame();
    final ui.Image baseImage = baseFrame.image;

    // Decode the signature
    final ui.Codec sigCodec = await ui.instantiateImageCodec(signatureBytes);
    final ui.FrameInfo sigFrame = await sigCodec.getNextFrame();
    final ui.Image sigImage = sigFrame.image;

    // Create canvas to composite
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // Draw base image
    canvas.drawImage(baseImage, ui.Offset.zero, ui.Paint());

    // Calculate signature position and size
    final sigWidth = sigWidthFrac * baseImage.width;
    final sigHeight = sigWidth * (sigImage.height / sigImage.width);
    final sigLeft = sigLeftFrac * baseImage.width;
    final sigTop = sigTopFrac * baseImage.height;

    // Draw signature
    canvas.drawImageRect(
      sigImage,
      ui.Rect.fromLTWH(
        0,
        0,
        sigImage.width.toDouble(),
        sigImage.height.toDouble(),
      ),
      ui.Rect.fromLTWH(sigLeft, sigTop, sigWidth, sigHeight),
      ui.Paint(),
    );

    // Convert to image
    final picture = recorder.endRecording();
    final finalImage = await picture.toImage(baseImage.width, baseImage.height);
    final byteData = await finalImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return byteData!.buffer.asUint8List();
  }

  /// Save and open signed document (PDF or image)
  static Future<Either<CustomException, FileInfo>> saveAndOpenSignedFile({
    required Uint8List bytes,
    required String originalFileName,
    required bool isPdf,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final ext = isPdf ? 'pdf' : 'png';
      final baseName = p.basenameWithoutExtension(originalFileName);
      final fileName =
          'signed_${baseName}_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final file = File('${dir.path}/$fileName');

      await file.writeAsBytes(bytes, flush: true);

      final fileInfo = FileInfo(
        name: fileName,
        path: file.path,
        extension: ext,
        size: bytes.length,
        lastModified: DateTime.now(),
        isDirectory: false,
        mimeType: isPdf ? 'application/pdf' : 'image/png',
      );

      await OpenFilex.open(file.path);

      return Right(fileInfo);
    } catch (e) {
      return Left(
        CustomException(
          message: 'Failed to save signed file: $e',
          code: 'SIGNATURE_SAVE_ERROR',
        ),
      );
    }
  }

  /// Load PDF page count
  static Future<Either<CustomException, int>> getPdfPageCount(
    Uint8List pdfBytes,
  ) async {
    try {
      final doc = await pdfx.PdfDocument.openData(pdfBytes);
      final pageCount = doc.pagesCount;
      await doc.close();
      return Right(pageCount);
    } catch (e) {
      return Left(
        CustomException(
          message: 'Failed to get page count: $e',
          code: 'PDF_PAGE_COUNT_ERROR',
        ),
      );
    }
  }

  /// Load specific PDF page as image for preview
  static Future<Either<CustomException, pdfx.PdfPageImage>> loadPdfPageAsImage(
    Uint8List pdfBytes,
    int pageNumber,
  ) async {
    try {
      final doc = await pdfx.PdfDocument.openData(pdfBytes);
      final page = await doc.getPage(pageNumber);
      final pageImage = await page.render(
        width: page.width,
        height: page.height,
        format: pdfx.PdfPageImageFormat.png,
      );
      await page.close();
      await doc.close();

      if (pageImage == null) {
        return Left(
          CustomException(
            message: 'Failed to render PDF page',
            code: 'PDF_RENDER_ERROR',
          ),
        );
      }

      return Right(pageImage);
    } catch (e) {
      return Left(
        CustomException(
          message: 'Failed to load PDF: $e',
          code: 'PDF_LOAD_ERROR',
        ),
      );
    }
  }
}
