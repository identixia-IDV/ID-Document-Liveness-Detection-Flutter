import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFFE6E9EF);
  static const card = Color(0xFFF7F8FA);
  static const accent = Color(0xFF0F766E);
  static const accentDim = Color(0xFF0B4F4A);
  static const text = Color(0xFF141A22);
  static const muted = Color(0xFF5A6573);
  static const statusInfo = Color(0xFF0B4F4A);
  static const statusOk = Color(0xFF0F766E);
  static const statusWarn = Color(0xFFB45309);
  static const statusError = Color(0xFFB91C1C);
  static const surface = Color(0xFFF7F8FA);
  static const border = Color(0xFFC5CCD8);
  static const radiusCard = 22.0;
  static const radiusPill = 28.0;
}

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.accent,
        onPrimary: const Color(0xFFF4FFFC),
        surface: AppColors.surface,
        onSurface: AppColors.text,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.text,
        elevation: 0,
      ),
    );
  }
}
