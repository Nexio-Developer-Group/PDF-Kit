import 'package:flutter/material.dart';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/presentation/component/document_tile.dart';
import 'package:pdf_kit/presentation/provider/selection_provider.dart';
import 'package:pdf_kit/service/pdf_merge_service.dart';
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

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: 'Merged Document');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
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

  // Custom proxy decorator for transparent drag item
  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (BuildContext context, Widget? child) {
        final double animValue = Curves.easeInOut.transform(animation.value);
        final double elevation = lerpDouble(0, 6, animValue)!;
        return Material(
          elevation: elevation,
          color: Colors.transparent,
          // shadowColor: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          child: child,
        );
      },
      child: child,
    );
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

    final result = await PdfMergeService.mergePdfs(
      filesWithRotation: filesWithRotation,
      outputFileName: outName,
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
      (mergedFile) {
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
        context.pop();
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
                                color: theme.colorScheme.primary.withOpacity(
                                  0.3,
                                ),
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
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // Reorderable files list as Sliver
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
                      // delay: const Duration(milliseconds: 500),
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
