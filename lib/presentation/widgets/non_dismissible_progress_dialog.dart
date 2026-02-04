import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf_kit/core/app_export.dart';

class ProgressDialogController {
  bool _open = false;

  bool get isOpen => _open;

  String _tOrFallback(AppLocalizations t, String key, String fallback) {
    final v = t.t(key);
    return v == key ? fallback : v;
  }

  String _localizeStage(BuildContext context, String value) {
    final t = AppLocalizations.of(context);

    // If the value starts with a known progress key prefix, it's a localization key
    if (value.startsWith('progress_stage_')) {
      return _tOrFallback(t, value, value);
    }

    // Legacy fallback for hardcoded strings (in case other parts still use them)
    String? key;
    switch (value) {
      case 'Preparing…':
        key = 'progress_stage_preparing';
        break;
      case 'Starting…':
        key = 'progress_stage_starting';
        break;
      case 'Analyzing PDF…':
        key = 'progress_stage_analyzing_pdf';
        break;
      case 'Compressing…':
        key = 'progress_stage_compressing';
        break;
      case 'Finalizing…':
        key = 'progress_stage_finalizing';
        break;
      case 'Done':
        key = 'progress_stage_done';
        break;
    }

    if (key == null) return value;
    return _tOrFallback(t, key, value);
  }

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
          final t = AppLocalizations.of(context);
          final keepOpen = _tOrFallback(
            t,
            'progress_dialog_keep_open',
            'Please keep the app open while we finish.',
          );

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
                    // Fixed height container to prevent flickering
                    SizedBox(
                      height: 40, // Fixed height for stage text (2 lines max)
                      child: ValueListenableBuilder<String>(
                        valueListenable: stage,
                        builder: (context, value, __) {
                          return Text(
                            _localizeStage(context, value),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(keepOpen),
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
