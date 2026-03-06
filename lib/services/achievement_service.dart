import 'package:flutter/foundation.dart';
import 'package:games_services/games_services.dart';

class AchievementService {
  bool _signedIn = false;
  final Set<String> _unlocked = {};

  void setSignedIn(bool value) => _signedIn = value;

  Future<void> checkAfterRun({
    required int runDistance,
    required int totalGames,
    required int currentBiome,
  }) async {
    if (!_signedIn) return;

    // Distance achievements
    const distanceThresholds = [100, 500, 1000, 2000, 3000, 5000];
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
