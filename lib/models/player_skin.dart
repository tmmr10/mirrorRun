import 'dart:ui';

enum SkinId { default_, ice, fire, gold, ocean, neon, void_ }

enum SkinDecoration { none, iceCrown, flames, crown, goggles, antenna, halo }

class PlayerSkin {
  final SkinId id;
  final String name;
  final Color leftColor;
  final Color rightColor;
  final Color leftGlow;
  final Color rightGlow;
  final int? unlockBiomeIndex;
  final String unlockDescription;
  final SkinDecoration decoration;

  const PlayerSkin({
    required this.id,
    required this.name,
    required this.leftColor,
    required this.rightColor,
    required this.leftGlow,
    required this.rightGlow,
    this.unlockBiomeIndex,
    required this.unlockDescription,
    this.decoration = SkinDecoration.none,
  });

  static const List<PlayerSkin> all = [
    PlayerSkin(
      id: SkinId.default_,
      name: 'DEFAULT',
      leftColor: Color(0xFFff6b35),
      rightColor: Color(0xFF9966ff),
      leftGlow: Color(0xFFff6b35),
      rightGlow: Color(0xFF9966ff),
      unlockBiomeIndex: null,
      unlockDescription: 'Always unlocked',
    ),
    PlayerSkin(
      id: SkinId.ice,
      name: 'ICE',
      leftColor: Color(0xFF00DDFF),
      rightColor: Color(0xFF3366FF),
      leftGlow: Color(0xFF00DDFF),
      rightGlow: Color(0xFF3366FF),
      unlockBiomeIndex: 2,
      unlockDescription: 'Reach Crystal biome',
      decoration: SkinDecoration.iceCrown,
    ),
    PlayerSkin(
      id: SkinId.fire,
      name: 'FIRE',
      leftColor: Color(0xFFFF3300),
      rightColor: Color(0xFFFFCC00),
      leftGlow: Color(0xFFFF3300),
      rightGlow: Color(0xFFFFCC00),
      unlockBiomeIndex: 4,
      unlockDescription: 'Reach Desert biome',
      decoration: SkinDecoration.flames,
    ),
    PlayerSkin(
      id: SkinId.gold,
      name: 'GOLD',
      leftColor: Color(0xFFFFD700),
      rightColor: Color(0xFFFFAA00),
      leftGlow: Color(0xFFFFD700),
      rightGlow: Color(0xFFFFAA00),
      unlockBiomeIndex: 5,
      unlockDescription: 'Reach Ocean biome',
      decoration: SkinDecoration.crown,
    ),
    PlayerSkin(
      id: SkinId.ocean,
      name: 'OCEAN',
      leftColor: Color(0xFF00CCAA),
      rightColor: Color(0xFF0044AA),
      leftGlow: Color(0xFF00CCAA),
      rightGlow: Color(0xFF0044AA),
      unlockBiomeIndex: 6,
      unlockDescription: 'Reach Ruins biome',
      decoration: SkinDecoration.goggles,
    ),
    PlayerSkin(
      id: SkinId.neon,
      name: 'NEON',
      leftColor: Color(0xFFFF00AA),
      rightColor: Color(0xFF00FF66),
      leftGlow: Color(0xFFFF00AA),
      rightGlow: Color(0xFF00FF66),
      unlockBiomeIndex: 7,
      unlockDescription: 'Reach Space biome',
      decoration: SkinDecoration.antenna,
    ),
    PlayerSkin(
      id: SkinId.void_,
      name: 'VOID',
      leftColor: Color(0xFFFFFFFF),
      rightColor: Color(0xFF888888),
      leftGlow: Color(0xFFFFFFFF),
      rightGlow: Color(0xFF888888),
      unlockBiomeIndex: 10,
      unlockDescription: 'Reach Void biome',
      decoration: SkinDecoration.halo,
    ),
  ];

  static PlayerSkin getById(SkinId id) => all.firstWhere((s) => s.id == id);
}
