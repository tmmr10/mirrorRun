import 'dart:convert';
import 'package:flutter/painting.dart';

enum SkinId { default_, ice, fire, gold, ocean, neon, void_ }

enum HeadDecoration { none, iceCrown, flames, crown, antenna, halo, horns, wings, mohawk, star }

enum FaceDecoration { none, goggles, visor, mask, monocle, scar, shades }

class PlayerSkin {
  final SkinId id;
  final String name;
  final Color leftColor;
  final Color rightColor;
  final Color leftGlow;
  final Color rightGlow;
  final int? unlockBiomeIndex;
  final String unlockDescription;
  final HeadDecoration headDecoration;
  final FaceDecoration faceDecoration;
  final int? coinPrice; // null = not purchasable, otherwise coins required

  const PlayerSkin({
    required this.id,
    required this.name,
    required this.leftColor,
    required this.rightColor,
    required this.leftGlow,
    required this.rightGlow,
    this.unlockBiomeIndex,
    required this.unlockDescription,
    this.headDecoration = HeadDecoration.none,
    this.faceDecoration = FaceDecoration.none,
    this.coinPrice,
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
      headDecoration: HeadDecoration.iceCrown,
      coinPrice: 300,
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
      headDecoration: HeadDecoration.flames,
      coinPrice: 750,
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
      headDecoration: HeadDecoration.crown,
      coinPrice: 1500,
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
      faceDecoration: FaceDecoration.goggles,
      coinPrice: 3000,
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
      headDecoration: HeadDecoration.antenna,
      coinPrice: 6000,
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
      headDecoration: HeadDecoration.halo,
      coinPrice: 12000,
    ),
  ];

  static PlayerSkin getById(SkinId id) => all.firstWhere((s) => s.id == id);
}

class CustomSkinData {
  final String name;
  final int leftColorValue;
  final int rightColorValue;
  final HeadDecoration headDecoration;
  final FaceDecoration faceDecoration;

  const CustomSkinData({
    required this.name,
    required this.leftColorValue,
    required this.rightColorValue,
    this.headDecoration = HeadDecoration.none,
    this.faceDecoration = FaceDecoration.none,
  });

  Color get leftColor => Color(leftColorValue);
  Color get rightColor => Color(rightColorValue);

  Color get leftGlow => _brighten(leftColor);
  Color get rightGlow => _brighten(rightColor);

  static Color _brighten(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl
        .withSaturation((hsl.saturation * 0.6).clamp(0.0, 1.0))
        .withLightness((hsl.lightness + 0.2).clamp(0.0, 1.0))
        .toColor();
  }

  PlayerSkin toPlayerSkin(int index) {
    return PlayerSkin(
      id: SkinId.default_,
      name: name,
      leftColor: leftColor,
      rightColor: rightColor,
      leftGlow: leftGlow,
      rightGlow: rightGlow,
      unlockDescription: 'Custom skin',
      headDecoration: headDecoration,
      faceDecoration: faceDecoration,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'leftColor': leftColorValue,
        'rightColor': rightColorValue,
        'headDeco': headDecoration.index,
        'faceDeco': faceDecoration.index,
      };

  factory CustomSkinData.fromJson(Map<String, dynamic> json) {
    // Backwards compat: old 'decoration' key maps to headDecoration
    final headIdx = json['headDeco'] as int? ?? json['decoration'] as int? ?? 0;
    final faceIdx = json['faceDeco'] as int? ?? 0;
    return CustomSkinData(
      name: json['name'] as String,
      leftColorValue: json['leftColor'] as int,
      rightColorValue: json['rightColor'] as int,
      headDecoration: headIdx >= 0 && headIdx < HeadDecoration.values.length
          ? HeadDecoration.values[headIdx]
          : HeadDecoration.none,
      faceDecoration: faceIdx >= 0 && faceIdx < FaceDecoration.values.length
          ? FaceDecoration.values[faceIdx]
          : FaceDecoration.none,
    );
  }

  static String encodeList(List<CustomSkinData> list) =>
      jsonEncode(list.map((s) => s.toJson()).toList());

  static List<CustomSkinData> decodeList(String jsonStr) {
    final list = jsonDecode(jsonStr) as List;
    final result = <CustomSkinData>[];
    for (final e in list) {
      try {
        result.add(CustomSkinData.fromJson(e as Map<String, dynamic>));
      } catch (_) {
        // Skip corrupt entries instead of failing all skins
      }
    }
    return result;
  }
}
