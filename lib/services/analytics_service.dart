import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static FirebaseAnalytics? _analytics;

  static FirebaseAnalytics? get _instance {
    if (_analytics != null) return _analytics;
    try {
      if (Firebase.apps.isNotEmpty) {
        _analytics = FirebaseAnalytics.instance;
      }
    } catch (_) {}
    return _analytics;
  }

  static Future<void> _log(String name, [Map<String, Object>? params]) async {
    try {
      await _instance?.logEvent(name: name, parameters: params);
    } catch (e) {
      debugPrint('Analytics event "$name" failed: $e');
    }
  }

  // --- User Properties ---

  static Future<void> setUserProperty(String name, String? value) async {
    try {
      await _instance?.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('Analytics user property "$name" failed: $e');
    }
  }

  static Future<void> setProUser(bool isPro) =>
      setUserProperty('pro_user', isPro ? 'true' : 'false');

  static Future<void> setTotalGames(int count) =>
      setUserProperty('total_games', count.toString());

  static Future<void> setFurthestBiome(String biome) =>
      setUserProperty('furthest_biome', biome);

  // --- Game Events ---

  static Future<void> logGameStarted({required String skinName}) =>
      _log('game_started', {'skin_name': skinName});

  static Future<void> logGameOver({
    required int score,
    required String biome,
    required int durationSeconds,
    required bool wasNewRecord,
  }) =>
      _log('game_over', {
        'score': score,
        'biome': biome,
        'duration_seconds': durationSeconds,
        'was_new_record': wasNewRecord ? 1 : 0,
      });

  static Future<void> logBiomeReached({required String biomeName, required int score}) =>
      _log('biome_reached', {
        'biome_name': biomeName,
        'score': score,
      });

  // --- Achievement Events ---

  static Future<void> logAchievementUnlocked({required String achievementId}) =>
      _log('achievement_unlocked', {'achievement_id': achievementId});

  static Future<void> logSkinUnlocked({required String skinName}) =>
      _log('skin_unlocked', {'skin_name': skinName});

  static Future<void> logSkinPurchased({required String skinName, required int cost}) =>
      _log('skin_purchased', {'skin_name': skinName, 'cost': cost});

  // --- Purchase Events ---

  static Future<void> logProPurchased() => _log('pro_purchased');

  static Future<void> logPurchasesRestored() => _log('purchases_restored');

  // --- Skin Events ---

  static Future<void> logSkinSelected({required String skinName, required bool isCustom}) =>
      _log('skin_selected', {
        'skin_name': skinName,
        'is_custom': isCustom ? 1 : 0,
      });

  static Future<void> logCustomSkinCreated() => _log('custom_skin_created');

  static Future<void> logCustomSkinDeleted() => _log('custom_skin_deleted');

  // --- Ad Events ---

  static Future<void> logAdShown() => _log('ad_shown');

  static Future<void> logAdFirstDeathSkipped() => _log('ad_first_death_skipped');

  // --- Share ---

  static Future<void> logShareTapped({required int score}) =>
      _log('share_tapped', {'score': score});

  // --- Game Events (special) ---

  static Future<void> logEventTriggered({required String eventType}) =>
      _log('game_event_triggered', {'event_type': eventType});

  // --- Coins & Revive ---

  static Future<void> logCoinCollected({required int total}) =>
      _log('coin_collected', {'total': total});

  static Future<void> logReviveOffered() => _log('revive_offered');

  static Future<void> logReviveUsedWithAd({required int score}) =>
      _log('revive_used_ad', {'score': score});

  static Future<void> logReviveUsedWithCoins({required int score, required int cost}) =>
      _log('revive_used_coins', {'score': score, 'cost': cost});

  static Future<void> logReviveUsedFreePro({required int score}) =>
      _log('revive_used_free_pro', {'score': score});

  static Future<void> logReviveDeclined({required int score}) =>
      _log('revive_declined', {'score': score});

  static Future<void> logRewardedAdFailed() => _log('rewarded_ad_failed');

  static Future<void> setTotalCoins(int count) =>
      setUserProperty('total_coins', count.toString());
}
