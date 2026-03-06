import 'package:shared_preferences/shared_preferences.dart';

class StatsService {
  late SharedPreferences _prefs;

  static const _keyTotalDistance = 'stats_total_distance';
  static const _keyTotalGames = 'stats_total_games';
  static const _keyTotalPlaytime = 'stats_total_playtime';
  static const _keyFurthestBiome = 'stats_furthest_biome';

  int _totalDistance = 0;
  int _totalGames = 0;
  double _totalPlaytime = 0;
  int _furthestBiomeIndex = 0;

  int get totalDistance => _totalDistance;
  int get totalGamesPlayed => _totalGames;
  double get totalPlaytimeSeconds => _totalPlaytime;
  int get furthestBiomeIndex => _furthestBiomeIndex;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _totalDistance = _prefs.getInt(_keyTotalDistance) ?? 0;
    _totalGames = _prefs.getInt(_keyTotalGames) ?? 0;
    _totalPlaytime = _prefs.getDouble(_keyTotalPlaytime) ?? 0;
    _furthestBiomeIndex = _prefs.getInt(_keyFurthestBiome) ?? 0;
  }

  Future<void> recordRun({
    required int distance,
    required int biomeIndex,
    required double durationSeconds,
  }) async {
    _totalDistance += distance;
    _totalGames++;
    _totalPlaytime += durationSeconds;
    if (biomeIndex > _furthestBiomeIndex) {
      _furthestBiomeIndex = biomeIndex;
    }

    await Future.wait([
      _prefs.setInt(_keyTotalDistance, _totalDistance),
      _prefs.setInt(_keyTotalGames, _totalGames),
      _prefs.setDouble(_keyTotalPlaytime, _totalPlaytime),
      _prefs.setInt(_keyFurthestBiome, _furthestBiomeIndex),
    ]);
  }
}
