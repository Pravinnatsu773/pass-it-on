import 'package:flutter/material.dart';

/// Defines the core color palette. 
/// These colors are chosen to ensure WCAG AA (or AAA) compliant contrast 
/// ratios when text is placed on top of them.
class AppColors {
  AppColors._();

  // Primary colors
  static const Color primary = Color(0xFF005CBB); // High contrast blue
  static const Color onPrimary = Color(0xFFFFFFFF); // White text on primary

  // Secondary colors
  static const Color secondary = Color(0xFF006C4C); // High contrast green
  static const Color onSecondary = Color(0xFFFFFFFF);

  // Background and surface
  static const Color background = Color(0xFFFDFDFD); // Off-white
  static const Color onBackground = Color(0xFF1A1C1E); // Near-black for high contrast text
  static const Color surface = Color(0xFFFDFDFD);
  static const Color onSurface = Color(0xFF1A1C1E);

  // Error states
  static const Color error = Color(0xFFBA1A1A); // Standard accessible error red
  static const Color onError = Color(0xFFFFFFFF);
}
