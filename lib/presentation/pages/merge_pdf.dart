import 'package:flutter/material.dart';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/presentation/component/document_tile.dart';
import 'package:pdf_kit/presentation/provider/selection_provider.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:path/path.dart' as p;

class MergePdfPage extends StatefulWidget {
  final String? selectionId;

  const MergePdfPage({super.key, this.selectionId});

  @override
  State<MergePdfPage> createState() => _MergePdfPageState();
}

class _MergePdfPageState extends State<MergePdfPage> {
  late final TextEditingController _nameCtrl;

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
    final first = _displayName(files.first);
    return '${first.isEmpty ? "Merged Document" : first} - Merged';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<SelectionProvider>(
      builder: (context, selection, _) {
        final files = selection.files;
        print(selection.selected);

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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                  const SizedBox(height: 16),

                  // Selected files (display cards)
                  for (final f in files) ...[
                    DocEntryCard(
                      info: f,
                      selectable: false,
                      selected: false,
                      onOpen: () => context.pushNamed(
                        AppRouteName.showPdf,
                        queryParameters: {'path': f.path},
                      ),
                      onMenu: (action) {
                        if (action == 'open') {
                          context.pushNamed(
                            AppRouteName.showPdf,
                            queryParameters: {'path': f.path},
                          );
                        }
                        // 'rename' / 'delete' / 'share' are stubs here.
                        // You can hook actual behaviors later.
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Add more files
                  _AddMoreButton(
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
                ],
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                onPressed: files.length >= 2
                    ? () {
                        final outName = _nameCtrl.text.trim().isEmpty
                            ? 'Merged Document'
                            : _nameCtrl.text.trim();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Merging ${files.length} files into "$outName"...',
                            ),
                          ),
                        );
                      }
                    : null,
                child: const Text('Merge'),
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
