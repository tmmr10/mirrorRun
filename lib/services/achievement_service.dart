import 'package:flutter/foundation.dart';
import 'package:games_services/games_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AchievementService {
  static const _prefsKey = 'unlocked_achievements';

  bool _signedIn = false;
  late SharedPreferences _prefs;
  final Set<String> _unlocked = {};

  void setSignedIn(bool value) => _signedIn = value;

  bool isUnlocked(String id) => _unlocked.contains(id);
  int get unlockedCount => _unlocked.length;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final stored = _prefs.getStringList(_prefsKey);
    if (stored != null) {
      _unlocked.addAll(stored);
    }
  }

  /// Returns list of newly unlocked achievement IDs during this run.
  Future<List<String>> checkAfterRun({
    required int runDistance,
    required int totalGames,
    required int currentBiome,
  }) async {
    final newlyUnlocked = <String>[];

    // Distance achievements
    const distanceThresholds = [75, 100, 300, 500, 750, 1000, 1400, 2000, 2500, 3000, 3200, 5000];
    for (final t in distanceThresholds) {
      if (runDistance >= t) {
        if (await _unlock('achievement_distance_$t')) {
          newlyUnlocked.add('achievement_distance_$t');
        }
      }
    }

    // Biome achievements
    const biomeMap = {
      2: 'crystal',
      3: 'volcano',
      4: 'desert',
      5: 'ocean',
      9: 'neon',
      10: 'void',
    };
    for (final entry in biomeMap.entries) {
      if (currentBiome >= entry.key) {
        if (await _unlock('achievement_biome_${entry.value}')) {
          newlyUnlocked.add('achievement_biome_${entry.value}');
        }
      }
    }

    // Games played achievements
    const gamesThresholds = [10, 50, 100, 500];
    for (final t in gamesThresholds) {
      if (totalGames >= t) {
        if (await _unlock('achievement_games_$t')) {
          newlyUnlocked.add('achievement_games_$t');
        }
      }
    }

    // First game
    if (totalGames >= 1) {
      if (await _unlock('achievement_first_game')) {
        newlyUnlocked.add('achievement_first_game');
      }
    }

    // Batch-persist all new unlocks at once
    if (newlyUnlocked.isNotEmpty) {
      await _prefs.setStringList(_prefsKey, _unlocked.toList());
    }

    return newlyUnlocked;
  }

  /// Returns true if the achievement was newly unlocked.
  Future<bool> _unlock(String id) async {
    if (_unlocked.contains(id)) return false;
    _unlocked.add(id);
    if (!_signedIn) return true;
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
    return true;
  }
}
