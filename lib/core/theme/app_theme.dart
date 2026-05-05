import 'package:flutter/material.dart';

/// Accent for APIs sin `BuildContext` (p. ej. color de notificación Android).
const Color kAppAccentColor = Color(0xFF4FC3F7);

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.bg,
    required this.surface,
    required this.surface2,
    required this.borderSubtle,
    required this.accent,
    required this.accentStrong,
    required this.green,
    required this.yellow,
    required this.red,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.heroVpn,
    required this.heroBannerTop,
    required this.trafficLiveCardGradient,
  });

  final Color bg;
  final Color surface;
  final Color surface2;
  final Color borderSubtle;
  final Color accent;
  final Color accentStrong;
  final Color green;
  final Color yellow;
  final Color red;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Gradient heroVpn;
  final Color heroBannerTop;
  /// Fondo de la tarjeta «velocidad en tiempo real» en Tráfico.
  final Gradient trafficLiveCardGradient;

  static const AppPalette dark = AppPalette(
    bg: Color(0xFF0F0F0F),
    surface: Color(0xFF1A1A1A),
    surface2: Color(0xFF222222),
    borderSubtle: Color(0x12FFFFFF),
    accent: Color(0xFF4FC3F7),
    accentStrong: Color(0xFF0288D1),
    green: Color(0xFF66BB6A),
    yellow: Color(0xFFFFCA28),
    red: Color(0xFFEF5350),
    textPrimary: Color(0xFFF5F5F5),
    textSecondary: Color(0xFFADADAD),
    textMuted: Color(0xFF666666),
    heroVpn: LinearGradient(
      colors: [Color(0xFF162A35), Color(0xFF0D1F29)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    heroBannerTop: Color(0xFF1A1A2E),
    trafficLiveCardGradient: LinearGradient(
      colors: [Color(0xFF0D1F14), Color(0xFF101A10)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  static const AppPalette light = AppPalette(
    bg: Color(0xFFF3F3F3),
    surface: Color(0xFFFFFFFF),
    surface2: Color(0xFFEEEEEE),
    borderSubtle: Color(0x1F000000),
    accent: Color(0xFF0288D1),
    accentStrong: Color(0xFF01579B),
    green: Color(0xFF2E7D32),
    yellow: Color(0xFFF9A825),
    red: Color(0xFFD32F2F),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF616161),
    textMuted: Color(0xFF9E9E9E),
    heroVpn: LinearGradient(
      colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    heroBannerTop: Color(0xFFE3F2FD),
    trafficLiveCardGradient: LinearGradient(
      colors: [Color(0xFFE8F5E9), Color(0xFFFFFFFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  );

  @override
  AppPalette copyWith({
    Color? bg,
    Color? surface,
    Color? surface2,
    Color? borderSubtle,
    Color? accent,
    Color? accentStrong,
    Color? green,
    Color? yellow,
    Color? red,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Gradient? heroVpn,
    Color? heroBannerTop,
    Gradient? trafficLiveCardGradient,
  }) {
    return AppPalette(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surface2: surface2 ?? this.surface2,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      accent: accent ?? this.accent,
      accentStrong: accentStrong ?? this.accentStrong,
      green: green ?? this.green,
      yellow: yellow ?? this.yellow,
      red: red ?? this.red,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      heroVpn: heroVpn ?? this.heroVpn,
      heroBannerTop: heroBannerTop ?? this.heroBannerTop,
      trafficLiveCardGradient:
          trafficLiveCardGradient ?? this.trafficLiveCardGradient,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surface2: Color.lerp(surface2, other.surface2, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentStrong: Color.lerp(accentStrong, other.accentStrong, t)!,
      green: Color.lerp(green, other.green, t)!,
      yellow: Color.lerp(yellow, other.yellow, t)!,
      red: Color.lerp(red, other.red, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      heroVpn: t < 0.5 ? heroVpn : other.heroVpn,
      heroBannerTop: Color.lerp(heroBannerTop, other.heroBannerTop, t)!,
      trafficLiveCardGradient:
          t < 0.5 ? trafficLiveCardGradient : other.trafficLiveCardGradient,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.dark;
}

/// Curva para transiciones de pestañas (shared axis).
const Curve tabSwitch = Cubic(0.33, 0.0, 0.2, 1.0);

ThemeData buildAppDarkTheme() {
  const p = AppPalette.dark;
  final scheme = ColorScheme.dark(
    surface: p.surface,
    primary: p.accent,
    secondary: p.green,
    error: p.red,
    onPrimary: Colors.black,
    onSurface: p.textPrimary,
    outline: p.borderSubtle,
    outlineVariant: p.borderSubtle,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.bg,
    extensions: const [AppPalette.dark],
    dividerTheme: DividerThemeData(color: p.borderSubtle),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      backgroundColor: p.bg,
      foregroundColor: p.textPrimary,
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 22,
        letterSpacing: -0.5,
        color: p.textPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: p.textSecondary,
      textColor: p.textPrimary,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface,
      indicatorColor: p.accent.withValues(alpha: 0.14),
      surfaceTintColor: Colors.transparent,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? p.accent : p.textMuted,
          size: 24,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? p.accent : p.textMuted,
        );
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? p.accent : Colors.grey),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? p.accent.withValues(alpha: 0.35)
              : p.surface2),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.accent,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface2,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: p.borderSubtle),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: p.accent, width: 1.4),
      ),
    ),
  );
}

ThemeData buildAppLightTheme() {
  const p = AppPalette.light;
  final scheme = ColorScheme.light(
    surface: p.surface,
    primary: p.accent,
    secondary: p.green,
    error: p.red,
    onPrimary: Colors.white,
    onSurface: p.textPrimary,
    outline: p.borderSubtle,
    outlineVariant: p.borderSubtle,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.bg,
    extensions: const [AppPalette.light],
    dividerTheme: DividerThemeData(color: p.borderSubtle),
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      backgroundColor: p.bg,
      foregroundColor: p.textPrimary,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 22,
        letterSpacing: -0.5,
        color: p.textPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: EdgeInsets.zero,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: p.textSecondary,
      textColor: p.textPrimary,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface,
      indicatorColor: p.accent.withValues(alpha: 0.18),
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      shadowColor: Colors.black26,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? p.accent : p.textMuted,
          size: 24,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: selected ? p.accent : p.textMuted,
        );
      }),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? p.accent : Colors.grey),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? p.accent.withValues(alpha: 0.35)
              : p.surface2),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surface2,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: p.accent, width: 1.4),
      ),
    ),
  );
}
