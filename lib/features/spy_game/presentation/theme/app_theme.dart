import 'package:flutter/material.dart';

/// Design tokens and semantic color definitions for the application.
abstract final class AppColors {
  /// Primary brand seed color.
  static const Color primarySeed = Color(0xFF6750A4);

  /// Secondary accent seed color.
  static const Color secondarySeed = Color(0xFF625B71);
}

/// Centralized application theme configuration.
abstract final class AppTheme {
  /// Light theme definition.
  static ThemeData get lightTheme => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primarySeed,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      );

  /// Dark theme definition.
  static ThemeData get darkTheme => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primarySeed,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      );
}
