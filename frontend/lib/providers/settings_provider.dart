import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsState {
  final ThemeMode themeMode;
  final Locale locale;

  const SettingsState({
    required this.themeMode,
    required this.locale,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyLanguageCode = 'language_code';

  SettingsNotifier()
      : super(const SettingsState(
          themeMode: ThemeMode.system,
          locale: Locale('en'),
        )) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Load Theme Preference
      final themeString = prefs.getString(_keyThemeMode);
      ThemeMode themeMode = ThemeMode.system;
      if (themeString == 'light') {
        themeMode = ThemeMode.light;
      } else if (themeString == 'dark') {
        themeMode = ThemeMode.dark;
      } else if (themeString == 'system') {
        themeMode = ThemeMode.system;
      }

      // 2. Load Language Preference
      final langString = prefs.getString(_keyLanguageCode) ?? 'en';
      final locale = Locale(langString);

      state = SettingsState(
        themeMode: themeMode,
        locale: locale,
      );
    } catch (e) {
      debugPrint('Error loading settings from SharedPreferences: $e');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      String themeString = 'system';
      if (mode == ThemeMode.light) themeString = 'light';
      if (mode == ThemeMode.dark) themeString = 'dark';
      await prefs.setString(_keyThemeMode, themeString);
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = state.copyWith(locale: locale);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLanguageCode, locale.languageCode);
    } catch (e) {
      debugPrint('Error saving language locale: $e');
    }
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
