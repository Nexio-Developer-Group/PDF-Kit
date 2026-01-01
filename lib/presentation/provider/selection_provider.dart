// selection_provider.dart - same implementation as before
import 'package:flutter/foundation.dart';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/service/pdf_protect_service.dart';

class SelectionProvider extends ChangeNotifier {
  final Map<String, FileInfo> _selected = {};
  final Map<String, int> _rotations = {};
  List<FileInfo> _orderedFiles = [];
  int _mode = 0;
  int? _maxSelectable; // optional upper limit
  int? _minSelectable; // optional lower limit
  String? _allowedFilter; // 'protected', 'unprotected', or null for all
  String?
  _fileType; // 'all', 'pdf', 'images' - defines the scope of file filtering
  // String? _lastErrorMessage; // surfaced when exceeding limit

  // Cache for PDF protection status checks to avoid repeated file I/O
  final Map<String, bool> _protectionStatusCache = {};

  // Callback for custom file validation (returns error message if invalid, null if valid)
  Future<String?> Function(FileInfo)? validateFileForSelection;

  int get mode => _mode;
  bool get isEnabled => _mode != 0;
  int get count => _selected.length;
  Map<String, FileInfo> get selected => _selected;
  bool isSelected(String path) => _selected.containsKey(path);

  List<FileInfo> get files => List.unmodifiable(_orderedFiles);

  int? get maxSelectable => _maxSelectable;
  int? get minSelectable => _minSelectable;
  String? get fileType => _fileType;
  int? _lastLimitCount; // instead of String? _lastErrorMessage

  int getRotation(String path) => _rotations[path] ?? 0;
  int? get lastLimitCount => _lastLimitCount; // NEW

  List<MapEntry<FileInfo, int>> get filesWithRotation {
    return _orderedFiles
        .map((file) => MapEntry(file, _rotations[file.path] ?? 0))
        .toList(growable: false);
  }

  void enable() {
    if (_mode == 0) {
      _mode = 1;
      notifyListeners();
    }
  }

  void disable() {
    if (_mode != 0) {
      _mode = 0;
      _selected.clear();
      _rotations.clear();
      _orderedFiles.clear();
      _protectionStatusCache.clear();
      notifyListeners();
    }
  }

  void setMaxSelectable(int? value) {
    _maxSelectable = value;
    notifyListeners();
  }

  void setMinSelectable(int? value) {
    _minSelectable = value;
    notifyListeners();
  }

  void setAllowedFilter(String? value) {
    _allowedFilter = value;
    notifyListeners();
  }

  void setFileType(String? value) {
    _fileType = value;
    notifyListeners();
  }

  Future<String?> _validatePdfOnly(FileInfo file) async {
    if (file.extension.toLowerCase() != 'pdf') {
      return 'Only PDF files can be selected for this operation.';
    }
    return null;
  }

  Future<String?> _validateImageOnly(FileInfo file) async {
    const imageExtensions = {
      'jpg',
      'jpeg',
      'png',
      'gif',
      'webp',
      'bmp',
      'tif',
      'tiff',
      'heic',
      'heif',
    };
    if (!imageExtensions.contains(file.extension.toLowerCase())) {
      return 'Only image files can be selected for this operation.';
    }
    return null;
  }

  void clearError() {
    if (_lastLimitCount != null) {
      _lastLimitCount = null;
      notifyListeners();
    }
  }

  String? _lastValidationError;
  String? get lastValidationError => _lastValidationError;

  void clearValidationError() {
    if (_lastValidationError != null) {
      _lastValidationError = null;
      notifyListeners();
    }
  }

  Future<String?> _validateFileWithFilter(FileInfo file) async {
    // Check for pdf-only filter
    if (_allowedFilter == 'pdf-only') {
      return await _validatePdfOnly(file);
    }

    // Check for image-only filter (accepts both 'images' and 'image-only')
    if (_allowedFilter == 'images' || _allowedFilter == 'image-only') {
      return await _validateImageOnly(file);
    }

    // For protection filters (protected/unprotected), only validate PDFs
    // Non-PDF files pass validation automatically
    if (file.extension.toLowerCase() != 'pdf') {
      return null; // Non-PDF files are allowed
    }

    // Check protection status for PDF files
    try {
      // Check cache first to avoid repeated file I/O
      bool isProtected;
      if (_protectionStatusCache.containsKey(file.path)) {
        isProtected = _protectionStatusCache[file.path]!;
      } else {
        // Not in cache - perform the check and cache the result
        final result = await PdfProtectionService.isPdfProtected(
          pdfPath: file.path,
        );

        isProtected = result.fold(
          (failure) => false, // If check fails, assume not protected
          (protected) => protected,
        );

        // Cache the result for future checks
        _protectionStatusCache[file.path] = isProtected;
      }

      // Validate based on filter
      if (_allowedFilter == 'protected' && !isProtected) {
        return 'This PDF is not protected with a password.';
      } else if (_allowedFilter == 'unprotected' && isProtected) {
        return 'Action not allowed on protected PDF. Unlock it first to proceed.';
      }
      return null;
    } catch (e) {
      return null; // If service unavailable, allow selection
    }
  }

  Future<void> toggle(FileInfo f) async {
    // If already selected -> unselect
    if (_selected.containsKey(f.path)) {
      _selected.remove(f.path);
      _rotations.remove(f.path);
      _orderedFiles.removeWhere((file) => file.path == f.path);
      notifyListeners();
      return;
    }

    // Validate based on allowed filter
    if (_allowedFilter != null) {
      final error = await _validateFileWithFilter(f);
      if (error != null) {
        _lastValidationError = error;
        notifyListeners();
        return; // do not add
      }
    }

    // Run custom validation if provided
    if (validateFileForSelection != null) {
      final error = await validateFileForSelection!(f);
      if (error != null) {
        _lastValidationError = error;
        notifyListeners();
        return; // do not add
      }
    }

    // Enforce max selectable limit if provided
    if (_maxSelectable != null && _selected.length >= _maxSelectable!) {
      _lastLimitCount = _maxSelectable; // just store the number
      notifyListeners();
      return; // do not add
    }

    _selected[f.path] = f;
    _rotations[f.path] = 0;
    _orderedFiles.add(f);
    notifyListeners();
  }

  void removeFile(String path) {
    _selected.remove(path);
    _rotations.remove(path);
    _orderedFiles.removeWhere((file) => file.path == path);
    notifyListeners();
  }

  void rotateFile(String path) {
    if (_selected.containsKey(path)) {
      final currentRotation = _rotations[path] ?? 0;
      _rotations[path] = (currentRotation + 90) % 360;
      notifyListeners();
    }
  }

  // selection_provider.dart
  void reorderFiles(int oldIndex, int newIndex) {
    // Adjust newIndex if moving down
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final file = _orderedFiles.removeAt(oldIndex);
    _orderedFiles.insert(newIndex, file);
    notifyListeners();
  }

  bool areAllSelected(Iterable<FileInfo> visible) {
    var any = false;
    for (final f in visible) {
      if (f.isDirectory) continue;
      any = true;
      if (!_selected.containsKey(f.path)) return false;
    }
    return any;
  }

  bool anySelected(Iterable<FileInfo> visible) {
    for (final f in visible) {
      if (!f.isDirectory && _selected.containsKey(f.path)) return true;
    }
    return false;
  }

  void selectAllVisible(Iterable<FileInfo> visible) {
    for (final f in visible) {
      if (!f.isDirectory) {
        if (!_selected.containsKey(f.path)) {
          _selected[f.path] = f;
          _rotations[f.path] = 0;
          _orderedFiles.add(f);
        }
      }
    }
    if (_mode == 0) _mode = 1;
    notifyListeners();
  }

  void clearVisible(Iterable<FileInfo> visible) {
    for (final f in visible) {
      _selected.remove(f.path);
      _rotations.remove(f.path);
      _orderedFiles.removeWhere((file) => file.path == f.path);
    }
    if (_mode == 0) _mode = 1;
    notifyListeners();
  }

  void clearKeepEnabled() {
    _selected.clear();
    _rotations.clear();
    _orderedFiles.clear();
    _mode = 1;
    // _lastErrorMessage = null;
    notifyListeners();
  }

  void cyclePage(Iterable<FileInfo> visible) {
    if (_mode == 0) {
      _mode = 1;
      notifyListeners();
      return;
    }
    if (areAllSelected(visible)) {
      clearVisible(visible);
    } else {
      selectAllVisible(visible);
    }
  }
}
