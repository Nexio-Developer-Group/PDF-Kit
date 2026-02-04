import 'package:flutter/material.dart';
import 'package:pdf_kit/core/localization/app_localizations.dart';

/// Shows a confirmation sheet for clearing all recent files
Future<void> showClearRecentFilesSheet({
  required BuildContext context,
  required VoidCallback onClear,
}) async {
  await showModalBottomSheet(
    context: context,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) {
      return SafeArea(
        bottom: true,
        top: false,
        left: false,
        right: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              padding: const EdgeInsets.all(0),
              decoration: BoxDecoration(
                color: Theme.of(context).dialogBackgroundColor,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withValues(alpha: 0.25),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: ClearRecentFilesSheet(onClear: onClear),
            ),
          ),
        ),
      );
    },
  );
}

class ClearRecentFilesSheet extends StatelessWidget {
  final VoidCallback onClear;

  const ClearRecentFilesSheet({super.key, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 48,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          // Icon
          Container(
            width: 64,
            height: 64,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.delete_sweep_outlined,
              size: 32,
              color: theme.colorScheme.error,
            ),
          ),

          // Title
          Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text(
                AppLocalizations.of(context).t('clear_recent_files_title'),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              AppLocalizations.of(context).t('clear_recent_files_message'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 24),

          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Text(AppLocalizations.of(context).t('common_cancel')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onClear();
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: theme.colorScheme.error,
                  ),
                  child: Text(
                    AppLocalizations.of(
                      context,
                    ).t('clear_recent_files_confirm'),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
