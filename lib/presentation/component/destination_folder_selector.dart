import 'package:flutter/material.dart';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/core/localization/app_localizations.dart';

class DestinationFolderSelector extends StatelessWidget {
  final FileInfo? selectedFolder;
  final bool isLoading;
  final VoidCallback onTap;
  final bool disabled;
  final String?
  labelOverride; // helper to customize "loading default folder" text if needed

  const DestinationFolderSelector({
    super.key,
    required this.selectedFolder,
    required this.isLoading,
    required this.onTap,
    this.disabled = false,
    this.labelOverride,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context);

    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: disabled
                ? theme.colorScheme.onSurfaceVariant.withOpacity(0.15)
                : theme.colorScheme.primary.withOpacity(0.3),
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
                    t.t('merge_pdf_loading_default_folder'),
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
                    color: disabled
                        ? theme.colorScheme.onSurfaceVariant.withOpacity(0.4)
                        : theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedFolder?.name ??
                              t.t('merge_pdf_select_folder_placeholder'),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: disabled
                                ? theme.colorScheme.onSurfaceVariant
                                      .withOpacity(0.5)
                                : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (selectedFolder != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            selectedFolder!.path,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withOpacity(disabled ? 0.4 : 1.0),
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
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(
                      disabled ? 0.3 : 1.0,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
