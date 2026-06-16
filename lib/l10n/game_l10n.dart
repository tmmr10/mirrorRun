import 'package:flutter/widgets.dart';
import '../models/player_skin.dart';
import '../services/daily_challenge_service.dart';
import '../services/upgrade_service.dart';
import 'l10n_ext.dart';

/// Context-based localization for *data-layer* strings. The data classes keep
/// their English `name`/`title` as a stable internal id; these mappers turn that
/// id into the user's language at render time. Unknown values fall back to the
/// raw string so nothing ever crashes or shows blank.

/// Localizes a biome's raw English name (e.g. `'FOREST'`).
String biomeNameLocalized(BuildContext c, String rawName) {
  final l = c.l10n;
  switch (rawName) {
    case 'FOREST':
      return l.biomeForest;
    case 'CITY':
      return l.biomeCity;
    case 'CRYSTAL':
      return l.biomeCrystal;
    case 'VOLCANO':
      return l.biomeVolcano;
    case 'DESERT':
      return l.biomeDesert;
    case 'OCEAN':
      return l.biomeOcean;
    case 'RUINS':
      return l.biomeRuins;
    case 'SPACE':
      return l.biomeSpace;
    case 'STORM':
      return l.biomeStorm;
    case 'NEON':
      return l.biomeNeon;
    case 'VOID':
      return l.biomeVoid;
    default:
      return rawName;
  }
}

/// Localizes one of the 7 built-in skins by [SkinId].
String skinNameLocalized(BuildContext c, SkinId id) {
  final l = c.l10n;
  switch (id) {
    case SkinId.default_:
      return l.skinNameDefault;
    case SkinId.ice:
      return l.skinNameIce;
    case SkinId.fire:
      return l.skinNameFire;
    case SkinId.gold:
      return l.skinNameGold;
    case SkinId.ocean:
      return l.skinNameOcean;
    case SkinId.neon:
      return l.skinNameNeon;
    case SkinId.void_:
      return l.skinNameVoid;
  }
}

/// Localizes a [PlayerSkin]'s display name. Built-in skins are translated by
/// their raw English name; custom skins (user-named) keep their own name.
///
/// Built-ins are matched by raw name rather than [SkinId] because a custom skin
/// is represented as a [PlayerSkin] with `id == SkinId.default_` but a custom
/// `name` — keying on the id would mistranslate it to "DEFAULT".
String playerSkinNameLocalized(BuildContext c, PlayerSkin skin) {
  final l = c.l10n;
  switch (skin.name) {
    case 'DEFAULT':
      return l.skinNameDefault;
    case 'ICE':
      return l.skinNameIce;
    case 'FIRE':
      return l.skinNameFire;
    case 'GOLD':
      return l.skinNameGold;
    case 'OCEAN':
      return l.skinNameOcean;
    case 'NEON':
      return l.skinNameNeon;
    case 'VOID':
      return l.skinNameVoid;
    default:
      return skin.name; // custom skin — keep user name
  }
}

/// Localizes a perk's short title.
String perkTitleLocalized(BuildContext c, Perk p) {
  final l = c.l10n;
  switch (p) {
    case Perk.coinMagnet:
      return l.perkCoinMagnetTitle;
    case Perk.coinBonus:
      return l.perkCoinBonusTitle;
    case Perk.powerUpDuration:
      return l.perkPowerUpTimeTitle;
    case Perk.startCombo:
      return l.perkHeadStartTitle;
    case Perk.startShield:
      return l.perkShieldTitle;
  }
}

/// Localizes a perk's effect description.
String perkEffectLocalized(BuildContext c, Perk p) {
  final l = c.l10n;
  switch (p) {
    case Perk.coinMagnet:
      return l.perkCoinMagnetEffect;
    case Perk.coinBonus:
      return l.perkCoinBonusEffect;
    case Perk.powerUpDuration:
      return l.perkPowerUpTimeEffect;
    case Perk.startCombo:
      return l.perkHeadStartEffect;
    case Perk.startShield:
      return l.perkShieldEffect;
  }
}

/// Localizes the daily-challenge label (with its target interpolated).
String dailyChallengeLabelLocalized(BuildContext c, DailyChallenge ch) {
  final l = c.l10n;
  switch (ch.type) {
    case DailyChallengeType.distance:
      return l.dailyChallengeDistance(ch.target);
    case DailyChallengeType.coins:
      return l.dailyChallengeCoins(ch.target);
    case DailyChallengeType.games:
      return l.dailyChallengeGames(ch.target);
  }
}

/// Localizes an achievement category (e.g. `'DISTANCE'` → `'DISTANZ'`).
String achievementCategoryLocalized(BuildContext c, String category) {
  final l = c.l10n;
  switch (category) {
    case 'DISTANCE':
      return l.achCategoryDistance;
    case 'BIOME':
      return l.achCategoryBiome;
    case 'GAMES':
      return l.achCategoryGames;
    case 'FIRST RUN':
      return l.achCategoryFirstRun;
    default:
      return category;
  }
}

/// Localizes an achievement label given its raw label + category.
/// - DISTANCE → raw label unchanged (e.g. "75m").
/// - BIOME → localized Title-Case biome name.
/// - GAMES → "{n} Spiele" (n = leading number from rawLabel).
/// - FIRST RUN → "1. Lauf".
String achievementLabelLocalized(
    BuildContext c, String category, String rawLabel) {
  final l = c.l10n;
  switch (category) {
    case 'DISTANCE':
      return rawLabel;
    case 'BIOME':
      switch (rawLabel) {
        case 'Crystal':
          return l.achBiomeCrystal;
        case 'Volcano':
          return l.achBiomeVolcano;
        case 'Desert':
          return l.achBiomeDesert;
        case 'Ocean':
          return l.achBiomeOcean;
        case 'Neon':
          return l.achBiomeNeon;
        case 'Void':
          return l.achBiomeVoid;
        default:
          return rawLabel;
      }
    case 'GAMES':
      final match = RegExp(r'\d+').firstMatch(rawLabel);
      final count = match != null ? int.parse(match.group(0)!) : 0;
      return l.achGamesCount(count);
    case 'FIRST RUN':
      return l.achFirstRun;
    default:
      return rawLabel;
  }
}

/// Localized label for a head decoration in the skin creator.
String headDecorationLocalized(BuildContext c, HeadDecoration d) {
  final l = c.l10n;
  switch (d) {
    case HeadDecoration.none:
      return l.decoNone;
    case HeadDecoration.iceCrown:
      return l.decoIce;
    case HeadDecoration.flames:
      return l.decoFire;
    case HeadDecoration.crown:
      return l.decoCrown;
    case HeadDecoration.antenna:
      return l.decoAntenna;
    case HeadDecoration.halo:
      return l.decoHalo;
    case HeadDecoration.horns:
      return l.decoHorns;
    case HeadDecoration.wings:
      return l.decoWings;
    case HeadDecoration.mohawk:
      return l.decoMohawk;
    case HeadDecoration.star:
      return l.decoStar;
  }
}

/// Localized label for a face decoration in the skin creator.
String faceDecorationLocalized(BuildContext c, FaceDecoration d) {
  final l = c.l10n;
  switch (d) {
    case FaceDecoration.none:
      return l.decoNone;
    case FaceDecoration.goggles:
      return l.decoGoggles;
    case FaceDecoration.visor:
      return l.decoVisor;
    case FaceDecoration.mask:
      return l.decoMask;
    case FaceDecoration.monocle:
      return l.decoMonocle;
    case FaceDecoration.scar:
      return l.decoScar;
    case FaceDecoration.shades:
      return l.decoShades;
  }
}
