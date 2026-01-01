import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart' as pdfx;

import 'package:pdf_kit/service/pdf_merge_service.dart' show CustomException;

class PdfRasterizationService {
  PdfRasterizationService._();

  static Future<Either<CustomException, File>> rasterizeAndCompressPdf({
    required File inputPdf,
    required String outputPath,
    required int dpi,
    required int jpegQuality,
    required int maxLongSidePx,
  }) async {
    pdfx.PdfDocument? doc;

    try {
      // pdfx document open API
      doc = await pdfx.PdfDocument.openFile(inputPdf.path); // [web:21]

      final out = pw.Document(compress: true);

      for (int pageNumber = 1; pageNumber <= doc.pagesCount; pageNumber++) {
        final page = await doc.getPage(pageNumber);

        final scale = dpi / 72.0;
        double targetW = page.width * scale;
        double targetH = page.height * scale;

        final longSide = max(targetW, targetH);
        if (longSide > maxLongSidePx) {
          final down = maxLongSidePx / longSide;
          targetW *= down;
          targetH *= down;
        }

        final pdfx.PdfPageImage? rendered = await page.render(
          width: targetW,
          height: targetH,
          format: pdfx.PdfPageImageFormat.jpeg,
          quality: jpegQuality,
          backgroundColor: '#FFFFFF',
          forPrint: false,
          removeTempFile: true,
        );

        await page.close();

        if (rendered == null) {
          return left(
            CustomException(
              message: 'Failed to render page $pageNumber',
              code: 'RENDER_FAILED',
            ),
          );
        }

        final Uint8List jpegBytes = rendered.bytes;

        // Keep original page size in PDF points
        final pageFormat = pdf.PdfPageFormat(page.width, page.height);

        out.addPage(
          pw.Page(
            pageFormat: pageFormat,
            margin: pw.EdgeInsets.zero,
            build: (_) => pw.FullPage(
              ignoreMargins: true,
              child: pw.Image(pw.MemoryImage(jpegBytes), fit: pw.BoxFit.fill),
            ),
          ),
        );
      }

      await doc.close();

      final outFile = File(outputPath);
      await outFile.writeAsBytes(await out.save(), flush: true);
      return right(outFile);
    } catch (e) {
      try {
        await doc?.close();
      } catch (_) {}

      return left(
        CustomException(
          message: 'Rasterization failed: ${e.toString()}',
          code: 'RASTERIZATION_ERROR',
        ),
      );
    }
  }
}
