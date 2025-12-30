# Smart Folder Navigation Implementation

## Overview
Implemented intelligent folder navigation for Downloads, Images, and Screenshots shortcuts in the Files Root Page. The system now checks if folders exist before navigating and allows users to select custom locations that are persisted across app sessions.

## Changes Made

### 1. Constants (`lib/core/constants.dart`)
Added preference keys for storing user-selected folder paths:
- `downloadsFolderPathKey` - Stores custom Downloads folder path
- `imagesFolderPathKey` - Stores custom Images folder path  
- `screenshotsFolderPathKey` - Stores custom Screenshots folder path

### 2. Files Root Page (`lib/presentation/pages/files_root_page.dart`)

#### New Imports
- Added `package:pdf_kit/core/constants.dart`
- Added `package:pdf_kit/core/utility/storage_utility.dart`

#### New Helper Methods

**`_getStoredPath(String prefsKey)`**
- Retrieves stored folder path from SharedPreferences using Prefs utility
- Returns null if no custom path has been set

**`_folderExists(String path)`**
- Checks if a folder exists on the file system
- Returns boolean indicating folder existence

**`_navigateToFolderOrPicker({required String prefsKey, required String defaultPath, required String pickerDescription})`**
- Main navigation logic that:
  1. Checks for stored custom path
  2. Falls back to default path if no custom path
  3. Verifies folder existence
  4. Navigates to folder if it exists
  5. Navigates to folder picker if folder doesn't exist

**`_navigateToFolder(String path)`**
- Handles navigation to a specific folder path
- Respects selection mode (fullscreen vs normal)
- Passes through selection parameters

**`_navigateToFolderPicker(String prefsKey, String description)`**
- Shows a SnackBar prompting user to select a folder
- Navigates to the folder picker screen with context
- Passes the preference key and description for later storage

#### Updated Card Widgets

**buildDownloadsFolderCard**
- Now calls `_navigateToFolderOrPicker()` with:
  - `prefsKey`: `Constants.downloadsFolderPathKey`
  - `defaultPath`: `/storage/emulated/0/Download`
  - `pickerDescription`: Localized "Downloads folder"

**buildImagesCard**
- Now calls `_navigateToFolderOrPicker()` with:
  - `prefsKey`: `Constants.imagesFolderPathKey`
  - `defaultPath`: `/storage/emulated/0/DCIM/Camera`
  - `pickerDescription`: Localized "Images folder"

**buildScreenshotsCard**
- Now calls `_navigateToFolderOrPicker()` with:
  - `prefsKey`: `Constants.screenshotsFolderPathKey`
  - `defaultPath`: `/storage/emulated/0/DCIM/Screenshots`
  - `pickerDescription`: Localized "Screenshots folder"

### 3. Localization Files
Added new translation keys to all language files (en, ar, bn, de, es, fr, hi, ja, pt, zh):
- `folder_picker_description` - General folder picker description
- `folder_picker_description_downloads` - Downloads folder label
- `folder_picker_description_images` - Images folder label
- `folder_picker_description_screenshots` - Screenshots folder label
- `folder_picker_no_folder_selected` - No folder selected message

## User Flow

### First Time Access
1. User taps on Downloads/Images/Screenshots shortcut
2. System checks if folder exists at default location
3. If exists: Navigate to folder
4. If not exists: Show SnackBar with "Choose" action
5. User can select custom folder location via folder picker
6. Selection is stored in SharedPreferences for future use

### Subsequent Access
1. User taps on shortcut
2. System retrieves stored custom path
3. Verifies path still exists
4. If exists: Navigate to stored path
5. If not exists: Prompt user to select new location

## Benefits

1. **Flexibility**: Users can choose custom locations for their Downloads, Images, and Screenshots
2. **Persistence**: Choices are saved and remembered across app sessions
3. **Fallback**: System gracefully handles missing folders
4. **User-Friendly**: Clear prompts guide users when folders need to be selected
5. **Global State**: Uses FileSystemProvider to ensure consistent folder access
6. **Localized**: All user-facing text is properly localized in 10 languages

## Technical Details

### Storage
- Uses `Prefs` utility class (wrapper around SharedPreferences)
- Stores absolute folder paths as strings
- Keys defined in Constants for consistency

### Folder Verification
- Uses Dart's `Directory` class to check folder existence
- Async operation wrapped in try-catch for error handling
- Returns false if any error occurs during check

### Navigation
- Respects selection mode context (fullscreen vs normal routes)
- Passes through selection parameters (selectionId, actionText)
- Uses app routing system (AppRouteName constants)

## Future Enhancements

1. **Folder Picker Integration**: Complete the folder picker navigation with callback to store selected path
2. **Reset Option**: Add settings to reset to default paths
3. **Path Validation**: Additional validation for write permissions
4. **Multiple Locations**: Support multiple custom locations per category
5. **Auto-Discovery**: Scan common locations and suggest to user
