import 'package:flutter/material.dart';

/// لوحة الألوان المستخرجة من تصميم HTML (Material 3 Dark).
class AppColors {
  AppColors._();

  static const Color background = Color(0xFF121414);
  static const Color onBackground = Color(0xFFE3E2E2);
  static const Color surface = Color(0xFF121414);
  static const Color surfaceDim = Color(0xFF121414);
  static const Color surfaceBright = Color(0xFF38393A);
  static const Color surfaceContainerLowest = Color(0xFF0D0E0F);
  static const Color surfaceContainerLow = Color(0xFF1A1C1C);
  static const Color surfaceContainer = Color(0xFF1E2020);
  static const Color surfaceContainerHigh = Color(0xFF292A2A);
  static const Color surfaceContainerHighest = Color(0xFF343535);
  static const Color onSurface = Color(0xFFE3E2E2);
  static const Color onSurfaceVariant = Color(0xFFD0C6AB);
  static const Color inverseSurface = Color(0xFFE3E2E2);
  static const Color onInverseSurface = Color(0xFF2F3131);

  static const Color primary = Color(0xFFFFF6DF);
  static const Color onPrimary = Color(0xFF3A3000);
  static const Color primaryContainer = Color(0xFFFFD700);
  static const Color onPrimaryContainer = Color(0xFF705E00);

  static const Color secondary = Color(0xFFC8C6C5);
  static const Color onSecondary = Color(0xFF313030);
  static const Color secondaryContainer = Color(0xFF474746);
  static const Color onSecondaryContainer = Color(0xFFB7B5B4);

  static const Color tertiary = Color(0xFFFFF3F2);
  static const Color onTertiary = Color(0xFF680009);
  static const Color tertiaryContainer = Color(0xFFFFCECA);
  static const Color onTertiaryContainer = Color(0xFFBE0C1E);

  static const Color error = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  static const Color outline = Color(0xFF999077);
  static const Color outlineVariant = Color(0xFF4D4732);
}

/// أنماط النصوص المشتركة: Space Grotesk للعناوين، Noto Sans للنصوص، Space Mono للأرقام.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle displayLarge([Color color = AppColors.onSurface]) =>
      TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontFamilyFallback: const ['NotoSansArabic'],
        fontSize: 40,
        height: 48 / 40,
        letterSpacing: -0.8,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle displayMobile([Color color = AppColors.onSurface]) =>
      TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontFamilyFallback: const ['NotoSansArabic'],
        fontSize: 32,
        height: 40 / 32,
        letterSpacing: -0.32,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle headlineLarge([Color color = AppColors.onSurface]) =>
      TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontFamilyFallback: const ['NotoSansArabic'],
        fontSize: 28,
        height: 36 / 28,
        letterSpacing: -0.28,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle headlineMedium([Color color = AppColors.onSurface]) =>
      TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontFamilyFallback: const ['NotoSansArabic'],
        fontSize: 22,
        height: 28 / 22,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle headlineSmall([Color color = AppColors.onSurface]) =>
      TextStyle(
        fontFamily: 'SpaceGrotesk',
        fontFamilyFallback: const ['NotoSansArabic'],
        fontSize: 18,
        height: 24 / 18,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle bodyLarge([Color color = AppColors.onSurface]) =>
      TextStyle(
        fontFamily: 'NotoSans',
        fontFamilyFallback: const ['NotoSansArabic'],
        fontSize: 16,
        height: 24 / 16,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle bodyMedium([Color color = AppColors.onSurface]) =>
      TextStyle(
        fontFamily: 'NotoSans',
        fontFamilyFallback: const ['NotoSansArabic'],
        fontSize: 14,
        height: 20 / 14,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle bodySmall([Color color = AppColors.onSurface]) =>
      TextStyle(
        fontFamily: 'NotoSans',
        fontFamilyFallback: const ['NotoSansArabic'],
        fontSize: 12,
        height: 16 / 12,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle labelMonoSmall([Color color = AppColors.onSurfaceVariant]) =>
      TextStyle(
        fontFamily: 'SpaceMono',
        fontFamilyFallback: const ['NotoSansArabic'],
        fontSize: 11,
        height: 14 / 11,
        letterSpacing: 0.88,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle labelMonoLarge([Color color = AppColors.onSurfaceVariant]) =>
      TextStyle(
        fontFamily: 'SpaceMono',
        fontFamilyFallback: const ['NotoSansArabic'],
        fontSize: 14,
        height: 20 / 14,
        letterSpacing: 0.7,
        fontWeight: FontWeight.w500,
        color: color,
      );
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: AppColors.primaryContainer,
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
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      inverseSurface: AppColors.inverseSurface,
      onInverseSurface: AppColors.onInverseSurface,
      surfaceContainerLowest: AppColors.surfaceContainerLowest,
      surfaceContainerLow: AppColors.surfaceContainerLow,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.surfaceContainerHigh,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.surfaceContainerLowest,
      canvasColor: AppColors.surfaceContainerLowest,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.headlineSmall(),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.primaryContainer,
        selectionColor: Color(0x66FFD700),
        selectionHandleColor: AppColors.primaryContainer,
      ),
      dividerColor: AppColors.surfaceContainerHighest,
      iconTheme: const IconThemeData(color: AppColors.onSurface),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceContainerHigh,
        contentTextStyle: AppTextStyles.labelMonoSmall(AppColors.primary),
        behavior: SnackBarBehavior.floating,
        shape: const StadiumBorder(),
      ),
    );
  }
}
