import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:flutter/material.dart';

Future<void> requestStoragePermissions(BuildContext context) async {
  // Android 11+ special case: "All files access"
  if (Platform.isAndroid) {
    final sdk = int.parse(await _getSdkVersion());
    
    if (sdk >= 30) {
      // Check if already granted
      if (!await Permission.manageExternalStorage.isGranted) {
        // Show a dialog before redirecting (optional)
        bool? openSettings = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text("Allow File Access"),
            content: const Text(
              "To manage PDFs and files, please allow full storage access.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text("Grant Access"),
              ),
            ],
          ),
        );
        if (openSettings == true) {
          // This opens the system "All files access" settings screen
          await openAppSettings();
        }
      }
    } else {
      // For Android 10 or below
      final statuses = await [
        Permission.storage,
      ].request();

      if (statuses[Permission.storage] != PermissionStatus.granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission denied')),
        );
      }
    }
  }
}

Future<String> _getSdkVersion() async {
  const platform = MethodChannel('com.example.pdfkit/device_info');
  final version = await platform.invokeMethod<String>('getSdkVersion');
  return version ?? '0';
}
