import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// NOTE: FilesTabWithRouter is no longer needed with go_router's StatefulShellRoute.
// The shell injects a StatefulNavigationShell that manages per-branch Navigators.

class HomeShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const HomeShell({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Renders the active branch's Navigator (keeps each tab's back stack/state)
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          // Switch tabs without pushing; preserve existing stacks
          navigationShell.goBranch(
            index,
            // If tapping the already-selected tab, you can choose to pop to its root
            // by setting initialLocation: true; set false to keep current location.
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_open_outlined),
            selectedIcon: Icon(Icons.folder),
            label: 'Files',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
