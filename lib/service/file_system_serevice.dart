import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:mime/mime.dart';
import 'package:pdf_kit/core/models/file_model.dart';

class FileSystemFailure implements Exception {
  final String message;
  FileSystemFailure(this.message);
  @override
  String toString() => 'FileSystemFailure: $message';
}

class FileSystemService {
  // One-level children listing (fast UI)
  static Future<Either<Exception, List<FileInfo>>> list(String dirPath) async {
    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) return Right(const []);
      final out = <FileInfo>[];

      await for (final e in dir.list(followLinks: false)) {
        try {
          if (e is Directory) {
            final st = await e.stat();
            final count = await _count(e);
            out.add(FileInfo(
              name: _base(e.path),
              path: e.path,
              extension: '',
              size: 0,
              lastModified: st.modified,
              parentDirectory: e.parent.path,
              isDirectory: true,
              mediaInfo: {'children': count},
            ));
          } else if (e is File) {
            final st = await e.stat();
            out.add(FileInfo(
              name: _base(e.path),
              path: e.path,
              extension: _ext(e.path),
              size: st.size,
              lastModified: st.modified,
              mimeType: lookupMimeType(e.path),
              parentDirectory: e.parent.path,
            ));
          }
        } catch (_) {/* skip unreadable entries */}
      }

      out.sort((a, b) {
        if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      return Right(out);
    } catch (e) {
      return Left(FileSystemFailure('List failed: $e'));
    }
  }

  // Recursive walker as a stream (useful for search)
  static Stream<Either<Exception, FileInfo>> walk(String rootPath) async* {
    try {
      final root = Directory(rootPath);
      if (!await root.exists()) return;
      await for (final e in root.list(recursive: true, followLinks: false)) {
        try {
          if (e is Directory) {
            final st = await e.stat();
            yield Right(FileInfo(
              name: _base(e.path),
              path: e.path,
              extension: '',
              size: 0,
              lastModified: st.modified,
              parentDirectory: e.parent.path,
              isDirectory: true,
            ));
          } else if (e is File) {
            final st = await e.stat();
            yield Right(FileInfo(
              name: _base(e.path),
              path: e.path,
              extension: _ext(e.path),
              size: st.size,
              lastModified: st.modified,
              mimeType: lookupMimeType(e.path),
              parentDirectory: e.parent.path,
            ));
          }
        } catch (err) {
          yield Left(FileSystemFailure('Walk item error: $err'));
        }
      }
    } catch (e) {
      yield Left(FileSystemFailure('Walk failed: $e'));
    }
  }

  // Name filter (case-insensitive), optionally recursive
  static Future<Either<Exception, List<FileInfo>>> search(String dirPath, String query, {bool recursive = true}) async {
    try {
      final q = query.toLowerCase();
      final found = <FileInfo>[];
      if (!recursive) {
        final res = await list(dirPath);
        return res.map((items) => items.where((e) => e.name.toLowerCase().contains(q)).toList());
      }
      await for (final either in walk(dirPath)) {
        either.fold((_) {}, (fi) {
          if (fi.name.toLowerCase().contains(q)) found.add(fi);
        });
      }
      return Right(found);
    } catch (e) {
      return Left(FileSystemFailure('Search failed: $e'));
    }
  }

  static Future<int> _count(Directory d) async {
    try { return await d.list(followLinks: false).length; } catch (_) { return 0; }
  }

  static String _base(String p) => p.split(Platform.pathSeparator).where((e) => e.isNotEmpty).last;
  static String _ext(String p) { final i = p.lastIndexOf('.'); return i == -1 ? '' : p.substring(i + 1).toLowerCase(); }
}
