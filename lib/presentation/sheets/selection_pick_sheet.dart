import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/presentation/provider/selection_provider.dart';
import 'package:pdf_kit/presentation/component/document_tile.dart';

/// Bottom sheet displaying selected files grouped by their parent folder.
Future<void> showSelectionPickSheet({
  required BuildContext context,
  required SelectionProvider provider,
  String? infoMessage, // optional message (limit or hint)
  bool isError = false, // highlight style when true
}) async {
  if (provider.count == 0) return;
  await showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _SelectionPickSheet(
      provider: provider,
      infoMessage: infoMessage,
      isError: isError,
    ),
  );
}

class _SelectionPickSheet extends StatefulWidget {
  final SelectionProvider provider;
  final String? infoMessage;
  final bool isError;
  const _SelectionPickSheet({
    required this.provider,
    this.infoMessage,
    this.isError = false,
  });

  @override
  State<_SelectionPickSheet> createState() => _SelectionPickSheetState();
}

class _SelectionPickSheetState extends State<_SelectionPickSheet> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final files = widget.provider.files;

    final Map<String, List<FileInfo>> grouped = {};
    for (final f in files) {
      final dir = p.dirname(f.path);
      grouped.putIfAbsent(dir, () => []).add(f);
    }
    final folders = grouped.keys.toList()..sort();
    final viewInsets = MediaQuery.of(context).viewInsets;

    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: true,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + viewInsets.bottom),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),

                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Text(
                        // '${files.length} Selected',
                        'Selected Files',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.15,
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 24, thickness: 1),
                  if (widget.infoMessage != null) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: widget.isError
                            ? theme.colorScheme.error.withOpacity(0.10)
                            : theme.colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color:
                              (widget.isError
                                      ? theme.colorScheme.error
                                      : theme.colorScheme.primary)
                                  .withOpacity(0.35),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            widget.isError ? Icons.warning_amber : Icons.info,
                            size: 20,
                            color: widget.isError
                                ? theme.colorScheme.error
                                : theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.infoMessage!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: 12),
                      itemCount: folders.length,
                      itemBuilder: (ctx, i) {
                        final folderPath = folders[i];
                        final folderFiles = grouped[folderPath]!;
                        return _FolderGroup(
                          folderPath: folderPath,
                          files: folderFiles,
                          provider: widget.provider,
                          onChanged: _handleChanged,
                        );
                      },
                    ),
                  ),
                  if (files.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'No files selected',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleChanged() {
    if (!mounted) return;
    setState(() {});
    if (widget.provider.count == 0) Navigator.of(context).maybePop();
  }
}

class _FolderGroup extends StatefulWidget {
  final String folderPath;
  final List<FileInfo> files;
  final SelectionProvider provider;
  final VoidCallback onChanged;
  const _FolderGroup({
    required this.folderPath,
    required this.files,
    required this.provider,
    required this.onChanged,
  });

  @override
  State<_FolderGroup> createState() => _FolderGroupState();
}

class _FolderGroupState extends State<_FolderGroup> {
  bool _expanded = true; // initially all expanded

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = widget.folderPath.split(Platform.pathSeparator).last;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.25),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
            child: Row(
              children: [
                Icon(
                  _expanded ? Icons.folder_open : Icons.folder,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? widget.folderPath : name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.files.length} item${widget.files.length == 1 ? '' : 's'}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant.withOpacity(
                            0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                  tooltip: _expanded ? 'Collapse' : 'Expand',
                  onPressed: () => setState(() => _expanded = !_expanded),
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            const SizedBox(height: 4),
            ...widget.files.map(
              (f) => Container(
                margin: const EdgeInsets.fromLTRB(4, 0, 4, 4),
                child: DocEntryCard(
                  info: f,
                  showActions: true,
                  reorderable: false,
                  selectable: false,
                  onEdit: null, // disable edit
                  onRemove: () {
                    widget.provider.removeFile(f.path);
                    widget.onChanged();
                  },
                  onOpen: null,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
