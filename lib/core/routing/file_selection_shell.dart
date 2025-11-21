import 'package:flutter/material.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/presentation/pages/page_export.dart';
import 'package:pdf_kit/presentation/provider/provider_export.dart';
import 'package:pdf_kit/presentation/layouts/layout_export.dart';
import 'package:pdf_kit/service/action_callback_manager.dart';

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
      final maxSelectable = int.tryParse(maxStr ?? '');

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
        onAction: (files) {
          if (selectionId != null) {
            // Decide target route based on actionText
            if (actionText?.toLowerCase() == 'compress') {
              rootNavKey.currentContext!.pushNamed(
                AppRouteName.compressPdf,
                queryParameters: {'selectionId': selectionId},
              );
            } else {
              rootNavKey.currentContext!.pushNamed(
                AppRouteName.mergePdf,
                queryParameters: {'selectionId': selectionId},
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
              if (actionText?.toLowerCase() == 'compress') {
                rootNavKey.currentContext!.pushNamed(
                  AppRouteName.compressPdf,
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
          child: AndroidFilesScreen(
            initialPath: state.uri.queryParameters['path'],
            selectable: true,
            isFullscreenRoute: true,
            selectionId: state.uri.queryParameters['selectionId'],
            selectionActionText: state.uri.queryParameters['actionText'],
          ),
        ),
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
                selectionActionText: state.uri.queryParameters['actionText'],
              ),
            ),
          ),
          GoRoute(
            name: AppRouteName.filesSearchFullscreen, // NEW
            path: 'search',
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              child: SearchFilesScreen(
                initialPath: state.uri.queryParameters['path'],
                selectable: true, // NEW
                isFullscreenRoute: true, // NEW
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
