import 'package:flutter/material.dart';

/// Theme aligned with the HTML proposal (Samsung One UI–style dark / M3).
class AppColors {
  AppColors._();

  static const Color bg = Color(0xFF0F0F0F);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color surface2 = Color(0xFF222222);
  static const Color borderSubtle = Color(0x12FFFFFF);

  static const Color accent = Color(0xFF4FC3F7);
  static const Color accentStrong = Color(0xFF0288D1);
  static const Color green = Color(0xFF66BB6A);
  static const Color yellow = Color(0xFFFFCA28);
  static const Color red = Color(0xFFEF5350);
  static const Color textPrimary = Color(0xFFF5F5F5);
  static const Color textSecondary = Color(0xFFADADAD);
  static const Color textMuted = Color(0xFF666666);

  static const Gradient heroVpn = LinearGradient(
    colors: [Color(0xFF162A35), Color(0xFF0D1F29)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Smooth curve for tab switches. Must map [0,1] → [0,1]: a Bézier with control y>1 (e.g. 1.45)
  /// overshoots and breaks [SharedAxisTransition] (“parametric value is outside of [0, 1] range”).
  static const Curve tabSwitch = Cubic(0.33, 0.0, 0.2, 1.0);
}

ThemeData buildAppDarkTheme() {
  const scheme = ColorScheme.dark(
    surface: AppColors.surface,
    primary: AppColors.accent,
    secondary: AppColors.green,
    error: AppColors.red,
    onPrimary: Colors.black,
    onSurface: AppColors.textPrimary,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    appBarTheme: const AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.textPrimary,
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 22,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.textSecondary,
      textColor: AppColors.textPrimary,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.accent : Colors.grey),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? AppColors.accent.withValues(alpha: 0.35)
              : AppColors.surface2),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface2,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
      ),
    ),
  );
}
