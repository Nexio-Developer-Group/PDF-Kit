import 'package:flutter/material.dart';
import 'package:pdf_kit/core/app_export.dart';

/// A breadcrumb navigation widget for file paths
/// Displays clickable path segments as chips for easy navigation
class BreadcrumbWidget extends StatefulWidget {
  final String path;
  final bool isFullscreenRoute;
  final String? selectionId;
  final String? selectionActionText;

  const BreadcrumbWidget({
    super.key,
    required this.path,
    this.isFullscreenRoute = false,
    this.selectionId,
    this.selectionActionText,
  });

  @override
  State<BreadcrumbWidget> createState() => _BreadcrumbWidgetState();
}

class _BreadcrumbWidgetState extends State<BreadcrumbWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Auto-scroll to end after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void didUpdateWidget(BreadcrumbWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-scroll to end when path changes
    if (oldWidget.path != widget.path) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final segments = _buildBreadcrumbSegments(widget.path);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      controller: _scrollController,
      child: Row(
        children: [
          // Home icon at the start
          _HomeButton(
            isFullscreenRoute: widget.isFullscreenRoute,
            selectionId: widget.selectionId,
            selectionActionText: widget.selectionActionText,
          ),

          // Separator
          if (segments.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Theme.of(
                  context,
                ).textTheme.bodySmall?.color?.withOpacity(0.5),
              ),
            ),

          // Breadcrumb chips
          for (int i = 0; i < segments.length; i++) ...[
            _BreadcrumbChip(
              label: segments[i].label,
              path: segments[i].path,
              isLast: i == segments.length - 1,
              isFullscreenRoute: widget.isFullscreenRoute,
              selectionId: widget.selectionId,
              selectionActionText: widget.selectionActionText,
            ),
            if (i < segments.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Theme.of(
                    context,
                  ).textTheme.bodySmall?.color?.withOpacity(0.5),
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// Parse path into breadcrumb segments
  List<_BreadcrumbSegment> _buildBreadcrumbSegments(String path) {
    final segments = <_BreadcrumbSegment>[];

    // Split path into parts
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();

    if (parts.isEmpty) {
      return [];
    }

    // Check if this is internal storage path (/storage/emulated/0)
    if (parts.length >= 3 &&
        parts[0] == 'storage' &&
        parts[1] == 'emulated' &&
        parts[2] == '0') {
      // Build path for internal storage root
      final internalStoragePath = '/storage/emulated/0';
      segments.add(
        _BreadcrumbSegment(
          label: 'Internal storage',
          path: internalStoragePath,
        ),
      );

      // Add remaining folders after internal storage
      String currentPath = internalStoragePath;
      for (int i = 3; i < parts.length; i++) {
        currentPath += '/${parts[i]}';
        segments.add(_BreadcrumbSegment(label: parts[i], path: currentPath));
      }
    } else {
      // For other paths (SD card, etc.), build normally
      String currentPath = '';
      for (int i = 0; i < parts.length; i++) {
        currentPath += '/${parts[i]}';
        segments.add(_BreadcrumbSegment(label: parts[i], path: currentPath));
      }
    }

    return segments;
  }
}

/// Home icon button for navigating to root
class _HomeButton extends StatelessWidget {
  final bool isFullscreenRoute;
  final String? selectionId;
  final String? selectionActionText;

  const _HomeButton({
    required this.isFullscreenRoute,
    this.selectionId,
    this.selectionActionText,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _navigateToRoot(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          Icons.home_rounded,
          size: 20,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }

  void _navigateToRoot(BuildContext context) {
    // Navigate back to files root page (storage selection)
    final routeName = isFullscreenRoute
        ? AppRouteName.filesRootFullscreen
        : AppRouteName.filesRoot;

    final params = <String, String>{};
    if (selectionId != null) {
      params['selectionId'] = selectionId!;
    }
    if (selectionActionText != null) {
      params['actionText'] = selectionActionText!;
    }

    context.goNamed(routeName, queryParameters: params);
  }
}

/// Individual breadcrumb chip
class _BreadcrumbChip extends StatelessWidget {
  final String label;
  final String path;
  final bool isLast;
  final bool isFullscreenRoute;
  final String? selectionId;
  final String? selectionActionText;

  const _BreadcrumbChip({
    required this.label,
    required this.path,
    required this.isLast,
    required this.isFullscreenRoute,
    this.selectionId,
    this.selectionActionText,
  });

  @override
  Widget build(BuildContext context) {
    final isPrimary = isLast;
    final backgroundColor = isPrimary
        ? Theme.of(context).colorScheme.primaryContainer
        : Theme.of(context).colorScheme.surfaceContainerLow;
    final textColor = isPrimary
        ? Theme.of(context).colorScheme.onPrimaryContainer
        : Theme.of(context).colorScheme.onSurfaceVariant;

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: textColor,
          fontWeight: isPrimary ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );

    if (isLast) {
      // Current folder - not clickable
      return chip;
    }

    // Parent folder - clickable
    return InkWell(
      onTap: () => _navigateToPath(context),
      borderRadius: BorderRadius.circular(20),
      child: chip,
    );
  }

  void _navigateToPath(BuildContext context) {
    // Determine the correct route name
    final routeName = isFullscreenRoute
        ? AppRouteName.filesFolderFullScreen
        : AppRouteName.filesFolder;

    // Build query parameters
    final params = <String, String>{'path': path};
    if (selectionId != null) {
      params['selectionId'] = selectionId!;
    }
    if (selectionActionText != null) {
      params['actionText'] = selectionActionText!;
    }

    // Use go() instead of pushNamed() to replace current route
    // This properly manages the navigation stack
    context.goNamed(routeName, queryParameters: params);
  }
}

/// Data class for breadcrumb segment
class _BreadcrumbSegment {
  final String label;
  final String path;

  _BreadcrumbSegment({required this.label, required this.path});
}
