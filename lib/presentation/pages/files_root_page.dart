import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf_kit/providers/file_system_provider.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:provider/provider.dart';

/// Page displaying storage volumes (Internal Storage, SD Card, etc.)
/// This is the root page of the file browser at /files
class FilesRootPage extends StatefulWidget {
  final bool isFullscreenRoute;
  final String? selectionId;
  final String? selectionActionText;

  const FilesRootPage({
    super.key,
    this.isFullscreenRoute = false,
    this.selectionId,
    this.selectionActionText,
  });

  @override
  State<FilesRootPage> createState() => _FilesRootPageState();
}

class _FilesRootPageState extends State<FilesRootPage> {
  @override
  void initState() {
    super.initState();
    // Load storage roots when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FileSystemProvider>().loadRoots();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final provider = context.watch<FileSystemProvider>();
    final roots = provider.roots;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/app_icon.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Icon(
                          Icons.widgets_rounded,
                          size: 24,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    t.t('files_header_title'),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Storage volumes list
            Expanded(
              child: roots.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 16),
                          Text(t.t('files_loading_storage')),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: roots.length,
                      itemBuilder: (context, index) {
                        final root = roots[index];
                        return _buildStorageCard(context, root);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageCard(BuildContext context, Directory root) {
    final t = AppLocalizations.of(context);

    // Determine storage type from path
    final isInternal = root.path.contains('emulated');
    final storageName = isInternal
        ? t.t('files_internal_storage')
        : t.t('files_sd_card');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Navigate to folder browser with this root path
          // Use correct route based on selection mode
          final routeName = widget.isFullscreenRoute
              ? AppRouteName.filesFolderFullScreen
              : AppRouteName.filesFolder;

          final params = <String, String>{'path': root.path};
          if (widget.selectionId != null) {
            params['selectionId'] = widget.selectionId!;
          }
          if (widget.selectionActionText != null) {
            params['actionText'] = widget.selectionActionText!;
          }

          context.pushNamed(routeName, queryParameters: params);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isInternal ? Icons.phone_android : Icons.sd_card,
                  size: 28,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storageName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      root.path,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
