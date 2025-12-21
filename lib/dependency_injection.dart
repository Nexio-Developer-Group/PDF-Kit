import 'package:pdf_kit/presentation/provider/selection_provider.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/service/action_callback_manager.dart';
import 'package:pdf_kit/providers/file_system_provider.dart';

/// Selection Implementation
SelectionProvider ensureSelection(String key) {
  if (!Get.isRegistered<SelectionProvider>(tag: key)) {
    Get.put<SelectionProvider>(SelectionProvider(), tag: key);
  }
  return Get.find<SelectionProvider>(tag: key);
}

/// Deselection Implementation
void removeSelection(String key) {
  if (Get.isRegistered<SelectionProvider>(tag: key)) {
    final p = Get.find<SelectionProvider>(tag: key);
    p.dispose(); // owner calls dispose
    Get.delete<SelectionProvider>(tag: key);
  }
}

class SelectionManager {
  final _cache = <String, SelectionProvider>{};

  SelectionProvider of(String key) {
    return _cache.putIfAbsent(key, () => SelectionProvider());
  }

  bool has(String key) => _cache.containsKey(key);

  void remove(String key) {
    _cache.remove(key)?.dispose(); // owner disposes
  }

  void clear() {
    for (final p in _cache.values) {
      p.dispose();
    }
    _cache.clear();
  }
}

Future<void> initDI() async {
  Get.put<SelectionManager>(SelectionManager(), permanent: true);
  Get.put<ActionCallbackManager>(ActionCallbackManager(), permanent: true);
  Get.put<FileSystemProvider>(FileSystemProvider(), permanent: true);
}
