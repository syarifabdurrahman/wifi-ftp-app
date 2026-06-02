import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Accent color presets
  static const List<Color> accentColors = [
    Color(0xFF00478D), // Default Blue
    Color(0xFF005EB8), // Bright Blue
    Color(0xFF1B9C5E), // Green
    Color(0xFFE65100), // Orange
    Color(0xFF7B1FA2), // Purple
    Color(0xFFC62828), // Red
    Color(0xFF00838F), // Teal
    Color(0xFFF9A825), // Amber
    Color(0xFF37474F), // Dark Gray
  ];

  static Color primary(int index) => accentColors[index.clamp(0, accentColors.length - 1)];
  static Color primaryContainer(int index) {
    final c = accentColors[index.clamp(0, accentColors.length - 1)];
    return Color.lerp(c, Colors.white, 0.3) ?? c;
  }

  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFC8DAFF);

  static const Color secondary = Color(0xFF505F76);
  static const Color secondaryContainer = Color(0xD0E1FBFF);
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

  // Dynamic helpers
  static Color getCardColor(BuildContext context) {
    return Theme.of(context).cardTheme.color ??
        (Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E2025)
            : surfaceContainerLowest);
  }

  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static ThemeData lightTheme([int accentIndex = 0]) {
    return _buildTheme(Brightness.light, accentIndex);
  }

  static ThemeData darkTheme([int accentIndex = 0]) {
    return _buildTheme(Brightness.dark, accentIndex);
  }

  static ThemeData _buildTheme(Brightness brightness, [int accentIndex = 0]) {
    final bool isDark = brightness == Brightness.dark;
    final Color accent = accentColors[accentIndex.clamp(0, accentColors.length - 1)];
    final Color accentDark = isDark
        ? Color.lerp(accent, Colors.white, 0.4) ?? accent
        : accent;
    final Color accentContainer = Color.lerp(accent, isDark ? Colors.black : Colors.white, 0.2) ?? accent;

    final ColorScheme colorScheme = ColorScheme(
      brightness: brightness,
      primary: accentDark,
      onPrimary: isDark ? const Color(0xFF002F64) : onPrimary,
      primaryContainer: accentContainer,
      onPrimaryContainer: isDark
          ? const Color(0xFFD6E3FF)
          : onPrimaryContainer,
      secondary: isDark ? const Color(0xFFB9C8DA) : secondary,
      onSecondary: isDark ? const Color(0xFF243240) : onSecondary,
      secondaryContainer: isDark
          ? const Color(0xFF3A4858)
          : const Color(0xFFD0E1FB),
      onSecondaryContainer: isDark
          ? const Color(0xFFD6E4F7)
          : onSecondaryContainer,
      tertiary: isDark ? const Color(0xFFFFB591) : tertiary,
      onTertiary: isDark ? const Color(0xFF551E00) : onTertiary,
      tertiaryContainer: isDark ? const Color(0xFF793100) : tertiaryContainer,
      onTertiaryContainer: isDark
          ? const Color(0xFFFFDBCA)
          : onTertiaryContainer,
      error: error,
      onError: onError,
      errorContainer: errorContainer,
      onErrorContainer: onErrorContainer,
      surface: isDark ? const Color(0xFF0B0E14) : surface,
      onSurface: isDark ? const Color(0xFFE2E2E6) : onSurface,
      onSurfaceVariant: isDark ? const Color(0xFFC4C6D0) : onSurfaceVariant,
      surfaceContainerHighest: isDark
          ? const Color(0xFF1A1C1E)
          : surfaceContainerHighest,
      outline: isDark ? const Color(0xFF8E9099) : outline,
      outlineVariant: isDark ? const Color(0xFF44474F) : outlineVariant,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: _textTheme(isDark),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: _textTheme(isDark).headlineMedium?.copyWith(
          color: isDark ? colorScheme.onSurface : colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark
            ? const Color(0xFF1A1C1E)
            : surfaceContainerLowest,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      cardTheme: CardThemeData(
        color: isDark ? const Color(0xFF1E2025) : surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: colorScheme.outlineVariant.withValues(
              alpha: isDark ? 0.2 : 0.5,
            ),
          ),
        ),
      ),
    );
  }

  static TextTheme _textTheme(bool isDark) {
    final Color textColor = isDark
        ? const Color(0xFFE2E2E9)
        : const Color(0xFF191C21);

    return TextTheme(
      displayLarge: GoogleFonts.inter(
        fontSize: 30,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      headlineMedium: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: textColor,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: textColor.withValues(alpha: 0.7),
      ),
    );
  }

  static TextStyle get codeSmall {
    return GoogleFonts.jetBrainsMono(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 1.5,
    );
  }
}
