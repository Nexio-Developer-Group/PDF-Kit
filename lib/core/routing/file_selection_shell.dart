import 'package:flutter/material.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/presentation/pages/page_export.dart';
import 'package:pdf_kit/presentation/provider/provider_export.dart';
import 'package:pdf_kit/presentation/layouts/layout_export.dart';
import 'package:pdf_kit/service/action_callback_manager.dart';
import 'package:pdf_kit/presentation/pages/files_root_page.dart'; // [NEW]
import 'package:pdf_kit/presentation/layouts/file_browser_shell.dart'; // [NEW]

ShellRoute buildSelectionShellRoute({
  required GlobalKey<NavigatorState> rootNavKey,
}) {
  return
  // One persistent SelectionScaffold across the fullscreen selection flow
  ShellRoute(
    parentNavigatorKey: rootNavKey,
    builder: (context, state, child) {
      final actionId = state.uri.queryParameters['actionId'];
      final actionText = state.uri.queryParameters['actionText'];
      final selectionId = state.uri.queryParameters['selectionId'];
      final maxStr = state.uri.queryParameters['max'];
      final minStr = state.uri.queryParameters['min'];
      final allowed = state.uri.queryParameters['allowed'];
      final maxSelectable = int.tryParse(maxStr ?? '');
      final minSelectable = int.tryParse(minStr ?? '');

      SelectionProvider? provided;
      if (selectionId != null) {
        try {
          provided = Get.find<SelectionManager>().of(selectionId);
        } catch (_) {
          provided = null;
        }
      }

      return SelectionScaffold(
        provider: provided,
        actionText: actionText,
        maxSelectable: maxSelectable,
        minSelectable: minSelectable,
        allowed: allowed,
        onAction: (files) {
          if (selectionId != null) {
            // Decide target route based on actionText
            final action = actionText?.toLowerCase() ?? '';

            // Check for specific actions in order (most specific first)
            if (action.contains('unlock')) {
              rootNavKey.currentContext!.pushNamed(
                AppRouteName.unlockPdf,
                queryParameters: {
                  'selectionId': selectionId,
                  if (minSelectable != null) 'min': minSelectable.toString(),
                  if (maxSelectable != null) 'max': maxSelectable.toString(),
                },
              );
            } else if (action.contains('protect')) {
              rootNavKey.currentContext!.pushNamed(
                AppRouteName.protectPdf,
                queryParameters: {
                  'selectionId': selectionId,
                  if (minSelectable != null) 'min': minSelectable.toString(),
                  if (maxSelectable != null) 'max': maxSelectable.toString(),
                },
              );
            } else if (action.contains('compress')) {
              rootNavKey.currentContext!.pushNamed(
                AppRouteName.compressPdf,
                queryParameters: {
                  'selectionId': selectionId,
                  if (minSelectable != null) 'min': minSelectable.toString(),
                  if (maxSelectable != null) 'max': maxSelectable.toString(),
                },
              );
            } else if (action.contains('sign')) {
              rootNavKey.currentContext!.pushNamed(
                AppRouteName.signPdf,
                queryParameters: {
                  'selectionId': selectionId,
                  if (minSelectable != null) 'min': minSelectable.toString(),
                  if (maxSelectable != null) 'max': maxSelectable.toString(),
                },
              );
            } else if (action.contains('images to pdf')) {
              rootNavKey.currentContext!.pushNamed(
                AppRouteName.imagesToPdf,
                queryParameters: {
                  'selectionId': selectionId,
                  if (minSelectable != null) 'min': minSelectable.toString(),
                  if (maxSelectable != null) 'max': maxSelectable.toString(),
                },
              );
            } else if (action.contains('reorder')) {
              rootNavKey.currentContext!.pushNamed(
                AppRouteName.reorderPdf,
                queryParameters: {
                  'selectionId': selectionId,
                  if (minSelectable != null) 'min': minSelectable.toString(),
                  if (maxSelectable != null) 'max': maxSelectable.toString(),
                },
              );
            } else if (action.contains('image')) {
              rootNavKey.currentContext!.pushNamed(
                AppRouteName.pdfToImage,
                queryParameters: {
                  'selectionId': selectionId,
                  if (minSelectable != null) 'min': minSelectable.toString(),
                  if (maxSelectable != null) 'max': maxSelectable.toString(),
                },
              );
            } else {
              rootNavKey.currentContext!.pushNamed(
                AppRouteName.mergePdf,
                queryParameters: {
                  'selectionId': selectionId,
                  if (minSelectable != null) 'min': minSelectable.toString(),
                  if (maxSelectable != null) 'max': maxSelectable.toString(),
                },
              );
            }
            return;
          }

          // No selectionId -> fall back to actionId-based callbacks.
          if (actionId != null) {
            final manager = Get.find<ActionCallbackManager>();
            final callback = manager.get(actionId);
            if (callback != null) {
              callback(files);
              manager.clear(); // cleanup after use
            } else {
              // Fallback decides route by actionText
              final action = actionText?.toLowerCase() ?? '';
              if (action.contains('compress')) {
                rootNavKey.currentContext!.pushNamed(
                  AppRouteName.compressPdf,
                  extra: files,
                );
              } else if (action.contains('sign')) {
                rootNavKey.currentContext!.pushNamed(
                  AppRouteName.signPdf,
                  extra: files,
                );
              } else if (action.contains('protect')) {
                rootNavKey.currentContext!.pushNamed(
                  AppRouteName.protectPdf,
                  extra: files,
                );
              } else if (action.contains('unlock')) {
                rootNavKey.currentContext!.pushNamed(
                  AppRouteName.unlockPdf,
                  extra: files,
                );
              } else if (action.contains('images to pdf')) {
                rootNavKey.currentContext!.pushNamed(
                  AppRouteName.imagesToPdf,
                  extra: files,
                );
              } else if (action.contains('reorder')) {
                rootNavKey.currentContext!.pushNamed(
                  AppRouteName.reorderPdf,
                  extra: files,
                );
              } else if (action.contains('image')) {
                rootNavKey.currentContext!.pushNamed(
                  AppRouteName.pdfToImage,
                  extra: files,
                );
              } else {
                rootNavKey.currentContext!.pushNamed(
                  AppRouteName.mergePdf,
                  extra: files,
                );
              }
            }
          }
        },
        child: child,
      );
    },
    routes: [
      GoRoute(
        name: AppRouteName.filesRootFullscreen,
        path: '/files-fullscreen',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: FilesRootPage(
            isFullscreenRoute: true,
            selectionId: state.uri.queryParameters['selectionId'],
            selectionActionText: state.uri.queryParameters['actionText'],
          ),
        ),
        routes: [
          // Persistent shell for folder browsing in selection mode
          ShellRoute(
            pageBuilder: (context, state, child) {
              return MaterialPage(
                key: state.pageKey,
                child: FileBrowserShell(
                  selectable: true,
                  isFullscreenRoute: true,
                  selectionId: state.uri.queryParameters['selectionId'],
                  selectionActionText: state.uri.queryParameters['actionText'],
                  child: child,
                ),
              );
            },
            routes: [
              GoRoute(
                name: AppRouteName.filesFolderFullScreen,
                path: 'folder',
                pageBuilder: (context, state) => MaterialPage(
                  key: state.pageKey,
                  child: AndroidFilesScreen(
                    initialPath: state.uri.queryParameters['path'],
                    selectable: true,
                    isFullscreenRoute: true,
                    selectionId: state.uri.queryParameters['selectionId'],
                    selectionActionText:
                        state.uri.queryParameters['actionText'],
                  ),
                ),
              ),
            ],
          ),
          // Search stays as direct child (no shell)
          GoRoute(
            name: AppRouteName.filesSearchFullscreen,
            path: 'search',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: SearchFilesScreen(
                initialPath: state.uri.queryParameters['path'],
                selectable: true,
                isFullscreenRoute: true,
                selectionId: state.uri.queryParameters['selectionId'],
                selectionActionText: state.uri.queryParameters['actionText'],
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
