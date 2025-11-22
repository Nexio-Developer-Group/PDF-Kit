// selection_layout.dart

import 'package:flutter/material.dart';
import 'package:pdf_kit/core/theme/app_theme.dart';
import 'package:pdf_kit/presentation/sheets/selection_pick_sheet.dart';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/presentation/provider/selection_provider.dart';

class SelectionScaffold extends StatefulWidget {
  final Widget child;
  final String? actionText;
  final void Function(List<FileInfo>)? onAction;
  final bool autoEnable; // defaults true for fullscreen selection shell
  final SelectionProvider? provider; // optional externally provided provider
  final int? maxSelectable; // NEW limit provided via query parameter

  const SelectionScaffold({
    super.key,
    required this.child,
    this.actionText,
    this.onAction,
    this.autoEnable = true,
    this.provider,
    this.maxSelectable,
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
    // Show bottom sheet with current selection + error message if limit exceeded
    if (provider.lastErrorMessage != null) {
      // Clear error after sheet pops
      showSelectionPickSheet(
        context: context,
        provider: provider,
        infoMessage: provider.lastErrorMessage,
        isError: true,
      ).then((_) => provider.clearError());
    }
  }

  @override
  Widget build(BuildContext context) {
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
    if (!provider.isEnabled) return const SizedBox.shrink();
    final count = provider.count;
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
                onPressed: (count > 0 && widget.onAction != null)
                    ? () => showSelectionPickSheet(
                        context: context,
                        provider: provider,
                        infoMessage: provider.maxSelectable != null
                            ? 'Max: ${provider.maxSelectable}'
                            : null,
                        isError: false,
                      )
                    : null,
                icon: const Icon(Icons.checklist),
                label: Text('$count selected'),
                style: Theme.of(context).elevatedButtonTheme.style?.copyWith(
                  backgroundColor: WidgetStateProperty.resolveWith<Color?>((
                    states,
                  ) {
                    if (states.contains(WidgetState.disabled)) {
                      return null;
                    }
                    return Theme.of(context).colorScheme.primary.withAlpha(15);
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
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: (count > 0 && widget.onAction != null)
                    ? () => widget.onAction!(provider.files)
                    : null,
                child: Text(widget.actionText ?? 'Action'),
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
    required Widget child,
    Key? key,
  }) : super(key: key, notifier: provider, child: child);

  static SelectionProvider of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SelectionScope>()!.notifier!;
}
