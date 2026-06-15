import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mirror_run/services/stats_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StatsService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    service = StatsService();
    await service.init();
  });

  group('StatsService.init', () {
    test('all totals start at zero on a fresh install', () {
      expect(service.totalDistance, 0);
      expect(service.totalGamesPlayed, 0);
      expect(service.totalPlaytimeSeconds, 0);
      expect(service.furthestBiomeIndex, 0);
    });

    test('restores persisted stats', () async {
      SharedPreferences.setMockInitialValues({
        'stats_total_distance': 1234,
        'stats_total_games': 7,
        'stats_total_playtime': 456.5,
        'stats_furthest_biome': 3,
      });
      final restored = StatsService();
      await restored.init();
      expect(restored.totalDistance, 1234);
      expect(restored.totalGamesPlayed, 7);
      expect(restored.totalPlaytimeSeconds, 456.5);
      expect(restored.furthestBiomeIndex, 3);
    });
  });

  group('StatsService.recordRun', () {
    test('increments games count and accumulates distance and playtime',
        () async {
      await service.recordRun(distance: 100, biomeIndex: 0, durationSeconds: 12.5);
      await service.recordRun(distance: 250, biomeIndex: 1, durationSeconds: 30.0);

      expect(service.totalGamesPlayed, 2);
      expect(service.totalDistance, 350);
      expect(service.totalPlaytimeSeconds, 42.5);
    });

    test('furthestBiomeIndex grows monotonically and never regresses',
        () async {
      await service.recordRun(distance: 10, biomeIndex: 2, durationSeconds: 1.0);
      expect(service.furthestBiomeIndex, 2);

      // A lower biome must not pull the furthest index down.
      await service.recordRun(distance: 10, biomeIndex: 0, durationSeconds: 1.0);
      expect(service.furthestBiomeIndex, 2);

      // A higher biome advances it.
      await service.recordRun(distance: 10, biomeIndex: 5, durationSeconds: 1.0);
      expect(service.furthestBiomeIndex, 5);
    });

    test('persists accumulated stats across a fresh init', () async {
      await service.recordRun(distance: 500, biomeIndex: 4, durationSeconds: 60.0);
      await service.recordRun(distance: 300, biomeIndex: 1, durationSeconds: 20.0);

      final reloaded = StatsService();
      await reloaded.init();
      expect(reloaded.totalDistance, 800);
      expect(reloaded.totalGamesPlayed, 2);
      expect(reloaded.totalPlaytimeSeconds, 80.0);
      expect(reloaded.furthestBiomeIndex, 4);
    });
  });
}
