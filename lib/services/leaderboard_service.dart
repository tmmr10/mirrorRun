import 'package:flutter/foundation.dart';
import 'package:games_services/games_services.dart';

class LeaderboardService {
  static const String _leaderboardId = 'mirror_run_highscore';

  bool _signedIn = false;
  bool get isSignedIn => _signedIn;

  Future<void> init() async {
    try {
      await GameAuth.signIn();
      _signedIn = true;
      debugPrint('>>> GameServices signed in');
    } catch (e) {
      debugPrint('>>> GameServices sign-in failed: $e');
    }
  }

  Future<void> submitScore(int score) async {
    if (!_signedIn) {
      try {
        await GameAuth.signIn();
        _signedIn = true;
      } catch (_) {
        return;
      }
    }
    try {
      await Leaderboards.submitScore(
        score: Score(
          iOSLeaderboardID: _leaderboardId,
          androidLeaderboardID: _leaderboardId,
          value: score,
        ),
      );
    } catch (e) {
      debugPrint('>>> Submit score failed: $e');
    }
  }

  Future<void> showAchievements() async {
    if (!_signedIn) {
      try {
        await GameAuth.signIn();
        _signedIn = true;
      } catch (e) {
        debugPrint('>>> GameServices sign-in failed: $e');
        return;
      }
    }
    try {
      await Achievements.showAchievements();
    } catch (e) {
      debugPrint('>>> Show achievements failed: $e');
    }
  }

  Future<void> showLeaderboard() async {
    if (!_signedIn) {
      try {
        await GameAuth.signIn();
        _signedIn = true;
      } catch (e) {
        debugPrint('>>> GameServices sign-in failed: $e');
        return;
      }
    }
    try {
      await Leaderboards.showLeaderboards(
        iOSLeaderboardID: _leaderboardId,
        androidLeaderboardID: _leaderboardId,
      );
    } catch (e) {
      debugPrint('>>> Show leaderboard failed: $e');
    }
  }
}
