import 'package:flutter/material.dart';
import 'dart:typed_data';

/// A reusable thumbnail widget for displaying PDF pages
/// with optional rotate, remove, and selection controls
class PdfPageThumbnail extends StatelessWidget {
  final int pageNum;
  final bool isSelected;
  final Uint8List? thumbnailBytes;
  final double rotation;
  final VoidCallback? onToggle;
  final VoidCallback? onRotate;
  final VoidCallback? onRemove;
  final VoidCallback? onTap;
  final bool isRemoved;
  final bool showRotateButton;
  final bool showRemoveButton;
  final bool showSelectButton;

  const PdfPageThumbnail({
    super.key,
    required this.pageNum,
    required this.isSelected,
    required this.thumbnailBytes,
    this.rotation = 0.0,
    this.onToggle,
    this.onRotate,
    this.onRemove,
    this.onTap,
    this.isRemoved = false,
    this.showRotateButton = true,
    this.showRemoveButton = false,
    this.showSelectButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.hardEdge,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isRemoved
                ? Colors.red
                : isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.3),
            width: isSelected || isRemoved ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isRemoved
              ? Colors.red.withValues(alpha: 0.08)
              : isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
              : theme.colorScheme.surface,
        ),
        child: Column(
          children: [
            // Header with page number and buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isRemoved
                    ? Colors.red.withValues(alpha: 0.15)
                    : isSelected
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(11),
                  topRight: Radius.circular(11),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Page $pageNum',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isRemoved
                            ? Colors.red
                            : isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showRemoveButton && onRemove != null)
                        Material(
                          color: isRemoved
                              ? Colors.red.withValues(alpha: 0.9)
                              : theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: onRemove,
                            borderRadius: BorderRadius.circular(16),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      if (showRemoveButton && onRemove != null)
                        const SizedBox(width: 4),
                      if (showRotateButton && onRotate != null)
                        Material(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: onRotate,
                            borderRadius: BorderRadius.circular(16),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.rotate_right,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      if (showRotateButton && onRotate != null)
                        const SizedBox(width: 4),
                      if (showSelectButton && onToggle != null)
                        Material(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: onToggle,
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Icon(
                                isSelected
                                    ? Icons.check_circle
                                    : Icons.circle_outlined,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            // Thumbnail
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: thumbnailBytes != null
                    ? LayoutBuilder(
                        builder: (context, constraints) {
                          return Center(
                            child: GestureDetector(
                              onTap: onTap,
                              child: ClipRect(
                                child: Align(
                                  alignment: Alignment.center,
                                  child: Transform.rotate(
                                    angle: rotation * 3.14159 / 180,
                                    child: Image.memory(
                                      thumbnailBytes!,
                                      fit: BoxFit.contain,
                                      width: constraints.maxWidth,
                                      height: constraints.maxHeight,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            theme.colorScheme.primary,
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
