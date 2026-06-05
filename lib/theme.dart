import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF006B47);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF00875A);
  static const Color onPrimaryContainer = Color(0xFFFFFFFF);
  static const Color inversePrimary = Color(0xFF71DBA6);

  static const Color secondary = Color(0xFF556158);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFD9E6DA);
  static const Color onSecondaryContainer = Color(0xFF5B675E);

  static const Color tertiary = Color(0xFF9B403E);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFBA5855);
  static const Color onTertiaryContainer = Color(0xFFFFFFFF);

  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  static const Color background = Color(0xFFFCF8FB);
  static const Color onBackground = Color(0xFF1B1B1D);
  static const Color backgroundAlt = Color(0xFFF8F9FA);

  static const Color surface = Color(0xFFFCF8FB);
  static const Color onSurface = Color(0xFF1B1B1D);
  static const Color surfaceVariant = Color(0xFFE4E2E4);
  static const Color onSurfaceVariant = Color(0xFF3E4942);
  static const Color inverseSurface = Color(0xFF303032);
  static const Color inverseOnSurface = Color(0xFFF3F0F2);
  static const Color surfaceDim = Color(0xFFDCD9DC);
  static const Color surfaceBright = Color(0xFFFCF8FB);

  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF6F3F5);
  static const Color surfaceContainer = Color(0xFFF0EDEF);
  static const Color surfaceContainerHigh = Color(0xFFEAE7EA);
  static const Color surfaceContainerHighest = Color(0xFFE4E2E4);

  static const Color outline = Color(0xFF6E7A71);
  static const Color outlineVariant = Color(0xFFBDCAC0);
  static const Color borderSubtle = Color(0xFFE5E5EA);

  static const Color primaryFixed = Color(0xFF8DF7C1);
  static const Color primaryFixedDim = Color(0xFF71DBA6);
  static const Color onPrimaryFixed = Color(0xFF002113);
  static const Color onPrimaryFixedVariant = Color(0xFF005235);

  static const Color secondaryFixed = Color(0xFFD9E6DA);
  static const Color secondaryFixedDim = Color(0xFFBDCABE);
  static const Color onSecondaryFixed = Color(0xFF131E17);
  static const Color onSecondaryFixedVariant = Color(0xFF3E4A41);

  static const Color tertiaryFixed = Color(0xFFFFDAD7);
  static const Color tertiaryFixedDim = Color(0xFFFFB3AF);
  static const Color onTertiaryFixed = Color(0xFF410005);
  static const Color onTertiaryFixedVariant = Color(0xFF7D2A2A);

  static const Color textSecondary = Color(0xFF6E6E73);
  static const Color statusWarning = Color(0xFFD97706);
  static const Color iconInactive = Color(0xFF94A3B8);
}

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.backgroundAlt,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.onPrimaryContainer,
        secondary: AppColors.secondary,
        onSecondary: AppColors.onSecondary,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.onSecondaryContainer,
        tertiary: AppColors.tertiary,
        onTertiary: AppColors.onTertiary,
        tertiaryContainer: AppColors.tertiaryContainer,
        onTertiaryContainer: AppColors.onTertiaryContainer,
        error: AppColors.error,
        onError: AppColors.onError,
        errorContainer: AppColors.errorContainer,
        onErrorContainer: AppColors.onErrorContainer,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        surfaceContainerHighest: AppColors.surfaceVariant,
        onSurfaceVariant: AppColors.onSurfaceVariant,
        outline: AppColors.outline,
        outlineVariant: AppColors.outlineVariant,
        inverseSurface: AppColors.inverseSurface,
        onInverseSurface: AppColors.inverseOnSurface,
        inversePrimary: AppColors.inversePrimary,
      ),
      textTheme: baseTextTheme.copyWith(
        // headline-lg: size 24, weight 700, line height 32
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          height: 32 / 24,
          color: AppColors.onSurface,
        ),
        // headline-md: size 20, weight 600, line height 28
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 28 / 20,
          color: AppColors.onSurface,
        ),
        // title-card: size 16, weight 600, line height 24
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          height: 24 / 16,
          color: AppColors.onSurface,
        ),
        // body-default: size 14, weight 400, line height 20
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          height: 20 / 14,
          color: AppColors.onSurface,
        ),
        // label-md: size 12, weight 500, line height 16
        labelMedium: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 16 / 12,
          color: AppColors.onSurface,
        ),
        // caption: size 12, weight 400, line height 16, letterSpacing 0.2
        bodySmall: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          height: 16 / 12,
          letterSpacing: 0.2,
          color: AppColors.textSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      buttonTheme: const ButtonThemeData(
        buttonColor: AppColors.primary,
        textTheme: ButtonTextTheme.primary,
      ),
    );
  }
}
