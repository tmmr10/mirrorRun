// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get languageTitle => 'SPRACHE';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageGerman => 'Deutsch';

  @override
  String get menuPlay => 'SPIELEN';

  @override
  String get menuChangeSkin => 'SKIN WECHSELN';

  @override
  String get menuCreateYourOwn => 'EIGENEN ERSTELLEN';

  @override
  String get menuDailyChallenge => 'TAGES-CHALLENGE';

  @override
  String get menuPlayDailySeedRun => 'TAGES-SEED-RUN SPIELEN';

  @override
  String get settingsTitle => 'EINSTELLUNGEN';

  @override
  String get settingsSound => 'TON';

  @override
  String get settingsVibration => 'VIBRATION';

  @override
  String get settingsBiomes => 'BIOME';

  @override
  String get settingsLeaderboard => 'BESTENLISTE';

  @override
  String get settingsStatistics => 'STATISTIK';

  @override
  String get settingsRestorePurchases => 'KÄUFE WIEDERHERSTELLEN';

  @override
  String get settingsLicenses => 'LIZENZEN';

  @override
  String get settingsPurchasesRestored => 'Käufe wiederhergestellt.';

  @override
  String get settingsRestoreComplete => 'Wiederherstellung abgeschlossen.';

  @override
  String get howtoTitle => 'SPIELANLEITUNG';

  @override
  String get howtoPowerUps => 'POWER-UPS';

  @override
  String get howtoMirrorTitle => 'SPIEGEL-BEWEGUNG';

  @override
  String get howtoMirrorDesc =>
      'Wische nach links oder rechts. Beide Runner bewegen sich gleichzeitig — gespiegelt. Weiche Hindernissen auf beiden Seiten aus.';

  @override
  String get howtoPhantomTitle => 'PHANTOM';

  @override
  String get howtoPhantomDesc =>
      'Hindernisse werden unsichtbar. Merk dir ihre Position, bevor sie verschwinden!';

  @override
  String get howtoSwapTitle => 'SWAP';

  @override
  String get howtoSwapDesc =>
      'Die Steuerung ist vertauscht. Links wird rechts, rechts wird links.';

  @override
  String get howtoDesyncTitle => 'DESYNC';

  @override
  String get howtoDesyncDesc =>
      'Die beiden Seiten scrollen unterschiedlich schnell.';

  @override
  String get howtoBlackoutTitle => 'BLACKOUT';

  @override
  String get howtoBlackoutDesc =>
      'Eine Seite wird dunkel — lauf sie aus dem Gedächtnis.';

  @override
  String get howtoShieldTitle => 'SCHILD';

  @override
  String get howtoShieldDesc =>
      'Fängt einen Treffer ab. Mit dem Schild-Perk startest du mit einem und lädst ihn über die Distanz wieder auf.';

  @override
  String get howtoSyncLockTitle => 'SYNC-LOCK';

  @override
  String get howtoSyncLockDesc =>
      'Die Steuerung wird kurz entspiegelt — beide Runner bewegen sich in dieselbe Richtung.';

  @override
  String get howtoSlowMoTitle => 'SLOW-MO';

  @override
  String get howtoSlowMoDesc => 'Verlangsamt die Welt für einen Moment.';

  @override
  String get howtoForesightTitle => 'VORAUSSICHT';

  @override
  String get howtoForesightDesc =>
      'Zeigt Hindernisse, die während PHANTOM verborgen sind.';

  @override
  String get biomeBannerEntering => 'DU BETRITTST';

  @override
  String get cdDragToMove => 'ZIEHEN ZUM BEWEGEN';

  @override
  String get hudNewBest => 'NEUE BESTLEISTUNG!';

  @override
  String hudBest(int score) {
    return 'BESTE $score';
  }

  @override
  String get hudResume => 'WEITER';

  @override
  String get hudQuit => 'BEENDEN';

  @override
  String get deathMotivKeepGoing => 'WEITER SO';

  @override
  String get deathMotivNotBad => 'NICHT SCHLECHT';

  @override
  String get deathMotivNiceRun => 'GUTER LAUF';

  @override
  String get deathMotivImpressive => 'BEEINDRUCKEND';

  @override
  String get deathMotivIncredible => 'UNGLAUBLICH';

  @override
  String get deathMotivUnstoppable => 'UNAUFHALTSAM';

  @override
  String get deathMotivLegendary => 'LEGENDÄR';

  @override
  String get deathMeter => 'METER';

  @override
  String get deathNewRecord => 'NEUER REKORD';

  @override
  String get deathThisRun => 'DIESER LAUF';

  @override
  String get deathBest => 'BESTE';

  @override
  String get deathCoins => 'COINS';

  @override
  String deathNewSkin(String name) {
    return 'NEUER SKIN: $name';
  }

  @override
  String deathAchievementGames(String count) {
    return '$count SPIELE';
  }

  @override
  String get deathAchievementFirstRun => '1. LAUF';

  @override
  String get deathRetry => 'NOCHMAL';

  @override
  String get deathMenu => 'MENÜ';

  @override
  String get deathRanks => 'RÄNGE';

  @override
  String get deathShare => 'TEILEN';

  @override
  String deathShareText(int distance, String biome) {
    return 'Ich bin ${distance}m durch $biome in Mirror Runners gelaufen!';
  }

  @override
  String get deathGoPro => 'PRO HOLEN';

  @override
  String get deathContinueQ => 'WEITER?';

  @override
  String get deathFreeRevive => 'GRATIS WEITERLEBEN';

  @override
  String deathProRevivesToday(int remaining) {
    return '$remaining / 3 HEUTE';
  }

  @override
  String get deathResetsAtMidnight => 'RESET UM MITTERNACHT';

  @override
  String get deathWatchAd => 'AD ANSEHEN';

  @override
  String get deathContinue => 'WEITER';

  @override
  String deathCoinCost(int cost) {
    return '$cost COINS';
  }

  @override
  String get skinTitle => 'SKINS';

  @override
  String get skinSectionCreator => 'SKIN-CREATOR';

  @override
  String get skinSectionCollection => 'SAMMLUNG';

  @override
  String get skinCreate => 'ERSTELLEN';

  @override
  String get skinCreateNewSkin => 'NEUER SKIN';

  @override
  String get skinGoPro => 'PRO HOLEN';

  @override
  String get skinEquipped => 'ANGELEGT';

  @override
  String get skinTapToEquip => 'TIPPEN ZUM ANLEGEN';

  @override
  String get skinEdit => 'BEARBEITEN';

  @override
  String get skinBuy => 'KAUFEN';

  @override
  String get skinNotEnough => 'ZU WENIG';

  @override
  String get skinCancel => 'ABBRECHEN';

  @override
  String skinUnlockNamed(String name) {
    return '$name FREISCHALTEN';
  }

  @override
  String skinBalance(int current, int next) {
    return 'Guthaben: $current → $next';
  }

  @override
  String get skinNotEnoughCoins => 'Nicht genug Coins';

  @override
  String get skinPurchaseFailed => 'Kauf fehlgeschlagen';

  @override
  String get builderTitle => 'SKIN-CREATOR';

  @override
  String get builderEditTitle => 'SKIN BEARBEITEN';

  @override
  String get builderUpdate => 'AKTUALISIEREN';

  @override
  String get builderSave => 'SPEICHERN';

  @override
  String get builderLockedDescription =>
      'Erstelle eigene Skins mit deinen Farben und Deko.';

  @override
  String get builderGoProIncluded => 'GO PRO — ENTHALTEN';

  @override
  String get builderLeftColor => 'LINKE FARBE';

  @override
  String get builderRightColor => 'RECHTE FARBE';

  @override
  String get builderHead => 'KOPF';

  @override
  String get builderFace => 'GESICHT';

  @override
  String get builderName => 'NAME';

  @override
  String builderDefaultName(int number) {
    return 'EIGENER $number';
  }

  @override
  String get builderDeleteTitle => 'SKIN LÖSCHEN';

  @override
  String get builderDelete => 'LÖSCHEN';

  @override
  String get builderCancel => 'ABBRECHEN';

  @override
  String get builderDiscardTitle => 'ÄNDERUNGEN VERWERFEN?';

  @override
  String get builderDiscardMessage =>
      'Deine ungespeicherten Änderungen gehen verloren.';

  @override
  String get builderDiscard => 'VERWERFEN';

  @override
  String builderMaxSkinsReached(int count) {
    return 'Maximal $count eigene Skins erreicht.';
  }

  @override
  String get proPurchaseFailed =>
      'Kauf fehlgeschlagen. Bitte versuch es erneut.';

  @override
  String get proPurchasesRestored => 'Käufe wiederhergestellt.';

  @override
  String get proRestoreComplete => 'Wiederherstellung abgeschlossen.';

  @override
  String get proTitle => 'MIRROR RUNNERS PRO';

  @override
  String get proSubtitle => 'EINMALKAUF — FÜR IMMER';

  @override
  String get proBenefitSkinCreatorLabel => 'SKIN CREATOR';

  @override
  String get proBenefitSkinCreatorDesc =>
      'Gestalte eigene Skins + schalte alle Skins frei';

  @override
  String get proBenefitNoAdsLabel => 'KEINE WERBUNG';

  @override
  String get proBenefitNoAdsDesc => 'Entfernt alle Werbeunterbrechungen';

  @override
  String get proBenefitFreeRevivesLabel => 'GRATIS WEITERLEBEN';

  @override
  String get proBenefitFreeRevivesDesc =>
      'Täglich gratis weiterspielen — keine Werbung, keine Coins';

  @override
  String proPriceLine(String price) {
    return '$price · EINMALIG';
  }

  @override
  String get proGoPro => 'PRO HOLEN';

  @override
  String get proRestorePurchases => 'KÄUFE WIEDERHERSTELLEN';

  @override
  String get proBest => 'BESTE';

  @override
  String get proActive => 'PRO AKTIV';

  @override
  String get perkTitle => 'PERKS';

  @override
  String get perkMaxed => 'MAX';

  @override
  String get perkBuy => 'KAUFEN';

  @override
  String get statsTitle => 'STATISTIK';

  @override
  String get statsTotalDistance => 'DISTANZ GESAMT';

  @override
  String get statsGamesPlayed => 'SPIELE';

  @override
  String get statsPlaytime => 'SPIELZEIT';

  @override
  String get statsFurthestBiome => 'WEITESTES BIOM';

  @override
  String get statsBestScore => 'BESTE PUNKTZAHL';

  @override
  String get statsShare => 'TEILEN';

  @override
  String get statsUnknownBiome => 'UNBEKANNT';

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
    return 'Mirror Runners Statistik:\n${best}m beste · $games Spiele · $playtime gespielt · $biome erreicht';
  }

  @override
  String get achTitle => 'ERFOLGE';

  @override
  String get biomeForest => 'WALD';

  @override
  String get biomeCity => 'STADT';

  @override
  String get biomeCrystal => 'KRISTALL';

  @override
  String get biomeVolcano => 'VULKAN';

  @override
  String get biomeDesert => 'WÜSTE';

  @override
  String get biomeOcean => 'OZEAN';

  @override
  String get biomeRuins => 'RUINEN';

  @override
  String get biomeSpace => 'WELTALL';

  @override
  String get biomeStorm => 'STURM';

  @override
  String get biomeNeon => 'NEON';

  @override
  String get biomeVoid => 'LEERE';

  @override
  String get skinNameDefault => 'STANDARD';

  @override
  String get skinNameIce => 'EIS';

  @override
  String get skinNameFire => 'FEUER';

  @override
  String get skinNameGold => 'GOLD';

  @override
  String get skinNameOcean => 'OZEAN';

  @override
  String get skinNameNeon => 'NEON';

  @override
  String get skinNameVoid => 'LEERE';

  @override
  String get perkCoinMagnetTitle => 'COIN-MAGNET';

  @override
  String get perkCoinMagnetEffect => 'Größere Coin-Reichweite';

  @override
  String get perkCoinBonusTitle => 'COIN-BONUS';

  @override
  String get perkCoinBonusEffect => '+1 Coin pro Aufnahme';

  @override
  String get perkPowerUpTimeTitle => 'POWER-UP-DAUER';

  @override
  String get perkPowerUpTimeEffect => 'Power-ups halten länger';

  @override
  String get perkHeadStartTitle => 'VORSPRUNG';

  @override
  String get perkHeadStartEffect =>
      'Starte mitten im Combo (x1.2 / x1.5 / x2.0)';

  @override
  String get perkShieldTitle => 'SCHILD';

  @override
  String get perkShieldEffect => 'Starte mit Schild; lädt alle 400m nach';

  @override
  String dailyChallengeDistance(int target) {
    return 'Erreiche ${target}m in einem Lauf';
  }

  @override
  String dailyChallengeCoins(int target) {
    return 'Sammle $target Coins in einem Lauf';
  }

  @override
  String dailyChallengeGames(int target) {
    return 'Spiele heute $target Läufe';
  }

  @override
  String get achCategoryDistance => 'DISTANZ';

  @override
  String get achCategoryBiome => 'BIOM';

  @override
  String get achCategoryGames => 'SPIELE';

  @override
  String get achCategoryFirstRun => 'ERSTER LAUF';

  @override
  String get achBiomeCrystal => 'Kristall';

  @override
  String get achBiomeVolcano => 'Vulkan';

  @override
  String get achBiomeDesert => 'Wüste';

  @override
  String get achBiomeOcean => 'Ozean';

  @override
  String get achBiomeNeon => 'Neon';

  @override
  String get achBiomeVoid => 'Leere';

  @override
  String achGamesCount(int count) {
    return '$count Spiele';
  }

  @override
  String get achFirstRun => '1. Lauf';

  @override
  String get worldsTitle => 'WELTEN';

  @override
  String get worldStart => 'START';

  @override
  String get worldUnlock => 'FREISCHALTEN';

  @override
  String get worldFreePlayNote => 'Free Play · nicht gewertet';

  @override
  String worldStartAt(int m) {
    return 'Erreicht bei ${m}m';
  }

  @override
  String get decoNone => 'OHNE';

  @override
  String get decoIce => 'EIS';

  @override
  String get decoFire => 'FEUER';

  @override
  String get decoCrown => 'KRONE';

  @override
  String get decoAntenna => 'ANTENNE';

  @override
  String get decoHalo => 'HALO';

  @override
  String get decoHorns => 'HÖRNER';

  @override
  String get decoWings => 'FLÜGEL';

  @override
  String get decoMohawk => 'IROKESE';

  @override
  String get decoStar => 'STERN';

  @override
  String get decoGoggles => 'BRILLE';

  @override
  String get decoVisor => 'VISIER';

  @override
  String get decoMask => 'MASKE';

  @override
  String get decoMonocle => 'MONOKEL';

  @override
  String get decoScar => 'NARBE';

  @override
  String get decoShades => 'SHADES';
}
