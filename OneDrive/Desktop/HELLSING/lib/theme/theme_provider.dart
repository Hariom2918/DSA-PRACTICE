import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'yamada_theme.dart';

/// Theme provider — persists theme choice and notifies listeners.
class ThemeProvider extends ChangeNotifier {
  static const String _prefKey = 'yamada_theme_mode';

  YamadaThemeMode _mode = YamadaThemeMode.blood;
  YamadaThemeMode get mode => _mode;

  YamadaThemeConfig get config => YamadaTheme.configFor(_mode);

  ThemeData get themeData => YamadaTheme.getThemeData(_mode);

  /// Flash color for theme switch animation
  Color get flashColor {
    switch (_mode) {
      case YamadaThemeMode.blood:
        return const Color(0xFFCB1E1E);
      case YamadaThemeMode.bone:
        return Colors.white;
      case YamadaThemeMode.void_:
        return Colors.black;
    }
  }

  /// Splash screen ink color adapts to theme
  Color get splashInkColor {
    switch (_mode) {
      case YamadaThemeMode.blood:
        return const Color(0xFF0A0000);
      case YamadaThemeMode.bone:
        return const Color(0xFF8B6914); // sepia
      case YamadaThemeMode.void_:
        return const Color(0xFFEBEBEB);
    }
  }

  Color get splashBackground {
    switch (_mode) {
      case YamadaThemeMode.blood:
        return const Color(0xFFCB1E1E);
      case YamadaThemeMode.bone:
        return const Color(0xFFF5F0E8);
      case YamadaThemeMode.void_:
        return const Color(0xFF080808);
    }
  }

  ThemeProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt(_prefKey) ?? 0;
    _mode = YamadaThemeMode.values[idx.clamp(0, 2)];
    YamadaTheme.applyConfig(YamadaTheme.configFor(_mode));
    notifyListeners();
  }

  Future<void> setTheme(YamadaThemeMode newMode) async {
    if (newMode == _mode) return;
    _mode = newMode;
    YamadaTheme.applyConfig(YamadaTheme.configFor(_mode));
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefKey, newMode.index);
  }
}
