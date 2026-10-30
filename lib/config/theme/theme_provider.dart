import 'package:flutter/material.dart';

import '../../core/storage/preferences_service.dart';

import 'dart:async';

class ThemeProvider extends ChangeNotifier {
  ThemeProvider(this._preferences) {
    unawaited(_restore());
  }

  final PreferencesService _preferences;
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  Future<void> _restore() async {
    final name = _preferences.getString('theme_mode');
    if (name == null) return;
    for (final mode in ThemeMode.values) {
      if (mode.name == name) {
        _themeMode = mode;
        notifyListeners();
        return;
      }
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      await _preferences.setString('theme_mode', mode.name);
    } catch (_) {
      // Keep the selected mode for this session if local preferences are unavailable.
    }
  }
}
