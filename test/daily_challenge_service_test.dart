import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mirror_run/services/daily_challenge_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  String todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  String dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  // recordRun persists via unawaited futures and re-reads prefs through
  // _ensureToday() on its next call. Flushing the microtask queue between
  // runs mirrors real runtime (where time passes between runs) and lets the
  // persisted games-counter / progress be read back correctly.
  Future<void> flush() => Future<void>.delayed(Duration.zero);

  /// Builds prefs that pin today's challenge to a specific type/target so the
  /// deterministic daily roll is bypassed (init loads the stored values when
  /// the stored date matches today).
  Map<String, Object> pinnedChallenge(
    DailyChallengeType type,
    int target, {
    int progress = 0,
    bool completed = false,
    int gamesToday = 0,
  }) {
    return {
      'dc_date': todayKey(),
      'dc_type': type.index,
      'dc_target': target,
      'dc_progress': progress,
      'dc_completed': completed,
      'dc_games_today': gamesToday,
    };
  }

  group('DailyChallengeService.init', () {
    test('rolls a valid challenge on a fresh install', () async {
      SharedPreferences.setMockInitialValues({});
      final service = DailyChallengeService();
      await service.init();

      final c = service.today;
      expect(DailyChallengeType.values, contains(c.type));
      expect(c.target, greaterThan(0));
      expect(c.progress, 0);
      expect(c.completed, isFalse);
      expect(c.reward, DailyChallengeService.reward);
      // challengeNotifier must hold the same published value.
      expect(service.challengeNotifier.value.target, c.target);
      expect(service.challengeNotifier.value.type, c.type);
    });

    test('rolls a target valid for the chosen type', () async {
      SharedPreferences.setMockInitialValues({});
      final service = DailyChallengeService();
      await service.init();

      const distance = [250, 400, 600, 800];
      const coins = [15, 25, 40];
      const games = [3, 5];

      final c = service.today;
      switch (c.type) {
        case DailyChallengeType.distance:
          expect(distance, contains(c.target));
        case DailyChallengeType.coins:
          expect(coins, contains(c.target));
        case DailyChallengeType.games:
          expect(games, contains(c.target));
      }
    });
  });

  group('DailyChallengeService determinism', () {
    test('two fresh instances roll the same challenge on the same day',
        () async {
      SharedPreferences.setMockInitialValues({});
      final a = DailyChallengeService();
      await a.init();

      // Fresh prefs again — forces a re-roll rather than reading stored values.
      SharedPreferences.setMockInitialValues({});
      final b = DailyChallengeService();
      await b.init();

      expect(b.today.type, a.today.type);
      expect(b.today.target, a.today.target);
    });
  });

  group('DailyChallengeService.recordRun progress', () {
    test('distance challenge tracks the best single run, not the sum',
        () async {
      SharedPreferences.setMockInitialValues(
          pinnedChallenge(DailyChallengeType.distance, 600));
      final service = DailyChallengeService();
      await service.init();

      await service.recordRun(distance: 300, coinsThisRun: 99);
      await flush();
      expect(service.today.progress, 300);

      // A worse run must not reduce progress.
      await service.recordRun(distance: 120, coinsThisRun: 99);
      await flush();
      expect(service.today.progress, 300);

      // A better run raises it.
      await service.recordRun(distance: 450, coinsThisRun: 99);
      await flush();
      expect(service.today.progress, 450);
    });

    test('coins challenge tracks the best single run', () async {
      SharedPreferences.setMockInitialValues(
          pinnedChallenge(DailyChallengeType.coins, 40));
      final service = DailyChallengeService();
      await service.init();

      await service.recordRun(distance: 9999, coinsThisRun: 10);
      await flush();
      expect(service.today.progress, 10);

      await service.recordRun(distance: 9999, coinsThisRun: 5);
      await flush();
      expect(service.today.progress, 10);

      await service.recordRun(distance: 9999, coinsThisRun: 30);
      await flush();
      expect(service.today.progress, 30);
    });

    test('games challenge is cumulative across runs', () async {
      SharedPreferences.setMockInitialValues(
          pinnedChallenge(DailyChallengeType.games, 5));
      final service = DailyChallengeService();
      await service.init();

      await service.recordRun(distance: 0, coinsThisRun: 0);
      await flush();
      expect(service.today.progress, 1);
      await service.recordRun(distance: 0, coinsThisRun: 0);
      await flush();
      expect(service.today.progress, 2);
      await service.recordRun(distance: 1000, coinsThisRun: 50);
      await flush();
      expect(service.today.progress, 3);
    });
  });

  group('DailyChallengeService completion', () {
    test('completes when progress reaches target, justCompleted only once',
        () async {
      SharedPreferences.setMockInitialValues(
          pinnedChallenge(DailyChallengeType.distance, 400));
      final service = DailyChallengeService();
      await service.init();

      final r1 = await service.recordRun(distance: 200, coinsThisRun: 0);
      await flush();
      expect(r1.challengeJustCompleted, isFalse);
      expect(r1.rewardEarned, 0);
      expect(service.today.completed, isFalse);

      // Crosses the target → completes exactly here.
      final r2 = await service.recordRun(distance: 450, coinsThisRun: 0);
      await flush();
      expect(service.today.completed, isTrue);
      expect(r2.challengeJustCompleted, isTrue);
      expect(r2.rewardEarned, DailyChallengeService.reward);

      // Further runs do not re-award the completion.
      final r3 = await service.recordRun(distance: 800, coinsThisRun: 0);
      await flush();
      expect(r3.challengeJustCompleted, isFalse);
      expect(r3.rewardEarned, 0);
      expect(service.today.completed, isTrue);
    });

    test('completes exactly when progress equals target', () async {
      SharedPreferences.setMockInitialValues(
          pinnedChallenge(DailyChallengeType.coins, 25));
      final service = DailyChallengeService();
      await service.init();

      final r = await service.recordRun(distance: 0, coinsThisRun: 25);
      await flush();
      expect(service.today.completed, isTrue);
      expect(r.challengeJustCompleted, isTrue);
      expect(r.rewardEarned, DailyChallengeService.reward);
    });

    test('published progress is clamped to the target', () async {
      SharedPreferences.setMockInitialValues(
          pinnedChallenge(DailyChallengeType.distance, 400));
      final service = DailyChallengeService();
      await service.init();

      await service.recordRun(distance: 1200, coinsThisRun: 0);
      await flush();
      expect(service.today.progress, 400);
      expect(service.today.fraction, 1.0);
    });
  });

  group('DailyChallengeService streak', () {
    test('first recorded run today starts the streak at >= 1', () async {
      SharedPreferences.setMockInitialValues(
          pinnedChallenge(DailyChallengeType.distance, 600));
      final service = DailyChallengeService();
      await service.init();

      final r = await service.recordRun(distance: 100, coinsThisRun: 0);
      expect(r.streakAdvanced, isTrue);
      expect(r.streak, greaterThanOrEqualTo(1));
      expect(service.streak, r.streak);
    });

    test('second run on the same day does not advance the streak again',
        () async {
      SharedPreferences.setMockInitialValues(
          pinnedChallenge(DailyChallengeType.distance, 600));
      final service = DailyChallengeService();
      await service.init();

      final first = await service.recordRun(distance: 100, coinsThisRun: 0);
      await flush();
      final second = await service.recordRun(distance: 200, coinsThisRun: 0);
      await flush();

      expect(second.streakAdvanced, isFalse);
      expect(second.streak, first.streak);
    });

    test('consecutive day continues the streak (+1)', () async {
      final yesterday =
          dateKey(DateTime.now().subtract(const Duration(days: 1)));
      final prefs = pinnedChallenge(DailyChallengeType.distance, 600)
        ..addAll({
          'dc_streak': 3,
          'dc_streak_date': yesterday,
        });
      SharedPreferences.setMockInitialValues(prefs);

      final service = DailyChallengeService();
      await service.init();
      expect(service.streak, 3);

      final r = await service.recordRun(distance: 100, coinsThisRun: 0);
      expect(r.streakAdvanced, isTrue);
      expect(r.streak, 4);
    });

    test('a gap of more than one day resets the streak to 1', () async {
      final longAgo =
          dateKey(DateTime.now().subtract(const Duration(days: 5)));
      final prefs = pinnedChallenge(DailyChallengeType.distance, 600)
        ..addAll({
          'dc_streak': 9,
          'dc_streak_date': longAgo,
        });
      SharedPreferences.setMockInitialValues(prefs);

      final service = DailyChallengeService();
      await service.init();
      expect(service.streak, 9);

      final r = await service.recordRun(distance: 100, coinsThisRun: 0);
      expect(r.streakAdvanced, isTrue);
      expect(r.streak, 1);
    });
  });

  group('DailyChallengeService persistence', () {
    test('progress and completion survive a fresh init on the same day',
        () async {
      SharedPreferences.setMockInitialValues(
          pinnedChallenge(DailyChallengeType.coins, 25));
      final service = DailyChallengeService();
      await service.init();
      await service.recordRun(distance: 0, coinsThisRun: 25);
      await flush();

      // recordRun persists via _persistChallenge (flushed above).
      final reloaded = DailyChallengeService();
      await reloaded.init();
      expect(reloaded.today.type, DailyChallengeType.coins);
      expect(reloaded.today.target, 25);
      expect(reloaded.today.completed, isTrue);
      expect(reloaded.today.progress, 25);
    });
  });
}
