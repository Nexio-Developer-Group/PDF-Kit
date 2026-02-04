import 'package:flutter/material.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/presentation/pages/page_export.dart';
import 'package:pdf_kit/presentation/provider/provider_export.dart';
import 'package:pdf_kit/presentation/layouts/layout_export.dart';
import 'package:pdf_kit/service/action_callback_manager.dart';
import 'package:pdf_kit/presentation/pages/files_root_page.dart'; // [NEW]
import 'package:pdf_kit/presentation/layouts/file_browser_shell.dart'; // [NEW]

final Set<String> _autoOpenedSelectionIds = <String>{};

String _normalizeOp(String? op) {
  final normalized = (op ?? '').trim().toLowerCase();
  debugPrint('🔧 [_normalizeOp] Input: "$op" → Output: "$normalized"');
  return normalized;
}

String _opFromActionText(String? actionText) {
  final action = (actionText ?? '').toLowerCase();
  debugPrint(
    '🔍 [_opFromActionText] actionText: "$actionText" → lowercase: "$action"',
  );

  String result;
  if (action.contains('unlock')) {
    result = 'unlock';
  } else if (action.contains('protect')) {
    result = 'protect';
  } else if (action.contains('compress')) {
    result = 'compress';
  } else if (action.contains('sign')) {
    result = 'sign';
  } else if (action.contains('images to pdf')) {
    result = 'images_to_pdf';
  } else if (action.contains('reorder')) {
    result = 'reorder';
  } else if (action.contains('split')) {
    result = 'split';
  } else if (action.contains('image')) {
    result = 'pdf_to_image';
  } else {
    result = 'merge';
  }

  debugPrint('🔍 [_opFromActionText] Result: "$result"');
  return result;
}

void _pushOperationRoute({
  required GlobalKey<NavigatorState> rootNavKey,
  required String op,
  required String selectionId,
  int? minSelectable,
  int? maxSelectable,
}) {
  debugPrint('🚀 [_pushOperationRoute] Called with:');
  debugPrint('   op: "$op"');
  debugPrint('   selectionId: "$selectionId"');
  debugPrint('   min: $minSelectable, max: $maxSelectable');

  final q = <String, String>{'selectionId': selectionId};
  if (minSelectable != null) q['min'] = minSelectable.toString();
  if (maxSelectable != null) q['max'] = maxSelectable.toString();

  final normalizedOp = _normalizeOp(op);
  debugPrint('🚀 [_pushOperationRoute] Normalized op: "$normalizedOp"');
  debugPrint('🚀 [_pushOperationRoute] Entering switch statement...');

  switch (normalizedOp) {
    case 'unlock':
      rootNavKey.currentContext!.pushNamed(
        AppRouteName.unlockPdf,
        queryParameters: q,
      );
      return;
    case 'protect':
      rootNavKey.currentContext!.pushNamed(
        AppRouteName.protectPdf,
        queryParameters: q,
      );
      return;
    case 'compress':
      rootNavKey.currentContext!.pushNamed(
        AppRouteName.compressPdf,
        queryParameters: q,
      );
      return;
    case 'sign':
      rootNavKey.currentContext!.pushNamed(
        AppRouteName.signPdf,
        queryParameters: q,
      );
      return;
    case 'images_to_pdf':
      rootNavKey.currentContext!.pushNamed(
        AppRouteName.imagesToPdf,
        queryParameters: q,
      );
      return;
    case 'reorder':
      rootNavKey.currentContext!.pushNamed(
        AppRouteName.reorderPdf,
        queryParameters: q,
      );
      return;
    case 'split':
      rootNavKey.currentContext!.pushNamed(
        AppRouteName.splitPdf,
        queryParameters: q,
      );
      return;
    case 'pdf_to_image':
      rootNavKey.currentContext!.pushNamed(
        AppRouteName.pdfToImage,
        queryParameters: q,
      );
      return;
    case 'merge':
    default:
      rootNavKey.currentContext!.pushNamed(
        AppRouteName.mergePdf,
        queryParameters: q,
      );
      return;
  }
}

ShellRoute buildSelectionShellRoute({
  required GlobalKey<NavigatorState> rootNavKey,
}) {
  return
  // One persistent SelectionScaffold across the fullscreen selection flow
  ShellRoute(
    parentNavigatorKey: rootNavKey,
    builder: (context, state, child) {
      debugPrint('🏗️ [ShellRoute] Builder called for path: ${state.uri.path}');
      debugPrint(
        '🏗️ [ShellRoute] Query parameters: ${state.uri.queryParameters}',
      );

      final actionId = state.uri.queryParameters['actionId'];
      final actionText = state.uri.queryParameters['actionText'];
      final selectionId = state.uri.queryParameters['selectionId'];
      final maxStr = state.uri.queryParameters['max'];
      final minStr = state.uri.queryParameters['min'];
      final allowed = state.uri.queryParameters['allowed'];
      final opParam = state.uri.queryParameters['op'];
      final auto = state.uri.queryParameters['auto'];
      // final fileType = state.uri.queryParameters['fileType'];
      final maxSelectable = int.tryParse(maxStr ?? '');
      final minSelectable = int.tryParse(minStr ?? '');

      debugPrint('🏗️ [ShellRoute] Extracted params:');
      debugPrint('   opParam: "$opParam"');
      debugPrint('   actionText: "$actionText"');
      debugPrint('   selectionId: "$selectionId"');

      SelectionProvider? provided;
      if (selectionId != null) {
        try {
          provided = Get.find<SelectionManager>().of(selectionId);
        } catch (_) {
          provided = null;
        }
      }

      final op = _normalizeOp(opParam).isNotEmpty
          ? _normalizeOp(opParam)
          : _opFromActionText(actionText);

      debugPrint('🏗️ [ShellRoute] Determined op: "$op"');

      // Auto-open operation page (used by the viewer options sheet) while
      // keeping the selection UI underneath for "Add more" flows.
      if (selectionId != null && auto == '1') {
        final key = '$selectionId:$op';
        if (!_autoOpenedSelectionIds.contains(key)) {
          _autoOpenedSelectionIds.add(key);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (rootNavKey.currentContext == null) return;
            _pushOperationRoute(
              rootNavKey: rootNavKey,
              op: op,
              selectionId: selectionId,
              minSelectable: minSelectable,
              maxSelectable: maxSelectable,
            );
          });
        }
      }

      return SelectionScaffold(
        provider: provided,
        actionText: actionText,
        maxSelectable: maxSelectable,
        minSelectable: minSelectable,
        allowed: allowed,
        onAction: (files) {
          debugPrint('🎬 [onAction] Called with ${files.length} files');
          debugPrint('🎬 [onAction] selectionId: "$selectionId"');
          debugPrint('🎬 [onAction] op: "$op"');

          if (selectionId != null) {
            debugPrint(
              '🎬 [onAction] Has selectionId, calling _pushOperationRoute',
            );
            _pushOperationRoute(
              rootNavKey: rootNavKey,
              op: op,
              selectionId: selectionId,
              minSelectable: minSelectable,
              maxSelectable: maxSelectable,
            );
            return;
          }

          debugPrint('🎬 [onAction] No selectionId, using fallback logic');

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
              } else if (action.contains('split')) {
                rootNavKey.currentContext!.pushNamed(
                  AppRouteName.splitPdf,
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
        name: AppRouteName.recentFilesFullscreen,
        path: '/recent-files-fullscreen',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: RecentFilesPage(
            isFullscreenRoute: true,
            selectable: true,
            selectionId: state.uri.queryParameters['selectionId'],
            selectionActionText: state.uri.queryParameters['actionText'],
          ),
        ),
      ),
      GoRoute(
        name: AppRouteName.recentFilesSearchFullscreen,
        path: '/recent-files-search-fullscreen',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: RecentFilesSearchPage(
            isFullscreenRoute: true,
            selectable: true,
            selectionId: state.uri.queryParameters['selectionId'],
            selectionActionText: state.uri.queryParameters['actionText'],
          ),
        ),
      ),
      GoRoute(
        name: AppRouteName.filesRootFullscreen,
        path: '/files-fullscreen',
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: FilesRootPage(
            isFullscreenRoute: true,
            selectionId: state.uri.queryParameters['selectionId'],
            selectionActionText: state.uri.queryParameters['actionText'],
            fileType: state.uri.queryParameters['fileType'],
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
                    fileType: state.uri.queryParameters['fileType'],
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
