import 'package:flutter/material.dart';
import 'package:pdf_kit/core/localization/app_localizations.dart';
import 'package:pdf_kit/core/routing/app_router.dart';
import 'package:pdf_kit/core/routing/app_route_name.dart';
import 'package:pdf_kit/service/pdf_protect_service.dart';
import 'package:pdf_kit/service/open_service.dart';

import 'app_keys.dart';

class AppSnackbar {
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>?
  showSnackBar(SnackBar snackBar) {
    final messenger = snackbarKey.currentState;
    if (messenger == null) return null;

    messenger.removeCurrentSnackBar();
    return messenger.showSnackBar(snackBar);
  }

  /// Shows a localized success snackbar with a custom message and a filled
  /// "Open" button.
  ///
  /// - For PDFs and images: opens in-app via `AppRouteName.pdfViewer`.
  /// - For password-protected PDFs: opens in native viewer via `OpenService`.
  /// - For other file types: opens in native viewer via `OpenService`.
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>?
  showSuccessWithOpen({
    required String message,
    required String path,
    bool openProtectedInNativeViewer = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final ctx = snackbarKey.currentContext;
    final t = ctx != null ? AppLocalizations.of(ctx) : null;

    final openSnack = t?.t('common_open_snackbar') ?? 'common_open_snackbar';
    final openLabel = openSnack != 'common_open_snackbar'
        ? openSnack
        : (t?.t('common_open') ?? 'Open');

    bool isImagePath(String p) {
      final lower = p.toLowerCase();
      return lower.endsWith('.jpg') ||
          lower.endsWith('.jpeg') ||
          lower.endsWith('.png') ||
          lower.endsWith('.webp') ||
          lower.endsWith('.gif') ||
          lower.endsWith('.bmp') ||
          lower.endsWith('.heic') ||
          lower.endsWith('.heif');
    }

    Future<void> open() async {
      // Close snackbar immediately for a cleaner UX.
      snackbarKey.currentState?.hideCurrentSnackBar();

      final lower = path.toLowerCase();
      final isPdf = lower.endsWith('.pdf');
      final isImage = isImagePath(path);

      // Always allow forcing native open (used by Protect flow).
      if (isPdf && openProtectedInNativeViewer) {
        OpenService.open(path);
        return;
      }

      // Other file types: native open.
      if (!isPdf && !isImage) {
        OpenService.open(path);
        return;
      }

      if (isPdf) {
        final isProtectedResult = await PdfProtectionService.isPdfProtected(
          pdfPath: path,
        );

        final isProtected = isProtectedResult.fold((_) => false, (r) => r);
        if (isProtected) {
          OpenService.open(path);
          return;
        }
      }

      appRouter.pushNamed(
        AppRouteName.pdfViewer,
        queryParameters: {'path': path, 'showOptionsSheet': 'false'},
      );
    }

    final background = Colors.green.shade700;
    final foreground = Colors.white;

    return showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: background,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        duration: duration,
        content: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: foreground),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () => open(),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: background,
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(openLabel),
            ),
          ],
        ),
      ),
    );
  }

  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? show(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    Color? backgroundColor,
    SnackBarBehavior? behavior,
  }) {
    return showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
        backgroundColor: backgroundColor,
        behavior: behavior,
      ),
    );
  }

  /// Shows a short localized success snackbar ("Done") with a single clean
  /// "Open" action.
  ///
  /// - For PDFs and images: opens in-app via `AppRouteName.pdfViewer`.
  /// - For password-protected PDFs: opens in native viewer via `OpenService`.
  /// - For other file types: opens in native viewer via `OpenService`.
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>?
  showDoneWithOpen({
    required String path,
    bool openProtectedInNativeViewer = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    final ctx = snackbarKey.currentContext;
    final t = ctx != null ? AppLocalizations.of(ctx) : null;

    final doneText = t?.t('common_done') ?? 'Done';

    return showSuccessWithOpen(
      message: doneText,
      path: path,
      openProtectedInNativeViewer: openProtectedInNativeViewer,
      duration: duration,
    );
  }
}
