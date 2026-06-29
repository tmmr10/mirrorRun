// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get languageTitle => 'LANGUAGE';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get menuPlay => 'PLAY';

  @override
  String get menuChooseWorld => 'CHOOSE WORLD';

  @override
  String get menuChangeSkin => 'CHANGE SKIN';

  @override
  String get menuCreateYourOwn => 'CREATE YOUR OWN';

  @override
  String get menuDailyChallenge => 'DAILY CHALLENGE';

  @override
  String get menuPlayDailySeedRun => 'PLAY DAILY SEED RUN';

  @override
  String get settingsTitle => 'SETTINGS';

  @override
  String get settingsSound => 'SOUND';

  @override
  String get settingsVibration => 'VIBRATION';

  @override
  String get settingsBiomes => 'BIOMES';

  @override
  String get settingsLeaderboard => 'LEADERBOARD';

  @override
  String get settingsStatistics => 'STATISTICS';

  @override
  String get settingsRate => 'RATE THIS APP';

  @override
  String get settingsRestorePurchases => 'RESTORE PURCHASES';

  @override
  String get settingsLegal => 'LEGAL';

  @override
  String get settingsPrivacy => 'PRIVACY POLICY';

  @override
  String get settingsTerms => 'TERMS OF SERVICE';

  @override
  String get settingsLicenses => 'LICENSES';

  @override
  String get settingsPurchasesRestored => 'Purchases restored.';

  @override
  String get settingsRestoreComplete => 'Restore complete.';

  @override
  String get howtoTitle => 'HOW TO PLAY';

  @override
  String get howtoPowerUps => 'POWER-UPS';

  @override
  String get howtoMirrorTitle => 'MIRROR MOVEMENT';

  @override
  String get howtoMirrorDesc =>
      'Drag left or right. Both runners move at the same time — mirrored. Dodge obstacles on both sides.';

  @override
  String get howtoPhantomTitle => 'PHANTOM';

  @override
  String get howtoPhantomDesc =>
      'Obstacles turn invisible. Memorize their positions before they fade!';

  @override
  String get howtoSwapTitle => 'SWAP';

  @override
  String get howtoSwapDesc =>
      'Controls are reversed. Left becomes right, right becomes left.';

  @override
  String get howtoDesyncTitle => 'DESYNC';

  @override
  String get howtoDesyncDesc => 'The two sides scroll at different speeds.';

  @override
  String get howtoBlackoutTitle => 'BLACKOUT';

  @override
  String get howtoBlackoutDesc => 'One side goes dark — run it from memory.';

  @override
  String get howtoShieldTitle => 'SHIELD';

  @override
  String get howtoShieldDesc =>
      'Absorbs one hit. The Shield perk starts you with one and recharges it over distance.';

  @override
  String get howtoSyncLockTitle => 'SYNC-LOCK';

  @override
  String get howtoSyncLockDesc =>
      'Controls briefly un-mirror — both runners move the same direction.';

  @override
  String get howtoSlowMoTitle => 'SLOW-MO';

  @override
  String get howtoSlowMoDesc => 'Slows the world down for a moment.';

  @override
  String get howtoForesightTitle => 'FORESIGHT';

  @override
  String get howtoForesightDesc =>
      'Banks a charge that reveals the obstacles hidden during your next PHANTOM.';

  @override
  String get biomeBannerEntering => 'ENTERING';

  @override
  String get cdDragToMove => 'DRAG TO MOVE';

  @override
  String get hudNewBest => 'NEW BEST!';

  @override
  String hudBest(int score) {
    return 'BEST $score';
  }

  @override
  String get hudResume => 'RESUME';

  @override
  String get hudQuit => 'QUIT';

  @override
  String get deathMotivKeepGoing => 'KEEP GOING';

  @override
  String get deathMotivNotBad => 'NOT BAD';

  @override
  String get deathMotivNiceRun => 'NICE RUN';

  @override
  String get deathMotivImpressive => 'IMPRESSIVE';

  @override
  String get deathMotivIncredible => 'INCREDIBLE';

  @override
  String get deathMotivUnstoppable => 'UNSTOPPABLE';

  @override
  String get deathMotivLegendary => 'LEGENDARY';

  @override
  String get deathMeter => 'METER';

  @override
  String get deathNewRecord => 'NEW RECORD';

  @override
  String get deathThisRun => 'THIS RUN';

  @override
  String get deathBest => 'BEST';

  @override
  String get deathCoins => 'COINS';

  @override
  String deathNewSkin(String name) {
    return 'NEW SKIN: $name';
  }

  @override
  String deathAchievementGames(String count) {
    return '$count GAMES';
  }

  @override
  String get deathAchievementFirstRun => '1ST RUN';

  @override
  String get deathRetry => 'RETRY';

  @override
  String get deathMenu => 'MENU';

  @override
  String get deathRanks => 'RANKS';

  @override
  String get deathShare => 'SHARE';

  @override
  String deathShareText(int distance, String biome) {
    return 'I ran ${distance}m through $biome in Mirror Runners!';
  }

  @override
  String get deathGoPro => 'GO PRO';

  @override
  String get deathContinueQ => 'CONTINUE?';

  @override
  String get deathFreeRevive => 'FREE REVIVE';

  @override
  String deathProRevivesToday(int remaining) {
    return '$remaining / 3 TODAY';
  }

  @override
  String get deathResetsAtMidnight => 'RESETS AT MIDNIGHT';

  @override
  String get deathWatchAd => 'WATCH AD';

  @override
  String get deathContinue => 'CONTINUE';

  @override
  String deathCoinCost(int cost) {
    return '$cost COINS';
  }

  @override
  String get skinTitle => 'SKINS';

  @override
  String get skinSectionCreator => 'SKIN CREATOR';

  @override
  String get skinSectionCollection => 'COLLECTION';

  @override
  String get skinCreate => 'CREATE';

  @override
  String get skinCreateNewSkin => 'NEW SKIN';

  @override
  String get skinGoPro => 'GO PRO';

  @override
  String get skinEquipped => 'EQUIPPED';

  @override
  String get skinTapToEquip => 'TAP TO EQUIP';

  @override
  String get skinEdit => 'EDIT';

  @override
  String get skinBuy => 'BUY';

  @override
  String get skinNotEnough => 'NOT ENOUGH';

  @override
  String get skinCancel => 'CANCEL';

  @override
  String skinUnlockNamed(String name) {
    return 'UNLOCK $name';
  }

  @override
  String skinBalance(int current, int next) {
    return 'Balance: $current → $next';
  }

  @override
  String get skinNotEnoughCoins => 'Not enough coins';

  @override
  String get skinPurchaseFailed => 'Purchase failed';

  @override
  String get builderTitle => 'SKIN CREATOR';

  @override
  String get builderEditTitle => 'EDIT SKIN';

  @override
  String get builderUpdate => 'UPDATE';

  @override
  String get builderSave => 'SAVE';

  @override
  String get builderLockedDescription =>
      'Create custom skins with your own colors and decorations.';

  @override
  String get builderGoProIncluded => 'GO PRO — INCLUDED';

  @override
  String get builderLeftColor => 'LEFT COLOR';

  @override
  String get builderRightColor => 'RIGHT COLOR';

  @override
  String get builderHead => 'HEAD';

  @override
  String get builderFace => 'FACE';

  @override
  String get builderName => 'NAME';

  @override
  String builderDefaultName(int number) {
    return 'CUSTOM $number';
  }

  @override
  String get builderDeleteTitle => 'DELETE SKIN';

  @override
  String get builderDelete => 'DELETE';

  @override
  String get builderCancel => 'CANCEL';

  @override
  String get builderDiscardTitle => 'DISCARD CHANGES?';

  @override
  String get builderDiscardMessage => 'Your unsaved changes will be lost.';

  @override
  String get builderDiscard => 'DISCARD';

  @override
  String builderMaxSkinsReached(int count) {
    return 'Maximum $count custom skins reached.';
  }

  @override
  String get proPurchaseFailed => 'Purchase failed. Please try again.';

  @override
  String get proPurchasesRestored => 'Purchases restored.';

  @override
  String get proRestoreComplete => 'Restore complete.';

  @override
  String get proTitle => 'MIRROR RUNNERS PRO';

  @override
  String get proSubtitle => 'ONE TIME PURCHASE — FOREVER';

  @override
  String get proBenefitSkinCreatorLabel => 'SKIN CREATOR';

  @override
  String get proBenefitSkinCreatorDesc =>
      'Design your own skins + unlock every skin';

  @override
  String get proBenefitNoAdsLabel => 'NO ADS';

  @override
  String get proBenefitNoAdsDesc => 'Remove all interstitial ads';

  @override
  String get proBenefitFreeRevivesLabel => 'FREE REVIVES';

  @override
  String get proBenefitFreeRevivesDesc =>
      'Free daily continues — no ads, no coins';

  @override
  String proPriceLine(String price) {
    return '$price · ONE TIME';
  }

  @override
  String get proGoPro => 'GO PRO';

  @override
  String get proRestorePurchases => 'RESTORE PURCHASES';

  @override
  String get proBest => 'BEST';

  @override
  String get proActive => 'PRO ACTIVE';

  @override
  String get perkTitle => 'PERKS';

  @override
  String get perkMaxed => 'MAXED';

  @override
  String get perkBuy => 'BUY';

  @override
  String get statsTitle => 'STATISTICS';

  @override
  String get statsTotalDistance => 'TOTAL DISTANCE';

  @override
  String get statsGamesPlayed => 'GAMES PLAYED';

  @override
  String get statsPlaytime => 'PLAYTIME';

  @override
  String get statsFurthestBiome => 'FURTHEST BIOME';

  @override
  String get statsBestScore => 'BEST SCORE';

  @override
  String get statsShare => 'SHARE';

  @override
  String get statsUnknownBiome => 'UNKNOWN';

  @override
  String statsMeters(int value) {
    return '${value}m';
  }

  @override
  String statsPlaytimeHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String statsPlaytimeMinutes(int minutes) {
    return '${minutes}m';
  }

  @override
  String statsShareText(int best, int games, String playtime, String biome) {
    return 'Mirror Runners Stats:\n${best}m best · $games games · $playtime played · $biome reached';
  }

  @override
  String get achTitle => 'ACHIEVEMENTS';

  @override
  String get biomeForest => 'FOREST';

  @override
  String get biomeCity => 'CITY';

  @override
  String get biomeCrystal => 'CRYSTAL';

  @override
  String get biomeVolcano => 'VOLCANO';

  @override
  String get biomeDesert => 'DESERT';

  @override
  String get biomeOcean => 'OCEAN';

  @override
  String get biomeRuins => 'RUINS';

  @override
  String get biomeSpace => 'SPACE';

  @override
  String get biomeStorm => 'STORM';

  @override
  String get biomeNeon => 'NEON';

  @override
  String get biomeVoid => 'VOID';

  @override
  String get skinNameDefault => 'DEFAULT';

  @override
  String get skinNameIce => 'ICE';

  @override
  String get skinNameFire => 'FIRE';

  @override
  String get skinNameGold => 'GOLD';

  @override
  String get skinNameOcean => 'OCEAN';

  @override
  String get skinNameNeon => 'NEON';

  @override
  String get skinNameVoid => 'VOID';

  @override
  String get perkCoinMagnetTitle => 'COIN MAGNET';

  @override
  String get perkCoinMagnetEffect => 'Wider coin pickup range';

  @override
  String get perkCoinBonusTitle => 'COIN BONUS';

  @override
  String get perkCoinBonusEffect => '+1 coin per pickup';

  @override
  String get perkPowerUpTimeTitle => 'POWER-UP TIME';

  @override
  String get perkPowerUpTimeEffect => 'Power-ups last longer';

  @override
  String get perkHeadStartTitle => 'HEAD START';

  @override
  String get perkHeadStartEffect => 'Begin mid-combo (x1.2 / x1.5 / x2.0)';

  @override
  String get perkShieldTitle => 'SHIELD';

  @override
  String get perkShieldEffect => 'Start shielded; recharges every 400m';

  @override
  String dailyChallengeDistance(int target) {
    return 'Reach ${target}m in one run';
  }

  @override
  String dailyChallengeCoins(int target) {
    return 'Collect $target coins in one run';
  }

  @override
  String dailyChallengeGames(int target) {
    return 'Play $target runs today';
  }

  @override
  String dailyChallengeDistanceTotal(int target) {
    return 'Run ${target}m total today';
  }

  @override
  String dailyChallengeCoinsTotal(int target) {
    return 'Collect $target coins today';
  }

  @override
  String dailyChallengeBiome(String world) {
    return 'Reach the $world';
  }

  @override
  String dailyChallengeCleanRun(int target) {
    return 'Reach ${target}m without reviving';
  }

  @override
  String get achCategoryDistance => 'DISTANCE';

  @override
  String get achCategoryBiome => 'BIOME';

  @override
  String get achCategoryGames => 'GAMES';

  @override
  String get achCategoryFirstRun => 'FIRST RUN';

  @override
  String get achBiomeCrystal => 'Crystal';

  @override
  String get achBiomeVolcano => 'Volcano';

  @override
  String get achBiomeDesert => 'Desert';

  @override
  String get achBiomeOcean => 'Ocean';

  @override
  String get achBiomeNeon => 'Neon';

  @override
  String get achBiomeVoid => 'Void';

  @override
  String achGamesCount(int count) {
    return '$count Games';
  }

  @override
  String get achFirstRun => '1st Run';

  @override
  String get worldsTitle => 'WORLDS';

  @override
  String get worldStart => 'START';

  @override
  String get worldUnlock => 'UNLOCK';

  @override
  String get worldFreePlayNote => 'Free Play · not ranked';

  @override
  String worldStartAt(int m) {
    return 'Reached at ${m}m';
  }

  @override
  String get decoNone => 'NONE';

  @override
  String get decoIce => 'ICE';

  @override
  String get decoFire => 'FIRE';

  @override
  String get decoCrown => 'CROWN';

  @override
  String get decoAntenna => 'ANTENNA';

  @override
  String get decoHalo => 'HALO';

  @override
  String get decoHorns => 'HORNS';

  @override
  String get decoWings => 'WINGS';

  @override
  String get decoMohawk => 'MOHAWK';

  @override
  String get decoStar => 'STAR';

  @override
  String get decoGoggles => 'GOGGLES';

  @override
  String get decoVisor => 'VISOR';

  @override
  String get decoMask => 'MASK';

  @override
  String get decoMonocle => 'MONOCLE';

  @override
  String get decoScar => 'SCAR';

  @override
  String get decoShades => 'SHADES';
}
