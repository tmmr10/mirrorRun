import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_skin.dart';

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
    if (!isUnlocked(id)) return; // Bugfix: was !_unlockedIds.contains(id)
    _selectedId = id;
    _selectedCustomIndex = -1;
    await _prefs.setString(_keySelected, id.name);
    await _prefs.setInt(_keyCustomSelected, -1);
  }

  Future<void> selectCustomSkin(int index) async {
    if (index < 0 || index >= _customSkins.length) return;
    _selectedCustomIndex = index;
    await _prefs.setInt(_keyCustomSelected, index);
  }

  Future<bool> saveCustomSkin(CustomSkinData skin) async {
    if (_customSkins.length >= maxCustomSkins) return false;
    _customSkins.add(skin);
    await _persistCustomSkins();
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
}
