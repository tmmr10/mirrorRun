import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_skin.dart';
import 'analytics_service.dart';
import 'coins_service.dart';

class SkinService {
  late SharedPreferences _prefs;

  static const _keySelected = 'skin_selected';
  static const _keyUnlocked = 'skins_unlocked';
  static const _keyCustomSkins = 'custom_skins';
  static const _keyCustomSelected = 'custom_skin_selected';
  static const _keyCustomUnlocked = 'custom_skin_unlocked';
  static const int maxCustomSkins = 5;

  SkinId _selectedId = SkinId.default_;
  final Set<SkinId> _unlockedIds = {SkinId.default_};

  List<CustomSkinData> _customSkins = [];
  int _selectedCustomIndex = -1;
  bool _customSkinUnlocked = false;

  PlayerSkin get currentSkin {
    if (_selectedCustomIndex >= 0 && _selectedCustomIndex < _customSkins.length) {
      return _customSkins[_selectedCustomIndex].toPlayerSkin(_selectedCustomIndex);
    }
    return PlayerSkin.getById(_selectedId);
  }

  SkinId get selectedId => _selectedId;
  int get selectedCustomIndex => _selectedCustomIndex;
  bool get isCustomSelected => _selectedCustomIndex >= 0;
  List<CustomSkinData> get customSkins => List.unmodifiable(_customSkins);
  bool get customSkinUnlocked => _customSkinUnlocked;

  bool isUnlocked(SkinId id) => _unlockedIds.contains(id);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    final selectedName = _prefs.getString(_keySelected);
    if (selectedName != null) {
      _selectedId = SkinId.values.firstWhere(
        (s) => s.name == selectedName,
        orElse: () => SkinId.default_,
      );
    }

    final unlockedNames = _prefs.getStringList(_keyUnlocked);
    if (unlockedNames != null) {
      for (final name in unlockedNames) {
        final id = SkinId.values.firstWhere(
          (s) => s.name == name,
          orElse: () => SkinId.default_,
        );
        _unlockedIds.add(id);
      }
    }
    _unlockedIds.add(SkinId.default_);

    // Custom skins
    _customSkinUnlocked = _prefs.getBool(_keyCustomUnlocked) ?? false;
    final customJson = _prefs.getString(_keyCustomSkins);
    if (customJson != null) {
      try {
        _customSkins = CustomSkinData.decodeList(customJson);
      } catch (e) {
        debugPrint('>>> Failed to load custom skins: $e');
        _customSkins = [];
      }
    }
    _selectedCustomIndex = _prefs.getInt(_keyCustomSelected) ?? -1;
    if (_selectedCustomIndex >= _customSkins.length) {
      _selectedCustomIndex = -1;
    }
  }

  Future<void> selectSkin(SkinId id) async {
    if (!isUnlocked(id)) return;
    _selectedId = id;
    _selectedCustomIndex = -1;
    await _prefs.setString(_keySelected, id.name);
    await _prefs.setInt(_keyCustomSelected, -1);
    unawaited(AnalyticsService.logSkinSelected(skinName: id.name, isCustom: false));
  }

  Future<void> selectCustomSkin(int index) async {
    if (index < 0 || index >= _customSkins.length) return;
    _selectedCustomIndex = index;
    await _prefs.setInt(_keyCustomSelected, index);
    unawaited(AnalyticsService.logSkinSelected(
      skinName: _customSkins[index].name,
      isCustom: true,
    ));
  }

  Future<bool> saveCustomSkin(CustomSkinData skin) async {
    if (_customSkins.length >= maxCustomSkins) return false;
    _customSkins.add(skin);
    await _persistCustomSkins();
    unawaited(AnalyticsService.logCustomSkinCreated());
    return true;
  }

  Future<void> updateCustomSkin(int index, CustomSkinData skin) async {
    if (index < 0 || index >= _customSkins.length) return;
    _customSkins[index] = skin;
    await _persistCustomSkins();
  }

  Future<void> deleteCustomSkin(int index) async {
    if (index < 0 || index >= _customSkins.length) return;
    _customSkins.removeAt(index);
    unawaited(AnalyticsService.logCustomSkinDeleted());
    // Adjust selected index
    if (_selectedCustomIndex == index) {
      _selectedCustomIndex = -1;
      await _prefs.setInt(_keyCustomSelected, -1);
    } else if (_selectedCustomIndex > index) {
      _selectedCustomIndex--;
      await _prefs.setInt(_keyCustomSelected, _selectedCustomIndex);
    }
    await _persistCustomSkins();
  }

  Future<void> setCustomSkinUnlocked(bool value) async {
    _customSkinUnlocked = value;
    await _prefs.setBool(_keyCustomUnlocked, value);
  }

  Future<void> _persistCustomSkins() async {
    await _prefs.setString(_keyCustomSkins, CustomSkinData.encodeList(_customSkins));
  }

  Future<void> debugUnlockSkin(SkinId id) async {
    _unlockedIds.add(id);
    await _prefs.setStringList(
      _keyUnlocked,
      _unlockedIds.map((id) => id.name).toList(),
    );
  }

  Future<void> debugLockSkin(SkinId id) async {
    if (id == SkinId.default_) return;
    _unlockedIds.remove(id);
    if (_selectedId == id) {
      _selectedId = SkinId.default_;
      await _prefs.setString(_keySelected, SkinId.default_.name);
    }
    await _prefs.setStringList(
      _keyUnlocked,
      _unlockedIds.map((id) => id.name).toList(),
    );
  }

  /// Returns list of newly unlocked skin IDs.
  Future<List<SkinId>> checkUnlocks(int furthestBiomeIndex) async {
    final newUnlocks = <SkinId>[];
    for (final skin in PlayerSkin.all) {
      if (skin.unlockBiomeIndex == null) continue;
      if (furthestBiomeIndex >= skin.unlockBiomeIndex! &&
          !_unlockedIds.contains(skin.id)) {
        _unlockedIds.add(skin.id);
        newUnlocks.add(skin.id);
      }
    }
    if (newUnlocks.isNotEmpty) {
      await _prefs.setStringList(
        _keyUnlocked,
        _unlockedIds.map((id) => id.name).toList(),
      );
    }
    return newUnlocks;
  }

  /// Purchases a skin using coins. Returns true on success.
  /// If persistence fails after coin deduction, coins are refunded.
  Future<bool> purchaseSkin(SkinId id, int cost, CoinsService coinsService) async {
    if (_unlockedIds.contains(id)) return true;
    final deducted = await coinsService.spendCoins(cost);
    if (!deducted) return false;
    // Defensive: a concurrent purchase may have unlocked it during the await.
    // Don't charge twice — refund this deduction.
    if (_unlockedIds.contains(id)) {
      await coinsService.addCoins(cost);
      return true;
    }
    _unlockedIds.add(id);
    try {
      await _prefs.setStringList(
        _keyUnlocked,
        _unlockedIds.map((skinId) => skinId.name).toList(),
      );
    } catch (e) {
      // Rollback: remove from in-memory set and refund coins
      _unlockedIds.remove(id);
      await coinsService.addCoins(cost);
      debugPrint('>>> purchaseSkin failed, refunded: $e');
      return false;
    }
    unawaited(AnalyticsService.logSkinPurchased(skinName: id.name, cost: cost));
    return true;
  }

  /// Unlocks all preset skins (for Pro users). Idempotent.
  Future<void> unlockAllPresets() async {
    bool anyNew = false;
    for (final skin in PlayerSkin.all) {
      if (!_unlockedIds.contains(skin.id)) {
        _unlockedIds.add(skin.id);
        anyNew = true;
      }
    }
    if (anyNew) {
      await _prefs.setStringList(
        _keyUnlocked,
        _unlockedIds.map((id) => id.name).toList(),
      );
    }
  }
}
