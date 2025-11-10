// file_system_service.dart
import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:pdf_kit/models/file_model.dart';
import 'package:pdf_kit/service/fiel_access_guard.dart';

class FileSystemFailure implements Exception {
  final String message;
  FileSystemFailure(this.message);
  @override
  String toString() => 'FileSystemFailure: $message';
}

class FileSystemService {
  // Allowed sets (fast extension gate first)
  static const Set<String> _imageExts = {
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
    'bmp',
    'tif',
    'tiff',
    'heic',
    'heif',
    'svg',
  };
  static const Set<String> _pdfExts = {'pdf'};

  static bool _isImageOrPdfPath(String path) {
    final ext = _ext(path);
    if (_imageExts.contains(ext) || _pdfExts.contains(ext)) return true;
    final mime = lookupMimeType(path);
    if (mime == null) return false; // fallback if unknown
    return mime.startsWith('image/') || mime == 'application/pdf';
  }

  // One-level children listing (folders + only image/pdf files)
  static Future<Either<Exception, List<FileInfo>>> list(String dirPath) async {
    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) return Right(const []);
      final out = <FileInfo>[];

      await for (final e in dir.list(followLinks: false)) {
        try {
          if (e is Directory) {
            final st = await e.stat();
            final count = await _countVisibleChildren(e);
            out.add(
              FileInfo(
                name: _base(e.path),
                path: e.path,
                extension: '',
                size: 0,
                lastModified: st.modified,
                parentDirectory: e.parent.path,
                isDirectory: true,
                mediaInfo: {'children': count},
              ),
            );
          } else if (e is File) {
            if (!_isImageOrPdfPath(e.path)) continue;
            final st = await e.stat();
            out.add(
              FileInfo(
                name: _base(e.path),
                path: e.path,
                extension: _ext(e.path),
                size: st.size,
                lastModified: st.modified,
                mimeType: lookupMimeType(e.path),
                parentDirectory: e.parent.path,
              ),
            );
          }
        } catch (_) {}
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

  // Deep walker (BFS) with guard + image/pdf filter
  static Stream<Either<Exception, FileInfo>> walkSafe(String rootPath) async* {
    final root = Directory(rootPath);
    if (!await root.exists()) return;
    final queue = <Directory>[root];

    while (queue.isNotEmpty) {
      final dir = queue.removeLast();
      if (!await FileAccessGuard.canEnterDirectory(dir)) continue;

      try {
        await for (final e in dir.list(recursive: false, followLinks: false)) {
          final path = e.path;

          if (e is Directory) {
            if (await FileAccessGuard.canEnterDirectory(e)) {
              debugPrint('Entering directory: $path');
              queue.add(e);
              yield Right(
                FileInfo(
                  name: _base(path),
                  path: path,
                  extension: '',
                  size: 0,
                  lastModified: (await e.stat()).modified,
                  parentDirectory: e.parent.path,
                  isDirectory: true,
                ),
              );
            }
          } else if (e is File) {
            if (!_isImageOrPdfPath(path)) continue;
            if (await FileAccessGuard.canReadFile(e)) {
              final st = await e.stat();
              yield Right(
                FileInfo(
                  name: _base(path),
                  path: path,
                  extension: _ext(path),
                  size: st.size,
                  lastModified: st.modified,
                  parentDirectory: e.parent.path,
                  mimeType: lookupMimeType(path),
                ),
              );
            }
          }
        }
      } catch (err) {
        yield Left(
          FileSystemFailure('Walk segment error at ${dir.path}: $err'),
        );
      }
    }
  }

  // Deep search (only image/pdf files) — matches NAME WITHOUT EXTENSION
  static Stream<Either<Exception, FileInfo>> searchStream(
    String dirPath,
    String query,
  ) async* {
    final q = query.toLowerCase();

    await for (final either in walkSafe(dirPath)) {
      Exception? err;
      FileInfo? fi;
      either.fold((l) => err = l, (r) => fi = r);

      if (err != null) {
        yield Left(err!);
        continue;
      }
      if (fi == null) continue;

      // Only files should match; ignore directories entirely
      if (fi!.isDirectory) continue;

      // Compare against stem (filename without extension), case-insensitive.
      final stemLower = _nameStemLower(fi!.name);
      if (stemLower.contains(q)) {
        yield Right(fi!);
      }
    }
  }

  static Future<Either<Exception, List<FileInfo>>> search(
    String dirPath,
    String query,
  ) async {
    try {
      final out = <FileInfo>[];
      await for (final either in searchStream(dirPath, query)) {
        either.fold((_) {}, out.add);
      }
      return Right(out);
    } catch (e) {
      return Left(FileSystemFailure('Search failed: $e'));
    }
  }

  // Helpers

  // Return lowercase stem of a filename (strip only the last extension).
  // Keeps leading-dot filenames intact (e.g., ".nomedia").
  static String _nameStemLower(String name) {
    final lower = name.toLowerCase();
    final i = lower.lastIndexOf('.');
    if (i <= 0) return lower; // no dot or leading-dot file; don't strip
    return lower.substring(0, i);
  }

  static Future<int> _countVisibleChildren(Directory dir, {int? cap}) async {
    int n = 0;
    try {
      // Skip if we can’t enter this directory at all.
      if (!await FileAccessGuard.canEnterDirectory(dir)) return 0;

      await for (final e in dir.list(followLinks: false)) {
        try {
          if (e is Directory) {
            if (await FileAccessGuard.canEnterDirectory(e)) {
              n++;
            }
          } else if (e is File) {
            if (await FileAccessGuard.canReadFile(e) &&
                _isImageOrPdfPath(e.path)) {
              n++;
            }
          }
          if (cap != null && n >= cap) return n; // early stop, e.g., 99+
        } on FileSystemException {
          // Ignore unreadable child entries; continue counting others.
        }
      }
    } catch (_) {
      // On parent listing failure, return 0.
      return 0;
    }
    return n;
  }

  static String _base(String p) =>
      p.split(Platform.pathSeparator).where((e) => e.isNotEmpty).last;

  static String _ext(String p) {
    final i = p.lastIndexOf('.');
    return i == -1 ? '' : p.substring(i + 1).toLowerCase();
  }
}
