import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class UnsupportedPlatformException implements Exception {
  final String message;
  UnsupportedPlatformException([
    this.message = "Unsupported platform for permission request",
  ]);
  @override
  String toString() => "UnsupportedPlatformException: $message";
}

class PermissionService {
  static const MethodChannel _ch = MethodChannel('all_files_access');

  // Opens Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION on Android 11+
  static Future<Unit> openAllFilesAccessPage() async {
    if (Platform.isAndroid) {
      try {
        await _ch.invokeMethod('openAllFiles');
      } catch (_) {}
    }
    return unit;
  }

  /// Opens the app-level permissions screen in Android settings (best-effort).
  static Future<Unit> openAppPermissionsPage() async {
    if (Platform.isAndroid) {
      try {
        await _ch.invokeMethod('openAppPermissions');
      } catch (_) {
        // Fallback to app details.
        await openAppSettings();
      }
    }
    return unit;
  }

  // Request All files access (Android), otherwise open settings if permanently denied
  static Future<Either<Exception, bool>> requestStoragePermission() async {
    try {
      if (!Platform.isAndroid) {
        return Left(UnsupportedPlatformException());
      }

      // 1) Try special access (API 30+)
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        status = await Permission.manageExternalStorage.request();
      }

      if (status.isGranted) return Right(true);

      if (status.isPermanentlyDenied) {
        await openAllFilesAccessPage(); // deep‑link into special access page
        return Right(false);
      }

      // 2) Fallback legacy read/write for <29 or OEMs
      final legacy = await Permission.storage.request();
      if (legacy.isGranted) return Right(true);

      if (legacy.isPermanentlyDenied) {
        await openAppSettings();
        return Right(false);
      }

      return Right(false);
    } catch (e) {
      return Left(Exception('Permission request failed: $e'));
    }
  }
}
