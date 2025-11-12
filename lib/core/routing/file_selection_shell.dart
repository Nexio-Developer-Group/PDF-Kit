import 'package:flutter/cupertino.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/presentation/pages/page_export.dart';
import 'package:pdf_kit/presentation/provider/provider_export.dart';
import 'package:pdf_kit/presentation/layouts/layout_export.dart';
import 'package:pdf_kit/service/action_callback_manager.dart';


ShellRoute buildSelectionShellRoute({required GlobalKey<NavigatorState> rootNavKey}) {
  return
  // One persistent SelectionScaffold across the fullscreen selection flow
  ShellRoute(
    parentNavigatorKey: rootNavKey,
    builder: (context, state, child) {
      final actionId = state.uri.queryParameters['actionId'];
      final actionText = state.uri.queryParameters['actionText'];
      final selectionId = state.uri.queryParameters['selectionId'];

      // If a selectionId is present, reuse the cached provider from SelectionManager
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
        onAction: (files) {
          if (selectionId != null) {
            Navigator.of(context).pop();
            return;
          }

          if (actionId != null) {
            final manager = Get.find<ActionCallbackManager>();
            final callback = manager.get(actionId);

            if (callback != null) {
              callback(files);
              manager.clear(); // cleanup after use
            } else {
              // Fallback to default action
              rootNavKey.currentContext!.pushNamed(
                AppRouteName.mergePdf,
                extra: files,
              );
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
        builder: (context, state) => AndroidFilesScreen(
          initialPath: state.uri.queryParameters['path'],
          selectable: true,
          isFullscreenRoute: true,
          selectionId: state.uri.queryParameters['selectionId'],
          selectionActionText: state.uri.queryParameters['actionText'],
        ),
        routes: [
          GoRoute(
            name: AppRouteName.filesFolderFullScreen,
            path: 'folder',
            builder: (context, state) => AndroidFilesScreen(
              initialPath: state.uri.queryParameters['path'],
              selectable: true,
              isFullscreenRoute: true,
              selectionId: state.uri.queryParameters['selectionId'],
              selectionActionText: state.uri.queryParameters['actionText'],
            ),
          ),
          GoRoute(
            name: AppRouteName.filesSearchFullscreen, // NEW
            path: 'search',
            builder: (context, state) => SearchFilesScreen(
              initialPath: state.uri.queryParameters['path'],
              selectable: true, // NEW
              isFullscreenRoute: true, // NEW
              selectionId: state.uri.queryParameters['selectionId'],
              selectionActionText: state.uri.queryParameters['actionText'],
            ),
          ),
        ],
      ),
    ],
  );
}
