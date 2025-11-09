import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf_kit/core/models/file_model.dart';
import 'package:pdf_kit/service/file_system_serevice.dart';
import 'package:pdf_kit/service/open_service.dart';
import 'package:pdf_kit/service/path_service.dart';
import 'package:pdf_kit/service/permission_service.dart';

class AndroidFilesScreen extends StatefulWidget {
  const AndroidFilesScreen({super.key});
  @override
  State<AndroidFilesScreen> createState() => _AndroidFilesScreenState();
}

class _AndroidFilesScreenState extends State<AndroidFilesScreen> {
  List<Directory> _roots = [];
  String? _currentPath;
  List<FileInfo> _entries = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final perm = await PermissionService.requestStoragePermission();
    perm.fold((_) {}, (ok) async {
      if (!ok) return;
      final vols = await PathService.volumes();
      vols.fold((_) {}, (dirs) async {
        setState(() => _roots = dirs);
        if (dirs.isNotEmpty) await _open(dirs.first.path);
      });
    });
  }

  Future<void> _open(String path) async {
    final res = await FileSystemService.list(path);
    res.fold((_) {}, (items) {
      setState(() {
        _currentPath = path;
        _entries = items;
      });
    });
  }

  Future<void> _search(String q) async {
    if (_currentPath == null) return;
    if (q.isEmpty) return _open(_currentPath!);
    final res = await FileSystemService.search(_currentPath!, q, recursive: true);
    res.fold((_) {}, (items) => setState(() => _entries = items));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? _entries
        : _entries.where((e) => e.name.toLowerCase().contains(_query.toLowerCase())).toList();

    final folders = filtered.where((e) => e.isDirectory).toList();
    final files = filtered.where((e) => !e.isDirectory).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentPath ?? 'Storage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final q = await showSearch<String>(
                context: context,
                delegate: _QueryDelegate(initial: _query),
              );
              if (q != null) {
                setState(() => _query = q);
                await _search(q);
              }
            },
          ),
        ],
      ),
      body: _currentPath == null ? _buildRoots() : _buildListing(folders, files),
    );
  }

  Widget _buildRoots() => ListView(
        children: _roots
            .map((d) => ListTile(
                  leading: const Icon(Icons.sd_storage),
                  title: Text(d.path),
                  onTap: () => _open(d.path),
                ))
            .toList(),
      );

  Widget _buildListing(List<FileInfo> folders, List<FileInfo> files) => RefreshIndicator(
        onRefresh: () => _open(_currentPath!),
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text('Total: ${folders.length + files.length} items'),
            ),
            if (folders.isNotEmpty) const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('Folders'),
            ),
            ...folders.map((f) => ListTile(
                  leading: const Icon(Icons.folder),
                  title: Text(f.name),
                  subtitle: Text('${f.mediaInfo?['children'] ?? 0} items'),
                  onTap: () => _open(f.path),
                )),
            const Divider(),
            ...files.map((f) => ListTile(
                  leading: Icon(_iconFor(f)),
                  title: Text(f.name),
                  subtitle: Text('${f.readableSize} • ${f.lastModified ?? ''}'),
                  onTap: () => OpenService.open(f.path),
                )),
          ],
        ),
      );

  IconData _iconFor(FileInfo f) {
    final m = f.mimeType ?? '';
    final e = f.extension;
    if (e == 'pdf') return Icons.picture_as_pdf;
    if (m.startsWith('image/')) return Icons.image;
    return Icons.insert_drive_file;
  }
}

class _QueryDelegate extends SearchDelegate<String> {
  final String initial;
  _QueryDelegate({this.initial = ''}) { query = initial; }
  @override List<Widget>? buildActions(BuildContext context) =>
      [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];
  @override Widget? buildLeading(BuildContext context) =>
      IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, initial));
  @override Widget buildResults(BuildContext context) => const SizedBox.shrink();
  @override Widget buildSuggestions(BuildContext context) => const SizedBox.shrink();
}
