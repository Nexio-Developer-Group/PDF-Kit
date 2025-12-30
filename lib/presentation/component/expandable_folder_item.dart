// lib/presentation/component/expandable_folder_item.dart

import 'package:flutter/material.dart';
import 'package:pdf_kit/presentation/models/folder_tree_node.dart';
import 'package:pdf_kit/presentation/provider/folder_picker_provider.dart';
import 'package:provider/provider.dart';

class ExpandableFolderItem extends StatelessWidget {
  final FolderTreeNode node;
  final int level;

  const ExpandableFolderItem({super.key, required this.node, this.level = 0});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FolderPickerProvider>();
    final indent = level * 20.0;
    // Always assume folders can have children (they're directories)
    final hasChildren = true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Main folder item
        InkWell(
          onTap: () => provider.selectFolder(node),
          child: Container(
            padding: EdgeInsets.only(
              left: 12 + indent,
              right: 8,
              top: 8,
              bottom: 8,
            ),
            decoration: BoxDecoration(
              color: node.isSelected
                  ? Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withOpacity(0.2)
                  : null,
              border: node.isSelected
                  ? Border(
                      left: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 3,
                      ),
                    )
                  : null,
            ),
            child: Row(
              children: [
                // Selection checkbox
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: node.isSelected,
                    onChanged: (_) => provider.selectFolder(node),
                    activeColor: Theme.of(context).colorScheme.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 12),

                // Folder icon
                Icon(
                  node.isExpanded ? Icons.folder_open : Icons.folder,
                  color: node.isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 10),

                // Folder name
                Expanded(
                  child: Text(
                    node.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: node.isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: node.isSelected
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(width: 8),

                // Expand/Collapse arrow (only show if has or can have children)
                SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    icon: Icon(
                      node.isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withOpacity(0.6),
                    ),
                    onPressed: () => provider.toggleExpansion(node),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Children with side line indicator
        if (node.isExpanded &&
            !node.isLoadingChildren &&
            node.children.isNotEmpty)
          Container(
            margin: EdgeInsets.only(left: 12 + indent),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
            ),
            child: Column(
              children: node.children
                  .map(
                    (child) =>
                        ExpandableFolderItem(node: child, level: level + 1),
                  )
                  .toList(),
            ),
          ),

        // Loading indicator
        if (node.isLoadingChildren)
          Container(
            margin: EdgeInsets.only(left: 12 + indent),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 20, top: 8, bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Loading...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
