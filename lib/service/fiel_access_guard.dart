// file_access_guard.dart (error-driven, no timeout decisions)
import 'dart:async';
import 'dart:io';

class FileAccessGuard {
  static final Set<String> _restrictedDirs = <String>{};
  static final Set<String> _restrictedFiles = <String>{};

  static bool isRestrictedPath(String path) =>
      _restrictedDirs.contains(path) || _restrictedFiles.contains(path);

  static bool _isPermDenied(Object e) {
    if (e is FileSystemException) {
      final msg = '${e.osError?.message ?? e.message}'.toLowerCase();
      final code = e.osError?.errorCode;
      // errno 13 = EACCES on Linux/Android
      return msg.contains('permission denied') || code == 13;
    }
    return false;
  }

  // Directory is considered restricted only if listing throws a permission error.
  static Future<bool> canEnterDirectory(Directory d) async {
    final p = d.path;
    if (_restrictedDirs.contains(p)) return false;

    final c = Completer<bool>();
    StreamSubscription<FileSystemEntity>? sub;
    try {
      sub = d
          .list(recursive: false, followLinks: false)
          .listen(
            (e) {
              // Received at least one entry => readable
              if (!c.isCompleted) c.complete(true);
              sub?.cancel();
            },
            onError: (e, _) {
              if (_isPermDenied(e)) {
                _restrictedDirs.add(p);
                if (!c.isCompleted) c.complete(false);
              } else {
                // Non-permission errors: don't mark restricted, but report not enterable now
                if (!c.isCompleted) c.complete(false);
              }
            },
            onDone: () {
              // Empty but readable directory
              if (!c.isCompleted) c.complete(true);
            },
            cancelOnError: true,
          );
      return await c.future;
    } catch (e) {
      if (_isPermDenied(e)) _restrictedDirs.add(p);
      return false;
    } finally {
      await sub?.cancel();
    }
  }

  // File is considered restricted only if a tiny read throws a permission error.
  static Future<bool> canReadFile(File f) async {
    final p = f.path;
    if (_restrictedFiles.contains(p)) return false;
    try {
      // Try to synchronously fetch small metadata then 1-byte read
      final raf = await f.open(mode: FileMode.read);
      try {
        // Attempt reading a single byte; if EOF on empty file, it's still readable
        await raf.read(1);
        // success (even if empty)
        return true;
      } finally {
        await raf.close();
      }
    } catch (e) {
      if (_isPermDenied(e)) _restrictedFiles.add(p);
      return false;
    }
  }
}
