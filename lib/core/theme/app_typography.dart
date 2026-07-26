import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Defines standard text styles.
/// Flutter automatically handles dynamic text scaling (TextScaler) by default,
/// but defining a clean TextTheme ensures consistency across the app.
class AppTypography {
  AppTypography._();

  static const _baseFontFamily = 'Roboto'; // Replace with your font

  static TextTheme get textTheme => const TextTheme(
        displayLarge: TextStyle(
          fontFamily: _baseFontFamily,
          fontSize: 57,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
          color: AppColors.onBackground,
        ),
        headlineMedium: TextStyle(
          fontFamily: _baseFontFamily,
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: AppColors.onBackground,
        ),
        bodyLarge: TextStyle(
          fontFamily: _baseFontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          color: AppColors.onBackground,
        ),
        bodyMedium: TextStyle(
          fontFamily: _baseFontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          color: AppColors.onBackground,
        ),
        labelLarge: TextStyle(
          fontFamily: _baseFontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: AppColors.onBackground,
        ),
      );
}
