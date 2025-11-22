import 'package:flutter/cupertino.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/presentation/layouts/layout_export.dart';
import 'package:pdf_kit/presentation/pages/page_export.dart';

StatefulShellRoute buildHomeShellRoute({
  required GlobalKey<NavigatorState> homeNavKey,
  required GlobalKey<NavigatorState> fileNavKey,
  required GlobalKey<NavigatorState> settingsNavKey,
}) {
  return // Shell with 3 tabs
  StatefulShellRoute.indexedStack(
    builder: (context, state, navShell) => HomeShell(navigationShell: navShell),
    branches: [
      // Home branch
      StatefulShellBranch(
        navigatorKey: homeNavKey,
        routes: [
          GoRoute(
            name: AppRouteName.home,
            path: '/',
            builder: (context, state) => const HomeTab(),
          ),
        ],
      ),

      // Files branch
      StatefulShellBranch(
        navigatorKey: fileNavKey,
        routes: [
          GoRoute(
            name: AppRouteName.filesRoot,
            path: '/files',
            builder: (context, state) => AndroidFilesScreen(
              initialPath: state.uri.queryParameters['path'],
            ),
            routes: [
              // Use query parameter for the full folder path so slashes are safe
              GoRoute(
                name: AppRouteName.filesFolder,
                path: 'folder',
                builder: (context, state) => AndroidFilesScreen(
                  initialPath: state.uri.queryParameters['path'],
                ),
              ),
              GoRoute(
                name: AppRouteName.filesSearch,
                path: 'search',
                builder: (context, state) => SearchFilesScreen(
                  initialPath: state.uri.queryParameters['path'],
                ),
              ),
            ],
          ),
        ],
      ),

      // Settings branch
      StatefulShellBranch(
        navigatorKey: settingsNavKey,
        routes: [
          GoRoute(
            name: AppRouteName.settings,
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
}
