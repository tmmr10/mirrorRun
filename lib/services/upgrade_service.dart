import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'coins_service.dart';

/// Permanent, coin-bought upgrades — the long-term coin sink. Each perk has
/// one or more levels with rising costs; bought levels persist forever.
enum Perk { startShield, coinMagnet, powerUpDuration, startCombo, coinBonus }

class PerkDef {
  final Perk perk;
  final String title;
  final String effect; // short effect description, level-agnostic
  final List<int> costs; // one entry per level

  const PerkDef(this.perk, this.title, this.effect, this.costs);

  int get maxLevel => costs.length;
}

class UpgradeService {
  late SharedPreferences _prefs;

  static const List<PerkDef> perks = [
    PerkDef(Perk.coinMagnet, 'COIN MAGNET',
        'Wider coin pickup range', [150, 400, 900]),
    PerkDef(Perk.coinBonus, 'COIN BONUS',
        '+1 coin per pickup', [250, 600, 1200]),
    PerkDef(Perk.powerUpDuration, 'POWER-UP TIME',
        'Power-ups last longer', [300, 700, 1400]),
    PerkDef(Perk.startCombo, 'HEAD START',
        'Begin mid-combo (x1.2 / x1.5 / x2.0)', [250, 600, 1200]),
    PerkDef(Perk.startShield, 'SHIELD',
        'Start shielded; recharges every 400m', [1200]),
  ];

  final Map<Perk, int> _levels = {for (final p in Perk.values) p: 0};

  /// Bumped whenever a level changes, so the UI can rebuild.
  final ValueNotifier<int> revision = ValueNotifier(0);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    for (final p in Perk.values) {
      _levels[p] = _prefs.getInt(_key(p)) ?? 0;
    }
  }

  String _key(Perk p) => 'perk_${p.name}';

  PerkDef def(Perk p) => perks.firstWhere((d) => d.perk == p);

  int level(Perk p) => _levels[p] ?? 0;
  bool isMaxed(Perk p) => level(p) >= def(p).maxLevel;

  /// Coin cost of the next level, or null if maxed.
  int? nextCost(Perk p) {
    final d = def(p);
    final lvl = level(p);
    if (lvl >= d.maxLevel) return null;
    return d.costs[lvl];
  }

  /// Attempts to buy the next level of [p] by spending coins.
  Future<bool> tryPurchase(Perk p, CoinsService coins) async {
    final cost = nextCost(p);
    if (cost == null) return false;
    if (coins.totalCoins < cost) return false;
    final ok = await coins.spendCoins(cost);
    if (!ok) return false;
    // Defensive: a concurrent purchase may have maxed the perk during the
    // await. Don't exceed maxLevel — refund the spent coins instead.
    if (level(p) >= def(p).maxLevel) {
      await coins.addCoins(cost);
      return false;
    }
    _levels[p] = level(p) + 1;
    await _prefs.setInt(_key(p), _levels[p]!);
    revision.value++;
    return true;
  }

  // ── Effect accessors (read by the game) ──

  /// Start each run with a shield already active.
  bool get startShield => level(Perk.startShield) > 0;

  /// Extra coin-pickup range in logical px.
  double get coinMagnetPadding => level(Perk.coinMagnet) * 12.0;

  /// Multiplier on power-up durations (1.0 = base): +25% per level.
  double get powerUpDurationMult => 1.0 + 0.25 * level(Perk.powerUpDuration);

  /// Head-start near-misses by level (0=none): 1→3 (x1.2), 2→6 (x1.5), 3→10 (x2.0).
  int get startComboNearMisses {
    switch (level(Perk.startCombo)) {
      case 1:
        return 3;
      case 2:
        return 6;
      case 3:
        return 10;
      default:
        return 0;
    }
  }

  /// Extra coins added to every pickup.
  int get coinBonusPerPickup => level(Perk.coinBonus);
}
