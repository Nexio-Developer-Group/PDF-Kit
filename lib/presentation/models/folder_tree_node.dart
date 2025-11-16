// lib/presentation/models/folder_tree_node.dart

import 'package:pdf_kit/models/file_model.dart';

/// Wrapper for FileInfo to track UI state (expansion, selection)
class FolderTreeNode {
  final FileInfo fileInfo;
  final int depth;
  final List<FolderTreeNode> children;
  final bool isExpanded;
  final bool isSelected;
  final bool isLoadingChildren;

  // FIXED: Made all fields final and children required in constructor
  FolderTreeNode({
    required this.fileInfo,
    required this.depth,
    List<FolderTreeNode>? children,
    this.isExpanded = false,
    this.isSelected = false,
    this.isLoadingChildren = false,
  }) : children = children ?? [];

  FolderTreeNode copyWith({
    FileInfo? fileInfo,
    int? depth,
    List<FolderTreeNode>? children,
    bool? isExpanded,
    bool? isSelected,
    bool? isLoadingChildren,
  }) {
    return FolderTreeNode(
      fileInfo: fileInfo ?? this.fileInfo,
      depth: depth ?? this.depth,
      children: children ?? this.children,
      isExpanded: isExpanded ?? this.isExpanded,
      isSelected: isSelected ?? this.isSelected,
      isLoadingChildren: isLoadingChildren ?? this.isLoadingChildren,
    );
  }

  String get name => fileInfo.name;
  String get path => fileInfo.path;
  int get childrenCount => fileInfo.childrenCount ?? 0;
}
