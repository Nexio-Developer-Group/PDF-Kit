// lib/presentation/widgets/folder_tree_item.dart

import 'package:flutter/material.dart';
import 'package:pdf_kit/presentation/models/folder_tree_node.dart';
import 'package:pdf_kit/presentation/provider/folder_picker_provider.dart';
import 'package:provider/provider.dart';

class FolderTreeItem extends StatelessWidget {
  final FolderTreeNode node;

  const FolderTreeItem({
    super.key,
    required this.node,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FolderPickerProvider>();
    const double indentSize = 24.0;
    final hasChildren = node.childrenCount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: node.isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
              : Colors.transparent,
          child: InkWell(
            onTap: () => provider.selectFolder(node),
            child: Padding(
              padding: EdgeInsets.only(
                left: node.depth * indentSize + 8,
                right: 8,
                top: 8,
                bottom: 8,
              ),
              child: Row(
                children: [
                  // Checkbox
                  Checkbox(
                    value: node.isSelected,
                    onChanged: (_) => provider.selectFolder(node),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 8),

                  // Folder Icon
                  Icon(
                    node.isExpanded ? Icons.folder_open : Icons.folder,
                    color: node.isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                  const SizedBox(width: 12),

                  // Folder Name
                  Expanded(
                    child: Text(
                      node.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: node.isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  // Children Count Badge
                  if (hasChildren) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${node.childrenCount}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                  ],

                  const SizedBox(width: 8),

                  // Expand/Collapse Arrow (only if has children)
                  if (hasChildren)
                    IconButton(
                      icon: Icon(
                        node.isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 24,
                      ),
                      onPressed: () => provider.toggleExpansion(node),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    )
                  else
                    const SizedBox(width: 32),
                ],
              ),
            ),
          ),
        ),

        // Show loading indicator while loading children
        if (node.isLoadingChildren)
          Padding(
            padding: EdgeInsets.only(
              left: (node.depth + 1) * indentSize + 16,
              top: 8,
              bottom: 8,
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(
                  'Loading...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),

        // Render children if expanded
        if (node.isExpanded && !node.isLoadingChildren && node.children.isNotEmpty)
          ...node.children.map((child) => FolderTreeItem(node: child)),
      ],
    );
  }
}
