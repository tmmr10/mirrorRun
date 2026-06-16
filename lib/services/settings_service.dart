import 'dart:ui' show Locale;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  late SharedPreferences _prefs;

  bool _soundEnabled = true;
  bool _hapticEnabled = true;

  /// null = follow system locale, otherwise 'en' / 'de'.
  String? _localeOverride;

  bool get soundEnabled => _soundEnabled;
  bool get hapticEnabled => _hapticEnabled;

  /// Language override code ('en'/'de') or null for the system language.
  String? get localeOverride => _localeOverride;

  /// Resolved [Locale] override, or null to follow the system language.
  Locale? get locale =>
      _localeOverride == null ? null : Locale(_localeOverride!);

  /// Bumped whenever the language changes so the app can rebuild.
  final ValueNotifier<int> localeRevision = ValueNotifier(0);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _soundEnabled = _prefs.getBool('sound_enabled') ?? true;
    _hapticEnabled = _prefs.getBool('haptic_enabled') ?? true;
    final code = _prefs.getString('locale_override');
    _localeOverride = (code == 'en' || code == 'de') ? code : null;
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    await _prefs.setBool('sound_enabled', value);
  }

  Future<void> setHapticEnabled(bool value) async {
    _hapticEnabled = value;
    await _prefs.setBool('haptic_enabled', value);
  }

  /// Sets the language override. Pass null to follow the system language.
  Future<void> setLocaleOverride(String? code) async {
    final normalized = (code == 'en' || code == 'de') ? code : null;
    if (normalized == _localeOverride) return;
    _localeOverride = normalized;
    if (normalized == null) {
      await _prefs.remove('locale_override');
    } else {
      await _prefs.setString('locale_override', normalized);
    }
    localeRevision.value++;
  }
}
