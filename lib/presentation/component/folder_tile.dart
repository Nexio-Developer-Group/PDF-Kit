import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf_kit/models/file_model.dart';

class FolderEntryCard extends StatelessWidget {
  final FileInfo info;
  final VoidCallback? onTap;

  const FolderEntryCard({super.key, required this.info, this.onTap});

  bool get _isDir => info.isDirectory;

  String _recent() {
    final dt = info.lastModified ?? DateTime.now();
    return DateFormat('MM/dd/yyyy  HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final countOrSize = _isDir
        ? '${info.childrenCount ?? 0} files'
        : info.readableSize;

    return Material(
      color: Colors.black.withAlpha(28),
      shadowColor: Colors.black.withAlpha(28),
      elevation: 2,
      borderRadius: BorderRadius.circular(12),

      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 12, left: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    // default asset inside the widget: keep path consistent in pubspec
                    'assets/folder.png',
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // const SizedBox(width: 12),
              Expanded(
                // child: Padding(
                // padding: EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 14,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withAlpha(153),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          countOrSize,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withAlpha(179),
                              ),
                        ),
                      ],
                    ),

                    // const SizedBox(height: 4),
                    Text(
                      _recent(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(153),
                      ),
                    ),
                  ],
                ),
                // ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(128),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
