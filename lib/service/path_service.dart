import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:external_path/external_path.dart';

class PathService {
  // Storage volumes (primary + removable), null-safe
  static Future<Either<Exception, List<Directory>>> volumes() async {
    try {
      final List<String>? list =
          await ExternalPath.getExternalStorageDirectories();
      if (list == null || list.isEmpty) return Right(const []);

      final seen = <String>{};
      final dirs = <Directory>[];
      for (final p in list.where((e) => e.isNotEmpty)) {
        if (seen.add(p)) {
          final d = Directory(p);
          if (await d.exists()) dirs.add(d);
        }
      }
      return Right(dirs);
    } catch (e) {
      return Left(Exception('Failed to resolve volumes: $e'));
    }
  }

  // Well-known public folders (Documents / Downloads / Pictures)
  static Future<Either<Exception, Map<String, Directory>>> publicDirs() async {
    try {
      final docs = await ExternalPath.getExternalStoragePublicDirectory(
        ExternalPath.DIRECTORY_DOCUMENTS,
      );
      final down = await ExternalPath.getExternalStoragePublicDirectory(
        ExternalPath.DIRECTORY_DOWNLOAD,
      );
      final pics = await ExternalPath.getExternalStoragePublicDirectory(
        ExternalPath.DIRECTORY_PICTURES,
      );

      final map = <String, Directory>{
        'Documents': Directory(docs),
        'Downloads': Directory(down),
        'Pictures': Directory(pics),
      };

      // Only include existing directories
      final existing = <String, Directory>{};
      for (final e in map.entries) {
        if (await e.value.exists()) existing[e.key] = e.value;
      }
      return Right(existing);
    } catch (e) {
      return Left(Exception('Failed to resolve public directories: $e'));
    }
  }
}
