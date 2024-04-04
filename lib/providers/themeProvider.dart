import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeModeOptions { light, dark }

class ThemeProvider with ChangeNotifier {
  ThemeModeOptions _themeMode = ThemeModeOptions.dark;

  ThemeModeOptions get themeMode => _themeMode;
  ThemeProvider() {
    _loadThemeMode();
  }

  void setThemeMode(ThemeModeOptions mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.toString());
    _themeMode = mode;
    notifyListeners();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString('theme_mode');
    _themeMode = savedMode != null
        ? ThemeModeOptions.values.firstWhere(
          (value) => value.toString() == savedMode,
      orElse: () => ThemeModeOptions.dark,
    )
        : ThemeModeOptions.dark;
    notifyListeners();
  }
}