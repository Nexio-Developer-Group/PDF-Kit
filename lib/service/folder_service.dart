import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:external_path/external_path.dart';
import 'package:path_provider/path_provider.dart';

class FolderServiceAndroid {
  const FolderServiceAndroid._();

  /// Creates [folderName] under [basePath].
  /// Set [requireAllFilesAccess] to true when [basePath] is a shared/public directory (e.g., Downloads).
  /// Returns Either<String error, Directory success>.
  static Future<Either<String, Directory>> createFolder({
    required String basePath,
    required String folderName,
    bool requireAllFilesAccess = false,
    bool recursive = true,
  }) async {
    try {
      print(
        '[FolderService] createFolder(basePath: "$basePath", folderName: "$folderName", requireAllFilesAccess: $requireAllFilesAccess, recursive: $recursive)',
      );
      if (!Platform.isAndroid) {
        print(
          '[FolderService] Unsupported platform: ${Platform.operatingSystem}',
        );
        return left('Unsupported platform');
      }

      if (folderName.trim().isEmpty) {
        print('[FolderService] Invalid name (empty after trim)');
        return left('Folder name cannot be empty');
      }

      final sanitized = _sanitizeFolderName(folderName);
      print('[FolderService] Sanitized name: "$sanitized"');
      final targetPath = _join(basePath, sanitized);
      print('[FolderService] Target path: $targetPath');

      if (requireAllFilesAccess) {
        print('[FolderService] Ensuring MANAGE_EXTERNAL_STORAGE permission...');
        final ok = await _ensureAllFilesAccess();
        print('[FolderService] All files access granted: $ok');
        if (!ok) return left('All files access not granted');
      }

      final dir = Directory(targetPath);
      if (await dir.exists()) {
        print('[FolderService] Already exists');
        return right(dir);
      }

      print('[FolderService] Creating directory (recursive=$recursive)...');
      final created = await dir.create(recursive: recursive);
      print('[FolderService] Created at: ${created.path}');
      return right(created);
    } catch (e) {
      print('[FolderService] Error: $e');
      return left('Failed to create folder: $e');
    }
  }

  /// Public Downloads directory on Android (absolute path).
  static Future<String> downloadsPath() async {
    return ExternalPath.getExternalStoragePublicDirectory(
      ExternalPath.DIRECTORY_DOWNLOAD,
    );
  }

  /// App-specific external files directory on Android (no broad storage permission).
  static Future<String> appFilesPath() async {
    final d = await getExternalStorageDirectory();
    if (d != null) return d.path;
    // Rare fallback: use internal app docs if external storage unavailable.
    final docs = await getApplicationDocumentsDirectory();
    return docs.path;
  }

  static Future<bool> _ensureAllFilesAccess() async {
    // MANAGE_EXTERNAL_STORAGE on Android 11+.
    final granted = await Permission.manageExternalStorage.isGranted;
    if (granted) return true;
    final status = await Permission.manageExternalStorage.request();
    return status.isGranted;
  }

  static String _sanitizeFolderName(String input) {
    final sanitized = input
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
        .trim();
    return sanitized.isEmpty ? 'New Folder' : sanitized;
  }

  static String _join(String base, String name) {
    final sep = Platform.pathSeparator;
    final baseNorm = base.replaceAll(RegExp(r'[\/\\]+$'), '');
    return '$baseNorm$sep$name';
  }

  /// Renames a folder from [path] to [newName].
  /// Returns Either<String error, Directory success>.
  static Future<Either<String, Directory>> renameFolder({
    required String path,
    required String newName,
  }) async {
    try {
      final dir = Directory(path);
      if (!await dir.exists()) {
        return left('Folder does not exist');
      }

      final parentPath = dir.parent.path;
      final sanitized = _sanitizeFolderName(newName);
      final newPath = _join(parentPath, sanitized);

      final newDir = Directory(newPath);
      if (await newDir.exists()) {
        return left('Folder with this name already exists');
      }

      final renamed = await dir.rename(newPath);
      return right(renamed);
    } catch (e) {
      return left('Failed to rename folder: $e');
    }
  }

  /// Deletes a folder at [path].
  /// Returns Either<String error, bool success>.
  static Future<Either<String, bool>> deleteFolder({
    required String path,
  }) async {
    try {
      final dir = Directory(path);
      if (!await dir.exists()) {
        return left('Folder does not exist');
      }

      await dir.delete(recursive: true);
      return right(true);
    } catch (e) {
      return left('Failed to delete folder: $e');
    }
  }
}
