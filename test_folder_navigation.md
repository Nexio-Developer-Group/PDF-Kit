# Testing Smart Folder Navigation

## Test Scenarios

### Test 1: Downloads Folder - Default Path Exists
**Steps:**
1. Clear any stored Downloads folder preference:
   - Open your app
   - Go to a Dart console or add debug code to clear: `Prefs.remove(Constants.downloadsFolderPathKey)`
2. Navigate to Files Root Page
3. Tap on "Downloads" card
4. **Expected Result:** App should navigate directly to `/storage/emulated/0/Download` folder

### Test 2: Downloads Folder - Default Path Doesn't Exist
**Steps:**
1. Clear stored preference: `Prefs.remove(Constants.downloadsFolderPathKey)`
2. **Simulate non-existent folder** - temporarily change default path in code to something that doesn't exist
3. Tap on "Downloads" card
4. **Expected Result:** 
   - SnackBar appears with message "Please select Downloads folder"
   - "Choose" button in SnackBar
   - Tapping "Choose" navigates to Folder Picker

### Test 3: Custom Folder Path - Path Exists
**Steps:**
1. Store a custom path: `Prefs.setString(Constants.downloadsFolderPathKey, '/storage/emulated/0/Documents')`
2. Verify the folder exists
3. Tap on "Downloads" card
4. **Expected Result:** App navigates to the custom path `/storage/emulated/0/Documents`

### Test 4: Custom Folder Path - Path No Longer Exists
**Steps:**
1. Store a path to a non-existent folder: `Prefs.setString(Constants.downloadsFolderPathKey, '/storage/emulated/0/NonExistentFolder')`
2. Tap on "Downloads" card
4. **Expected Result:** 
   - SnackBar appears prompting to select folder
   - Folder picker opens when "Choose" is tapped

### Test 5: Images Folder - Default Path Exists
**Steps:**
1. Clear preference: `Prefs.remove(Constants.imagesFolderPathKey)`
2. Tap on "Images" card
3. **Expected Result:** Navigate to `/storage/emulated/0/DCIM/Camera`

### Test 6: Screenshots Folder - Default Path Exists
**Steps:**
1. Clear preference: `Prefs.remove(Constants.screenshotsFolderPathKey)`
2. Tap on "Screenshots" card
3. **Expected Result:** Navigate to `/storage/emulated/0/DCIM/Screenshots`

---

## Quick Test Code Snippet

Add this temporary test button to your Files Root Page to quickly test different scenarios:

```dart
// Add this in your build method somewhere for testing
if (kDebugMode)
  ElevatedButton(
    onPressed: () async {
      // Test Scenario: Force navigation with non-existent default
      await _navigateToFolderOrPicker(
        prefsKey: Constants.downloadsFolderPathKey,
        defaultPath: '/storage/emulated/0/NonExistentTestFolder',
        pickerDescription: 'Test Downloads folder',
      );
    },
    child: Text('Test Non-Existent Folder'),
  ),
```

---

## Manual Testing Steps for Quick Validation

### Quick Test - Force Non-Existent Folder

1. **Temporarily modify the default path** in `buildDownloadsFolderCard`:
   ```dart
   onTap: () {
     _navigateToFolderOrPicker(
       prefsKey: Constants.downloadsFolderPathKey,
       defaultPath: '/storage/emulated/0/NonExistentFolder123', // Changed this
       pickerDescription: t.t('folder_picker_description_downloads'),
     );
   },
   ```

2. **Run the app**:
   ```powershell
   flutter run
   ```

3. **Test the flow**:
   - Navigate to Files Root Page
   - Tap Downloads card
   - Should see SnackBar: "Please select Downloads folder"
   - Tap "Choose" button
   - Should navigate to Folder Picker page
   
4. **Restore the original default path** after testing

---

## Automated Test (Optional)

Create a widget test in `test/` folder:

```dart
// test/files_root_page_navigation_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_kit/core/constants.dart';
import 'package:pdf_kit/core/utility/storage_utility.dart';
import 'dart:io';

void main() {
  group('Folder Navigation Tests', () {
    test('Non-existent folder should return false', () async {
      final exists = await Directory('/non/existent/path').exists();
      expect(exists, false);
    });

    test('Default download path check', () async {
      final downloadPath = '/storage/emulated/0/Download';
      // This will depend on the device/emulator you're testing on
      final exists = await Directory(downloadPath).exists();
      print('Downloads folder exists: $exists');
    });
  });
}
```

---

## Expected Behavior Summary

| Scenario | Stored Path | Default Exists | Result |
|----------|-------------|----------------|--------|
| First time, default exists | None | ✅ Yes | Navigate to default |
| First time, default missing | None | ❌ No | Show picker |
| Custom path exists | /custom/path | N/A | Navigate to custom |
| Custom path missing | /old/path | ✅ Yes | Show picker |
| Custom path missing | /old/path | ❌ No | Show picker |

---

## Debug Output

To see what's happening, you can add debug prints:

```dart
Future<void> _navigateToFolderOrPicker({
  required String prefsKey,
  required String defaultPath,
  required String pickerDescription,
}) async {
  String? storedPath = _getStoredPath(prefsKey);
  String pathToCheck = storedPath ?? defaultPath;
  
  print('🔍 Checking folder: $pathToCheck');
  print('📁 Stored path: ${storedPath ?? "none"}');
  
  bool exists = await _folderExists(pathToCheck);
  print('✅ Exists: $exists');

  if (exists && storedPath != null) {
    print('➡️ Navigating to stored folder: $storedPath');
    _navigateToFolder(storedPath);
  } else if (exists && storedPath == null) {
    print('➡️ Navigating to default folder: $defaultPath');
    _navigateToFolder(defaultPath);
  } else {
    print('❌ Folder not found, showing picker');
    _navigateToFolderPicker(prefsKey, pickerDescription);
  }
}
```

This will help you see exactly what path is being checked and what decision is being made.
