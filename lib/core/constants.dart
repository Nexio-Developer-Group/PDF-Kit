class Constants {
  Constants._();

  /// Shared preferences keys
  static const String prefsLanguageKey = 'app_language_code';
  static const String prefsThemeKey = 'app_theme_mode';
  static const String prefsOnboardingCompletedKey = 'onboarding_completed';

  /// Device registration payload cache (stringified JSON)
  static const String deviceRegistrationPayloadKey =
      'device_registration_payload_json';

  /// Backend domain for device registration / FCM token sync.
  ///
  /// Endpoint used: `POST {base}/api/add_device`
  static const String deviceRegistrationBaseUrl =
      'https://django.nexiotech.cloud';

  /// Recent files storage key (used by RecentFilesService)
  static const String recentFilesKey = 'recent_files';

  /// File search previous terms storage key (used by SearchFilesScreen)
  static const String fileSearchPreviousTermsKey = 'file_search_previous_terms';

  /// Recent files search previous terms storage key (used by RecentFilesSearchPage)
  static const String recentFilesSearchPreviousTermsKey =
      'recent_files_search_previous_terms';

  /// PDF content fit mode preference key
  static const String pdfContentFitModeKey = 'pdf_content_fit_mode';

  /// Default sort option for file browser (name/modified)
  static const String filesSortOptionKey = 'files_sort_option';

  /// Default PDF content fit mode (use PdfContentFitMode enum for actual values)
  static const String defaultPdfContentFitMode = 'original';

  /// Default image compression quality (0-100) used when compressing images
  /// during merge/compress flows. Tweak this value as needed.
  static const int imageCompressQuality = 60;

  /// Image size threshold in bytes (2 MB). Images larger than this will be
  /// compressed before being added to PDF during merge operations.
  static const int imageSizeThreshold = 2 * 1024 * 1024; // 2 MB

  // ========== Custom Folder Paths Configuration ==========

  /// User-chosen Downloads folder path storage key
  static const String downloadsFolderPathKey = 'custom_downloads_folder_path';

  /// User-chosen Images folder path storage key
  static const String imagesFolderPathKey = 'custom_images_folder_path';

  /// User-chosen Screenshots folder path storage key
  static const String screenshotsFolderPathKey =
      'custom_screenshots_folder_path';

  /// User-chosen PDF output folder path storage key
  static const String pdfOutputFolderPathKey = 'custom_pdf_output_folder_path';

  // ========== PDF Merge Size Management Configuration ==========

  /// Target maximum size for merged PDF in MB
  /// If estimated output exceeds this, automatic compression will be applied
  static const int mergedPdfTargetSizeMB = 50;

  /// PDF compression ratio estimate (0.0 to 1.0)
  /// PDFs typically compress to 80-90% of original size with document compression
  static const double pdfCompressionRatio = 0.85;

  /// Image compression ratio estimate (0.0 to 1.0)
  /// Images typically compress to 40-60% depending on quality
  static const double imageCompressionRatio = 0.5;

  /// Minimum compression factor allowed (0.0 to 1.0)
  /// Even with size constraints, quality won't drop below this threshold
  /// 0.3 means maximum 70% quality reduction
  static const double minCompressionFactor = 0.3;

  /// Maximum compression factor (no compression needed)
  static const double maxCompressionFactor = 1.0;

  /// Base image quality for dynamic compression (0-100)
  /// This is the starting quality before applying compression factor
  static const int baseImageQuality = 95;

  /// Minimum image quality allowed (0-100)
  /// Even with heavy compression, quality won't drop below this
  static const int minImageQuality = 20;
}
