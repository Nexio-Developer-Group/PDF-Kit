// lib/presentation/pages/folder_picker_page.dart

import 'package:flutter/material.dart';
import 'package:pdf_kit/core/localization/app_localizations.dart';
import 'package:pdf_kit/core/theme/app_theme.dart';
import 'package:pdf_kit/presentation/component/expandable_folder_item.dart';
import 'package:pdf_kit/presentation/provider/folder_picker_provider.dart';
import 'package:provider/provider.dart';

class FolderPickerPage extends StatelessWidget {
  final String? initialPath;
  final String? title;
  final String? description;

  const FolderPickerPage({
    super.key,
    this.initialPath,
    this.title,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          FolderPickerProvider()..initialize(initialPath: initialPath),
      child: _FolderPickerPageContent(title: title, description: description),
    );
  }
}

class _FolderPickerPageContent extends StatefulWidget {
  final String? title;
  final String? description;

  const _FolderPickerPageContent({this.title, this.description});

  @override
  State<_FolderPickerPageContent> createState() =>
      _FolderPickerPageContentState();
}

class _FolderPickerPageContentState extends State<_FolderPickerPageContent> {
  bool _isSelecting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Consumer<FolderPickerProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    Text(
                      AppLocalizations.of(
                        context,
                      ).t('folder_picker_unable_to_load_title'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => provider.refresh(),
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        AppLocalizations.of(context).t('folder_picker_retry'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.rootNodes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_off_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).t('folder_picker_no_folders'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: screenPadding,
            children: [
              // Page heading and description
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title ??
                        AppLocalizations.of(context).t('folder_picker_title'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.description ??
                        AppLocalizations.of(
                          context,
                        ).t('folder_picker_description'),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                  // Always show selected folder info
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: provider.hasSelection
                          ? Theme.of(
                              context,
                            ).colorScheme.primaryContainer.withOpacity(0.3)
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: provider.hasSelection
                            ? Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.5)
                            : Theme.of(context).colorScheme.outline,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(
                            context,
                          ).t('folder_picker_selected_folder_label'),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: provider.hasSelection
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              provider.hasSelection
                                  ? Icons.folder
                                  : Icons.folder_outlined,
                              size: 16,
                              color: provider.hasSelection
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                provider.hasSelection
                                    ? provider.selectedFolderPath!
                                    : AppLocalizations.of(
                                        context,
                                      ).t('folder_picker_no_folder_selected'),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontWeight: provider.hasSelection
                                          ? FontWeight.w500
                                          : FontWeight.w400,
                                      fontStyle: provider.hasSelection
                                          ? FontStyle.normal
                                          : FontStyle.italic,
                                      color: provider.hasSelection
                                          ? null
                                          : Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                    ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Folder list
              ...provider.rootNodes.map(
                (node) => ExpandableFolderItem(node: node, level: 0),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<FolderPickerProvider>(
        builder: (context, provider, _) {
          return SafeArea(
            // bottom: true,
            // minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: provider.hasSelection && !_isSelecting
                      ? () {
                          setState(() {
                            _isSelecting = true;
                          });
                          provider.lockSelection();
                          Navigator.pop(context, provider.selectedFolderPath);
                        }
                      : null,
                  child: _isSelecting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          AppLocalizations.of(
                            context,
                          ).t('folder_picker_select_button'),
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
