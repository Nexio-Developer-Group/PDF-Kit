import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// overall screens paddings
/// 10 pixels horizontal padding
const EdgeInsets screenPadding = EdgeInsets.symmetric(
  horizontal: 12.0,
  vertical: 0.0,
);

/// A class that contains all theme configurations for the PDF management application.
/// Implements Contemporary Professional Minimalism with Adaptive Professional Palette.
class AppTheme {
  AppTheme._();

  // Primary color palette - Deep blue for trust and professionalism
  static const Color primaryLight = Color(0xFF1565C0);
  static const Color primaryDark = Color(0xFF90CAF9);

  // Secondary color palette - Complementary teal for secondary actions
  static const Color secondaryLight = Color(0xFF00695C);
  static const Color secondaryDark = Color(0xFF4DB6AC);

  // Surface colors optimized for extended reading
  static const Color surfaceLight = Color(0xFFFAFAFA);
  static const Color surfaceDark = Color(0xFF121212);

  // Text colors with WCAG AA compliance
  static const Color onSurfaceLight = Color(0xFF1C1B1F);
  static const Color onSurfaceDark = Color(0xFFE6E1E5);

  // Status colors - solid colors for accessibility
  static const Color errorLight = Color(0xFFBA1A1A);
  static const Color errorDark = Color(0xFFFFB4AB);
  static const Color successLight = Color(0xFF146C2E);
  static const Color successDark = Color(0xFF4CAF50);
  static const Color warningLight = Color(0xFFE65100);
  static const Color warningDark = Color(0xFFFF9800);

  // Accent color - Purple for highlights and selected states
  static const Color accentLight = Color(0xFF6750A4);
  static const Color accentDark = Color(0xFFD0BCFF);

  // Additional surface variations
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E1E1E);
  static const Color dialogLight = Color(0xFFFFFFFF);
  static const Color dialogDark = Color(0xFF2D2D2D);

  // Shadow and outline colors with Material Design 3 specifications
  static const Color shadowLight = Color(0x26000000); // 15% opacity
  static const Color shadowDark = Color(0x26FFFFFF);
  static const Color outlineLight = Color(0x1F000000); // 12% opacity
  static const Color outlineDark = Color(0x1FFFFFFF);

  // Text emphasis levels for hierarchy
  static const Color textHighEmphasisLight = Color(0xDE000000); // 87% opacity
  static const Color textMediumEmphasisLight = Color(0x99000000); // 60% opacity
  static const Color textDisabledLight = Color(0x61000000); // 38% opacity

  static const Color textHighEmphasisDark = Color(0xDEFFFFFF); // 87% opacity
  static const Color textMediumEmphasisDark = Color(0x99FFFFFF); // 60% opacity
  static const Color textDisabledDark = Color(0x61FFFFFF); // 38% opacity

  /// Light theme configuration for professional document management
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: primaryLight,
      onPrimary: Colors.white,
      primaryContainer: primaryLight.withValues(alpha: 0.1),
      onPrimaryContainer: primaryLight,
      secondary: secondaryLight,
      onSecondary: Colors.white,
      secondaryContainer: secondaryLight.withValues(alpha: 0.1),
      onSecondaryContainer: secondaryLight,
      tertiary: accentLight,
      onTertiary: Colors.white,
      tertiaryContainer: accentLight.withValues(alpha: 0.1),
      onTertiaryContainer: accentLight,
      error: errorLight,
      onError: Colors.white,
      errorContainer: errorLight.withValues(alpha: 0.1),
      onErrorContainer: errorLight,
      surface: surfaceLight,
      onSurface: onSurfaceLight,
      onSurfaceVariant: textMediumEmphasisLight,
      outline: outlineLight,
      outlineVariant: outlineLight.withValues(alpha: 0.5),
      shadow: shadowLight,
      scrim: Colors.black54,
      inverseSurface: surfaceDark,
      onInverseSurface: onSurfaceDark,
      inversePrimary: primaryDark,
      surfaceTint: primaryLight,
    ),
    scaffoldBackgroundColor: surfaceLight,
    cardColor: cardLight,
    dividerColor: outlineLight,

    // AppBar theme for professional document interface
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceLight,
      foregroundColor: onSurfaceLight,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: shadowLight,
      surfaceTintColor: surfaceLight,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: onSurfaceLight,
        letterSpacing: 0.15,
      ),
      iconTheme: IconThemeData(color: onSurfaceLight, size: 24),
      actionsIconTheme: IconThemeData(color: onSurfaceLight, size: 24),
    ),

    // Card theme with subtle elevation
    cardTheme: CardThemeData(
      color: cardLight,
      elevation: 1,
      shadowColor: shadowLight,
      surfaceTintColor: surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: const EdgeInsets.all(8.0),
    ),

    // Bottom navigation for file management workflow
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceLight,
      selectedItemColor: primaryLight,
      unselectedItemColor: textMediumEmphasisLight,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),

    // Navigation bar theme for modern navigation
    navigationBarTheme: NavigationBarThemeData(
      height: 64,
      backgroundColor: surfaceLight,
      elevation: 3,
      shadowColor: shadowLight,
      indicatorColor: primaryLight.withValues(alpha: 0.12),
      labelTextStyle: WidgetStateTextStyle.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.roboto(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: primaryLight,
          );
        }
        return GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textMediumEmphasisLight,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: primaryLight, size: 24);
        }
        return IconThemeData(color: textMediumEmphasisLight, size: 24);
      }),
    ),

    // Tab bar theme for document organization
    tabBarTheme: TabBarThemeData(
      labelColor: primaryLight,
      unselectedLabelColor: textMediumEmphasisLight,
      indicatorColor: primaryLight,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      unselectedLabelStyle: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
      ),
      overlayColor: WidgetStateProperty.all(
        primaryLight.withValues(alpha: 0.12),
      ),
    ),

    // Floating action button with gradient reserved for primary actions
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryLight,
      foregroundColor: Colors.white,
      elevation: 6,
      focusElevation: 8,
      hoverElevation: 8,
      highlightElevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
    ),

    // Button themes for document actions
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: primaryLight,
        elevation: 2,
        shadowColor: shadowLight,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryLight,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        side: BorderSide(color: outlineLight),
        textStyle: GoogleFonts.roboto(
          fontSize: 14,
          color: Colors.black,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(  
        foregroundColor: primaryLight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        textStyle: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ),
    ),

    // Typography system with Inter for headings and Roboto for body
    textTheme: _buildTextTheme(isLight: true),

    // Input decoration for document forms
    inputDecorationTheme: InputDecorationTheme(
      fillColor: surfaceLight,
      filled: true,
      // suffixIconConstraints: BoxConstraints(maxHeight: 24, maxWidth: 24),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: outlineLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: outlineLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: primaryLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: errorLight),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: errorLight, width: 2),
      ),
      labelStyle: GoogleFonts.roboto(
        color: textMediumEmphasisLight,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      hintStyle: GoogleFonts.roboto(
        color: textDisabledLight,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      helperStyle: GoogleFonts.roboto(
        color: textMediumEmphasisLight,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      errorStyle: GoogleFonts.roboto(
        color: errorLight,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),

    // Interactive element themes
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryLight;
        }
        return Colors.grey[300];
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryLight.withValues(alpha: 0.5);
        }
        return Colors.grey[300];
      }),
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryLight;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      side: BorderSide(color: outlineLight, width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
    ),

    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryLight;
        }
        return outlineLight;
      }),
    ),

    // Progress indicators for loading states
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primaryLight,
      linearTrackColor: primaryLight.withValues(alpha: 0.2),
      circularTrackColor: primaryLight.withValues(alpha: 0.2),
    ),

    // Slider theme for document controls
    sliderTheme: SliderThemeData(
      activeTrackColor: primaryLight,
      thumbColor: primaryLight,
      overlayColor: primaryLight.withValues(alpha: 0.12),
      inactiveTrackColor: primaryLight.withValues(alpha: 0.24),
      valueIndicatorColor: primaryLight,
      valueIndicatorTextStyle: GoogleFonts.roboto(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),

    // Tooltip theme for help text
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: onSurfaceLight.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: GoogleFonts.roboto(
        color: surfaceLight,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),

    // Snackbar theme for notifications
    snackBarTheme: SnackBarThemeData(
      backgroundColor: onSurfaceLight,
      contentTextStyle: GoogleFonts.roboto(
        color: surfaceLight,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      actionTextColor: accentLight,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      elevation: 6,
    ),

    // Dialog theme for document operations
    dialogTheme: DialogThemeData(
      backgroundColor: dialogLight,
      elevation: 24,
      shadowColor: shadowLight,
      surfaceTintColor: surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: onSurfaceLight,
      ),
      contentTextStyle: GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: onSurfaceLight,
      ),
    ),

    // List tile theme for file listings
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      tileColor: Colors.transparent,
      selectedTileColor: primaryLight.withValues(alpha: 0.08),
      iconColor: textMediumEmphasisLight,
      textColor: onSurfaceLight,
      titleTextStyle: GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: onSurfaceLight,
      ),
      subtitleTextStyle: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textMediumEmphasisLight,
      ),
    ),

    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        iconSize: WidgetStateProperty.all(24),
        foregroundColor: WidgetStateProperty.all(Colors.black),
        padding: WidgetStateProperty.all(EdgeInsets.all(5)),
      ),
    ),
  );

  /// Dark theme configuration for comfortable night reading
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorScheme: ColorScheme(
      brightness: Brightness.dark,
      primary: primaryDark,
      onPrimary: Colors.black,
      primaryContainer: primaryDark.withValues(alpha: 0.2),
      onPrimaryContainer: primaryDark,
      secondary: secondaryDark,
      onSecondary: Colors.black,
      secondaryContainer: secondaryDark.withValues(alpha: 0.2),
      onSecondaryContainer: secondaryDark,
      tertiary: accentDark,
      onTertiary: Colors.black,
      tertiaryContainer: accentDark.withValues(alpha: 0.2),
      onTertiaryContainer: accentDark,
      error: errorDark,
      onError: Colors.black,
      errorContainer: errorDark.withValues(alpha: 0.2),
      onErrorContainer: errorDark,
      surface: surfaceDark,
      onSurface: onSurfaceDark,
      onSurfaceVariant: textMediumEmphasisDark,
      outline: outlineDark,
      outlineVariant: outlineDark.withValues(alpha: 0.5),
      shadow: shadowDark,
      scrim: Colors.black87,
      inverseSurface: surfaceLight,
      onInverseSurface: onSurfaceLight,
      inversePrimary: primaryLight,
      surfaceTint: primaryDark,
    ),
    scaffoldBackgroundColor: surfaceDark,
    cardColor: cardDark,
    dividerColor: outlineDark,

    // AppBar theme for dark mode
    appBarTheme: AppBarTheme(
      backgroundColor: surfaceDark,
      foregroundColor: onSurfaceDark,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: shadowDark,
      surfaceTintColor: surfaceDark,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: onSurfaceDark,
        letterSpacing: 0.15,
      ),
      iconTheme: IconThemeData(color: onSurfaceDark, size: 24),
      actionsIconTheme: IconThemeData(color: onSurfaceDark, size: 24),
    ),

    // Card theme for dark mode
    cardTheme: CardThemeData(
      color: cardDark,
      elevation: 1,
      shadowColor: shadowDark,
      surfaceTintColor: surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: const EdgeInsets.all(8.0),
    ),

    // Bottom navigation for dark mode
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceDark,
      selectedItemColor: primaryDark,
      unselectedItemColor: textMediumEmphasisDark,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      unselectedLabelStyle: GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),

    // Navigation bar theme for dark mode
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surfaceDark,
      elevation: 3,
      shadowColor: shadowDark,
      indicatorColor: primaryDark.withValues(alpha: 0.2),
      labelTextStyle: WidgetStateTextStyle.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.roboto(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: primaryDark,
          );
        }
        return GoogleFonts.roboto(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textMediumEmphasisDark,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return IconThemeData(color: primaryDark, size: 24);
        }
        return IconThemeData(color: textMediumEmphasisDark, size: 24);
      }),
    ),

    // Tab bar theme for dark mode
    tabBarTheme: TabBarThemeData(
      labelColor: primaryDark,
      unselectedLabelColor: textMediumEmphasisDark,
      indicatorColor: primaryDark,
      indicatorSize: TabBarIndicatorSize.label,
      labelStyle: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
      ),
      unselectedLabelStyle: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.1,
      ),
      overlayColor: WidgetStateProperty.all(
        primaryDark.withValues(alpha: 0.12),
      ),
    ),

    // Floating action button for dark mode
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryDark,
      foregroundColor: Colors.black,
      elevation: 6,
      focusElevation: 8,
      hoverElevation: 8,
      highlightElevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
    ),

    // Button themes for dark mode
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: primaryDark,
        elevation: 2,
        shadowColor: shadowDark,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        textStyle: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryDark,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        side: BorderSide(color: outlineDark),
        textStyle: GoogleFonts.roboto(
          fontSize: 14,
          color: primaryDark,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryDark,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        textStyle: GoogleFonts.roboto(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
      ),
    ),

    // Typography system for dark mode
    textTheme: _buildTextTheme(isLight: false),

    // Input decoration for dark mode
    inputDecorationTheme: InputDecorationTheme(
      fillColor: surfaceDark,
      filled: true,
      suffixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: outlineDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: outlineDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: primaryDark, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: errorDark),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: errorDark, width: 2),
      ),
      labelStyle: GoogleFonts.roboto(
        color: textMediumEmphasisDark,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      hintStyle: GoogleFonts.roboto(
        color: textDisabledDark,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      helperStyle: GoogleFonts.roboto(
        color: textMediumEmphasisDark,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      errorStyle: GoogleFonts.roboto(
        color: errorDark,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    ),

    // Interactive element themes for dark mode
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryDark;
        }
        return Colors.grey[600];
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryDark.withValues(alpha: 0.5);
        }
        return Colors.grey[600];
      }),
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryDark;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.black),
      side: BorderSide(color: outlineDark, width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
    ),

    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryDark;
        }
        return outlineDark;
      }),
    ),

    // Progress indicators for dark mode
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: primaryDark,
      linearTrackColor: primaryDark.withValues(alpha: 0.2),
      circularTrackColor: primaryDark.withValues(alpha: 0.2),
    ),

    // Slider theme for dark mode
    sliderTheme: SliderThemeData(
      activeTrackColor: primaryDark,
      thumbColor: primaryDark,
      overlayColor: primaryDark.withValues(alpha: 0.12),
      inactiveTrackColor: primaryDark.withValues(alpha: 0.24),
      valueIndicatorColor: primaryDark,
      valueIndicatorTextStyle: GoogleFonts.roboto(
        color: Colors.black,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),

    // Tooltip theme for dark mode
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: onSurfaceDark.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: GoogleFonts.roboto(
        color: surfaceDark,
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),

    // Snackbar theme for dark mode
    snackBarTheme: SnackBarThemeData(
      backgroundColor: onSurfaceDark,
      contentTextStyle: GoogleFonts.roboto(
        color: surfaceDark,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      actionTextColor: accentDark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      elevation: 6,
    ),

    // Dialog theme for dark mode
    dialogTheme: DialogThemeData(
      backgroundColor: dialogDark,
      elevation: 24,
      shadowColor: shadowDark,
      surfaceTintColor: surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: onSurfaceDark,
      ),
      contentTextStyle: GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: onSurfaceDark,
      ),
    ),

    // List tile theme for dark mode
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      tileColor: Colors.transparent,
      selectedTileColor: primaryDark.withValues(alpha: 0.12),
      iconColor: textMediumEmphasisDark,
      textColor: onSurfaceDark,
      titleTextStyle: GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: onSurfaceDark,
      ),
      subtitleTextStyle: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textMediumEmphasisDark,
      ),
    ),
  );

  /// Helper method to build text theme based on brightness
  /// Implements typography standards with Inter for headings and Roboto for body text
  static TextTheme _buildTextTheme({required bool isLight}) {
    final Color textHighEmphasis = isLight
        ? textHighEmphasisLight
        : textHighEmphasisDark;
    final Color textMediumEmphasis = isLight
        ? textMediumEmphasisLight
        : textMediumEmphasisDark;
    final Color textDisabled = isLight ? textDisabledLight : textDisabledDark;

    return TextTheme(
      // Display styles - Inter for headings
      displayLarge: GoogleFonts.inter(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: textHighEmphasis,
        letterSpacing: -0.25,
        height: 1.12,
      ),
      displayMedium: GoogleFonts.inter(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: textHighEmphasis,
        letterSpacing: 0,
        height: 1.16,
      ),
      displaySmall: GoogleFonts.inter(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: textHighEmphasis,
        letterSpacing: 0,
        height: 1.22,
      ),

      // Headline styles - Inter for headings
      headlineLarge: GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: textHighEmphasis,
        letterSpacing: 0,
        height: 1.25,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: textHighEmphasis,
        letterSpacing: 0,
        height: 1.29,
      ),
      headlineSmall: GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: textHighEmphasis,
        letterSpacing: 0,
        height: 1.33,
      ),

      // Title styles - Inter for headings
      titleLarge: GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textHighEmphasis,
        letterSpacing: 0,
        height: 1.27,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textHighEmphasis,
        letterSpacing: 0.15,
        height: 1.50,
      ),
      titleSmall: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: textHighEmphasis,
        letterSpacing: 0.1,
        height: 1.43,
      ),

      // Body styles - Roboto for body text
      bodyLarge: GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textHighEmphasis,
        letterSpacing: 0.5,
        height: 1.50,
      ),
      bodyMedium: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textHighEmphasis,
        letterSpacing: 0.25,
        height: 1.43,
      ),
      bodySmall: GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: textMediumEmphasis,
        letterSpacing: 0.4,
        height: 1.33,
      ),

      // Label styles - Roboto for captions and labels
      labelLarge: GoogleFonts.roboto(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textHighEmphasis,
        letterSpacing: 0.1,
        height: 1.43,
      ),
      labelMedium: GoogleFonts.roboto(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textMediumEmphasis,
        letterSpacing: 0.5,
        height: 1.33,
      ),
      labelSmall: GoogleFonts.roboto(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textDisabled,
        letterSpacing: 0.5,
        height: 1.45,
      ),
    );
  }

  /// Helper method to get monospace text style for data display
  /// Uses Roboto Mono for file sizes, dates, and technical information
  static TextStyle getMonospaceStyle({
    required bool isLight,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    final Color textColor = isLight
        ? textHighEmphasisLight
        : textHighEmphasisDark;

    return GoogleFonts.robotoMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: textColor,
      letterSpacing: 0,
      height: 1.43,
    );
  }

  /// Helper method to get success color based on theme brightness
  static Color getSuccessColor(bool isLight) {
    return isLight ? successLight : successDark;
  }

  /// Helper method to get warning color based on theme brightness
  static Color getWarningColor(bool isLight) {
    return isLight ? warningLight : warningDark;
  }

  /// Helper method to get accent color based on theme brightness
  static Color getAccentColor(bool isLight) {
    return isLight ? accentLight : accentDark;
  }
}
