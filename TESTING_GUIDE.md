## 🧪 Quick Test Guide: Folder Navigation

### Current Setup
✅ Missing imports have been added
✅ Debug logging is enabled
✅ App is building

---

## 🎯 Test Scenario 1: Non-Existent Folder (Easiest to Test)

### Option A: Temporarily Change Default Path

1. **Edit** `lib/presentation/pages/files_root_page.dart` line ~770:
   
   **Change from:**
   ```dart
   onTap: () {
     _navigateToFolderOrPicker(
       prefsKey: Constants.downloadsFolderPathKey,
       defaultPath: '/storage/emulated/0/Download',
       pickerDescription: t.t('folder_picker_description_downloads'),
     );
   },
   ```
   
   **Change to:**
   ```dart
   onTap: () {
     _navigateToFolderOrPicker(
       prefsKey: Constants.downloadsFolderPathKey,
       defaultPath: '/storage/emulated/0/TestFolderDoesNotExist',  // 👈 Changed
       pickerDescription: t.t('folder_picker_description_downloads'),
     );
   },
   ```

2. **Hot Reload** the app (press `r` in the terminal or save the file if you have hot reload enabled)

3. **Navigate** to Files tab

4. **Tap** the Downloads card

5. **Expected Behavior:**
   - See debug logs in terminal:
     ```
     🔍 [Folder Navigation] Checking folder: /storage/emulated/0/TestFolderDoesNotExist
     📁 [Folder Navigation] Stored path: none
     📂 [Folder Navigation] Default path: /storage/emulated/0/TestFolderDoesNotExist
     ❌ [Folder Navigation] Folder exists: false
     🎯 [Folder Navigation] Showing folder picker for: Downloads folder
     ```
   - See SnackBar at bottom: "Please select Downloads folder"
   - See "Choose" button in SnackBar
   - Tap "Choose" → Should navigate to Folder Picker

6. **Restore** the original path after testing

---

## 🎯 Test Scenario 2: Default Path Exists (Normal Case)

1. **Make sure** the default path is correct:
   ```dart
   defaultPath: '/storage/emulated/0/Download',
   ```

2. **Clear** any stored preference by adding a temporary button or using ADB:
   ```dart
   // Temporary test button - add to build method
   TextButton(
     onPressed: () async {
       await Prefs.remove(Constants.downloadsFolderPathKey);
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Cleared stored path')),
       );
     },
     child: Text('Clear Stored Path'),
   ),
   ```

3. **Tap** Downloads card

4. **Expected Behavior:**
   - Debug logs show:
     ```
     🔍 [Folder Navigation] Checking folder: /storage/emulated/0/Download
     📁 [Folder Navigation] Stored path: none
     ✅ [Folder Navigation] Folder exists: true
     ➡️ [Folder Navigation] Navigating to default folder: /storage/emulated/0/Download
     ```
   - App navigates directly to Downloads folder

---

## 🎯 Test Scenario 3: Custom Path (After User Selection)

1. **Store a custom path** using this test button:
   ```dart
   TextButton(
     onPressed: () async {
       // Simulate user selected a different folder
       await Prefs.setString(
         Constants.downloadsFolderPathKey,
         '/storage/emulated/0/Documents',
       );
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Set custom path to Documents')),
       );
     },
     child: Text('Set Custom Path'),
   ),
   ```

2. **Tap** Downloads card

3. **Expected Behavior:**
   - Debug logs show:
     ```
     🔍 [Folder Navigation] Checking folder: /storage/emulated/0/Documents
     📁 [Folder Navigation] Stored path: /storage/emulated/0/Documents
     ✅ [Folder Navigation] Folder exists: true
     ➡️ [Folder Navigation] Navigating to stored folder: /storage/emulated/0/Documents
     ```
   - App navigates to Documents folder (not Downloads!)

---

## 📱 Where to Look During Testing

### 1. Terminal/Console Output
Watch for the emoji debug logs:
- 🔍 = Checking folder
- 📁 = Stored path info
- ✅/❌ = Exists check result
- ➡️ = Navigation happening
- 🎯 = Picker being shown

### 2. App Screen
- SnackBar appears at bottom
- "Choose" action button
- Folder picker navigation

### 3. Hot Reload
After making changes, press `r` in the terminal or use VS Code's hot reload button

---

## 🐛 Troubleshooting

### If you see errors about `Constants`:
- Check that `import 'package:pdf_kit/core/constants.dart';` is present
- Rebuild the app with hot restart (`R` in terminal)

### If folder always exists:
- Try a clearly non-existent path like `/storage/emulated/0/XYZ123ABC`
- Check the debug logs to see what path is being checked

### If SnackBar doesn't appear:
- Check that `ScaffoldMessenger` has a valid context
- Try tapping the card multiple times
- Check terminal for any errors

---

## 💡 Quick Testing Tip

Add this temporary widget to your Files Root Page for instant testing:

```dart
// Add near the top of your build method, inside the Column
if (true) // Set to false to hide
  Container(
    padding: EdgeInsets.all(8),
    color: Colors.yellow[100],
    child: Column(
      children: [
        Text('🧪 Test Controls', style: TextStyle(fontWeight: FontWeight.bold)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: () async {
                await Prefs.remove(Constants.downloadsFolderPathKey);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✅ Cleared Downloads path')),
                );
              },
              child: Text('Clear'),
            ),
            ElevatedButton(
              onPressed: () async {
                await Prefs.setString(
                  Constants.downloadsFolderPathKey,
                  '/storage/emulated/0/NonExistent',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✅ Set to non-existent path')),
                );
              },
              child: Text('Set Invalid'),
            ),
            ElevatedButton(
              onPressed: () {
                final stored = Prefs.getString(Constants.downloadsFolderPathKey);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Stored: ${stored ?? "none"}')),
                );
              },
              child: Text('Check'),
            ),
          ],
        ),
      ],
    ),
  ),
```

This gives you instant control to test all scenarios!
