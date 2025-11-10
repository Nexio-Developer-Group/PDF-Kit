// search_files_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/presentation/component/document_tile.dart';
import 'package:pdf_kit/presentation/component/folder_tile.dart';
import 'package:pdf_kit/service/file_system_serevice.dart';
import 'package:pdf_kit/service/open_service.dart';

class SearchFilesScreen extends StatefulWidget {
  final String? initialPath;
  const SearchFilesScreen({super.key, this.initialPath});
  @override
  State<SearchFilesScreen> createState() => _SearchFilesScreenState();
}

class _SearchFilesScreenState extends State<SearchFilesScreen> {
  final TextEditingController _controller = TextEditingController();
  StreamSubscription? _sub;

  // Results and helpers
  final List<FileInfo> _results = [];
  final Set<String> _seen = <String>{};

  String _query = '';
  bool _searching = false;

  // Batching to reduce rebuild frequency
  Timer? _batchTimer;
  final List<FileInfo> _pending = [];

  // Fake “Previous Search” seeds for now
  final List<String> _previous = const [
    'My Home Certificate',
    'Work Documents',
    'Recommendation Letter',
    'Sales Report Documents',
    'Business Plan Proposal',
    'Job Application Letter',
    'Legal & Terms of Reference',
    'My National ID Card',
  ];

  @override
  void dispose() {
    _sub?.cancel();
    _batchTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _start(String q) {
    _sub?.cancel();

    setState(() {
      _query = q;
      _searching = q.isNotEmpty && widget.initialPath != null;
      // Clear previous results at the start of every new query
      _results.clear();
      _seen.clear();
      _pending.clear();
    });

    if (q.isEmpty || widget.initialPath == null) {
      return;
    }

    final stream = FileSystemService.searchStream(widget.initialPath!, q);
    _sub = stream.listen(
      (either) {
        either.fold(
          (_) {}, // You can surface an error snackbar if desired
          (fi) {
            // Avoid duplicates
            if (_seen.add(fi.path)) {
              _pending.add(fi);
              _scheduleFlush();
            }
          },
        );
      },
      onDone: () => setState(() => _searching = false),
      onError: (_) => setState(() => _searching = false),
    );
  }

  void _scheduleFlush() {
    // Flush batched results ~30fps to avoid flicker
    _batchTimer ??= Timer(const Duration(milliseconds: 32), () {
      if (!mounted) return;
      setState(() {
        _results.addAll(_pending);
        _pending.clear();
      });
      _batchTimer = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _query.isNotEmpty;
    final noResults = hasQuery && !_searching && _results.isEmpty;

    // The service yields only files, but keep the split in case you later include dirs.
    final folders = _results.where((e) => e.isDirectory).toList();
    final files = _results.where((e) => !e.isDirectory).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _searchBar(context),
            if (!hasQuery) _previousSection(context),
            if (hasQuery && !noResults) Expanded(child: _list(folders, files)),
            if (noResults) _emptyState(context),
          ],
        ),
      ),
    );
  }

  Widget _searchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.arrow_back),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withAlpha((0.6 * 225).toInt()),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: (q) {
                  _start(q); // Rebuilds happen inside _start
                },
                style: Theme.of(context).textTheme.labelLarge,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search files and folders...',
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: (_controller.text.isNotEmpty)
                      ? IconButton(
                          constraints: const BoxConstraints(
                            minWidth: 28,
                            minHeight: 28,
                          ),
                          iconSize: 18,
                          padding: const EdgeInsets.all(5),
                          tooltip: 'Clear',
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _controller.clear();
                            _start('');
                          },
                        )
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previousSection(BuildContext context) {
    return Expanded(
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Row(
              children: [
                Text(
                  'Previous Search',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () {}, // optional: clear all later
                  icon: const Icon(Icons.close),
                  tooltip: 'Clear all',
                ),
              ],
            ),
          ),
          ..._previous.map(
            (label) => ListTile(
              title: Text(label),
              trailing: const Icon(Icons.close, size: 18),
              onTap: () {
                _controller.text = label;
                _controller.selection =
                    TextSelection.collapsed(offset: label.length);
                _start(label);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(List<FileInfo> folders, List<FileInfo> files) {
    // Use the growing _results list directly to keep order and identity
    final items = _results;

    return RefreshIndicator(
      onRefresh: () async {
        _sub?.cancel();
        setState(() {
          _results.clear();
          _seen.clear();
          _pending.clear();
        });
        _start(_query);
      },
      child: ListView.builder(
        key: const PageStorageKey('search_list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final f = items[index];
          return RepaintBoundary(
            key: ValueKey(f.path),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              child: f.isDirectory
                  ? FolderEntryCard(
                      info: f,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                SearchFilesScreen(initialPath: f.path),
                          ),
                        );
                      },
                      onMenuSelected: (_) {},
                    )
                  : DocEntryCard(
                      info: f,
                      onOpen: () => OpenService.open(f.path),
                      onMenu: (_) {},
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/not_found.png'),
              const SizedBox(height: 12),
              Text(
                'Not Found',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                "Please search with another keywords.",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
