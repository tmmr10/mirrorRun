import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'settings_service.dart';

class AudioService {
  final SettingsService _settings;
  bool _ready = false;

  AudioService(this._settings);

  Future<void> init() async {
    try {
      await FlameAudio.audioCache.loadAll(['death.wav', 'biome_chime.wav']);
      _ready = true;
    } catch (e) {
      debugPrint('AudioService init failed: $e');
    }
  }

  void playDeath() {
    if (_ready && _settings.soundEnabled) {
      try { FlameAudio.play('death.wav'); } catch (e) { debugPrint('Audio play failed: $e'); }
    }
  }

  void playBiomeTransition() {
    if (_ready && _settings.soundEnabled) {
      try { FlameAudio.play('biome_chime.wav'); } catch (e) { debugPrint('Audio play failed: $e'); }
    }
  }
}
