// recent_files_service.dart
import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf_kit/core/app_export.dart';
import 'package:pdf_kit/models/file_model.dart';

/// 🗂️ Service for managing recent files with LRU (Least Recently Used) policy.
/// Stores up to 10 most recent files using SharedPreferences.
class RecentFilesService {
  RecentFilesService._();

  static const String _key = 'recent_files';
  static const int _maxRecentFiles = 10;

  /// 📥 Add a file to recent files list.
  static Future<Either<String, List<FileInfo>>> addRecentFile(
    FileInfo fileInfo,
  ) async {
    debugPrint('➕ [RecentFilesService] Adding file: ${fileInfo.name}');
    try {
      // Get current list
      final currentResult = await getRecentFiles();

      // ✅ FIX: Convert to modifiable list using .toList()
      List<FileInfo> currentFiles = currentResult.fold(
        (error) {
          debugPrint('   ⚠️ No existing files found: $error');
          return <FileInfo>[]; // This creates a modifiable list
        },
        (files) {
          debugPrint('   📦 Current files count: ${files.length}');
          return files.toList(); // ✅ Convert to modifiable list
        },
      );

      // Remove if already exists (to avoid duplicates)
      final existingIndex = currentFiles.indexWhere(
        (file) => file.path == fileInfo.path,
      );
      if (existingIndex != -1) {
        debugPrint(
          '   🔄 File already exists at position $existingIndex, moving to top',
        );
        currentFiles.removeAt(existingIndex);
      }

      // Add to the beginning (most recent)
      currentFiles.insert(0, fileInfo);
      debugPrint('   ⬆️ File added to top');

      // Keep only max recent files
      if (currentFiles.length > _maxRecentFiles) {
        final removed = currentFiles.length - _maxRecentFiles;
        currentFiles = currentFiles.sublist(0, _maxRecentFiles);
        debugPrint(
          '   ✂️ Trimmed $removed old files (keeping $_maxRecentFiles)',
        );
      }

      // Save to preferences
      final jsonList = currentFiles.map((file) => file.toJson()).toList();
      final success = await Prefs.setJsonList(_key, jsonList);

      if (!success) {
        debugPrint('   ❌ Failed to save to SharedPreferences');
        return const Left('Failed to save recent files');
      }

      debugPrint('   ✅ Successfully saved ${currentFiles.length} files');
      return Right(currentFiles);
    } catch (e) {
      debugPrint('   ❌ Exception: ${e.toString()}');
      return Left('Error adding recent file: ${e.toString()}');
    }
  }

  /// 📤 Get all recent files.
  static Future<Either<String, List<FileInfo>>> getRecentFiles() async {
    debugPrint('📖 [RecentFilesService] Getting recent files...');
    try {
      final files = Prefs.getJsonList<FileInfo>(
        _key,
        (json) => FileInfo.fromJson(json as Map<String, dynamic>),
      );

      if (files == null) {
        debugPrint('   📭 No files found in storage');
        // ✅ Return modifiable empty list (not const)
        return Right(<FileInfo>[]);
      }

      debugPrint('   ✅ Found ${files.length} files in storage');
      return Right(files);
    } catch (e) {
      debugPrint('   ❌ Exception: ${e.toString()}');
      return Left('Error retrieving recent files: ${e.toString()}');
    }
  }

  /// 🗑️ Remove a specific file from recent files by path.
  static Future<Either<String, List<FileInfo>>> removeRecentFile(
    String filePath,
  ) async {
    debugPrint('🗑️ [RecentFilesService] Removing file: $filePath');
    try {
      final currentResult = await getRecentFiles();

      // ✅ FIX: Convert to modifiable list
      final currentFiles = currentResult.fold(
        (error) {
          debugPrint('   ⚠️ Error getting current files: $error');
          return <FileInfo>[];
        },
        (files) => files.toList(), // ✅ Convert to modifiable list
      );

      // Remove the file with matching path
      final initialCount = currentFiles.length;
      currentFiles.removeWhere((file) => file.path == filePath);
      final removedCount = initialCount - currentFiles.length;

      if (removedCount > 0) {
        debugPrint('   ✂️ Removed $removedCount file(s)');
      } else {
        debugPrint('   ℹ️ File not found in recent files');
      }

      // Save updated list
      final jsonList = currentFiles.map((file) => file.toJson()).toList();
      final success = await Prefs.setJsonList(_key, jsonList);

      if (!success) {
        debugPrint('   ❌ Failed to save updated list');
        return const Left('Failed to remove recent file');
      }

      debugPrint('   ✅ Successfully saved. Remaining: ${currentFiles.length}');
      return Right(currentFiles);
    } catch (e) {
      debugPrint('   ❌ Exception: ${e.toString()}');
      return Left('Error removing recent file: ${e.toString()}');
    }
  }

  /// 🧹 Clear all recent files.
  static Future<Either<String, bool>> clearRecentFiles() async {
    debugPrint('🧹 [RecentFilesService] Clearing all recent files...');
    try {
      final success = await Prefs.remove(_key);

      if (!success) {
        debugPrint('   ❌ Failed to clear');
        return const Left('Failed to clear recent files');
      }

      debugPrint('   ✅ All recent files cleared');
      return const Right(true);
    } catch (e) {
      debugPrint('   ❌ Exception: ${e.toString()}');
      return Left('Error clearing recent files: ${e.toString()}');
    }
  }

  /// 🔍 Check if a file exists in recent files.
  static Future<Either<String, bool>> containsFile(String filePath) async {
    debugPrint('🔍 [RecentFilesService] Checking if file exists: $filePath');
    try {
      final result = await getRecentFiles();

      return result.fold(
        (error) {
          debugPrint('   ❌ Error: $error');
          return Left(error);
        },
        (files) {
          final exists = files.any((file) => file.path == filePath);
          debugPrint(
            '   ${exists ? "✅" : "❌"} File ${exists ? "exists" : "not found"}',
          );
          return Right(exists);
        },
      );
    } catch (e) {
      debugPrint('   ❌ Exception: ${e.toString()}');
      return Left('Error checking file existence: ${e.toString()}');
    }
  }

  /// 📊 Get the count of recent files.
  static Future<Either<String, int>> getRecentFilesCount() async {
    debugPrint('📊 [RecentFilesService] Getting recent files count...');
    try {
      final result = await getRecentFiles();

      return result.fold(
        (error) {
          debugPrint('   ❌ Error: $error');
          return Left(error);
        },
        (files) {
          debugPrint('   ✅ Count: ${files.length}');
          return Right(files.length);
        },
      );
    } catch (e) {
      debugPrint('   ❌ Exception: ${e.toString()}');
      return Left('Error getting recent files count: ${e.toString()}');
    }
  }

  /// 👀 Watch for changes in recent files.
  static Stream<void> watchRecentFiles() {
    return Prefs.watch(_key);
  }
}
