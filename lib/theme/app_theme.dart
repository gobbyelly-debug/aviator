import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF070B16);
  static const surface = Color(0xFF0C1220);
  static const surfaceAlt = Color(0xFF0E1524);
  static const surfaceMuted = Color(0xFF101726);
  static const navBackground = Color(0xFF0A0F19);
  static const panel = Color(0xFF111827);
  static const panelAlt = Color(0xFF1A2232);
  static const accent = Color(0xFFFF355D);
  static const accentStrong = Color(0xFFFF214C);
  static const success = Color(0xFF32D583);
  static const textMuted = Color(0xFF99A0AE);
  static const textSoft = Color(0xFF9097A6);
  static const textFaint = Color(0xFF7D8495);
  static const border = Color(0x14FFFFFF);
}

ThemeData buildAppTheme() {
  final colorScheme =
      ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: AppColors.accent,
      ).copyWith(
        surface: AppColors.surface,
        primary: AppColors.accent,
        secondary: AppColors.accentStrong,
      );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: colorScheme,
    fontFamily: 'Roboto',
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.panel,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.navBackground,
      indicatorColor: AppColors.accent.withAlpha(34),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final color = states.contains(WidgetState.selected)
            ? AppColors.accent
            : Colors.white70;
        return IconThemeData(color: color);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final color = states.contains(WidgetState.selected)
            ? Colors.white
            : AppColors.textMuted;
        return TextStyle(
          color: color,
          fontWeight: states.contains(WidgetState.selected)
              ? FontWeight.w700
              : FontWeight.w500,
        );
      }),
    ),
  );
}
