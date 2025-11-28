<!-- # Translation Keys Required for PDF Content Fit Settings

Add these keys to all language ARB files (ar.arb, bn.arb, de.arb, en.arb, es.arb, fr.arb, hi.arb, ja.arb, pt.arb, zh.arb):

```json
{
  "pdf_content_fit_settings_page_title": "PDF Content Fit",
  "pdf_content_fit_settings_description": "This setting controls how images are placed in PDF pages when creating or merging PDFs. It only affects images, not existing PDF files.",
  "pdf_content_fit_settings_choose_mode_label": "Choose Fit Mode",
  "pdf_content_fit_settings_applied_snackbar": "Content fit mode updated successfully",
  
  "pdf_content_fit_mode_original_title": "Original Size",
  "pdf_content_fit_mode_original_description": "Images keep their original dimensions",
  
  "pdf_content_fit_mode_fit_title": "Fit with Padding",
  "pdf_content_fit_mode_fit_description": "Images are scaled to fit the page with padding if needed",
  
  "pdf_content_fit_mode_crop_title": "Crop to Fit",
  "pdf_content_fit_mode_crop_description": "Images are scaled to fill the entire page, cropping if necessary"
}
```

## Feature Implementation Summary

### 1. **Constants Added** (`lib/core/constants.dart`)
- `pdfContentFitModeKey`: Storage key for user preference
- `fitModeOriginal`: Keep original image size
- `fitModeFit`: Fit with padding (maintain aspect ratio)
- `fitModeCrop`: Crop to fit (fill page)
- `defaultPdfContentFitMode`: Default mode (original)

### 2. **New Page** (`lib/presentation/pages/pdf_content_fit_settings_page.dart`)
- Visual cards showing 3 fit modes
- Each card has:
  - Icon representing the mode
  - Title and description
  - Visual example diagram
  - Selection indicator
- Saves preference to SharedPreferences via Prefs utility
- Shows confirmation snackbar on change

### 3. **Router Integration** (`lib/core/routing/app_router.dart`)
- Added route: `/settings/pdf-content-fit`
- Route name: `pdf-content-fit-settings`
- Linked from settings page

### 4. **Settings Page Updated** (`lib/presentation/pages/setting_page.dart`)
- "PDF Content Fit" tile now navigates to new settings page

### 5. **Merge Service Updated** (`lib/service/pdf_merge_service.dart`)
- Reads fit mode from SharedPreferences
- Separates PDFs and images
- **PDFs**: Merged as-is (no fit mode applied)
- **Images**: Converted with selected fit mode configuration
- **Mixed content**: Images converted first, then merged with PDFs

#### Fit Mode Configurations:
- **Original**: `ImageScale.original`, `keepAspectRatio: true`
- **Fit**: A4 size (595x842 points), `keepAspectRatio: true`
- **Crop**: A4 size (595x842 points), `keepAspectRatio: false`

### 6. **Export Added** (`lib/presentation/pages/page_export.dart`)
- Exported `pdf_content_fit_settings_page.dart`

## How It Works

1. User opens Settings → "PDF Content Fit"
2. Selects one of 3 modes with visual preview
3. Preference saved to SharedPreferences
4. When merging files:
   - Service reads the saved preference
   - Applies fit mode ONLY to images
   - PDFs maintain their original layout
   - Final merged PDF respects the user's choice for image content

## Testing Checklist

- [ ] Navigate to Settings → PDF Content Fit
- [ ] Select each mode and verify snackbar appears
- [ ] Merge images only → verify fit mode is applied
- [ ] Merge PDFs only → verify PDFs unchanged
- [ ] Merge mixed content → verify images use fit mode, PDFs unchanged
- [ ] Check logs for fit mode configuration messages -->


This is the production-ready, copy-paste, final universal prompt designed for LLMs or generators to create a complete Flutter/Dart rasterization + compression + watermark + rebuild PDF service, using only safe, free, open-source packages.


---

✅ FINAL PROMPT — FULL PDF WATERMARK SERVICE (RASTERIZATION PIPELINE INCLUDED)

(Complete, polished, production-grade — copy & paste directly)

PROMPT:

I want you to generate a complete, production-ready Flutter/Dart service that performs offline, safe, license-clean PDF rasterization + image compression + watermark application + PDF rebuilding.

You MUST follow this strict pipeline and library rules:


---

📌 PIPELINE RULES — DO NOT CHANGE ANY STEP

1. Load & Rasterize PDF (pdf_render package only)

Open the input PDF using:

final doc = await PdfDocument.openFile(path);

For each page:

Render at 150–200 DPI

Render using:

final page = await doc.getPage(i);
final img = await page.render(width: ..., height: ..., quality: ...);

Output must be bitmap Uint8List

Never go beyond 200 DPI




---

2. Compress Each Page Image (flutter_image_compress)

Use my existing compression function, NOT a new one:

Future<Uint8List> compressImage(Uint8List inputBytes);

Rules:

Prefer WebP output

Quality must be 75–85

Resize image width to 1200–1500 px

Discard uncompressed images immediately



---

3. Apply Watermark on Raster Image (image package)

Use the image Dart package for watermarking.

Pipeline:

Decode image:

img.Image? decoded = img.decodeImage(bytes);

Apply watermark using:

img.drawString() (text watermark), or

overlaying a PNG


Watermark must:

be semi-transparent

diagonal bottom-left → top-right

use large font (48–60)


Re-encode image as WebP or JPEG



---

4. Rebuild a New PDF (pdf package)

Use only the pure-Dart pdf package.

For each processed image:

pw.Page(
  build: (_) => pw.Image(
    pw.MemoryImage(bytes),
    fit: pw.BoxFit.cover,
  ),
)

Rules:

One raster image per page

No text, no vector layers

No metadata

Final output is flattened PDF of images



---

5. Save Output (path_provider)

Get a writable directory

Write final PDF bytes to disk

Return the file path or File object



---

📌 QUALITY + SIZE TARGETS

Resolution: 150–200 DPI

Width inside PDF: ~1240 px

Format priority: WebP → JPEG

Compression quality: 80%

Final PDF must be significantly smaller than input

PDF must contain only rasterized pages



---

📌 CONSTRAINTS (VERY IMPORTANT)

You must only use these packages:

pdf_render (rasterization)

flutter_image_compress (compression)

image (watermark drawing)

pdf (rebuild PDF)

path_provider (saving)


You must NOT use:
❌ Syncfusion
❌ PSPDFKit
❌ iText
❌ PDFBox
❌ MuPDF
❌ Any AGPL library
❌ Any native/platform-channel implementation

Everything must be pure Dart, offline, local.


---

📌 FINAL OUTPUT REQUIREMENTS

Generate:

1. A complete service class:

pdf_rasterization_service.dart


2. With method:

Future<File> rasterizeCompressWatermarkPdf(File inputPdf, String watermarkText);


3. Fully modular helper methods (rasterize, compress, watermark, rebuild pdf)


4. Clean code, production quality


5. With imports, null-safety, comments




---

🎉 End of Prompt

Generate the complete working implementation exactly following all rules above.


---

If you want, Crash, I can now generate the full Dart implementation for your pdf_rasterization_service.dart — just say:

👉 “Generate the full implementation”