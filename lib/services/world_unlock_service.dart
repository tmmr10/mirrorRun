import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'coins_service.dart';
import '../game/world/biome.dart';

/// Tracks which worlds (biomes) the player has access to.
///
/// A biome is unlocked when it has been reached naturally during a run, when it
/// was bought early with coins, or when it is the very first biome (FOREST,
/// index 0), which is always free. Reached/purchased state is persisted via
/// [SharedPreferences].
class WorldUnlockService {
  late SharedPreferences _prefs;

  static const _keyMaxReached = 'world_max_reached';
  static const _keyPurchased = 'world_purchased';

  /// Coin cost per biome index when buying early (Forest is always free).
  static const int _costPerIndex = 250;

  /// Highest biome index ever reached naturally during a run.
  int _maxReachedIndex = 0;

  /// Biome indices the player bought early with coins.
  final Set<int> _purchased = {};

  /// Bumped whenever unlock state changes, so the UI can rebuild.
  final ValueNotifier<int> revision = ValueNotifier(0);

  /// Loads the persisted unlock state.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _maxReachedIndex = _prefs.getInt(_keyMaxReached) ?? 0;
    _purchased
      ..clear()
      ..addAll(
        (_prefs.getStringList(_keyPurchased) ?? const [])
            .map(int.tryParse)
            .whereType<int>(),
      );
  }

  /// Highest biome index reached naturally during a run.
  int get maxReachedIndex => _maxReachedIndex;

  /// Whether [biomeIndex] is currently playable.
  bool isUnlocked(int biomeIndex) =>
      biomeIndex == 0 ||
      biomeIndex <= _maxReachedIndex ||
      _purchased.contains(biomeIndex);

  /// Coin cost to unlock [biomeIndex] early, or null if it is already unlocked
  /// or the index is invalid. The cost ladder rises with the index and does not
  /// depend on how far the player has reached: index 1 = 250, index 2 = 500, …
  int? unlockCost(int biomeIndex) {
    if (biomeIndex < 0 || biomeIndex >= BiomeManager.biomes.length) return null;
    if (isUnlocked(biomeIndex)) return null;
    return _costPerIndex * biomeIndex;
  }

  /// Attempts to unlock [biomeIndex] early by spending coins.
  ///
  /// Returns false if the biome is already unlocked, if the index is invalid,
  /// or if the player cannot afford the cost.
  Future<bool> tryUnlock(int biomeIndex, CoinsService coins) async {
    final cost = unlockCost(biomeIndex);
    if (cost == null) return false;
    if (coins.totalCoins < cost) return false;
    final ok = await coins.spendCoins(cost);
    if (!ok) return false;
    // Defensive: a concurrent purchase may have unlocked this biome during the
    // await. Don't double-charge — refund the spent coins instead.
    if (_purchased.contains(biomeIndex)) {
      await coins.addCoins(cost);
      return false;
    }
    _purchased.add(biomeIndex);
    await _prefs.setStringList(
      _keyPurchased,
      _purchased.map((i) => i.toString()).toList(),
    );
    revision.value++;
    return true;
  }

  /// Records that the player reached [biomeIndex] naturally during a run.
  /// Call this after a run completes.
  Future<void> registerReached(int biomeIndex) async {
    if (biomeIndex <= _maxReachedIndex) return;
    _maxReachedIndex = biomeIndex;
    await _prefs.setInt(_keyMaxReached, _maxReachedIndex);
    revision.value++;
  }
}
