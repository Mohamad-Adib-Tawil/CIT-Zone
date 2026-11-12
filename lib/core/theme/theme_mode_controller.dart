import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Owns the user's appearance preference for the lifetime of the app.
class ThemeModeController extends ValueNotifier<ThemeMode> {
  ThemeModeController._(this._preferences, ThemeMode initialMode)
    : super(initialMode);

  ThemeModeController.inMemory() : _preferences = null, super(ThemeMode.system);

  static const _storageKey = 'appearance.theme_mode';
  final SharedPreferencesAsync? _preferences;
  Future<void> _pendingWrite = Future<void>.value();

  static Future<ThemeModeController> load() async {
    final preferences = SharedPreferencesAsync();
    final storedValue = await preferences.getString(_storageKey);
    return ThemeModeController._(preferences, _decode(storedValue));
  }

  Future<void> setMode(ThemeMode mode) async {
    if (value == mode) return;
    value = mode;
    _pendingWrite = _pendingWrite.then(
      (_) async => _preferences?.setString(_storageKey, mode.name),
    );
    await _pendingWrite;
  }

  static ThemeMode _decode(String? value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    'system' => ThemeMode.system,
    _ => ThemeMode.system,
  };
}
