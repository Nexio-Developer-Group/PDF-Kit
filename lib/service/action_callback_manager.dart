// services/action_callback_manager.dart
import 'package:pdf_kit/models/file_model.dart';

// Type-safe callback signature
typedef FileSelectionCallback = void Function(List<FileInfo> files);

class ActionCallbackManager {
  String? _currentAction;
  FileSelectionCallback? _currentCallback;

  void register(String actionId, FileSelectionCallback callback) {
    _currentAction = actionId;
    _currentCallback = callback;
  }

  FileSelectionCallback? get(String actionId) {
    if (_currentAction == actionId) return _currentCallback;
    return null;
  }

  void clear() {
    _currentAction = null;
    _currentCallback = null;
  }

  bool has(String actionId) => _currentAction == actionId;
}
