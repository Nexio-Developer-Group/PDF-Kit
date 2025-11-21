// selection_provider.dart - same implementation as before
import 'package:flutter/foundation.dart';
import 'package:pdf_kit/models/file_model.dart';

class SelectionProvider extends ChangeNotifier {
  final Map<String, FileInfo> _selected = {};
  final Map<String, int> _rotations = {};
  List<FileInfo> _orderedFiles = [];
  int _mode = 0;
  int? _maxSelectable; // optional upper limit
  String? _lastErrorMessage; // surfaced when exceeding limit

  int get mode => _mode;
  bool get isEnabled => _mode != 0;
  int get count => _selected.length;
  Map<String, FileInfo> get selected => _selected;
  bool isSelected(String path) => _selected.containsKey(path);

  List<FileInfo> get files => List.unmodifiable(_orderedFiles);

  int? get maxSelectable => _maxSelectable;
  String? get lastErrorMessage => _lastErrorMessage;

  int getRotation(String path) => _rotations[path] ?? 0;

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
      notifyListeners();
    }
  }

  void setMaxSelectable(int? value) {
    _maxSelectable = value;
    notifyListeners();
  }

  void clearError() {
    if (_lastErrorMessage != null) {
      _lastErrorMessage = null;
      notifyListeners();
    }
  }

  void toggle(FileInfo f) {
    // Remove existing selection
    if (_selected.containsKey(f.path)) {
      _selected.remove(f.path);
      _rotations.remove(f.path);
      _orderedFiles.removeWhere((file) => file.path == f.path);
      notifyListeners();
      return;
    }

    // Enforce max selectable limit if provided
    if (_maxSelectable != null && _selected.length >= _maxSelectable!) {
      _lastErrorMessage =
          'You can select at most $_maxSelectable file${_maxSelectable == 1 ? '' : 's'}.';
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
    _lastErrorMessage = null;
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
