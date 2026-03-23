import 'package:flutter/material.dart';

/// YAMADA design system — three brutal themes.
enum YamadaThemeMode { blood, bone, void_ }

class YamadaThemeConfig {
  final Color background;
  final Color text;
  final Color accent;
  final Color cardColor;
  final Color navBarBg;
  final Color navBarSelected;
  final Color navBarUnselected;
  final Brightness brightness;

  const YamadaThemeConfig({
    required this.background,
    required this.text,
    required this.accent,
    required this.cardColor,
    required this.navBarBg,
    required this.navBarSelected,
    required this.navBarUnselected,
    required this.brightness,
  });
}

class YamadaTheme {
  YamadaTheme._();

  // ── Theme Configs ─────────────────────────────────────────────
  static const bloodConfig = YamadaThemeConfig(
    background: Color(0xFFCB1E1E),
    text: Color(0xFF0A0000),
    accent: Color(0xFF0A0000),
    cardColor: Color(0x1A000000), // rgba(0,0,0,0.1)
    navBarBg: Color(0xFF0A0000),
    navBarSelected: Color(0xFFCB1E1E),
    navBarUnselected: Color(0x80CB1E1E),
    brightness: Brightness.light,
  );

  static const boneConfig = YamadaThemeConfig(
    background: Color(0xFFF5F0E8),
    text: Color(0xFF1A1008),
    accent: Color(0xFF8B4513),
    cardColor: Color(0x148B4513), // rgba(139,69,19,0.08)
    navBarBg: Color(0xFF1A1008),
    navBarSelected: Color(0xFFF5F0E8),
    navBarUnselected: Color(0x80F5F0E8),
    brightness: Brightness.light,
  );

  static const voidConfig = YamadaThemeConfig(
    background: Color(0xFF080808),
    text: Color(0xFFEBEBEB),
    accent: Color(0xFFCB1E1E),
    cardColor: Color(0x0AFFFFFF), // rgba(255,255,255,0.04)
    navBarBg: Color(0xFF111111),
    navBarSelected: Color(0xFFCB1E1E),
    navBarUnselected: Color(0x80EBEBEB),
    brightness: Brightness.dark,
  );

  static YamadaThemeConfig configFor(YamadaThemeMode mode) {
    switch (mode) {
      case YamadaThemeMode.blood:
        return bloodConfig;
      case YamadaThemeMode.bone:
        return boneConfig;
      case YamadaThemeMode.void_:
        return voidConfig;
    }
  }

  // ── Legacy static references for backwards compat ──────────────
  // These are updated dynamically by ThemeProvider, default to BLOOD
  static Color crimson = const Color(0xFFCB1E1E);
  static Color ink = const Color(0xFF0A0000);
  static Color inkLight = const Color(0x990A0000);
  static Color inkSubtle = const Color(0x660A0000);
  static Color inkGhost = const Color(0x330A0000);
  static const Color white = Color(0xFFFFFFFF);

  static void applyConfig(YamadaThemeConfig config) {
    crimson = config.background;
    ink = config.text;
    inkLight = config.text.withValues(alpha: 0.6);
    inkSubtle = config.text.withValues(alpha: 0.4);
    inkGhost = config.text.withValues(alpha: 0.2);
  }

  // ── Typography ────────────────────────────────────────────────
  static const String fontAnton = 'Anton';
  static const String fontBarlowCondensed = 'BarlowCondensed';
  static const String fontBarlow = 'Barlow';

  static TextStyle get heading1 => TextStyle(
    fontFamily: fontAnton,
    fontSize: 48,
    height: 1.05,
    color: ink,
    letterSpacing: 1.5,
  );

  static TextStyle get heading2 => TextStyle(
    fontFamily: fontAnton,
    fontSize: 32,
    height: 1.1,
    color: ink,
    letterSpacing: 1.0,
  );

  static TextStyle get heading3 => TextStyle(
    fontFamily: fontAnton,
    fontSize: 24,
    height: 1.15,
    color: ink,
  );

  static TextStyle get sectionLabel => TextStyle(
    fontFamily: fontBarlowCondensed,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 2.5,
    color: ink,
  );

  static TextStyle get dataLarge => TextStyle(
    fontFamily: fontBarlowCondensed,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    color: ink,
    height: 1.0,
  );

  static TextStyle get dataMedium => TextStyle(
    fontFamily: fontBarlowCondensed,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: ink,
  );

  static TextStyle get body => TextStyle(
    fontFamily: fontBarlow,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: ink,
    height: 1.5,
  );

  static TextStyle get bodyBold => TextStyle(
    fontFamily: fontBarlow,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: ink,
    height: 1.5,
  );

  static TextStyle get caption => TextStyle(
    fontFamily: fontBarlowCondensed,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
    color: ink,
  );

  // ── Borders ───────────────────────────────────────────────────
  static Border get hardBorder => Border.all(color: ink, width: 2);
  static Border get hardBorder3 => Border.all(color: ink, width: 3);

  // ── ThemeData ─────────────────────────────────────────────────
  static ThemeData getThemeData(YamadaThemeMode mode) {
    final config = configFor(mode);
    applyConfig(config);

    return ThemeData(
      brightness: config.brightness,
      scaffoldBackgroundColor: config.background,
      colorScheme: ColorScheme(
        brightness: config.brightness,
        primary: config.text,
        onPrimary: config.background,
        secondary: config.accent,
        onSecondary: config.background,
        surface: config.background,
        onSurface: config.text,
        error: const Color(0xFFFF0000),
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: config.background,
        foregroundColor: config.text,
        elevation: 0,
        titleTextStyle: heading2,
        centerTitle: false,
      ),
      textTheme: TextTheme(
        displayLarge: heading1,
        displayMedium: heading2,
        displaySmall: heading3,
        titleLarge: sectionLabel,
        bodyLarge: body,
        bodyMedium: body,
        labelLarge: dataMedium,
        labelSmall: caption,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: config.navBarBg,
        selectedItemColor: config.navBarSelected,
        unselectedItemColor: config.navBarUnselected,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: caption.copyWith(color: config.navBarSelected),
        unselectedLabelStyle: caption.copyWith(color: config.navBarUnselected),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: config.text,
        foregroundColor: config.background,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: config.text, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: config.text, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: config.text, width: 3),
        ),
        labelStyle: body,
        hintStyle: body.copyWith(color: inkSubtle),
      ),
      dividerTheme: DividerThemeData(
        color: config.text,
        thickness: 2,
      ),
    );
  }

  // Legacy default themeData (BLOOD)
  static ThemeData get themeData => getThemeData(YamadaThemeMode.blood);
}
