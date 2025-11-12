// selection_layout.dart

import 'package:flutter/material.dart';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/presentation/provider/selection_provider.dart';

class SelectionScaffold extends StatefulWidget {
  final Widget child;
  final String? actionText;
  final void Function(List<FileInfo>)? onAction;
  final bool autoEnable; // NEW: defaults true for fullscreen selection shell
  final SelectionProvider? provider; // optional externally provided provider

  const SelectionScaffold({
    super.key,
    required this.child,
    this.actionText,
    this.onAction,
    this.autoEnable = true, // NEW
    this.provider,
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
  }

  @override
  void dispose() {
    // Only dispose providers we created locally
    if (_ownsProvider) {
      provider.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SelectionScope(
      provider: provider,
      child: Scaffold(
        body: SafeArea(child: widget.child),
        bottomNavigationBar: AnimatedBuilder(
          animation: provider,
          builder: (_, __) => _bottomBar(context),
        ),
      ),
    );
  }

  Widget _bottomBar(BuildContext context) {
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
                onPressed: count > 0 ? () {} : null,
                icon: const Icon(Icons.checklist),
                label: Text('$count selected'),
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
