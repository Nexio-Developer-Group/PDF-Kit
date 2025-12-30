import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/service/file_service.dart';
import 'package:pdf_kit/service/file_system_serevice.dart';
import 'package:pdf_kit/service/folder_service.dart';

import 'package:pdf_kit/service/path_service.dart';

/// A centralized provider for File System access.
///
/// uses [FileSystemService] and [FileService] to fetch data,
/// but caches it here to allow multiple UI listeners (tabs/screens)
/// to stay in sync.
class FileSystemProvider extends ChangeNotifier with WidgetsBindingObserver {
  // --- State ---

  /// Available storage roots
  List<Directory> _roots = [];

  /// Cache of folder path -> list of files
  final Map<String, List<FileInfo>> _cache = {};

  /// Cache of folder path -> error message (if any)
  final Map<String, String> _errors = {};

  /// Track loading state per folder
  final Set<String> _loading = {};

  /// Global search results
  final List<FileInfo> _searchResults = [];
  bool _isSearching = false;
  String _currentQuery = '';

  // --- Getters ---

  bool isLoading(String path) => _loading.contains(path);
  String? error(String path) => _errors[path];
  String get currentQuery => _currentQuery;
  List<Directory> get roots => List.unmodifiable(_roots);

  /// Get cached files for a path. Returns empty if not loaded.
  /// Use [subscribeTo] or [load] to ensure data is present.
  List<FileInfo> filesFor(String path) => _cache[path] ?? [];

  bool get isSearching => _isSearching;
  List<FileInfo> get searchResults => List.unmodifiable(_searchResults);

  // --- Lifecycle ---

  FileSystemProvider() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAllActive();
    }
  }

  // --- Actions ---

  /// Check if a directory exists locally
  Future<bool> directoryExists(String path) async {
    try {
      final dir = Directory(path);
      return await dir.exists();
    } catch (e) {
      return false;
    }
  }

  Future<void> loadRoots() async {
    print('🔍 [FileSystemProvider] loadRoots called');
    final res = await PathService.volumes();
    res.fold(
      (err) {
        print('❌ [FileSystemProvider] loadRoots error: $err');
      },
      (dirs) {
        print('✅ [FileSystemProvider] loadRoots success: $dirs');
        _roots = dirs;
        notifyListeners();
      },
    );
  }

  /// Load files for a specific path.
  /// [forceRefresh] will ignore cache and fetch from disk.
  Future<void> load(String path, {bool forceRefresh = false}) async {
    print(
      '🔍 [FileSystemProvider] load called for: $path (forceRefresh: $forceRefresh)',
    );
    if (!forceRefresh && _cache.containsKey(path)) {
      print('📦 [FileSystemProvider] returning cached for: $path');
      // Data exists, but maybe check if it's stale?
      // For now, trust cache unless forced or auto-refreshed.
      return;
    }

    if (_loading.contains(path)) {
      print('⏳ [FileSystemProvider] already loading: $path');
      return; // Already loading
    }

    _loading.add(path);
    _errors.remove(path); // Clear previous errors
    notifyListeners();

    final result = await FileSystemService.list(path);

    _loading.remove(path);

    result.fold(
      (error) {
        print('❌ [FileSystemProvider] error loading $path: $error');
        _errors[path] = error.toString();
        // keep old cache if exists? or clear?
        // _cache.remove(path);
      },
      (files) {
        print('✅ [FileSystemProvider] loaded ${files.length} items for $path');
        _cache[path] = files;
      },
    );
    notifyListeners();
  }

  /// Reload all currently cached paths.
  /// Useful when app resumes or a global change happens.
  Future<void> _refreshAllActive() async {
    // Only refresh paths that we have cached (meaning a UI visited them)
    final pathsToRefresh = _cache.keys.toList();
    for (final path in pathsToRefresh) {
      await load(path, forceRefresh: true);
    }
  }

  Future<void> createFolder(
    String parentPath,
    String folderName, {
    bool requireAllFiles = false,
  }) async {
    final res = await FolderServiceAndroid.createFolder(
      basePath: parentPath,
      folderName: folderName,
      requireAllFilesAccess: requireAllFiles,
      recursive: true,
    );

    await res.fold(
      (err) async {
        // Just notify listener of error? Or throw?
        // Ideally we return the Either, but for state consistency we refresh.
        // For UI feedback, the caller might want the result.
        // We can just refresh to be safe.
      },
      (_) async {
        // Success: Refresh the parent folder
        await load(parentPath, forceRefresh: true);
      },
    );
  }

  Future<void> renameFile(FileInfo file, String newName) async {
    final result = await FileService.renameFile(file, newName);

    await result.fold(
      (err) async {
        // Error handling if needed
      },
      (newFile) async {
        // Update cache locally for immediate UI response
        final parent = file.parentDirectory ?? p.dirname(file.path);

        // Optimistic update
        if (_cache.containsKey(parent)) {
          final list = _cache[parent]!;
          final idx = list.indexWhere((f) => f.path == file.path);
          if (idx != -1) {
            list[idx] = newFile;
            // Re-sort might be needed if sorted by name,
            // but the view usually handles sorting.
            // We just update the data source.
            notifyListeners();
          } else {
            await load(parent, forceRefresh: true);
          }
        } else {
          await load(parent, forceRefresh: true);
        }
      },
    );
  }

  Future<void> deleteFile(FileInfo file) async {
    final result = await FileService.deleteFile(file);

    await result.fold((err) async {}, (success) async {
      final parent = file.parentDirectory ?? p.dirname(file.path);
      // Optimistic removal
      if (_cache.containsKey(parent)) {
        _cache[parent]!.removeWhere((f) => f.path == file.path);
        notifyListeners();
      } else {
        await load(parent, forceRefresh: true);
      }
    });
  }

  /// Add multiple files to a folder's cache
  /// Useful for updating UI when new files are created (e.g., after split operation)
  Future<void> addFiles(String folderPath, List<FileInfo> files) async {
    if (files.isEmpty) return;

    // Ensure the folder is in cache
    if (!_cache.containsKey(folderPath)) {
      await load(folderPath, forceRefresh: true);
      return;
    }

    // Add files to cache if they don't exist
    final existingPaths = _cache[folderPath]!.map((f) => f.path).toSet();
    final newFiles = files
        .where((f) => !existingPaths.contains(f.path))
        .toList();

    if (newFiles.isNotEmpty) {
      _cache[folderPath]!.addAll(newFiles);
      notifyListeners();
    }
  }

  // --- Search ---

  StreamSubscription? _searchSub;

  void clearSearch() {
    _searchSub?.cancel();
    _isSearching = false;
    _currentQuery = '';
    _searchResults.clear();
    notifyListeners();
  }

  void search(String path, String query) {
    if (query.isEmpty) {
      clearSearch();
      return;
    }

    // Cancel previous
    _searchSub?.cancel();

    _isSearching = true;
    _currentQuery = query;
    _searchResults.clear();
    notifyListeners();

    final stream = FileSystemService.searchStream(path, query);

    _searchSub = stream.listen(
      (either) {
        either.fold(
          (err) {}, // ignore errors
          (file) {
            _searchResults.add(file);
            // Verify if we want to batch notify?
            // For now, notify every few items or rely on StreamBuilder in UI.
            // Provider pattern usually requires notifyListeners.
            // To avoid spamming, we could throttle.
            // For simplicity, we notify.
            notifyListeners();
          },
        );
      },
      onDone: () {
        // Search complete
      },
    );
  }
}
