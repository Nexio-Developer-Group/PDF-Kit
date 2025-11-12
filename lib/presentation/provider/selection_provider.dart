// selection_provider.dart (replace with this API)
import 'package:flutter/foundation.dart';
import 'package:pdf_kit/models/file_model.dart';

class SelectionProvider extends ChangeNotifier {
  final Map<String, FileInfo> _selected = {};
  int _mode = 0; // 0 off, 1 on

  int get mode => _mode;
  bool get isEnabled => _mode != 0;
  int get count => _selected.length;
  Map<String, FileInfo> get selected => _selected;
  bool isSelected(String path) => _selected.containsKey(path);
  List<FileInfo> get files => _selected.values.toList(growable: false);

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
      notifyListeners();
    }
  }

  void toggle(FileInfo f) {
    if (_selected.containsKey(f.path)) {
      _selected.remove(f.path);
    } else {
      _selected[f.path] = f;
    }
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
      if (!f.isDirectory) _selected[f.path] = f;
    }
    if (_mode == 0) _mode = 1;
    notifyListeners();
  }

  void clearVisible(Iterable<FileInfo> visible) {
    for (final f in visible) {
      _selected.remove(f.path);
    }
    if (_mode == 0) _mode = 1;
    notifyListeners();
  }

  void clearKeepEnabled() {
    _selected.clear();
    _mode = 1;
    notifyListeners();
  }

  // Page-scoped toggle: enable -> selectAllVisible -> clearVisible
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
