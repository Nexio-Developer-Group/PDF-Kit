// lib/presentation/pages/merge_pdf_page.dart

import 'package:flutter/material.dart';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/presentation/component/document_tile.dart';
import 'package:pdf_kit/presentation/provider/selection_provider.dart';
import 'package:pdf_kit/service/pdf_merge_service.dart';
import 'package:pdf_kit/service/recent_file_service.dart';
import 'package:pdf_kit/service/path_service.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:path/path.dart' as p;
import 'dart:ui';

class MergePdfPage extends StatefulWidget {
  final String? selectionId;

  const MergePdfPage({super.key, this.selectionId});

  @override
  State<MergePdfPage> createState() => _MergePdfPageState();
}

class _MergePdfPageState extends State<MergePdfPage> {
  late final TextEditingController _nameCtrl;
  bool _isMerging = false;
  FileInfo? _selectedDestinationFolder;
  bool _isLoadingDefaultFolder = true;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: 'Merged Document');
    _loadDefaultDestination();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  /// Load default destination folder (Downloads)
  Future<void> _loadDefaultDestination() async {
    setState(() => _isLoadingDefaultFolder = true);

    try {
      final publicDirsResult = await PathService.publicDirs();
      
      publicDirsResult.fold(
        (error) {
          debugPrint('Failed to load default destination: $error');
          setState(() => _isLoadingDefaultFolder = false);
        },
        (publicDirs) {
          final downloadsDir = publicDirs['Downloads'];
          if (downloadsDir != null) {
            setState(() {
              _selectedDestinationFolder = FileInfo(
                name: 'Downloads',
                path: downloadsDir.path,
                extension: '',
                size: 0,
                isDirectory: true,
                lastModified: DateTime.now(),
              );
              _isLoadingDefaultFolder = false;
            });
          } else {
            setState(() => _isLoadingDefaultFolder = false);
          }
        },
      );
    } catch (e) {
      debugPrint('Error loading default destination: $e');
      setState(() => _isLoadingDefaultFolder = false);
    }
  }

  /// Open folder picker and update destination
// lib/presentation/pages/merge_pdf_page.dart

/// Open folder picker and update destination
Future<void> _selectDestinationFolder() async {
  // ✅ Option 1: Use pushNamed with the route name
  final selectedPath = await context.pushNamed<String>(AppRouteName.folderPickScreen);
  
  // ✅ OR Option 2: Use push with the full path
  // final selectedPath = await context.push<String>('/folder-picker');

  if (selectedPath != null && mounted) {
    setState(() {
      _selectedDestinationFolder = FileInfo(
        name: selectedPath.split('/').last,
        path: selectedPath,
        extension: '',
        size: 0,
        isDirectory: true,
        lastModified: DateTime.now(),
      );
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Destination: ${_selectedDestinationFolder!.name}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

  String _displayName(FileInfo f) {
    try {
      final dynamic maybeName = (f as dynamic).name;
      if (maybeName is String && maybeName.trim().isNotEmpty) return maybeName;
    } catch (_) {}
    return p.basenameWithoutExtension(f.path);
  }

  String _suggestDefaultName(List<FileInfo> files) {
    if (files.isEmpty) return 'Merged Document';
    final List<String> first = _displayName(files.first).split('.');
    first.removeLast();
    return '${first.isEmpty ? "Merged Document" : first.join('.')} - Merged';
  }

  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double animValue = Curves.easeInOut.transform(animation.value);
        final double elevation = lerpDouble(0, 6, animValue)!;
        return Material(
          elevation: elevation,
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          child: child,
        );
      },
      child: child,
    );
  }

  Future<void> _storeRecentFiles(
    FileInfo mergedFile,
    List<FileInfo> sourceFiles,
  ) async {
    debugPrint('');
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('💾 [MergePDF] Starting storage of recent files');
    debugPrint('═══════════════════════════════════════════════════════');

    try {
      debugPrint('📝 [MergePDF] Storing merged file: ${mergedFile.name}');
      debugPrint('   Path: ${mergedFile.path}');
      debugPrint('   Size: ${mergedFile.readableSize}');

      final mergedResult = await RecentFilesService.addRecentFile(mergedFile);

      mergedResult.fold(
        (error) {
          debugPrint('❌ [MergePDF] Failed to store merged file: $error');
        },
        (updatedFiles) {
          debugPrint('✅ [MergePDF] Merged file stored successfully');
          debugPrint('   Total files in storage: ${updatedFiles.length}');
        },
      );

      debugPrint('');
      debugPrint('📚 [MergePDF] Storing ${sourceFiles.length} source files:');

      for (var i = 0; i < sourceFiles.length; i++) {
        final sourceFile = sourceFiles[i];
        debugPrint('   ${i + 1}. ${sourceFile.name}');

        final result = await RecentFilesService.addRecentFile(sourceFile);

        result.fold(
          (error) {
            debugPrint('      ❌ Failed: $error');
          },
          (updatedFiles) {
            debugPrint('      ✅ Stored (Total: ${updatedFiles.length})');
          },
        );
      }

      debugPrint('');
      debugPrint('🎉 [MergePDF] All files storage completed!');
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('');

      final verifyResult = await RecentFilesService.getRecentFiles();
      verifyResult.fold(
        (error) {
          debugPrint('❌ [MergePDF] Verification failed: $error');
        },
        (files) {
          debugPrint('✅ [MergePDF] Verification successful!');
          debugPrint('   Files in storage: ${files.length}');
          for (var i = 0; i < files.length; i++) {
            debugPrint('   ${i + 1}. ${files[i].name}');
          }
        },
      );
      debugPrint('');
    } catch (e) {
      debugPrint('❌ [MergePDF] Error storing recent files: $e');
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('');
    }
  }

  Future<void> _handleMerge(
    BuildContext context,
    SelectionProvider selection,
  ) async {
    setState(() => _isMerging = true);

    final outName = _nameCtrl.text.trim().isEmpty
        ? 'Merged Document'
        : _nameCtrl.text.trim();

    final filesWithRotation = selection.filesWithRotation;
    final sourceFiles = selection.files;

    // Pass destination folder to merge service
    final result = await PdfMergeService.mergePdfs(
      filesWithRotation: filesWithRotation,
      outputFileName: outName,
      destinationPath: _selectedDestinationFolder?.path, // Pass destination
    );

    setState(() => _isMerging = false);

    result.fold(
      (error) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${error.message}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      },
      (mergedFile) async {
        await _storeRecentFiles(mergedFile, sourceFiles);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully merged to ${mergedFile.name}'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Open',
              onPressed: () {
                context.pushNamed(
                  AppRouteName.showPdf,
                  queryParameters: {'path': mergedFile.path},
                );
              },
            ),
          ),
        );
        selection.disable();
        context.pop(true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<SelectionProvider>(
      builder: (context, selection, _) {
        final files = selection.files;

        if ((_nameCtrl.text.isEmpty || _nameCtrl.text == 'Merged Document') &&
            files.isNotEmpty) {
          _nameCtrl.text = _suggestDefaultName(files);
          _nameCtrl.selection = TextSelection.fromPosition(
            TextPosition(offset: _nameCtrl.text.length),
          );
        }

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            title: const Text('Merge PDF'),
            centerTitle: false,
          ),
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${files.length} selected files to be merged',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // File Name section
                        Text('File Name', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameCtrl,
                          textInputAction: TextInputAction.done,
                          decoration: InputDecoration(
                            hintText: 'Type output file name',
                            border: const UnderlineInputBorder(),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary.withOpacity(0.3),
                              ),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 🆕 Destination Folder Section
                        Text(
                          'Save to Folder',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        _DestinationFolderSelector(
                          selectedFolder: _selectedDestinationFolder,
                          isLoading: _isLoadingDefaultFolder,
                          onTap: _selectDestinationFolder,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // Reorderable files list
                SliverReorderableList(
                  itemCount: files.length,
                  onReorder: (oldIndex, newIndex) {
                    selection.reorderFiles(oldIndex, newIndex);
                  },
                  proxyDecorator: _proxyDecorator,
                  itemBuilder: (context, index) {
                    final f = files[index];
                    return ReorderableDelayedDragStartListener(
                      key: ValueKey(f.path),
                      index: index,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: DocEntryCard(
                          info: f,
                          showActions: true,
                          rotation: selection.getRotation(f.path),
                          onRotate: () => selection.rotateFile(f.path),
                          onRemove: () => selection.removeFile(f.path),
                          onOpen: () => context.pushNamed(
                            AppRouteName.showPdf,
                            queryParameters: {'path': f.path},
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Add more files button
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverToBoxAdapter(
                    child: _AddMoreButton(
                      onTap: () {
                        final params = <String, String>{'actionText': 'Add'};
                        if (widget.selectionId != null) {
                          params['selectionId'] = widget.selectionId!;
                        }
                        context.pushNamed(
                          AppRouteName.filesRootFullscreen,
                          queryParameters: params,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: (files.length >= 2 && !_isMerging)
                    ? () => _handleMerge(context, selection)
                    : null,
                child: _isMerging
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text('Merge'),
              ),
            ),
          ),
        );
      },
    );
  }
}

// 🆕 Destination Folder Selector Widget
class _DestinationFolderSelector extends StatelessWidget {
  final FileInfo? selectedFolder;
  final bool isLoading;
  final VoidCallback onTap;

  const _DestinationFolderSelector({
    required this.selectedFolder,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: isLoading
            ? Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Loading default folder...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  Icon(
                    Icons.folder,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedFolder?.name ?? 'Select Folder',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (selectedFolder != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            selectedFolder!.path,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
      ),
    );
  }
}

class _AddMoreButton extends StatelessWidget {
  const _AddMoreButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Add More Files',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
