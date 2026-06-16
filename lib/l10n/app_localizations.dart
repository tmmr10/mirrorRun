import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// No description provided for @languageTitle.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGE'**
  String get languageTitle;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageGerman.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get languageGerman;

  /// No description provided for @menuPlay.
  ///
  /// In en, this message translates to:
  /// **'PLAY'**
  String get menuPlay;

  /// No description provided for @menuChangeSkin.
  ///
  /// In en, this message translates to:
  /// **'CHANGE SKIN'**
  String get menuChangeSkin;

  /// No description provided for @menuCreateYourOwn.
  ///
  /// In en, this message translates to:
  /// **'CREATE YOUR OWN'**
  String get menuCreateYourOwn;

  /// No description provided for @menuDailyChallenge.
  ///
  /// In en, this message translates to:
  /// **'DAILY CHALLENGE'**
  String get menuDailyChallenge;

  /// No description provided for @menuPlayDailySeedRun.
  ///
  /// In en, this message translates to:
  /// **'PLAY DAILY SEED RUN'**
  String get menuPlayDailySeedRun;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get settingsTitle;

  /// No description provided for @settingsSound.
  ///
  /// In en, this message translates to:
  /// **'SOUND'**
  String get settingsSound;

  /// No description provided for @settingsVibration.
  ///
  /// In en, this message translates to:
  /// **'VIBRATION'**
  String get settingsVibration;

  /// No description provided for @settingsBiomes.
  ///
  /// In en, this message translates to:
  /// **'BIOMES'**
  String get settingsBiomes;

  /// No description provided for @settingsLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'LEADERBOARD'**
  String get settingsLeaderboard;

  /// No description provided for @settingsStatistics.
  ///
  /// In en, this message translates to:
  /// **'STATISTICS'**
  String get settingsStatistics;

  /// No description provided for @settingsRestorePurchases.
  ///
  /// In en, this message translates to:
  /// **'RESTORE PURCHASES'**
  String get settingsRestorePurchases;

  /// No description provided for @settingsLicenses.
  ///
  /// In en, this message translates to:
  /// **'LICENSES'**
  String get settingsLicenses;

  /// No description provided for @settingsPurchasesRestored.
  ///
  /// In en, this message translates to:
  /// **'Purchases restored.'**
  String get settingsPurchasesRestored;

  /// No description provided for @settingsRestoreComplete.
  ///
  /// In en, this message translates to:
  /// **'Restore complete.'**
  String get settingsRestoreComplete;

  /// No description provided for @howtoTitle.
  ///
  /// In en, this message translates to:
  /// **'HOW TO PLAY'**
  String get howtoTitle;

  /// No description provided for @howtoPowerUps.
  ///
  /// In en, this message translates to:
  /// **'POWER-UPS'**
  String get howtoPowerUps;

  /// No description provided for @howtoMirrorTitle.
  ///
  /// In en, this message translates to:
  /// **'MIRROR MOVEMENT'**
  String get howtoMirrorTitle;

  /// No description provided for @howtoMirrorDesc.
  ///
  /// In en, this message translates to:
  /// **'Drag left or right. Both runners move at the same time — mirrored. Dodge obstacles on both sides.'**
  String get howtoMirrorDesc;

  /// No description provided for @howtoPhantomTitle.
  ///
  /// In en, this message translates to:
  /// **'PHANTOM'**
  String get howtoPhantomTitle;

  /// No description provided for @howtoPhantomDesc.
  ///
  /// In en, this message translates to:
  /// **'Obstacles turn invisible. Memorize their positions before they fade!'**
  String get howtoPhantomDesc;

  /// No description provided for @howtoSwapTitle.
  ///
  /// In en, this message translates to:
  /// **'SWAP'**
  String get howtoSwapTitle;

  /// No description provided for @howtoSwapDesc.
  ///
  /// In en, this message translates to:
  /// **'Controls are reversed. Left becomes right, right becomes left.'**
  String get howtoSwapDesc;

  /// No description provided for @howtoDesyncTitle.
  ///
  /// In en, this message translates to:
  /// **'DESYNC'**
  String get howtoDesyncTitle;

  /// No description provided for @howtoDesyncDesc.
  ///
  /// In en, this message translates to:
  /// **'The two sides scroll at different speeds.'**
  String get howtoDesyncDesc;

  /// No description provided for @howtoBlackoutTitle.
  ///
  /// In en, this message translates to:
  /// **'BLACKOUT'**
  String get howtoBlackoutTitle;

  /// No description provided for @howtoBlackoutDesc.
  ///
  /// In en, this message translates to:
  /// **'One side goes dark — run it from memory.'**
  String get howtoBlackoutDesc;

  /// No description provided for @howtoShieldTitle.
  ///
  /// In en, this message translates to:
  /// **'SHIELD'**
  String get howtoShieldTitle;

  /// No description provided for @howtoShieldDesc.
  ///
  /// In en, this message translates to:
  /// **'Absorbs one hit. The Shield perk starts you with one and recharges it over distance.'**
  String get howtoShieldDesc;

  /// No description provided for @howtoSyncLockTitle.
  ///
  /// In en, this message translates to:
  /// **'SYNC-LOCK'**
  String get howtoSyncLockTitle;

  /// No description provided for @howtoSyncLockDesc.
  ///
  /// In en, this message translates to:
  /// **'Controls briefly un-mirror — both runners move the same direction.'**
  String get howtoSyncLockDesc;

  /// No description provided for @howtoSlowMoTitle.
  ///
  /// In en, this message translates to:
  /// **'SLOW-MO'**
  String get howtoSlowMoTitle;

  /// No description provided for @howtoSlowMoDesc.
  ///
  /// In en, this message translates to:
  /// **'Slows the world down for a moment.'**
  String get howtoSlowMoDesc;

  /// No description provided for @howtoForesightTitle.
  ///
  /// In en, this message translates to:
  /// **'FORESIGHT'**
  String get howtoForesightTitle;

  /// No description provided for @howtoForesightDesc.
  ///
  /// In en, this message translates to:
  /// **'Reveals obstacles hidden during PHANTOM.'**
  String get howtoForesightDesc;

  /// No description provided for @biomeBannerEntering.
  ///
  /// In en, this message translates to:
  /// **'ENTERING'**
  String get biomeBannerEntering;

  /// No description provided for @cdDragToMove.
  ///
  /// In en, this message translates to:
  /// **'DRAG TO MOVE'**
  String get cdDragToMove;

  /// No description provided for @hudNewBest.
  ///
  /// In en, this message translates to:
  /// **'NEW BEST!'**
  String get hudNewBest;

  /// No description provided for @hudBest.
  ///
  /// In en, this message translates to:
  /// **'BEST {score}'**
  String hudBest(int score);

  /// No description provided for @hudResume.
  ///
  /// In en, this message translates to:
  /// **'RESUME'**
  String get hudResume;

  /// No description provided for @hudQuit.
  ///
  /// In en, this message translates to:
  /// **'QUIT'**
  String get hudQuit;

  /// No description provided for @deathMotivKeepGoing.
  ///
  /// In en, this message translates to:
  /// **'KEEP GOING'**
  String get deathMotivKeepGoing;

  /// No description provided for @deathMotivNotBad.
  ///
  /// In en, this message translates to:
  /// **'NOT BAD'**
  String get deathMotivNotBad;

  /// No description provided for @deathMotivNiceRun.
  ///
  /// In en, this message translates to:
  /// **'NICE RUN'**
  String get deathMotivNiceRun;

  /// No description provided for @deathMotivImpressive.
  ///
  /// In en, this message translates to:
  /// **'IMPRESSIVE'**
  String get deathMotivImpressive;

  /// No description provided for @deathMotivIncredible.
  ///
  /// In en, this message translates to:
  /// **'INCREDIBLE'**
  String get deathMotivIncredible;

  /// No description provided for @deathMotivUnstoppable.
  ///
  /// In en, this message translates to:
  /// **'UNSTOPPABLE'**
  String get deathMotivUnstoppable;

  /// No description provided for @deathMotivLegendary.
  ///
  /// In en, this message translates to:
  /// **'LEGENDARY'**
  String get deathMotivLegendary;

  /// No description provided for @deathMeter.
  ///
  /// In en, this message translates to:
  /// **'METER'**
  String get deathMeter;

  /// No description provided for @deathNewRecord.
  ///
  /// In en, this message translates to:
  /// **'NEW RECORD'**
  String get deathNewRecord;

  /// No description provided for @deathThisRun.
  ///
  /// In en, this message translates to:
  /// **'THIS RUN'**
  String get deathThisRun;

  /// No description provided for @deathBest.
  ///
  /// In en, this message translates to:
  /// **'BEST'**
  String get deathBest;

  /// No description provided for @deathCoins.
  ///
  /// In en, this message translates to:
  /// **'COINS'**
  String get deathCoins;

  /// No description provided for @deathNewSkin.
  ///
  /// In en, this message translates to:
  /// **'NEW SKIN: {name}'**
  String deathNewSkin(String name);

  /// No description provided for @deathAchievementGames.
  ///
  /// In en, this message translates to:
  /// **'{count} GAMES'**
  String deathAchievementGames(String count);

  /// No description provided for @deathAchievementFirstRun.
  ///
  /// In en, this message translates to:
  /// **'1ST RUN'**
  String get deathAchievementFirstRun;

  /// No description provided for @deathRetry.
  ///
  /// In en, this message translates to:
  /// **'RETRY'**
  String get deathRetry;

  /// No description provided for @deathMenu.
  ///
  /// In en, this message translates to:
  /// **'MENU'**
  String get deathMenu;

  /// No description provided for @deathRanks.
  ///
  /// In en, this message translates to:
  /// **'RANKS'**
  String get deathRanks;

  /// No description provided for @deathShare.
  ///
  /// In en, this message translates to:
  /// **'SHARE'**
  String get deathShare;

  /// No description provided for @deathShareText.
  ///
  /// In en, this message translates to:
  /// **'I ran {distance}m through {biome} in Mirror Runners!'**
  String deathShareText(int distance, String biome);

  /// No description provided for @deathGoPro.
  ///
  /// In en, this message translates to:
  /// **'GO PRO'**
  String get deathGoPro;

  /// No description provided for @deathContinueQ.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE?'**
  String get deathContinueQ;

  /// No description provided for @deathFreeRevive.
  ///
  /// In en, this message translates to:
  /// **'FREE REVIVE'**
  String get deathFreeRevive;

  /// No description provided for @deathProRevivesToday.
  ///
  /// In en, this message translates to:
  /// **'{remaining} / 3 TODAY'**
  String deathProRevivesToday(int remaining);

  /// No description provided for @deathResetsAtMidnight.
  ///
  /// In en, this message translates to:
  /// **'RESETS AT MIDNIGHT'**
  String get deathResetsAtMidnight;

  /// No description provided for @deathWatchAd.
  ///
  /// In en, this message translates to:
  /// **'WATCH AD'**
  String get deathWatchAd;

  /// No description provided for @deathContinue.
  ///
  /// In en, this message translates to:
  /// **'CONTINUE'**
  String get deathContinue;

  /// No description provided for @deathCoinCost.
  ///
  /// In en, this message translates to:
  /// **'{cost} COINS'**
  String deathCoinCost(int cost);

  /// No description provided for @skinTitle.
  ///
  /// In en, this message translates to:
  /// **'SKINS'**
  String get skinTitle;

  /// No description provided for @skinSectionCreator.
  ///
  /// In en, this message translates to:
  /// **'SKIN CREATOR'**
  String get skinSectionCreator;

  /// No description provided for @skinSectionCollection.
  ///
  /// In en, this message translates to:
  /// **'COLLECTION'**
  String get skinSectionCollection;

  /// No description provided for @skinCreate.
  ///
  /// In en, this message translates to:
  /// **'CREATE'**
  String get skinCreate;

  /// No description provided for @skinCreateNewSkin.
  ///
  /// In en, this message translates to:
  /// **'NEW SKIN'**
  String get skinCreateNewSkin;

  /// No description provided for @skinGoPro.
  ///
  /// In en, this message translates to:
  /// **'GO PRO'**
  String get skinGoPro;

  /// No description provided for @skinEquipped.
  ///
  /// In en, this message translates to:
  /// **'EQUIPPED'**
  String get skinEquipped;

  /// No description provided for @skinTapToEquip.
  ///
  /// In en, this message translates to:
  /// **'TAP TO EQUIP'**
  String get skinTapToEquip;

  /// No description provided for @skinEdit.
  ///
  /// In en, this message translates to:
  /// **'EDIT'**
  String get skinEdit;

  /// No description provided for @skinBuy.
  ///
  /// In en, this message translates to:
  /// **'BUY'**
  String get skinBuy;

  /// No description provided for @skinNotEnough.
  ///
  /// In en, this message translates to:
  /// **'NOT ENOUGH'**
  String get skinNotEnough;

  /// No description provided for @skinCancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get skinCancel;

  /// No description provided for @skinUnlockNamed.
  ///
  /// In en, this message translates to:
  /// **'UNLOCK {name}'**
  String skinUnlockNamed(String name);

  /// No description provided for @skinBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance: {current} → {next}'**
  String skinBalance(int current, int next);

  /// No description provided for @skinNotEnoughCoins.
  ///
  /// In en, this message translates to:
  /// **'Not enough coins'**
  String get skinNotEnoughCoins;

  /// No description provided for @skinPurchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed'**
  String get skinPurchaseFailed;

  /// No description provided for @builderTitle.
  ///
  /// In en, this message translates to:
  /// **'SKIN CREATOR'**
  String get builderTitle;

  /// No description provided for @builderEditTitle.
  ///
  /// In en, this message translates to:
  /// **'EDIT SKIN'**
  String get builderEditTitle;

  /// No description provided for @builderUpdate.
  ///
  /// In en, this message translates to:
  /// **'UPDATE'**
  String get builderUpdate;

  /// No description provided for @builderSave.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get builderSave;

  /// No description provided for @builderLockedDescription.
  ///
  /// In en, this message translates to:
  /// **'Create custom skins with your own colors and decorations.'**
  String get builderLockedDescription;

  /// No description provided for @builderGoProIncluded.
  ///
  /// In en, this message translates to:
  /// **'GO PRO — INCLUDED'**
  String get builderGoProIncluded;

  /// No description provided for @builderLeftColor.
  ///
  /// In en, this message translates to:
  /// **'LEFT COLOR'**
  String get builderLeftColor;

  /// No description provided for @builderRightColor.
  ///
  /// In en, this message translates to:
  /// **'RIGHT COLOR'**
  String get builderRightColor;

  /// No description provided for @builderHead.
  ///
  /// In en, this message translates to:
  /// **'HEAD'**
  String get builderHead;

  /// No description provided for @builderFace.
  ///
  /// In en, this message translates to:
  /// **'FACE'**
  String get builderFace;

  /// No description provided for @builderName.
  ///
  /// In en, this message translates to:
  /// **'NAME'**
  String get builderName;

  /// No description provided for @builderDefaultName.
  ///
  /// In en, this message translates to:
  /// **'CUSTOM {number}'**
  String builderDefaultName(int number);

  /// No description provided for @builderDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'DELETE SKIN'**
  String get builderDeleteTitle;

  /// No description provided for @builderDelete.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get builderDelete;

  /// No description provided for @builderCancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get builderCancel;

  /// No description provided for @builderDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'DISCARD CHANGES?'**
  String get builderDiscardTitle;

  /// No description provided for @builderDiscardMessage.
  ///
  /// In en, this message translates to:
  /// **'Your unsaved changes will be lost.'**
  String get builderDiscardMessage;

  /// No description provided for @builderDiscard.
  ///
  /// In en, this message translates to:
  /// **'DISCARD'**
  String get builderDiscard;

  /// No description provided for @builderMaxSkinsReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum {count} custom skins reached.'**
  String builderMaxSkinsReached(int count);

  /// No description provided for @proPurchaseFailed.
  ///
  /// In en, this message translates to:
  /// **'Purchase failed. Please try again.'**
  String get proPurchaseFailed;

  /// No description provided for @proPurchasesRestored.
  ///
  /// In en, this message translates to:
  /// **'Purchases restored.'**
  String get proPurchasesRestored;

  /// No description provided for @proRestoreComplete.
  ///
  /// In en, this message translates to:
  /// **'Restore complete.'**
  String get proRestoreComplete;

  /// No description provided for @proTitle.
  ///
  /// In en, this message translates to:
  /// **'MIRROR RUNNERS PRO'**
  String get proTitle;

  /// No description provided for @proSubtitle.
  ///
  /// In en, this message translates to:
  /// **'ONE TIME PURCHASE — FOREVER'**
  String get proSubtitle;

  /// No description provided for @proBenefitSkinCreatorLabel.
  ///
  /// In en, this message translates to:
  /// **'SKIN CREATOR'**
  String get proBenefitSkinCreatorLabel;

  /// No description provided for @proBenefitSkinCreatorDesc.
  ///
  /// In en, this message translates to:
  /// **'Design your own skins + unlock every skin'**
  String get proBenefitSkinCreatorDesc;

  /// No description provided for @proBenefitNoAdsLabel.
  ///
  /// In en, this message translates to:
  /// **'NO ADS'**
  String get proBenefitNoAdsLabel;

  /// No description provided for @proBenefitNoAdsDesc.
  ///
  /// In en, this message translates to:
  /// **'Remove all interstitial ads'**
  String get proBenefitNoAdsDesc;

  /// No description provided for @proBenefitFreeRevivesLabel.
  ///
  /// In en, this message translates to:
  /// **'FREE REVIVES'**
  String get proBenefitFreeRevivesLabel;

  /// No description provided for @proBenefitFreeRevivesDesc.
  ///
  /// In en, this message translates to:
  /// **'Free daily continues — no ads, no coins'**
  String get proBenefitFreeRevivesDesc;

  /// No description provided for @proPriceLine.
  ///
  /// In en, this message translates to:
  /// **'{price} · ONE TIME'**
  String proPriceLine(String price);

  /// No description provided for @proGoPro.
  ///
  /// In en, this message translates to:
  /// **'GO PRO'**
  String get proGoPro;

  /// No description provided for @proRestorePurchases.
  ///
  /// In en, this message translates to:
  /// **'RESTORE PURCHASES'**
  String get proRestorePurchases;

  /// No description provided for @proBest.
  ///
  /// In en, this message translates to:
  /// **'BEST'**
  String get proBest;

  /// No description provided for @proActive.
  ///
  /// In en, this message translates to:
  /// **'PRO ACTIVE'**
  String get proActive;

  /// No description provided for @perkTitle.
  ///
  /// In en, this message translates to:
  /// **'PERKS'**
  String get perkTitle;

  /// No description provided for @perkMaxed.
  ///
  /// In en, this message translates to:
  /// **'MAXED'**
  String get perkMaxed;

  /// No description provided for @perkBuy.
  ///
  /// In en, this message translates to:
  /// **'BUY'**
  String get perkBuy;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'STATISTICS'**
  String get statsTitle;

  /// No description provided for @statsTotalDistance.
  ///
  /// In en, this message translates to:
  /// **'TOTAL DISTANCE'**
  String get statsTotalDistance;

  /// No description provided for @statsGamesPlayed.
  ///
  /// In en, this message translates to:
  /// **'GAMES PLAYED'**
  String get statsGamesPlayed;

  /// No description provided for @statsPlaytime.
  ///
  /// In en, this message translates to:
  /// **'PLAYTIME'**
  String get statsPlaytime;

  /// No description provided for @statsFurthestBiome.
  ///
  /// In en, this message translates to:
  /// **'FURTHEST BIOME'**
  String get statsFurthestBiome;

  /// No description provided for @statsBestScore.
  ///
  /// In en, this message translates to:
  /// **'BEST SCORE'**
  String get statsBestScore;

  /// No description provided for @statsShare.
  ///
  /// In en, this message translates to:
  /// **'SHARE'**
  String get statsShare;

  /// No description provided for @statsUnknownBiome.
  ///
  /// In en, this message translates to:
  /// **'UNKNOWN'**
  String get statsUnknownBiome;

  /// No description provided for @statsMeters.
  ///
  /// In en, this message translates to:
  /// **'{value}m'**
  String statsMeters(int value);

  /// No description provided for @statsPlaytimeHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String statsPlaytimeHoursMinutes(int hours, int minutes);

  /// No description provided for @statsPlaytimeMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m'**
  String statsPlaytimeMinutes(int minutes);

  /// No description provided for @statsShareText.
  ///
  /// In en, this message translates to:
  /// **'Mirror Runners Stats:\n{best}m best · {games} games · {playtime} played · {biome} reached'**
  String statsShareText(int best, int games, String playtime, String biome);

  /// No description provided for @achTitle.
  ///
  /// In en, this message translates to:
  /// **'ACHIEVEMENTS'**
  String get achTitle;

  /// No description provided for @biomeForest.
  ///
  /// In en, this message translates to:
  /// **'FOREST'**
  String get biomeForest;

  /// No description provided for @biomeCity.
  ///
  /// In en, this message translates to:
  /// **'CITY'**
  String get biomeCity;

  /// No description provided for @biomeCrystal.
  ///
  /// In en, this message translates to:
  /// **'CRYSTAL'**
  String get biomeCrystal;

  /// No description provided for @biomeVolcano.
  ///
  /// In en, this message translates to:
  /// **'VOLCANO'**
  String get biomeVolcano;

  /// No description provided for @biomeDesert.
  ///
  /// In en, this message translates to:
  /// **'DESERT'**
  String get biomeDesert;

  /// No description provided for @biomeOcean.
  ///
  /// In en, this message translates to:
  /// **'OCEAN'**
  String get biomeOcean;

  /// No description provided for @biomeRuins.
  ///
  /// In en, this message translates to:
  /// **'RUINS'**
  String get biomeRuins;

  /// No description provided for @biomeSpace.
  ///
  /// In en, this message translates to:
  /// **'SPACE'**
  String get biomeSpace;

  /// No description provided for @biomeStorm.
  ///
  /// In en, this message translates to:
  /// **'STORM'**
  String get biomeStorm;

  /// No description provided for @biomeNeon.
  ///
  /// In en, this message translates to:
  /// **'NEON'**
  String get biomeNeon;

  /// No description provided for @biomeVoid.
  ///
  /// In en, this message translates to:
  /// **'VOID'**
  String get biomeVoid;

  /// No description provided for @skinNameDefault.
  ///
  /// In en, this message translates to:
  /// **'DEFAULT'**
  String get skinNameDefault;

  /// No description provided for @skinNameIce.
  ///
  /// In en, this message translates to:
  /// **'ICE'**
  String get skinNameIce;

  /// No description provided for @skinNameFire.
  ///
  /// In en, this message translates to:
  /// **'FIRE'**
  String get skinNameFire;

  /// No description provided for @skinNameGold.
  ///
  /// In en, this message translates to:
  /// **'GOLD'**
  String get skinNameGold;

  /// No description provided for @skinNameOcean.
  ///
  /// In en, this message translates to:
  /// **'OCEAN'**
  String get skinNameOcean;

  /// No description provided for @skinNameNeon.
  ///
  /// In en, this message translates to:
  /// **'NEON'**
  String get skinNameNeon;

  /// No description provided for @skinNameVoid.
  ///
  /// In en, this message translates to:
  /// **'VOID'**
  String get skinNameVoid;

  /// No description provided for @perkCoinMagnetTitle.
  ///
  /// In en, this message translates to:
  /// **'COIN MAGNET'**
  String get perkCoinMagnetTitle;

  /// No description provided for @perkCoinMagnetEffect.
  ///
  /// In en, this message translates to:
  /// **'Wider coin pickup range'**
  String get perkCoinMagnetEffect;

  /// No description provided for @perkCoinBonusTitle.
  ///
  /// In en, this message translates to:
  /// **'COIN BONUS'**
  String get perkCoinBonusTitle;

  /// No description provided for @perkCoinBonusEffect.
  ///
  /// In en, this message translates to:
  /// **'+1 coin per pickup'**
  String get perkCoinBonusEffect;

  /// No description provided for @perkPowerUpTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'POWER-UP TIME'**
  String get perkPowerUpTimeTitle;

  /// No description provided for @perkPowerUpTimeEffect.
  ///
  /// In en, this message translates to:
  /// **'Power-ups last longer'**
  String get perkPowerUpTimeEffect;

  /// No description provided for @perkHeadStartTitle.
  ///
  /// In en, this message translates to:
  /// **'HEAD START'**
  String get perkHeadStartTitle;

  /// No description provided for @perkHeadStartEffect.
  ///
  /// In en, this message translates to:
  /// **'Begin mid-combo (x1.2 / x1.5 / x2.0)'**
  String get perkHeadStartEffect;

  /// No description provided for @perkShieldTitle.
  ///
  /// In en, this message translates to:
  /// **'SHIELD'**
  String get perkShieldTitle;

  /// No description provided for @perkShieldEffect.
  ///
  /// In en, this message translates to:
  /// **'Start shielded; recharges every 400m'**
  String get perkShieldEffect;

  /// No description provided for @dailyChallengeDistance.
  ///
  /// In en, this message translates to:
  /// **'Reach {target}m in one run'**
  String dailyChallengeDistance(int target);

  /// No description provided for @dailyChallengeCoins.
  ///
  /// In en, this message translates to:
  /// **'Collect {target} coins in one run'**
  String dailyChallengeCoins(int target);

  /// No description provided for @dailyChallengeGames.
  ///
  /// In en, this message translates to:
  /// **'Play {target} runs today'**
  String dailyChallengeGames(int target);

  /// No description provided for @achCategoryDistance.
  ///
  /// In en, this message translates to:
  /// **'DISTANCE'**
  String get achCategoryDistance;

  /// No description provided for @achCategoryBiome.
  ///
  /// In en, this message translates to:
  /// **'BIOME'**
  String get achCategoryBiome;

  /// No description provided for @achCategoryGames.
  ///
  /// In en, this message translates to:
  /// **'GAMES'**
  String get achCategoryGames;

  /// No description provided for @achCategoryFirstRun.
  ///
  /// In en, this message translates to:
  /// **'FIRST RUN'**
  String get achCategoryFirstRun;

  /// No description provided for @achBiomeCrystal.
  ///
  /// In en, this message translates to:
  /// **'Crystal'**
  String get achBiomeCrystal;

  /// No description provided for @achBiomeVolcano.
  ///
  /// In en, this message translates to:
  /// **'Volcano'**
  String get achBiomeVolcano;

  /// No description provided for @achBiomeDesert.
  ///
  /// In en, this message translates to:
  /// **'Desert'**
  String get achBiomeDesert;

  /// No description provided for @achBiomeOcean.
  ///
  /// In en, this message translates to:
  /// **'Ocean'**
  String get achBiomeOcean;

  /// No description provided for @achBiomeNeon.
  ///
  /// In en, this message translates to:
  /// **'Neon'**
  String get achBiomeNeon;

  /// No description provided for @achBiomeVoid.
  ///
  /// In en, this message translates to:
  /// **'Void'**
  String get achBiomeVoid;

  /// No description provided for @achGamesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Games'**
  String achGamesCount(int count);

  /// No description provided for @achFirstRun.
  ///
  /// In en, this message translates to:
  /// **'1st Run'**
  String get achFirstRun;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
