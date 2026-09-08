import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _themeKey = 'theme_mode';
  static const _vibrateKey = 'vibrate_on_scan';
  static const _soundKey = 'play_sound';
  static const _autoSaveKey = 'auto_save';

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  ThemeMode get themeMode {
    final value = _prefs.getString(_themeKey) ?? 'system';
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    await _prefs.setString(_themeKey, value);
  }

  bool get vibrateOnScan => _prefs.getBool(_vibrateKey) ?? true;
  Future<void> setVibrateOnScan(bool value) => _prefs.setBool(_vibrateKey, value);

  bool get playSound => _prefs.getBool(_soundKey) ?? true;
  Future<void> setPlaySound(bool value) => _prefs.setBool(_soundKey, value);

  bool get autoSave => _prefs.getBool(_autoSaveKey) ?? true;
  Future<void> setAutoSave(bool value) => _prefs.setBool(_autoSaveKey, value);

  // Scan history
  List<String> get scanHistoryJson {
    return _prefs.getStringList('scan_history') ?? [];
  }

  Future<void> saveScanHistory(List<String> history) async {
    await _prefs.setStringList('scan_history', history);
  }

  Future<void> clearHistory() async {
    await _prefs.remove('scan_history');
  }
}
