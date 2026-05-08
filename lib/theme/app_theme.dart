import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF00478D);
  static const Color primaryContainer = Color(0xFF005EB8);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFC8DAFF);

  static const Color secondary = Color(0xFF505F76);
  static const Color secondaryContainer = Color(0xD0E1FBFF); // Actually #D0E1FB
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF54647A);

  static const Color tertiary = Color(0xFF793100);
  static const Color tertiaryContainer = Color(0xFF9F4300);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFFFFCFB9);

  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);

  static const Color background = Color(0xFFF9F9FF);
  static const Color onBackground = Color(0xFF191C21);
  static const Color surface = Color(0xFFF9F9FF);
  static const Color onSurface = Color(0xFF191C21);
  static const Color onSurfaceVariant = Color(0xFF424752);
  static const Color surfaceVariant = Color(0xFFE1E2EA);
  static const Color outline = Color(0xFF727783);
  static const Color outlineVariant = Color(0xFFC2C6D4);

  // Surface containers (from Material 3)
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F3FB);
  static const Color surfaceContainer = Color(0xFFECEDF6);
  static const Color surfaceContainerHigh = Color(0xFFE7E8F0);
  static const Color surfaceContainerHighest = Color(0xFFE1E2EA);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: Color(0xFFD0E1FB),
        onSecondaryContainer: onSecondaryContainer,
        tertiary: tertiary,
        onTertiary: onTertiary,
        tertiaryContainer: tertiaryContainer,
        onTertiaryContainer: onTertiaryContainer,
        error: error,
        onError: onError,
        errorContainer: errorContainer,
        onErrorContainer: onErrorContainer,
        background: background,
        onBackground: onBackground,
        surface: surface,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        surfaceVariant: surfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
      ),
      scaffoldBackgroundColor: background,
      textTheme: _textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: _textTheme.headlineMedium?.copyWith(
          color: primary,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceContainerLowest,
        selectedItemColor: primary,
        unselectedItemColor: onSurfaceVariant,
        selectedLabelStyle: _textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
        unselectedLabelStyle: _textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  static TextTheme get _textTheme {
    return TextTheme(
      displayLarge: GoogleFonts.inter(
        fontSize: 30,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.02 * 30,
        height: 38 / 30,
      ),
      headlineMedium: GoogleFonts.inter(
        // Assuming Geist falls back to Inter if not available natively, or we can use inter for display as well
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.01 * 20,
        height: 28 / 20,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.05 * 12,
        height: 16 / 12,
      ),
    );
  }

  // A helper for monospace font
  static TextStyle get codeSmall {
    return GoogleFonts.jetBrainsMono(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 18 / 13,
    );
  }
}
