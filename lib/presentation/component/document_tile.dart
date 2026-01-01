import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf_kit/presentation/widget/shimmer.dart';
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf_kit/service/pdf_protect_service.dart';

class _Thumb {
  final Uint8List bytes;
  final int width;
  final int height;
  const _Thumb(this.bytes, this.width, this.height);
}

class DocEntryCard extends StatefulWidget {
  final FileInfo info;
  final VoidCallback? onOpen;
  final ValueChanged<String>? onMenu;
  final bool selectable;
  final bool selected;
  final VoidCallback? onToggleSelected;
  final VoidCallback? onLongPress;
  final bool showRemove;
  final bool showEdit;
  final bool showVertOption;
  final VoidCallback? onEdit;
  final VoidCallback? onRemove;
  final bool reorderable;
  final bool disabled;

  const DocEntryCard({
    super.key,
    required this.info,
    this.onOpen,
    this.onMenu,
    this.selectable = false,
    this.selected = false,
    this.onToggleSelected,
    this.onLongPress,
    this.showRemove = false,
    this.showEdit = false,
    this.showVertOption = true,
    this.onEdit,
    this.onRemove,
    this.reorderable = false,
    this.disabled = false,
  });

  @override
  State<DocEntryCard> createState() => _DocEntryCardState();
}

class _DocEntryCardState extends State<DocEntryCard> {
  static final Map<String, _Thumb> _cache = {};
  late Future<_Thumb?> _thumbnailFuture; // Cache the future itself

  bool get _isPdf => widget.info.extension.toLowerCase() == 'pdf';
  bool get _isImage => const {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'heic',
    'heif',
  }.contains(widget.info.extension.toLowerCase());

  int? _pageCount; // for PDFs only

  @override
  void initState() {
    super.initState();
    _thumbnailFuture = _thumbnail(); // Initialize once
  }

  @override
  void didUpdateWidget(DocEntryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only recreate future if the file path changes
    if (oldWidget.info.path != widget.info.path) {
      _thumbnailFuture = _thumbnail();
    }
  }

  Future<_Thumb?> _thumbnail() async {
    final key = widget.info.path;
    if (_cache.containsKey(key)) return _cache[key];

    if (_isPdf) {
      debugPrint(
        '📑 [DocEntryCard] Opening PDF to get page count and thumbnail: $key',
      );

      final doc = await PdfDocument.openFile(widget.info.path);
      debugPrint(
        '✅ [DocEntryCard] PdfDocument opened: $key, pagesCount=${doc.pagesCount}',
      );

      _pageCount = doc.pagesCount; // pdfx provides this
      // Trigger a rebuild so the page count row updates
      if (mounted) {
        debugPrint(
          '🔄 [DocEntryCard] setState after setting _pageCount=$_pageCount for: $key',
        );

        setState(() {});
      }
      final page = await doc.getPage(1);

      // Safe thumbnail rendering - target max 200px to prevent OOM crashes
      // Never render at native PDF resolution (can be 28000×20000px!)
      const thumbSize = 200.0;

      // Calculate aspect-ratio safe render size
      final aspect = page.width / page.height;
      double renderW, renderH;

      if (aspect >= 1) {
        // Landscape or square
        renderW = thumbSize;
        renderH = thumbSize / aspect;
      } else {
        // Portrait
        renderH = thumbSize;
        renderW = thumbSize * aspect;
      }

      debugPrint(
        '🖼️ [DocEntryCard] Rendering PDF thumbnail: '
        '${renderW.toInt()}×${renderH.toInt()}px '
        '(original: ${page.width.toInt()}×${page.height.toInt()})',
      );

      final img = await page.render(width: renderW, height: renderH);
      await page.close();
      await doc.close();
      if (img == null) return null;

      // Store actual rendered dimensions, not original page size
      final t = _Thumb(img.bytes, renderW.toInt(), renderH.toInt());
      _cache[key] = t;
      return t;
    }

    if (_isImage) {
      final bytes = await File(widget.info.path).readAsBytes();
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final desc = await ui.ImageDescriptor.encoded(buffer);
      final t = _Thumb(bytes, desc.width, desc.height);
      desc.dispose();
      buffer.dispose();
      _cache[key] = t;
      return t;
    }

    return null;
  }

  String _recent() {
    final dt = widget.info.lastModified ?? DateTime.now();
    // 12‑hour format with AM/PM, e.g. 11/23/2025  10:45 PM
    return DateFormat('MM/dd/yyyy  hh:mm a').format(dt);
  }

  void _share() {
    SharePlus.instance.share(
      ShareParams(files: [XFile(widget.info.path)], text: widget.info.name),
    );
  }

  Future<void> _handleTap(BuildContext context) async {
    if (widget.disabled) return;

    if (_isPdf) {
      final isProtectedResult = await PdfProtectionService.isPdfProtected(
        pdfPath: widget.info.path,
      );

      bool isProtected = false;
      isProtectedResult.fold(
        (l) => isProtected = false,
        (r) => isProtected = r,
      );

      if (isProtected) {
        if (mounted) {
          await OpenFilex.open(widget.info.path);
        }
        return;
      }
    }

    // Route both PDFs (unprotected) and images to the viewer page
    if (_isPdf || _isImage) {
      if (!mounted) return;
      context.pushNamed(
        AppRouteName.pdfViewer,
        queryParameters: {'path': widget.info.path},
      );
    } else {
      // For other file types, use the original onOpen callback
      widget.onOpen?.call();
    }
  }

  void _handleThumbnailTap(BuildContext context) {
    if (widget.disabled) return;
    // Thumbnail tap always opens the viewer, even in selection mode
    _handleTap(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    debugPrint(
      '🎨 [DocEntryCard] build(): ${widget.info.name} '
      '(path=${widget.info.path}, isPdf=$_isPdf, pageCount=$_pageCount)',
    );

    return Material(
      borderRadius: BorderRadius.circular(12),
      color: Colors.black.withAlpha(widget.disabled ? 12 : 28),
      shadowColor: Colors.black.withAlpha(28),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: widget.disabled
            ? null
            : widget.selectable
            ? widget.onToggleSelected
            : () => _handleTap(context),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(vertical: 6) +
              EdgeInsets.only(left: 0, right: 12),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 12, left: 12),
                child: InkWell(
                  // In selectable mode, thumbnail opens viewer; otherwise handled by parent
                  onTap: widget.selectable && !widget.disabled
                      ? () => _handleThumbnailTap(context)
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: FutureBuilder<_Thumb?>(
                    future: _thumbnailFuture, // Use the cached future
                    builder: (context, snap) {
                      Widget child;
                      if (snap.connectionState == ConnectionState.waiting) {
                        child = const Center(
                          child: SizedBox(
                            width: 56,
                            height: 56,
                            child: ShimmerBox(
                              height: 56,
                              width: 56,
                              borderRadius: BorderRadiusGeometry.all(
                                Radius.circular(10),
                              ),
                            ),
                          ),
                        );
                      } else if (snap.data != null) {
                        final t = snap.data!;
                        final fit = (t.height < t.width)
                            ? BoxFit.fitWidth
                            : BoxFit.fitHeight;

                        child = ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox.square(
                            dimension: 56,
                            child: Stack(
                              children: [
                                // Thumbnail
                                Positioned.fill(
                                  child: Image.memory(
                                    t.bytes,
                                    fit: fit,
                                    cacheWidth: 140,
                                    cacheHeight: 140,
                                  ),
                                ),

                                // Extension badge (top‑left)
                                Positioned(
                                  top: 4,
                                  left: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 2.5,
                                      vertical: 1,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(
                                        0.6,
                                      ), // not pure black
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: Text(
                                      widget.info.extension.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),

                                // Eye icon overlay in selectable mode
                                if (widget.selectable)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withAlpha(23 * 3),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.visibility_outlined,
                                        color: Colors.white.withAlpha(23 * 5),
                                        size: 28,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        child = Container(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          width: 56,
                          height: 56,
                          child: Icon(
                            _isPdf
                                ? Icons.picture_as_pdf
                                : Icons.image_outlined,
                            size: 34,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        );
                      }
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: child,
                      );
                    },
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.info.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _recent(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(153),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sd_storage,
                              size: 12,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withAlpha(153),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.info.readableSize,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withAlpha(153),
                                  ),
                            ),
                          ],
                        ),
                        if (_isPdf && _pageCount != null) ...[
                          const SizedBox(width: 12),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_stories,
                                size: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(153),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_pageCount} page${_pageCount == 1 ? '' : 's'}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withAlpha(153),
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              if (widget.reorderable)
                Padding(
                  padding: const EdgeInsets.only(right: 8, left: 8),
                  child: Icon(
                    Icons.drag_indicator,
                    color: Theme.of(context).colorScheme.onSurfaceVariant
                        .withOpacity(widget.disabled ? 0.3 : 1.0),
                  ),
                )
              else if (widget.selectable)
                Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: InkResponse(
                    onTap: widget.disabled ? null : widget.onToggleSelected,
                    child: Icon(
                      widget.selected
                          ? Icons.check_box
                          : Icons.check_box_outline_blank,
                      color: widget.disabled
                          ? Theme.of(context).iconTheme.color?.withOpacity(0.4)
                          : null,
                    ),
                  ),
                )
              else if (widget.showEdit || widget.showRemove)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.showEdit && widget.onEdit != null)
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: widget.disabled ? null : widget.onEdit,
                        tooltip: t.t('doc_menu_edit'),
                      ),
                    if (widget.showRemove && widget.onRemove != null)
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: widget.disabled ? null : widget.onRemove,
                        tooltip: t.t('doc_menu_remove'),
                        color: Theme.of(context).colorScheme.error,
                      ),
                  ],
                )
              else if (widget.showVertOption)
                (widget.disabled
                    ? Icon(
                        Icons.more_vert,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant.withOpacity(0.3),
                      )
                    : PopupMenuButton<String>(
                        onSelected: widget.onMenu,
                        itemBuilder: (c) => [
                          PopupMenuItem(
                            value: 'open',
                            child: Text(t.t('doc_menu_open')),
                          ),
                          PopupMenuItem(
                            value: 'rename',
                            child: Text(t.t('doc_menu_rename')),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(t.t('doc_menu_delete')),
                          ),
                          PopupMenuItem(
                            value: 'share',
                            onTap: () {
                              _share();
                            },
                            child: Text(t.t('doc_menu_share')),
                          ),
                        ],
                      )),
            ],
          ),
        ),
      ),
    );
  }
}
