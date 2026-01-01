// lib/service/file_service.dart
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:path/path.dart' as p;
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/service/pdf_merge_service.dart' show CustomException;
import 'package:pdf_kit/service/recent_file_service.dart';

/// Service for general file operations like delete, rename, copy, move, etc.
class FileService {
  FileService._();

  /// Deletes a file from the file system
  ///
  /// [fileInfo] - The file to delete
  ///
  /// Returns [true] on success, or [CustomException] on failure
  static Future<Either<CustomException, bool>> deleteFile(
    FileInfo fileInfo,
  ) async {
    try {
      final file = File(fileInfo.path);

      if (!await file.exists()) {
        return Left(
          CustomException(
            message: 'File not found: ${fileInfo.name}',
            code: 'FILE_NOT_FOUND',
          ),
        );
      }

      await file.delete();

      // Best-effort: also remove from recent files storage.
      try {
        await RecentFilesService.removeRecentFile(fileInfo.path);
      } catch (_) {}
      return const Right(true);
    } catch (e) {
      return Left(
        CustomException(
          message: 'Failed to delete file: ${e.toString()}',
          code: 'DELETE_ERROR',
        ),
      );
    }
  }

  /// Deletes multiple files from the file system
  ///
  /// [files] - List of files to delete
  ///
  /// Returns a map of file paths to their deletion results
  static Future<Map<String, Either<CustomException, bool>>> deleteFiles(
    List<FileInfo> files,
  ) async {
    final results = <String, Either<CustomException, bool>>{};

    for (final fileInfo in files) {
      final result = await deleteFile(fileInfo);
      results[fileInfo.path] = result;
    }

    return results;
  }

  /// Renames a file
  ///
  /// [fileInfo] - The file to rename
  /// [newName] - The new name for the file (without path, with or without extension)
  ///
  /// Returns [FileInfo] of the renamed file on success, or [CustomException] on failure
  static Future<Either<CustomException, FileInfo>> renameFile(
    FileInfo fileInfo,
    String newName,
  ) async {
    try {
      final file = File(fileInfo.path);

      if (!await file.exists()) {
        return Left(
          CustomException(
            message: 'File not found: ${fileInfo.name}',
            code: 'FILE_NOT_FOUND',
          ),
        );
      }

      // Ensure the new name has the same extension if not provided
      String finalName = newName.trim();
      if (!finalName.contains('.') && fileInfo.extension.isNotEmpty) {
        finalName = '$finalName.${fileInfo.extension}';
      }

      // Create new path in the same directory
      final newPath = p.join(p.dirname(fileInfo.path), finalName);

      // Check if a file with the new name already exists
      if (await File(newPath).exists()) {
        return Left(
          CustomException(
            message: 'A file with the name "$finalName" already exists',
            code: 'FILE_EXISTS',
          ),
        );
      }

      // Rename the file
      final renamedFile = await file.rename(newPath);

      // Get new file stats
      final stats = await renamedFile.stat();

      // Create FileInfo for renamed file
      final renamedFileInfo = FileInfo(
        name: p.basename(newPath),
        path: newPath,
        extension: p.extension(newPath).replaceFirst('.', ''),
        size: stats.size,
        lastModified: stats.modified,
        mimeType: fileInfo.mimeType,
        parentDirectory: p.dirname(newPath),
        isDirectory: false,
      );

      return Right(renamedFileInfo);
    } catch (e) {
      return Left(
        CustomException(
          message: 'Failed to rename file: ${e.toString()}',
          code: 'RENAME_ERROR',
        ),
      );
    }
  }

  /// Copies a file to a new location
  ///
  /// [fileInfo] - The file to copy
  /// [destinationPath] - The destination directory path or full file path
  /// [newName] - Optional new name for the copied file
  ///
  /// Returns [FileInfo] of the copied file on success, or [CustomException] on failure
  static Future<Either<CustomException, FileInfo>> copyFile(
    FileInfo fileInfo, {
    required String destinationPath,
    String? newName,
  }) async {
    try {
      final file = File(fileInfo.path);

      if (!await file.exists()) {
        return Left(
          CustomException(
            message: 'File not found: ${fileInfo.name}',
            code: 'FILE_NOT_FOUND',
          ),
        );
      }

      // Determine if destinationPath is a directory or file path
      final destDir = Directory(destinationPath);
      String targetPath;

      if (await destDir.exists()) {
        // destinationPath is a directory
        final fileName = newName ?? fileInfo.name;
        targetPath = p.join(destinationPath, fileName);
      } else {
        // destinationPath might be a full file path
        targetPath = destinationPath;

        // Ensure parent directory exists
        final parentDir = Directory(p.dirname(targetPath));
        if (!await parentDir.exists()) {
          await parentDir.create(recursive: true);
        }
      }

      // Check if target file already exists
      if (await File(targetPath).exists()) {
        return Left(
          CustomException(
            message: 'A file already exists at the destination',
            code: 'FILE_EXISTS',
          ),
        );
      }

      // Copy the file
      final copiedFile = await file.copy(targetPath);

      // Get file stats
      final stats = await copiedFile.stat();

      // Create FileInfo for copied file
      final copiedFileInfo = FileInfo(
        name: p.basename(targetPath),
        path: targetPath,
        extension: p.extension(targetPath).replaceFirst('.', ''),
        size: stats.size,
        lastModified: stats.modified,
        mimeType: fileInfo.mimeType,
        parentDirectory: p.dirname(targetPath),
        isDirectory: false,
      );

      return Right(copiedFileInfo);
    } catch (e) {
      return Left(
        CustomException(
          message: 'Failed to copy file: ${e.toString()}',
          code: 'COPY_ERROR',
        ),
      );
    }
  }

  /// Moves a file to a new location
  ///
  /// [fileInfo] - The file to move
  /// [destinationPath] - The destination directory path
  /// [newName] - Optional new name for the moved file
  ///
  /// Returns [FileInfo] of the moved file on success, or [CustomException] on failure
  static Future<Either<CustomException, FileInfo>> moveFile(
    FileInfo fileInfo, {
    required String destinationPath,
    String? newName,
  }) async {
    try {
      final file = File(fileInfo.path);

      if (!await file.exists()) {
        return Left(
          CustomException(
            message: 'File not found: ${fileInfo.name}',
            code: 'FILE_NOT_FOUND',
          ),
        );
      }

      // Ensure destination directory exists
      final destDir = Directory(destinationPath);
      if (!await destDir.exists()) {
        await destDir.create(recursive: true);
      }

      // Determine target path
      final fileName = newName ?? fileInfo.name;
      final targetPath = p.join(destinationPath, fileName);

      // Check if target file already exists
      if (await File(targetPath).exists()) {
        return Left(
          CustomException(
            message: 'A file already exists at the destination',
            code: 'FILE_EXISTS',
          ),
        );
      }

      // Move the file
      final movedFile = await file.rename(targetPath);

      // Get file stats
      final stats = await movedFile.stat();

      // Create FileInfo for moved file
      final movedFileInfo = FileInfo(
        name: p.basename(targetPath),
        path: targetPath,
        extension: p.extension(targetPath).replaceFirst('.', ''),
        size: stats.size,
        lastModified: stats.modified,
        mimeType: fileInfo.mimeType,
        parentDirectory: p.dirname(targetPath),
        isDirectory: false,
      );

      return Right(movedFileInfo);
    } catch (e) {
      return Left(
        CustomException(
          message: 'Failed to move file: ${e.toString()}',
          code: 'MOVE_ERROR',
        ),
      );
    }
  }

  /// Checks if a file exists
  ///
  /// [filePath] - The path to the file
  ///
  /// Returns [true] if the file exists, [false] otherwise
  static Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Gets the size of a file in bytes
  ///
  /// [filePath] - The path to the file
  ///
  /// Returns file size in bytes, or [CustomException] on failure
  static Future<Either<CustomException, int>> getFileSize(
    String filePath,
  ) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        return Left(
          CustomException(message: 'File not found', code: 'FILE_NOT_FOUND'),
        );
      }

      final stats = await file.stat();
      return Right(stats.size);
    } catch (e) {
      return Left(
        CustomException(
          message: 'Failed to get file size: ${e.toString()}',
          code: 'SIZE_ERROR',
        ),
      );
    }
  }

  /// Creates a duplicate of a file in the same directory
  ///
  /// [fileInfo] - The file to duplicate
  /// [suffix] - Optional suffix to add to the duplicated file name (default: "copy")
  ///
  /// Returns [FileInfo] of the duplicated file on success, or [CustomException] on failure
  static Future<Either<CustomException, FileInfo>> duplicateFile(
    FileInfo fileInfo, {
    String suffix = 'copy',
  }) async {
    try {
      final file = File(fileInfo.path);

      if (!await file.exists()) {
        return Left(
          CustomException(
            message: 'File not found: ${fileInfo.name}',
            code: 'FILE_NOT_FOUND',
          ),
        );
      }

      // Generate a unique name for the duplicate
      final baseName = p.basenameWithoutExtension(fileInfo.path);
      final extension = p.extension(fileInfo.path);
      final directory = p.dirname(fileInfo.path);

      String duplicateName = '$baseName - $suffix$extension';
      String duplicatePath = p.join(directory, duplicateName);
      int counter = 1;

      // Ensure unique name
      while (await File(duplicatePath).exists()) {
        duplicateName = '$baseName - $suffix ($counter)$extension';
        duplicatePath = p.join(directory, duplicateName);
        counter++;
      }

      // Copy the file
      final duplicatedFile = await file.copy(duplicatePath);

      // Get file stats
      final stats = await duplicatedFile.stat();

      // Create FileInfo for duplicated file
      final duplicatedFileInfo = FileInfo(
        name: p.basename(duplicatePath),
        path: duplicatePath,
        extension: extension.replaceFirst('.', ''),
        size: stats.size,
        lastModified: stats.modified,
        mimeType: fileInfo.mimeType,
        parentDirectory: directory,
        isDirectory: false,
      );

      return Right(duplicatedFileInfo);
    } catch (e) {
      return Left(
        CustomException(
          message: 'Failed to duplicate file: ${e.toString()}',
          code: 'DUPLICATE_ERROR',
        ),
      );
    }
  }

  /// Gets detailed information about a file
  ///
  /// [filePath] - The path to the file
  ///
  /// Returns [FileInfo] on success, or [CustomException] on failure
  static Future<Either<CustomException, FileInfo>> getFileInfo(
    String filePath,
  ) async {
    try {
      final file = File(filePath);

      if (!await file.exists()) {
        return Left(
          CustomException(message: 'File not found', code: 'FILE_NOT_FOUND'),
        );
      }

      final stats = await file.stat();
      final fileInfo = FileInfo(
        name: p.basename(filePath),
        path: filePath,
        extension: p.extension(filePath).replaceFirst('.', ''),
        size: stats.size,
        lastModified: stats.modified,
        parentDirectory: p.dirname(filePath),
        isDirectory: false,
      );

      return Right(fileInfo);
    } catch (e) {
      return Left(
        CustomException(
          message: 'Failed to get file info: ${e.toString()}',
          code: 'INFO_ERROR',
        ),
      );
    }
  }
}
