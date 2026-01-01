import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ProgressDialogController {
  bool _open = false;

  bool get isOpen => _open;

  void show({
    required BuildContext context,
    required String title,
    required ValueListenable<double> progress,
    required ValueListenable<String> stage,
  }) {
    if (_open) return;
    _open = true;

    unawaited(
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (_) {
          return PopScope(
            canPop: false,
            child: AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ValueListenableBuilder<double>(
                      valueListenable: progress,
                      builder: (_, value, __) {
                        final pct = (value * 100)
                            .clamp(0, 100)
                            .toStringAsFixed(0);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LinearProgressIndicator(
                              value: value.clamp(0.0, 1.0),
                            ),
                            const SizedBox(height: 8),
                            Text('$pct%'),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<String>(
                      valueListenable: stage,
                      builder: (_, value, __) {
                        return Text(
                          value,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text('Please keep the app open while we finish.'),
                  ],
                ),
              ),
            ),
          );
        },
      ).whenComplete(() {
        _open = false;
      }),
    );
  }

  void dismiss(BuildContext context) {
    if (!_open) return;
    final nav = Navigator.of(context, rootNavigator: true);
    if (nav.canPop()) {
      nav.pop();
    }
    _open = false;
  }
}
