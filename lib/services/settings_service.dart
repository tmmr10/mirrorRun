import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  late SharedPreferences _prefs;

  bool _soundEnabled = true;
  bool _hapticEnabled = true;

  bool get soundEnabled => _soundEnabled;
  bool get hapticEnabled => _hapticEnabled;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _soundEnabled = _prefs.getBool('sound_enabled') ?? true;
    _hapticEnabled = _prefs.getBool('haptic_enabled') ?? true;
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    await _prefs.setBool('sound_enabled', value);
  }

  Future<void> setHapticEnabled(bool value) async {
    _hapticEnabled = value;
    await _prefs.setBool('haptic_enabled', value);
  }
}
