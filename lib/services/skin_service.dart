import 'package:shared_preferences/shared_preferences.dart';
import '../models/player_skin.dart';

class SkinService {
  late SharedPreferences _prefs;

  static const _keySelected = 'skin_selected';
  static const _keyUnlocked = 'skins_unlocked';

  SkinId _selectedId = SkinId.default_;
  final Set<SkinId> _unlockedIds = {SkinId.default_};

  PlayerSkin get currentSkin => PlayerSkin.getById(_selectedId);
  SkinId get selectedId => _selectedId;

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
  }

  Future<void> selectSkin(SkinId id) async {
    if (!_unlockedIds.contains(id)) return;
    _selectedId = id;
    await _prefs.setString(_keySelected, id.name);
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
