import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:image/image.dart' as img;
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart' as pdfx;

import 'package:pdf_kit/service/pdf_merge_service.dart' show CustomException;

class PdfRasterizationService {
  PdfRasterizationService._();

  static Future<Either<CustomException, int>> getPageCount({
    required File inputPdf,
  }) async {
    pdfx.PdfDocument? doc;
    try {
      doc = await pdfx.PdfDocument.openFile(inputPdf.path);
      final c = doc.pagesCount;
      await doc.close();
      return right(c);
    } catch (e) {
      try {
        await doc?.close();
      } catch (_) {}
      return left(
        CustomException(
          message: 'Failed to read PDF page count: ${e.toString()}',
          code: 'PAGECOUNT_ERROR',
        ),
      );
    }
  }

  /// Rasterize -> JPEG -> rebuild PDF.
  ///
  /// Key knobs:
  /// - dpi: target DPI (72–120 gives big reductions).
  /// - maxLongSidePx: hard cap to prevent huge pages from producing massive images.
  /// - jpegQuality: base quality used by pdfx render.
  /// - grayscale: optional last-mile reduction (good for text-heavy scans).
  /// - postReencode: second pass via `image` package to force yuv420 + better packing.
  static Future<Either<CustomException, File>> rasterizeAndCompressPdf({
    required File inputPdf,
    required String outputPath,
    required int dpi,
    required int maxLongSidePx,
    required int jpegQuality,
    required bool grayscale,
    required bool postReencode,
    bool optimizeForSpeed = true,
  }) async {
    pdfx.PdfDocument? doc;

    try {
      doc = await pdfx.PdfDocument.openFile(inputPdf.path);

      final out = pw.Document(compress: true);

      for (int pageNumber = 1; pageNumber <= doc.pagesCount; pageNumber++) {
        final page = await doc.getPage(pageNumber);

        // pdfx page.width/page.height are in "PDF points space" (~72dpi basis).
        final scale = dpi / 72.0;
        double targetW = page.width * scale;
        double targetH = page.height * scale;

        final longSide = max(targetW, targetH);
        if (longSide > maxLongSidePx) {
          final down = maxLongSidePx / longSide;
          targetW *= down;
          targetH *= down;
        }

        final rendered = await page.render(
          width: targetW,
          height: targetH,
          format: pdfx.PdfPageImageFormat.jpeg,
          quality: jpegQuality,
          backgroundColor: '#FFFFFF',
          forPrint: false,
          // removeTempFile: true,
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

        Uint8List jpegBytes = rendered.bytes;

        // Optional second pass: decode -> grayscale -> encodeJpg(quality, yuv420).
        if (postReencode || grayscale) {
          final decoded = img.decodeImage(jpegBytes);
          if (decoded != null) {
            final processed = grayscale ? img.grayscale(decoded) : decoded;
            jpegBytes = img.encodeJpg(
              processed,
              quality: jpegQuality,
              chroma: img.JpegChroma.yuv420,
            );
          }
        }

        // Preserve original PDF page size in points.
        final pageFormat = pdf.PdfPageFormat(page.width, page.height);

        out.addPage(
          pw.Page(
            pageFormat: pageFormat,
            margin: pw.EdgeInsets.zero,
            build: (_) => pw.FullPage(
              ignoreMargins: true,
              child: pw.Image(
                pw.MemoryImage(jpegBytes),
                fit: pw.BoxFit.fill,
              ),
            ),
          ),
        );

        // Small yield helps keep UI responsive on some devices.
        if (!optimizeForSpeed) {
          await Future<void>.delayed(const Duration(milliseconds: 1));
        }
      }

      await doc.close();

      final outFile = File(outputPath);
      await outFile.parent.create(recursive: true);

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
