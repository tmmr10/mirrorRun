import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The kind of goal a daily challenge asks for.
///
/// NOTE: new variants are appended at the end so the persisted `dc_type`
/// index of an in-progress challenge stays valid across updates.
enum DailyChallengeType {
  distance,
  coins,
  games,
  distanceTotal,
  coinsTotal,
  biome,
  cleanRun,
}

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
      case DailyChallengeType.distanceTotal:
        return 'Run ${target}m total today';
      case DailyChallengeType.coinsTotal:
        return 'Collect $target coins today';
      case DailyChallengeType.biome:
        return 'Reach world #${target + 1}';
      case DailyChallengeType.cleanRun:
        return 'Reach ${target}m without reviving';
    }
  }
}

/// Result of recording a run against the daily challenge / streak.
class DailyRunResult {
  final bool challengeJustCompleted;
  final int rewardEarned;
  final int streak;
  final bool streakAdvanced;
  /// Coins granted for advancing the daily play streak (0 if not advanced today).
  final int streakReward;

  const DailyRunResult({
    required this.challengeJustCompleted,
    required this.rewardEarned,
    required this.streak,
    required this.streakAdvanced,
    this.streakReward = 0,
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
  static const _kDistToday = 'dc_dist_today';
  static const _kCoinsToday = 'dc_coins_today';
  static const _kStreak = 'dc_streak';
  static const _kStreakDate = 'dc_streak_date';

  static const int reward = 100;
  /// Coins per streak day (×min(streak,7)) granted on the first run of a day.
  static const int streakRewardPerDay = 20;

  // Candidate targets per type — one is picked deterministically per day.
  static const List<int> _distanceTargets = [250, 400, 600, 800];
  static const List<int> _coinsTargets = [15, 25, 40];
  static const List<int> _gamesTargets = [3, 5];
  static const List<int> _distanceTotalTargets = [800, 1500, 2500];
  static const List<int> _coinsTotalTargets = [40, 70, 120];
  static const List<int> _biomeTargets = [2, 3, 4]; // CRYSTAL / VOLCANO / DESERT
  static const List<int> _cleanRunTargets = [250, 400];

  DailyChallengeType _type = DailyChallengeType.distance;
  int _target = 250;
  int _progress = 0;
  bool _completed = false;
  int _gamesToday = 0;
  // Cumulative per-day accumulators (for the *Total* challenge types).
  int _distToday = 0;
  int _coinsToday = 0;
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

  /// Candidate target list for a given challenge type.
  static List<int> _targetsFor(DailyChallengeType t) => switch (t) {
        DailyChallengeType.distance => _distanceTargets,
        DailyChallengeType.coins => _coinsTargets,
        DailyChallengeType.games => _gamesTargets,
        DailyChallengeType.distanceTotal => _distanceTotalTargets,
        DailyChallengeType.coinsTotal => _coinsTotalTargets,
        DailyChallengeType.biome => _biomeTargets,
        DailyChallengeType.cleanRun => _cleanRunTargets,
      };

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
      _distToday = _prefs.getInt(_kDistToday) ?? 0;
      _coinsToday = _prefs.getInt(_kCoinsToday) ?? 0;
    } else {
      // New day → deterministic roll from the date, but never repeat the type
      // the player last saw (variety guard; survives skipped days).
      final now = DateTime.now();
      final seed = now.year * 10000 + now.month * 100 + now.day;
      final rng = Random(seed);
      final prevIdx = _prefs.getInt(_kType);
      final DailyChallengeType? prevType = (prevIdx != null &&
              prevIdx >= 0 &&
              prevIdx < DailyChallengeType.values.length)
          ? DailyChallengeType.values[prevIdx]
          : null;

      var type = DailyChallengeType
          .values[rng.nextInt(DailyChallengeType.values.length)];
      if (prevType != null && type == prevType) {
        final pool = DailyChallengeType.values
            .where((e) => e != prevType)
            .toList();
        type = pool[rng.nextInt(pool.length)];
      }
      _type = type;
      final targets = _targetsFor(_type);
      _target = targets[rng.nextInt(targets.length)];
      _progress = 0;
      _completed = false;
      _gamesToday = 0;
      _distToday = 0;
      _coinsToday = 0;
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
    await _prefs.setInt(_kDistToday, _distToday);
    await _prefs.setInt(_kCoinsToday, _coinsToday);
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
  Future<bool> _advanceStreak() async {
    final todayKey = _todayKey();
    final lastDate = _prefs.getString(_kStreakDate);
    if (lastDate == todayKey) return false; // already counted today

    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final yKey = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-'
        '${yesterday.day.toString().padLeft(2, '0')}';

    _streak = (lastDate == yKey) ? _streak + 1 : 1;
    // Persist count + date together (awaited) so a kill can't desync them
    // (which would double-count or roll back the streak).
    await _prefs.setInt(_kStreak, _streak);
    await _prefs.setString(_kStreakDate, todayKey);
    return true;
  }

  /// Records a finished run; updates progress, completion and streak.
  Future<DailyRunResult> recordRun({
    required int distance,
    required int coinsThisRun,
    required int biomeIndexReached,
    required bool reviveUsed,
  }) async {
    _ensureToday();
    final streakAdvanced = await _advanceStreak();

    _gamesToday++;
    _distToday += distance;
    _coinsToday += coinsThisRun;
    final wasCompleted = _completed;

    // Cumulative types track running daily totals / counts; single-run types
    // track the best run of the day (a max).
    switch (_type) {
      case DailyChallengeType.games:
        _progress = _gamesToday;
      case DailyChallengeType.distanceTotal:
        _progress = _distToday;
      case DailyChallengeType.coinsTotal:
        _progress = _coinsToday;
      case DailyChallengeType.distance:
        if (distance > _progress) _progress = distance;
      case DailyChallengeType.coins:
        if (coinsThisRun > _progress) _progress = coinsThisRun;
      case DailyChallengeType.biome:
        if (biomeIndexReached > _progress) _progress = biomeIndexReached;
      case DailyChallengeType.cleanRun:
        // Only runs finished without a revive count toward this goal.
        if (!reviveUsed && distance > _progress) _progress = distance;
    }
    if (!_completed && _progress >= _target) {
      _completed = true;
    }
    final justCompleted = _completed && !wasCompleted;

    // Persist (incl. _completed) BEFORE the caller grants the reward, so a kill
    // can't replay the reward on next launch.
    await _persistChallenge(_todayKey());
    _publish();

    return DailyRunResult(
      challengeJustCompleted: justCompleted,
      rewardEarned: justCompleted ? reward : 0,
      streak: _streak,
      streakAdvanced: streakAdvanced,
      // Daily login-streak bonus (first run of a new day): scales up to day 7.
      streakReward: streakAdvanced ? (_streak.clamp(1, 7)) * streakRewardPerDay : 0,
    );
  }
}
