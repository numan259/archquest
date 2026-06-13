import 'package:flutter/material.dart';

/// Dark-first design language for ArchQuest. The accent is cyan to match the
/// lecture diagrams, but per-subject cards may tint with their own accent.
class AppColors {
  AppColors._();

  static const background = Color(0xFF121212);
  static const surface = Color(0xFF1E1E1E);
  static const surfaceVariant = Color(0xFF262626);
  static const accent = Color(0xFF4FC3F7); // electric cyan
  static const success = Color(0xFF66BB6A);
  static const error = Color(0xFFEF5350);
  static const warning = Color(0xFFFFB74D); // exam-trap amber
  static const onSurface = Color(0xFFECECEC);
  static const onSurfaceMuted = Color(0xFF9E9E9E);
  static const locked = Color(0xFF3A3A3A);
}

class AppRadii {
  AppRadii._();
  static const card = 16.0;
  static const chip = 10.0;
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: AppColors.accent,
      onPrimary: Color(0xFF06222E),
      secondary: AppColors.accent,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      error: AppColors.error,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: null,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
      ),
      textTheme: base.textTheme
          .apply(
            bodyColor: AppColors.onSurface,
            displayColor: AppColors.onSurface,
          )
          .copyWith(
            titleLarge: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.onSurface,
            ),
            bodyMedium: const TextStyle(fontSize: 16, height: 1.4),
            bodyLarge: const TextStyle(fontSize: 17, height: 1.45),
          ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.surfaceVariant,
        labelStyle: const TextStyle(color: AppColors.onSurface, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.chip),
        ),
        side: BorderSide.none,
      ),
      progressIndicatorTheme:
          const ProgressIndicatorThemeData(color: AppColors.accent),
      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.surfaceVariant,
        contentTextStyle: TextStyle(color: AppColors.onSurface),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
