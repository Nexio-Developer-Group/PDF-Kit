import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_kit/core/localization/app_localizations.dart';

/// Shows a modal bottom sheet with PDF info and action options:
/// - Preview image (thumbnail of first page)
/// - File name, location, size, page count
/// - Actions: rename, delete, split, protect/unlock, compress
Future<void> showPdfOptionsSheet({
  required BuildContext context,
  required String pdfPath,
  bool? isPdf,
  VoidCallback? onRename,
  VoidCallback? onDelete,
  VoidCallback? onSplit,
  VoidCallback? onProtect,
  VoidCallback? onCompress,
  VoidCallback? onMergePdf,
  VoidCallback? onImagesToPdf,
  VoidCallback? onPdfToImage,
  VoidCallback? onReorder,
  VoidCallback? onMoveToFolder,
}) {
  debugPrint('[PdfOptionsSheet] Opening for path="$pdfPath"');

  final detectedIsPdf = p.extension(pdfPath).toLowerCase() == '.pdf';

  return showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return _PdfOptionsSheetContent(
        pdfPath: pdfPath,
        isPdf: isPdf ?? detectedIsPdf,
        onRename: onRename,
        onDelete: onDelete,
        onSplit: onSplit,
        onProtect: onProtect,
        onCompress: onCompress,
        onMergePdf: onMergePdf,
        onImagesToPdf: onImagesToPdf,
        onPdfToImage: onPdfToImage,
        onReorder: onReorder,
        onMoveToFolder: onMoveToFolder,
      );
    },
  ).whenComplete(() => debugPrint('[PdfOptionsSheet] Closed'));
}

class _PdfOptionsSheetContent extends StatefulWidget {
  final String pdfPath;
  final bool isPdf;
  final VoidCallback? onRename;
  final VoidCallback? onDelete;
  final VoidCallback? onSplit;
  final VoidCallback? onProtect;
  final VoidCallback? onCompress;
  final VoidCallback? onMergePdf;
  final VoidCallback? onImagesToPdf;
  final VoidCallback? onPdfToImage;
  final VoidCallback? onReorder;
  final VoidCallback? onMoveToFolder;

  const _PdfOptionsSheetContent({
    required this.pdfPath,
    required this.isPdf,
    this.onRename,
    this.onDelete,
    this.onSplit,
    this.onProtect,
    this.onCompress,
    this.onMergePdf,
    this.onImagesToPdf,
    this.onPdfToImage,
    this.onReorder,
    this.onMoveToFolder,
  });

  @override
  State<_PdfOptionsSheetContent> createState() =>
      _PdfOptionsSheetContentState();
}

class _PdfOptionsSheetContentState extends State<_PdfOptionsSheetContent> {
  late final File _file;
  String? _fileName;
  String? _location;
  int? _sizeBytes;
  int? _pageCount;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _file = File(widget.pdfPath);
    _loadFileInfo();
  }

  Future<void> _loadFileInfo() async {
    try {
      final stat = await _file.stat();
      final name = p.basename(widget.pdfPath);
      final dir = p.dirname(widget.pdfPath);
      final size = stat.size;
      // For page count, you'd typically parse the PDF or use a library
      // For now, placeholder:
      final pageCount = widget.isPdf ? 0 : null; // Replace with actual logic

      setState(() {
        _fileName = name;
        _location = dir;
        _sizeBytes = size;
        _pageCount = pageCount;
        _loading = false;
      });
    } catch (e) {
      debugPrint('[PdfOptionsSheet] Failed to load file info: $e');
      setState(() {
        _loading = false;
      });
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  void _invokeAction(VoidCallback? callback) {
    Navigator.of(context).pop();
    callback?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    final isPdf = widget.isPdf;

    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Container(
            color: theme.dialogBackgroundColor,
            child: Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 20,
                top: 10,
                bottom: 16,
              ),
              child: _loading
                  ? const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Drag handle
                        Container(
                          width: 48,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.18,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),

                        // Preview thumbnail (placeholder)
                        Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: isPdf
                                ? const Icon(
                                    Icons.picture_as_pdf,
                                    size: 48,
                                    color: Colors.red,
                                  )
                                : const Icon(
                                    Icons.image,
                                    size: 48,
                                    color: Colors.blueGrey,
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // File name
                        Text(
                          _fileName ?? 'Unknown',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Location
                        Text(
                          _location ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Size & page count
                        Text(
                          isPdf
                              ? '${_sizeBytes != null ? _formatBytes(_sizeBytes!) : 'Unknown size'} • ${_pageCount ?? 0} pages'
                              : (_sizeBytes != null
                                    ? _formatBytes(_sizeBytes!)
                                    : 'Unknown size'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Divider(
                          height: 1,
                          color: theme.dividerColor.withAlpha(64),
                        ),
                        const SizedBox(height: 8),

                        // Actions list
                        if (widget.onRename != null)
                          _ActionTile(
                            icon: Icons.edit,
                            label: t.t('pdf_options_rename'),
                            onTap: () => _invokeAction(widget.onRename),
                          ),
                        if (widget.onDelete != null)
                          _ActionTile(
                            icon: Icons.delete,
                            label: t.t('pdf_options_delete'),
                            onTap: () => _invokeAction(widget.onDelete),
                          ),
                        if (isPdf)
                          _ActionTile(
                            icon: Icons.content_cut,
                            label: t.t('pdf_options_split'),
                            onTap: () => _invokeAction(widget.onSplit),
                          ),
                        if (isPdf)
                          _ActionTile(
                            icon: Icons.lock,
                            label: t.t('pdf_options_protect'),
                            onTap: () => _invokeAction(widget.onProtect),
                          ),
                        if (isPdf)
                          _ActionTile(
                            icon: Icons.compress,
                            label: t.t('pdf_options_compress'),
                            onTap: () => _invokeAction(widget.onCompress),
                          ),
                        if (widget.onMergePdf != null)
                          _ActionTile(
                            icon: Icons.merge_type,
                            label: t.t('action_merge_label'),
                            onTap: () => _invokeAction(widget.onMergePdf),
                          ),
                        if (!isPdf && widget.onImagesToPdf != null)
                          _ActionTile(
                            icon: Icons.picture_as_pdf,
                            label: t.t('action_images_to_pdf_label'),
                            onTap: () => _invokeAction(widget.onImagesToPdf),
                          ),
                        if (isPdf && widget.onPdfToImage != null)
                          _ActionTile(
                            icon: Icons.image,
                            label: t.t('action_pdf_to_image_label'),
                            onTap: () => _invokeAction(widget.onPdfToImage),
                          ),
                        if (isPdf && widget.onReorder != null)
                          _ActionTile(
                            icon: Icons.reorder,
                            label: t.t('action_reorder_label'),
                            onTap: () => _invokeAction(widget.onReorder),
                          ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }
}
