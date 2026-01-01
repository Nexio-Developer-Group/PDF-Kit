import 'package:flutter/material.dart';
import 'package:pdf_kit/presentation/models/filter_models.dart';

/// InheritedWidget that provides filter state to descendant widgets
class FileBrowserFilterScope extends InheritedWidget {
  final SortOption sortOption;
  final Set<TypeFilter> typeFilters;
  final String? fileType; // 'all', 'pdf', 'images' - from functionality

  const FileBrowserFilterScope({
    super.key,
    required this.sortOption,
    required this.typeFilters,
    this.fileType,
    required super.child,
  });

  /// Get the filter scope from context (returns null if not found)
  static FileBrowserFilterScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<FileBrowserFilterScope>();
  }

  @override
  bool updateShouldNotify(FileBrowserFilterScope oldWidget) {
    return sortOption != oldWidget.sortOption ||
        typeFilters != oldWidget.typeFilters ||
        fileType != oldWidget.fileType;
  }
}
