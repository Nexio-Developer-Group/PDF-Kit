// lib/presentation/providers/folder_picker_provider.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/presentation/models/folder_tree_node.dart';
import 'package:pdf_kit/service/file_system_serevice.dart';
import 'package:pdf_kit/service/path_service.dart';

class FolderPickerProvider extends ChangeNotifier {
  List<FolderTreeNode> _rootNodes = [];
  String? _selectedFolderPath;
  bool _isLoading = false;
  String? _errorMessage;

  List<FolderTreeNode> get rootNodes => _rootNodes;
  String? get selectedFolderPath => _selectedFolderPath;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasSelection => _selectedFolderPath != null;

  /// Initialize with storage volumes and public directories
  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final volumesEither = await PathService.volumes();
      final publicDirsEither = await PathService.publicDirs();

      final List<FolderTreeNode> nodes = [];

      // Add public directories first
      publicDirsEither.fold(
        (error) {
          debugPrint('Error loading public dirs: $error');
          _errorMessage = error.toString();
        },
        (publicDirs) {
          for (final entry in publicDirs.entries) {
            final fileInfo = FileInfo(
              name: entry.key,
              path: entry.value.path,
              extension: '',
              size: 0,
              isDirectory: true,
              lastModified: DateTime.now(),
              parentDirectory: entry.value.parent.path,
            );

            nodes.add(FolderTreeNode(fileInfo: fileInfo, depth: 0));
          }
        },
      );

      // Add storage volumes
      volumesEither.fold(
        (error) {
          debugPrint('Error loading volumes: $error');
          _errorMessage ??= error.toString();
        },
        (volumes) {
          for (final volume in volumes) {
            final name = _extractVolumeName(volume.path);
            final fileInfo = FileInfo(
              name: name,
              path: volume.path,
              extension: '',
              size: 0,
              isDirectory: true,
              lastModified: DateTime.now(),
              parentDirectory: volume.parent.path,
            );

            nodes.add(FolderTreeNode(fileInfo: fileInfo, depth: 0));
          }
        },
      );

      _rootNodes = nodes;
    } catch (e) {
      _errorMessage = 'Failed to load folders: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle folder expansion and load children if needed
  /// FIXED: Changed parameter from FolderTreeItem to FolderTreeNode
  Future<void> toggleExpansion(FolderTreeNode node) async {
    // Toggle expansion state
    final updatedNode = node.copyWith(isExpanded: !node.isExpanded);
    _updateNodeInTree(node, updatedNode);
    notifyListeners();

    // Load children if expanding and children not loaded yet
    if (updatedNode.isExpanded && updatedNode.children.isEmpty) {
      await _loadChildren(updatedNode);
    }
  }

  /// Load children folders for a given node
  Future<void> _loadChildren(FolderTreeNode parentNode) async {
    // Mark as loading
    final loadingNode = parentNode.copyWith(isLoadingChildren: true);
    _updateNodeInTree(parentNode, loadingNode);
    notifyListeners();

    try {
      final listResult = await FileSystemService.list(parentNode.path);

      listResult.fold(
        (error) {
          debugPrint('Error loading children for ${parentNode.path}: $error');
          // Mark loading complete even on error
          final errorNode = parentNode.copyWith(isLoadingChildren: false);
          _updateNodeInTree(loadingNode, errorNode);
        },
        (fileInfoList) {
          // Filter only directories
          final folders = fileInfoList
              .where((info) => info.isDirectory)
              .toList();

          // Convert FileInfo to FolderTreeNode
          final children = folders.map((info) {
            return FolderTreeNode(fileInfo: info, depth: parentNode.depth + 1);
          }).toList();

          // Update parent with children
          final updatedNode = parentNode.copyWith(
            children: children,
            isLoadingChildren: false,
          );
          _updateNodeInTree(loadingNode, updatedNode);
        },
      );
    } catch (e) {
      debugPrint('Exception loading children: $e');
      final errorNode = parentNode.copyWith(isLoadingChildren: false);
      _updateNodeInTree(loadingNode, errorNode);
    } finally {
      notifyListeners();
    }
  }

  /// Select a folder (single selection only)
  void selectFolder(FolderTreeNode node) {
    // Deselect all folders first
    _deselectAllFolders();

    // Select the clicked folder
    final updatedNode = node.copyWith(isSelected: true);
    _updateNodeInTree(node, updatedNode);
    _selectedFolderPath = node.path;

    notifyListeners();
  }

  /// Deselect all folders recursively
  void _deselectAllFolders() {
    _rootNodes = _rootNodes.map(_deselectNodeRecursively).toList();
    _selectedFolderPath = null;
  }

  FolderTreeNode _deselectNodeRecursively(FolderTreeNode node) {
    final deselectedChildren = node.children
        .map(_deselectNodeRecursively)
        .toList();
    return node.copyWith(isSelected: false, children: deselectedChildren);
  }

  /// Update a specific node in the tree
  void _updateNodeInTree(FolderTreeNode oldNode, FolderTreeNode newNode) {
    _rootNodes = _rootNodes
        .map((root) => _replaceNode(root, oldNode, newNode))
        .toList();
  }

  FolderTreeNode _replaceNode(
    FolderTreeNode current,
    FolderTreeNode target,
    FolderTreeNode replacement,
  ) {
    if (current.path == target.path) {
      return replacement;
    }

    final updatedChildren = current.children
        .map((child) => _replaceNode(child, target, replacement))
        .toList();

    return current.copyWith(children: updatedChildren);
  }

  /// Extract readable volume name from path
  String _extractVolumeName(String path) {
    if (path.contains('emulated/0')) return 'Internal Storage';
    if (path.contains('sdcard')) return 'SD Card';
    final segments = path.split(Platform.pathSeparator);
    return segments.isNotEmpty ? segments.last : 'Storage';
  }

  /// Clear selection
  void clearSelection() {
    _deselectAllFolders();
    notifyListeners();
  }

  /// Refresh the entire tree
  Future<void> refresh() async {
    await initialize();
  }
}
