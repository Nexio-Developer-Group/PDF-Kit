// android_files_screen.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/presentation/component/document_tile.dart';
import 'package:pdf_kit/presentation/component/folder_tile.dart';
import 'package:pdf_kit/service/file_system_serevice.dart';
import 'package:pdf_kit/service/open_service.dart';
import 'package:pdf_kit/service/path_service.dart';
import 'package:pdf_kit/service/permission_service.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/presentation/sheets/new_folder_sheet.dart';

class AndroidFilesScreen extends StatefulWidget {
  final String? initialPath;
  const AndroidFilesScreen({super.key, this.initialPath});
  @override
  State<AndroidFilesScreen> createState() => _AndroidFilesScreenState();
}

class _AndroidFilesScreenState extends State<AndroidFilesScreen> {
  List<Directory> _roots = [];
  String? _currentPath;
  List<FileInfo> _entries = [];

  // Search-related fields left intact in case you reuse filtering locally later.
  String _query = '';
  bool _searching = false;
  StreamSubscription? _searchSub;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  @override
  void dispose() {
    _searchSub?.cancel();
    super.dispose();
  }

  Future<void> _boot() async {
    final perm = await PermissionService.requestStoragePermission();
    perm.fold((_) {}, (ok) async {
      if (!ok) return;
      final vols = await PathService.volumes();
      vols.fold((_) {}, (dirs) async {
        setState(() => _roots = dirs);
        final startPath =
            widget.initialPath ?? (dirs.isNotEmpty ? dirs.first.path : null);
        if (startPath != null) await _open(startPath);
      });
    });
  }

  Future<void> _open(String path) async {
    _cancelSearch();
    final res = await FileSystemService.list(path);
    res.fold((_) {}, (items) {
      setState(() {
        _currentPath = path;
        _entries = items;
        _query = '';
        _searching = false;
      });
    });
  }

  void _cancelSearch() {
    _searchSub?.cancel();
    _searchSub = null;
  }

  Future<void> _openFolder(String path) async {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AndroidFilesScreen(initialPath: path)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // No in-place searching here; this screen only lists.
    final items = _entries;
    final folders = items.where((e) => e.isDirectory).toList();
    final files = items.where((e) => !e.isDirectory).toList();

    return Scaffold(
      // Custom header replaces AppBar
      body: SafeArea(
        child: Padding(
          padding: screenPadding,
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: _currentPath == null
                    ? _buildRoots()
                    : _buildListing(folders, files, context),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
        tooltip: 'Back to Roots',
        child: const Icon(Icons.home),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      child: Row(
        children: [
          // Left: app glyph (simple circle + star to emulate Files brand feel)
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.widgets_rounded,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Files',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Go to dedicated search screen, pass the current path.
              Navigator.pushNamed(
                context,
                AppRoutes.search,
                arguments: {'path': _currentPath},
              );
            },
            tooltip: 'Search',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
            tooltip: 'More',
          ),
        ],
      ),
    );
  }

  Widget _buildRoots() => ListView(
    children: _roots
        .map(
          (d) => ListTile(
            leading: const Icon(Icons.sd_storage),
            title: Text(d.path),
            onTap: () => _openFolder(d.path),
          ),
        )
        .toList(),
  );

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () => _open(_currentPath!),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          const SizedBox(height: 56),
          Center(child: Image.asset('assets/not_found.png')),
          const SizedBox(height: 12),
          Text(
            'This folder is empty',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildListing(List<FileInfo> folders, List<FileInfo> files, BuildContext context) {
    final isEmpty = folders.isEmpty && files.isEmpty;

    return Column(
      children: [
        // Fixed (non-scrollable) toolbar
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                'Total: ${folders.length + files.length} items',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              const IconButton(
                padding: EdgeInsets.all(0),
                onPressed: null,
                icon: Icon(Icons.import_export_rounded),
              ),
              IconButton(
                onPressed:() {showNewFolderSheet(context: context, onCreate: null);},
                icon: Icon(Icons.create_new_folder_outlined),
              ),
            ],
          ),
        ),

        // Scrollable content only
        Expanded(
          child: isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () => _open(_currentPath!),
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 16),
                    children: [
                      // Folders
                      ...folders.map(
                        (f) => Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 12,
                          ),
                          child: FolderEntryCard(
                            info: f,
                            onTap: () => _openFolder(f.path),
                            onMenuSelected: (v) => _handleFolderMenu(v, f),
                          ),
                        ),
                      ),
                      // Files
                      ...files.map(
                        (f) => Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 12,
                          ),
                          child: DocEntryCard(
                            info: f,
                            onOpen: () => OpenService.open(f.path),
                            onMenu: (v) => _handleFileMenu(v, f),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  void _handleFolderMenu(String v, FileInfo f) {
    switch (v) {
      case 'open':
        _openFolder(f.path);
        break;
      case 'rename':
        break;
      case 'delete':
        break;
    }
  }

  void _handleFileMenu(String v, FileInfo f) {
    switch (v) {
      case 'open':
        OpenService.open(f.path);
        break;
      case 'rename':
        break;
      case 'delete':
        break;
    }
  }
}
