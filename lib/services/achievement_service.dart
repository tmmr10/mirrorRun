import 'package:flutter/foundation.dart';
import 'package:games_services/games_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AchievementService {
  static const _prefsKey = 'unlocked_achievements';

  bool _signedIn = false;
  final Set<String> _unlocked = {};

  void setSignedIn(bool value) => _signedIn = value;

  bool isUnlocked(String id) => _unlocked.contains(id);
  int get unlockedCount => _unlocked.length;

  /// Achievements unlocked during the current run (cleared on each check).
  final List<String> newlyUnlocked = [];

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_prefsKey);
    if (stored != null) {
      _unlocked.addAll(stored);
    }
  }

  Future<void> checkAfterRun({
    required int runDistance,
    required int totalGames,
    required int currentBiome,
  }) async {
    newlyUnlocked.clear();
    // Distance achievements
    const distanceThresholds = [75, 100, 300, 500, 750, 1000, 1400, 2000, 2500, 3000, 3200, 5000];
    for (final t in distanceThresholds) {
      if (runDistance >= t) {
        await _unlock('achievement_distance_$t');
      }
    }

    // Biome achievements
    const biomeMap = {
      2: 'crystal',
      3: 'volcano', // index 3 = volcano (350m)
      4: 'desert',
      5: 'ocean',
      9: 'neon',
      10: 'void',
    };
    for (final entry in biomeMap.entries) {
      if (currentBiome >= entry.key) {
        await _unlock('achievement_biome_${entry.value}');
      }
    }

    // Games played achievements
    const gamesThresholds = [10, 50, 100, 500];
    for (final t in gamesThresholds) {
      if (totalGames >= t) {
        await _unlock('achievement_games_$t');
      }
    }

    // First game
    if (totalGames >= 1) {
      await _unlock('achievement_first_game');
    }
  }

  Future<void> _unlock(String id) async {
    if (_unlocked.contains(id)) return;
    _unlocked.add(id);
    newlyUnlocked.add(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _unlocked.toList());
    if (!_signedIn) return;
    try {
      await Achievements.unlock(
        achievement: Achievement(
          androidID: id,
          iOSID: id,
        ),
      );
    } catch (e) {
      debugPrint('>>> Achievement unlock failed ($id): $e');
    }
  }
}
