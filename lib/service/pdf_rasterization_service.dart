import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as pw;
import 'package:pdf/widgets.dart' as pw_widgets;
import 'package:pdfx/pdfx.dart' as pdfx; // <- use pdfx for rasterization
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Service responsible for rasterizing PDFs, compressing page images,
/// applying watermarks, and rebuilding a flattened PDF.
class PdfRasterizationService {
  PdfRasterizationService._();

  /// Main pipeline entry.
  ///
  /// - Rasterizes the input PDF pages (≈150–200 DPI)
  /// - Compresses each raster image (WebP/JPEG, ~80% quality)
  /// - Applies text or image watermark (grid or single)
  /// - Rebuilds a new flattened PDF and saves it to a writable directory
  static Future<File> rasterizeCompressWatermarkPdf({
    required File inputPdf,
    String? watermarkText,
    String? watermarkImagePath,
    bool isGridPattern = false,
  }) async {
    debugPrint(
      '🧩 [PdfRasterizationService] Starting pipeline for: ${inputPdf.path}',
    );

    // 1. Rasterize pages.
    final pagesBytes = await _rasterizePdf(inputPdf.path);

    final processedPages = <Uint8List>[];

    for (int i = 0; i < pagesBytes.length; i++) {
      final pageBytes = pagesBytes[i];

      // 2. Compress page image (WebP via flutter_image_compress).
      final compressed = await _compressImage(pageBytes);

      // 3. Apply watermark.
      final watermarked = await _applyWatermark(
        compressed,
        watermarkText: watermarkText,
        watermarkImagePath: watermarkImagePath,
        isGridPattern: isGridPattern,
      );

      processedPages.add(watermarked);
    }

    // 4. Rebuild flattened PDF.
    final pdfBytes = await _rebuildPdf(processedPages);

    // 5. Save output.
    final outputFile = await _saveOutputPdf(inputPdf, pdfBytes);

    debugPrint(
      '✅ [PdfRasterizationService] Pipeline done → ${outputFile.path}',
    );
    return outputFile;
  }

  /// 1. Load & Rasterize PDF using `pdfx`.
  ///
  /// Renders each page around 1240px width (≈150–200 DPI for A4/Letter).
  static Future<List<Uint8List>> _rasterizePdf(String pdfPath) async {
    final doc = await pdfx.PdfDocument.openFile(pdfPath); // [web:131]
    final List<Uint8List> pages = [];

    try {
      final pageCount = doc.pagesCount;
      debugPrint('📄 [Rasterize] Page count: $pageCount');

      // pdfx pages are 1-based.
      for (int i = 1; i <= pageCount; i++) {
        final page = await doc.getPage(i);

        const targetWidth = 1240;
        final targetHeight = (targetWidth * page.height / page.width).round();

        final pageImage = await page.render(
          width: targetWidth.toDouble(),
          height: targetHeight.toDouble(),
          format: pdfx.PdfPageImageFormat.jpeg,
          backgroundColor: '#FFFFFF',
          quality: 90,
        ); // returns PdfPageImage?[web:131]

        if (pageImage != null) {
          pages.add(pageImage.bytes); // Uint8List JPEG bytes.[web:131]
        }

        await page.close();
      }
    } finally {
      await doc.close();
    }

    return pages;
  }

  /// 2. Compress each page image using `flutter_image_compress`.
  ///
  /// - Resize width to ~1400px (within 1200–1500px target).
  /// - Compress to WebP at quality 80 on disk, then read bytes.
  static Future<Uint8List> _compressImage(Uint8List inputBytes) async {
    final decoded = img.decodeImage(inputBytes);
    if (decoded == null) {
      return inputBytes;
    }

    const targetWidth = 1400;
    final resized = img.copyResize(
      decoded,
      width: targetWidth,
      interpolation: img.Interpolation.average,
    );

    final tempDir = await getTemporaryDirectory();
    final tempInput = File(
      p.join(
        tempDir.path,
        'page_input_${DateTime.now().microsecondsSinceEpoch}.png',
      ),
    );
    final tempOutputPath = p.join(
      tempDir.path,
      'page_output_${DateTime.now().microsecondsSinceEpoch}.webp',
    );

    // Write intermediate PNG for the compressor.
    await tempInput.writeAsBytes(img.encodePng(resized));

    final compressed = await FlutterImageCompress.compressAndGetFile(
      tempInput.path,
      tempOutputPath,
      quality: 80,
      format: CompressFormat.webp,
    ); // Returns XFile.[web:13]

    // Remove temp input ASAP.
    await tempInput.delete().catchError((_) {});

    if (compressed == null) {
      // Fallback: JPEG in-memory if plugin fails.
      final fallback = img.encodeJpg(resized, quality: 80);
      return Uint8List.fromList(fallback);
    }

    final outBytes = await compressed.readAsBytes();
    // XFile has no delete(); delete via File(path).
    await File(compressed.path).delete().catchError((_) {});
    return outBytes;
  }

  /// 3. Apply watermark using the `image` package.
  ///
  /// Supports either text or image-based watermark, optionally in a grid.
  static Future<Uint8List> _applyWatermark(
    Uint8List inputBytes, {
    String? watermarkText,
    String? watermarkImagePath,
    required bool isGridPattern,
  }) async {
    final decoded = img.decodeImage(inputBytes);
    if (decoded == null) {
      return inputBytes;
    }

    // Work on a clone of the decoded image.
    final canvas = decoded.clone();

    if (watermarkImagePath != null && watermarkImagePath.isNotEmpty) {
      final wmFile = File(watermarkImagePath);
      if (await wmFile.exists()) {
        final wmBytes = await wmFile.readAsBytes();
        final wmImg = img.decodeImage(wmBytes);
        if (wmImg != null) {
          _drawImageWatermark(canvas, wmImg, isGridPattern: isGridPattern);
        }
      }
    } else if (watermarkText != null && watermarkText.isNotEmpty) {
      _drawTextWatermark(canvas, watermarkText, isGridPattern: isGridPattern);
    }

    // Re-encode as JPEG (PDF-friendly, good compression).
    final encoded = img.encodeJpg(canvas, quality: 80);
    return Uint8List.fromList(encoded);
  }

  /// Draw text watermark on the given canvas.
  ///
  /// Uses built-in arial48 font and semi-transparent black color.[web:36][web:1]
  static void _drawTextWatermark(
    img.Image canvas,
    String text, {
    required bool isGridPattern,
  }) {
    final font = img.arial48; // Built-in BitmapFont.[web:36]
    // Light gray, low alpha so underlying text stays readable.
    final color = img.ColorUint8.rgba(0, 0, 0, 40); // Semi-transparent black.

    // Create a transparent layer to draw the text on, so we can rotate it.
    img.Image makeTextStamp(String text) {
      // Use a relatively small stamp so it behaves like a watermark,
      // not a full block.
      final stampWidth = (canvas.width * 0.35).round();
      final stampHeight = (canvas.height * 0.10).round();
      final stamp = img.Image(width: stampWidth, height: stampHeight);

      // Fill with transparent background.
      img.fill(stamp, color: img.ColorUint8.rgba(0, 0, 0, 0));

      // Draw text with some padding; exact centering is not critical.
      const padding = 8;
      final textX = padding;
      final textY = (stampHeight / 2 - 24)
          .round(); // approximate half of 48px font

      img.drawString(stamp, text, font: font, x: textX, y: textY, color: color);

      // Rotate the whole stamp by -45 degrees for diagonal watermark.
      return img.copyRotate(stamp, angle: -45);
    }

    final stamp = makeTextStamp(text);

    void drawStampAt(int x, int y) {
      img.compositeImage(canvas, stamp, dstX: x, dstY: y);
    }

    if (isGridPattern) {
      // Wider spacing so the pattern does not look like a solid block.
      final spacingX = (stamp.width * 2.5).round();
      final spacingY = (stamp.height * 2.5).round();
      for (
        int x = -stamp.width;
        x < canvas.width + stamp.width;
        x += spacingX
      ) {
        for (
          int y = -stamp.height;
          y < canvas.height + stamp.height;
          y += spacingY
        ) {
          drawStampAt(x, y);
        }
      }
    } else {
      final centerX = (canvas.width - stamp.width) ~/ 2;
      final centerY = (canvas.height - stamp.height) ~/ 2;
      drawStampAt(centerX, centerY);
    }
  }

  /// Draw an image watermark (PNG, etc.) onto the canvas.
  static void _drawImageWatermark(
    img.Image canvas,
    img.Image watermark, {
    required bool isGridPattern,
  }) {
    // Scale watermark to ~20% of page width so it is subtle.
    const scale = 0.2;
    final targetWidth = (canvas.width * scale).round();
    final resized = img.copyResize(watermark, width: targetWidth);

    // Rotate the image watermark by -45 degrees to match text style.
    final rotated = img.copyRotate(resized, angle: -45);

    void drawAt(int x, int y) {
      img.compositeImage(canvas, rotated, dstX: x, dstY: y);
    }

    if (isGridPattern) {
      final spacingX = (rotated.width * 2.5).round();
      final spacingY = (rotated.height * 2.5).round();
      for (
        int x = -rotated.width;
        x < canvas.width + rotated.width;
        x += spacingX
      ) {
        for (
          int y = -rotated.height;
          y < canvas.height + rotated.height;
          y += spacingY
        ) {
          drawAt(x, y);
        }
      }
    } else {
      final x = (canvas.width - rotated.width) ~/ 2;
      final y = (canvas.height - rotated.height) ~/ 2;
      drawAt(x, y);
    }
  }

  /// 4. Rebuild a new PDF from processed images.
  ///
  /// Each page is a single full-bleed raster image (flattened).
  static Future<Uint8List> _rebuildPdf(List<Uint8List> pages) async {
    final doc = pw_widgets.Document();

    for (final bytes in pages) {
      final mem = pw_widgets.MemoryImage(bytes);

      doc.addPage(
        pw_widgets.Page(
          pageFormat: pw.PdfPageFormat.a4,
          build: (_) => pw_widgets.Image(mem, fit: pw_widgets.BoxFit.cover),
        ),
      );
    }

    return doc.save();
  }

  /// 5. Save output PDF to a writable directory.
  static Future<File> _saveOutputPdf(File inputPdf, Uint8List bytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final name = p.basenameWithoutExtension(inputPdf.path);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final outputPath = p.join(
      directory.path,
      '${name}_watermarked_$timestamp.pdf',
    );

    final outFile = File(outputPath);
    await outFile.writeAsBytes(bytes, flush: true);
    return outFile;
  }
}
