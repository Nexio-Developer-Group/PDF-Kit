// selection_layout.dart

import 'package:flutter/material.dart';
import 'package:pdf_kit/presentation/sheets/selection_pick_sheet.dart';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/presentation/provider/selection_provider.dart';
import 'package:pdf_kit/core/app_export.dart';

class SelectionScaffold extends StatefulWidget {
  final Widget child;
  final String? actionText;
  final void Function(List<FileInfo>)? onAction;
  final bool autoEnable; // defaults true for fullscreen selection shell
  final SelectionProvider? provider; // optional externally provided provider
  final int? maxSelectable; // NEW limit provided via query parameter
  final int? minSelectable; // NEW minimum required selection to perform action
  final String? allowed; // Filter: 'protected', 'unprotected', or null for all

  const SelectionScaffold({
    super.key,
    required this.child,
    this.actionText,
    this.onAction,
    this.autoEnable = true,
    this.provider,
    this.maxSelectable,
    this.minSelectable,
    this.allowed,
  });

  @override
  State<SelectionScaffold> createState() => SelectionScaffoldState();
}

class SelectionScaffoldState extends State<SelectionScaffold> {
  late final SelectionProvider provider;
  late final bool _ownsProvider;

  @override
  void initState() {
    super.initState();
    if (widget.provider != null) {
      provider = widget.provider!;
      _ownsProvider = false;
    } else {
      provider = SelectionProvider();
      _ownsProvider = true;
    }

    if (widget.autoEnable) {
      // Ensure bottom bar is visible immediately (0 selected)
      provider.enable();
    }

    // apply max selectable if provided
    provider.setMaxSelectable(widget.maxSelectable);
    // apply min selectable if provided
    provider.setMinSelectable(widget.minSelectable);
    // apply allowed filter if provided
    provider.setAllowedFilter(widget.allowed);

    // Listen for selection limit errors and surface them via sheet
    provider.addListener(_handleProviderUpdate);
  }

  @override
  void dispose() {
    // Only dispose providers we created locally
    if (_ownsProvider) {
      provider.dispose();
    }
    super.dispose();
  }

  void _handleProviderUpdate() {
    // Handle validation errors first (show snackbar)
    if (provider.lastValidationError != null) {
      final t = AppLocalizations.of(context);
      final errorMessage = t.t(provider.lastValidationError!);
      AppSnackbar.showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      provider.clearValidationError();
      return;
    }

    // Handle limit errors (show sheet)
    if (provider.lastLimitCount == null) return;

    final t = AppLocalizations.of(context);
    final count = provider.lastLimitCount!;

    final key = count == 1
        ? 'selection_limit_error_single'
        : 'selection_limit_error_multiple';

    final msg = t.t(key).replaceAll('{count}', count.toString());

    showSelectionPickSheet(
      context: context,
      provider: provider,
      infoMessage: msg,
      isError: true,
    ).then((_) => provider.clearError());
  }

  @override
  Widget build(BuildContext context) {
    // Set context for localization
    // provider.setContext(context);
    return SelectionScope(
      provider: provider,
      child: Scaffold(
        body: SafeArea(child: widget.child),
        bottomNavigationBar: AnimatedBuilder(
          animation: provider,
          builder: (_, __) =>
              Padding(padding: screenPadding, child: _bottomBar(context)),
        ),
      ),
    );
  }

  Widget _bottomBar(BuildContext context) {
    final theme = Theme.of(context);
    final t = AppLocalizations.of(context); // NEW

    if (!provider.isEnabled) return const SizedBox.shrink();
    final count = provider.count;

    // Localized "{count} selected"
    final selectedLabel = t
        .t('selection_count_label')
        .replaceAll('{count}', count.toString());

    // Localized default action label
    final actionLabel = widget.actionText ?? t.t('selection_action_default');

    // Optional: localized "Max: X" info, if you add this key to ARB:
    // "selection_max_info": "Max: {count}"
    String? maxInfo;
    if (provider.maxSelectable != null) {
      maxInfo = t
          .t('selection_max_info')
          .replaceAll('{count}', provider.maxSelectable.toString());
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                // Only allow opening the selection sheet when there's at least
                // one selected item. If nothing is selected (count == 0)
                // both buttons remain disabled.
                onPressed: (widget.onAction != null && count > 0)
                    ? () {
                        final min = provider.minSelectable ?? 0;
                        String? info = maxInfo;
                        bool isError = false;

                        if (min > 0 && count < min) {
                          info = t
                              .t('selection_min_error')
                              .replaceAll('{count}', min.toString());
                          isError = true;
                        } else if (provider.lastLimitCount != null) {
                          // if provider reported a max limit error, surface it
                          final cnt = provider.lastLimitCount!;
                          final key = cnt == 1
                              ? 'selection_limit_error_single'
                              : 'selection_limit_error_multiple';
                          info = t.t(key).replaceAll('{count}', cnt.toString());
                          isError = true;
                        }

                        showSelectionPickSheet(
                          context: context,
                          provider: provider,
                          infoMessage: info,
                          isError: isError,
                        );
                      }
                    : null,
                icon: const Icon(Icons.checklist),
                label: Text(selectedLabel),
                style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
                  elevation: WidgetStateProperty.all(0),
                  backgroundColor: WidgetStateProperty.resolveWith<Color?>((
                    states,
                  ) {
                    if (states.contains(WidgetState.disabled)) {
                      return null;
                    }
                    return Theme.of(context).colorScheme.primary.withAlpha(40);
                  }),
                  iconColor: WidgetStateProperty.resolveWith<Color?>((states) {
                    if (states.contains(WidgetState.disabled)) {
                      return null;
                    }
                    return Theme.of(context).colorScheme.primary;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith<Color?>((
                    states,
                  ) {
                    if (states.contains(WidgetState.disabled)) return null;
                    return theme.colorScheme.primary;
                  }),
                  side: WidgetStateProperty.all(BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: (widget.onAction != null && count > 0)
                    ? () {
                        final min = provider.minSelectable ?? 0;
                        if (min > 0 && count < min) {
                          final msg = t
                              .t('selection_min_error')
                              .replaceAll('{count}', min.toString());
                          // Open selection pick sheet (same UX as max error)
                          showSelectionPickSheet(
                            context: context,
                            provider: provider,
                            infoMessage: msg,
                            isError: true,
                          );
                          return;
                        }

                        widget.onAction!(provider.files);
                      }
                    : null,
                child: Text(actionLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Reactive scope so descendants rebuild on selection changes
class SelectionScope extends InheritedNotifier<SelectionProvider> {
  const SelectionScope({
    required SelectionProvider provider,
    required super.child,
    super.key,
  }) : super(notifier: provider);

  static SelectionProvider of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SelectionScope>()!.notifier!;
}
