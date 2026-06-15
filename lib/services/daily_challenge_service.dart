import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The kind of goal a daily challenge asks for.
enum DailyChallengeType { distance, coins, games }

/// Immutable snapshot of today's challenge, for the UI to render.
class DailyChallenge {
  final DailyChallengeType type;
  final int target;
  final int progress;
  final bool completed;
  final int reward;

  const DailyChallenge({
    required this.type,
    required this.target,
    required this.progress,
    required this.completed,
    required this.reward,
  });

  double get fraction => target <= 0 ? 0 : (progress / target).clamp(0.0, 1.0);

  String get label {
    switch (type) {
      case DailyChallengeType.distance:
        return 'Reach ${target}m in one run';
      case DailyChallengeType.coins:
        return 'Collect $target coins in one run';
      case DailyChallengeType.games:
        return 'Play $target runs today';
    }
  }
}

/// Result of recording a run against the daily challenge / streak.
class DailyRunResult {
  final bool challengeJustCompleted;
  final int rewardEarned;
  final int streak;
  final bool streakAdvanced;

  const DailyRunResult({
    required this.challengeJustCompleted,
    required this.rewardEarned,
    required this.streak,
    required this.streakAdvanced,
  });
}

/// Daily challenge + login/play streak. The challenge is deterministic per
/// local calendar day (seeded by the date) so it stays stable until midnight.
class DailyChallengeService {
  late SharedPreferences _prefs;

  static const _kDate = 'dc_date';
  static const _kType = 'dc_type';
  static const _kTarget = 'dc_target';
  static const _kProgress = 'dc_progress';
  static const _kCompleted = 'dc_completed';
  static const _kGamesToday = 'dc_games_today';
  static const _kStreak = 'dc_streak';
  static const _kStreakDate = 'dc_streak_date';

  static const int reward = 100;

  // Candidate targets per type — one is picked deterministically per day.
  static const List<int> _distanceTargets = [250, 400, 600, 800];
  static const List<int> _coinsTargets = [15, 25, 40];
  static const List<int> _gamesTargets = [3, 5];

  DailyChallengeType _type = DailyChallengeType.distance;
  int _target = 250;
  int _progress = 0;
  bool _completed = false;
  int _gamesToday = 0;
  int _streak = 0;

  final ValueNotifier<DailyChallenge> challengeNotifier =
      ValueNotifier(const DailyChallenge(
    type: DailyChallengeType.distance,
    target: 250,
    progress: 0,
    completed: false,
    reward: reward,
  ));

  int get streak => _streak;
  DailyChallenge get today => challengeNotifier.value;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _streak = _prefs.getInt(_kStreak) ?? 0;
    _ensureToday();
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  /// Rolls a fresh challenge if the stored one is from a previous day.
  void _ensureToday() {
    final todayKey = _todayKey();
    final storedDate = _prefs.getString(_kDate);

    if (storedDate == todayKey) {
      _type = DailyChallengeType.values[
          (_prefs.getInt(_kType) ?? 0).clamp(0, DailyChallengeType.values.length - 1)];
      _target = _prefs.getInt(_kTarget) ?? 250;
      _progress = _prefs.getInt(_kProgress) ?? 0;
      _completed = _prefs.getBool(_kCompleted) ?? false;
      _gamesToday = _prefs.getInt(_kGamesToday) ?? 0;
    } else {
      // New day → deterministic roll from the date.
      final now = DateTime.now();
      final seed = now.year * 10000 + now.month * 100 + now.day;
      final rng = Random(seed);
      _type = DailyChallengeType.values[rng.nextInt(DailyChallengeType.values.length)];
      _target = switch (_type) {
        DailyChallengeType.distance =>
          _distanceTargets[rng.nextInt(_distanceTargets.length)],
        DailyChallengeType.coins =>
          _coinsTargets[rng.nextInt(_coinsTargets.length)],
        DailyChallengeType.games =>
          _gamesTargets[rng.nextInt(_gamesTargets.length)],
      };
      _progress = 0;
      _completed = false;
      _gamesToday = 0;
      unawaited(_persistChallenge(todayKey));
    }
    _publish();
  }

  Future<void> _persistChallenge(String dateKey) async {
    await _prefs.setString(_kDate, dateKey);
    await _prefs.setInt(_kType, _type.index);
    await _prefs.setInt(_kTarget, _target);
    await _prefs.setInt(_kProgress, _progress);
    await _prefs.setBool(_kCompleted, _completed);
    await _prefs.setInt(_kGamesToday, _gamesToday);
  }

  void _publish() {
    challengeNotifier.value = DailyChallenge(
      type: _type,
      target: _target,
      progress: _progress.clamp(0, _target),
      completed: _completed,
      reward: reward,
    );
  }

  /// Updates the streak based on play activity for the current day.
  bool _advanceStreak() {
    final todayKey = _todayKey();
    final lastDate = _prefs.getString(_kStreakDate);
    if (lastDate == todayKey) return false; // already counted today

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final yKey = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-'
        '${yesterday.day.toString().padLeft(2, '0')}';

    _streak = (lastDate == yKey) ? _streak + 1 : 1;
    unawaited(_prefs.setInt(_kStreak, _streak));
    unawaited(_prefs.setString(_kStreakDate, todayKey));
    return true;
  }

  /// Records a finished run; updates progress, completion and streak.
  DailyRunResult recordRun({required int distance, required int coinsThisRun}) {
    _ensureToday();
    final streakAdvanced = _advanceStreak();

    _gamesToday++;
    final wasCompleted = _completed;

    final runValue = switch (_type) {
      DailyChallengeType.distance => distance,
      DailyChallengeType.coins => coinsThisRun,
      DailyChallengeType.games => _gamesToday,
    };
    // distance/coins track the best single run; games is cumulative.
    if (_type == DailyChallengeType.games) {
      _progress = _gamesToday;
    } else if (runValue > _progress) {
      _progress = runValue;
    }
    if (!_completed && _progress >= _target) {
      _completed = true;
    }
    final justCompleted = _completed && !wasCompleted;

    unawaited(_persistChallenge(_todayKey()));
    _publish();

    return DailyRunResult(
      challengeJustCompleted: justCompleted,
      rewardEarned: justCompleted ? reward : 0,
      streak: _streak,
      streakAdvanced: streakAdvanced,
    );
  }
}
