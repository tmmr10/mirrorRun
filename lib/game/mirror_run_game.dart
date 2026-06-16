import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game_state.dart';
import 'components/background.dart';
import 'components/collectible.dart';
import 'components/collectible_spawner.dart';
import 'components/mirror_line.dart';
import 'components/obstacle.dart';
import 'components/obstacle_spawner.dart';
import 'components/event_system.dart';
import 'components/particle_system.dart';
import 'components/player.dart';
import 'components/power_up.dart';
import 'components/power_up_spawner.dart';
import 'components/blackout_overlay.dart';
import 'components/floating_text.dart';
import 'world/biome.dart';
import '../models/player_skin.dart';
import '../services/ad_service.dart';
import '../services/coins_service.dart';
import '../services/iap_service.dart';
import '../services/achievement_service.dart';
import '../services/audio_service.dart';
import '../services/highscore_service.dart';
import '../services/leaderboard_service.dart';
import '../services/settings_service.dart';
import '../services/skin_service.dart';
import '../services/analytics_service.dart';
import '../services/stats_service.dart';
import '../services/daily_challenge_service.dart';
import '../services/upgrade_service.dart';
import '../services/world_unlock_service.dart';

class MirrorRunGame extends FlameGame with KeyboardEvents {
  static const double vw = 440;
  /// Fixed design height. The playfield is a constant [vw] x [vh] box on EVERY
  /// device (uniform-fit + letterboxing), so vertical reaction time no longer
  /// depends on the screen aspect ratio — fair across iPhone, iPad and SE, which
  /// matters for the shared leaderboard.
  static double vh = 956; // dynamic, updated in onGameResize
  static double get groundY => vh - 160;

  /// The actual rendered zoom (uniform-fit min of width/height ratios), used to
  /// map screen-space drag deltas back into game coordinates under letterboxing.
  double _renderZoom = 1.0;
  double get renderZoom => _renderZoom;
  static const List<double> mirrorLanesL = [25, 110, 195];
  static const List<double> mirrorLanesR = [245, 330, 415];

  /// Free-movement bounds for the left player.
  static const double leftMinX = 25;
  static const double leftMaxX = 195;
  /// Mirrored bounds for the right player (used while sync-lock un-mirrors it).
  static const double rightMinX = vw - leftMaxX; // 245
  static const double rightMaxX = vw - leftMinX; // 415
  /// Fixed step for keyboard input.
  static const double _keyStep = 65;

  late HighscoreService highscoreService;
  late AdService adService;
  late SettingsService settingsService;
  late AudioService audioService;
  late CoinsService coinsService;
  late LeaderboardService leaderboardService;
  late StatsService statsService;
  late AchievementService achievementService;
  late SkinService skinService;
  late DailyChallengeService dailyChallengeService;
  late UpgradeService upgradeService;
  late WorldUnlockService worldUnlockService;

  /// True while the current run was started from a picked world (Free Play):
  /// such runs don't count toward leaderboard, highscore, daily or unlocks.
  bool _freePlayRun = false;
  bool get isFreePlayRun => _freePlayRun;

  /// In a picked-world (Free Play) run the displayed distance counts from 0
  /// (the world is just the starting scenery); internally [score] still tracks
  /// the absolute distance so the biome stays correct.
  int _scoreDisplayOffset = 0;

  /// Set after a run when the daily challenge was just completed (for UI feedback).
  final ValueNotifier<DailyRunResult?> dailyResultNotifier = ValueNotifier(null);

  /// Used by SkinSelector to pass edit index to SkinBuilder overlay.
  int? skinBuilderEditIndex;

  /// Optional preset values for SkinBuilder (used by screenshot tour).
  Map<String, dynamic>? skinBuilderPreset;

  PlayState playState = PlayState.menu;

  int debugStartScore = 0;
  bool screenshotMode = false;

  int score = 0;
  double speed = 1.4;
  double _frameAccumulator = 0;
  double _deathTimer = 0;
  static const double _deathDelay = 2.5;

  // Combo / Focus multiplier
  double comboMultiplier = 1.0;
  int _comboNearMisses = 0;
  double _scoreBaseAccumulator = 0; // accumulates base distance (speed/60 per tick)
  double _scoreBonusAccumulator = 0; // accumulates combo bonus on top
  double _runStartTime = 0;

  /// Combo tier thresholds (near-miss counts) → multipliers 1.2/1.5/2.0/3.0.
  static const List<int> _comboThresholds = [3, 6, 10, 15];
  /// Seconds without a near-miss before the combo loses one tier.
  static const double _comboDecaySeconds = 3.5;
  double _timeSinceNearMiss = 0;

  /// Cached current biome, refreshed once per frame (avoids per-obstacle lookups).
  BiomeData _currentBiome = BiomeManager.biomes[0];
  BiomeData get currentBiome => _currentBiome;

  final ValueNotifier<int> scoreNotifier = ValueNotifier(0);
  final ValueNotifier<String> biomeNotifier = ValueNotifier('FOREST');
  final ValueNotifier<int> bestNotifier = ValueNotifier(0);
  final ValueNotifier<bool> newRecordNotifier = ValueNotifier(false);
  final ValueNotifier<GameEvent?> eventNotifier = ValueNotifier(null);
  final ValueNotifier<String?> eventWarningNotifier = ValueNotifier(null);
  /// Incremented when an event ends, to trigger "NORMAL" flash.
  final ValueNotifier<int> eventEndNotifier = ValueNotifier(0);
  final ValueNotifier<List<SkinId>> newSkinsNotifier = ValueNotifier([]);
  final ValueNotifier<List<String>> newAchievementsNotifier = ValueNotifier([]);
  final ValueNotifier<double> comboNotifier = ValueNotifier(1.0);
  /// Flips true once, mid-run, when the player overtakes their previous best.
  final ValueNotifier<bool> beatRecordNotifier = ValueNotifier(false);
  int _runStartBest = 0;
  bool _beatRecordThisRun = false;

  Player? playerLeft;
  Player? playerRight;
  late Background background;
  late MirrorLine mirrorLine;
  late ObstacleSpawner spawner;
  late CollectibleSpawner collectibleSpawner;
  late ParticleSystem particleSystem;
  late EventSystem eventSystem;
  late FloatingTextLayer floatingText;
  int _lastBiomeIdx = -1;

  // Screen-shake on death
  double _shakeTimer = 0;
  static const double _shakeDuration = 0.32;
  final Random _shakeRng = Random();

  /// True while playing a Daily Seed Run (deterministic patterns for the day).
  bool seedRunActive = false;

  // Revive + invincibility state
  bool _reviveUsedThisRun = false;
  /// True once the additive progression of the current run has been recorded.
  /// Prevents the double-counting that happened when a revived run died again
  /// (each `die()` used to re-record stats/daily/achievements/unlocks).
  bool _runFinalized = false;
  double _invincibilityTimer = 0;
  static const double _invincibilityDuration = 2.0;

  // Power-up state
  late PowerUpSpawner powerUpSpawner;
  bool shieldActive = false;
  /// Perk: score at which the start-shield recharges (0 = no recharge pending).
  int _nextShieldRechargeScore = 0;
  static const int _shieldRechargeMeters = 400;
  double _syncLockTimer = 0;
  double _slowMoTimer = 0;
  double _foresightTimer = 0;
  static const double _syncLockDuration = 4.0;
  static const double _slowMoDuration = 3.5;
  // Longer than the others so it reliably overlaps a (relatively rare) PHANTOM.
  static const double _foresightDuration = 10.0;
  static const double _slowMoFactor = 0.55;
  bool get syncLockActive => _syncLockTimer > 0;
  bool get slowMoActive => _slowMoTimer > 0;
  /// True while Foresight reveals obstacles hidden by PHANTOM (read by Obstacle).
  bool get foresightActive => _foresightTimer > 0;
  bool get shieldUp => shieldActive;

  /// Currently-active power-ups, for the HUD indicator.
  final ValueNotifier<List<PowerUpType>> powerUpsNotifier = ValueNotifier([]);
  List<PowerUpType> _lastPowerUps = const [];

  /// Coin price to continue a run (alternative to ad/Pro revive).
  static const int reviveCoinCost = 50;
  bool get canRevive => playState == PlayState.dead && !_reviveUsedThisRun;
  bool get canAffordCoinRevive => coinsService.totalCoins >= reviveCoinCost;

  /// Spend coins to continue the run. Returns false if not allowed/affordable.
  Future<bool> reviveWithCoins() async {
    if (!canRevive || !canAffordCoinRevive) return false;
    final ok = await coinsService.spendCoins(reviveCoinCost);
    if (!ok) return false;
    // The state can change during the await (e.g. a keyboard restart). If we
    // can no longer revive, refund the coins instead of burning them.
    if (!canRevive) {
      await coinsService.addCoins(reviveCoinCost);
      return false;
    }
    revivePlayer(viaAd: false);
    return true;
  }
  bool get isInvincible => _invincibilityTimer > 0;
  double get invincibilityTimer => _invincibilityTimer;

  /// Optionally inject an already-initialized [SettingsService] (so the host
  /// MaterialApp can read the language override before the game finishes
  /// loading). When null, the game creates and initializes its own.
  final SettingsService? _injectedSettings;

  MirrorRunGame({SettingsService? settingsService})
      : _injectedSettings = settingsService,
        super();

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Fill the full screen width (no letterbox): the 440-wide playfield always
    // spans the device width; the vertical play space [vh] follows the aspect
    // ratio. [_renderZoom] is the real px-per-game-unit, used to map drag input.
    final zoom = size.x / vw;
    _renderZoom = zoom;
    camera.viewfinder.zoom = zoom;
    vh = size.y / zoom;
    _baseCameraPosition = Vector2.zero();
    if (_shakeTimer <= 0) {
      camera.viewfinder.position = _baseCameraPosition.clone();
    }
  }

  /// Camera position that centres the design box (recomputed on every resize).
  /// Screen-shake offsets are added on top of this.
  Vector2 _baseCameraPosition = Vector2.zero();

  @override
  Future<void> onLoad() async {
    debugPrint('>>> onLoad START');

    highscoreService = HighscoreService();
    await highscoreService.init();
    debugPrint('>>> highscore OK');

    if (_injectedSettings != null) {
      settingsService = _injectedSettings;
    } else {
      settingsService = SettingsService();
      await settingsService.init();
    }
    debugPrint('>>> settings OK');

    coinsService = CoinsService();
    await coinsService.init();
    debugPrint('>>> coins OK (total=${coinsService.totalCoins})');

    audioService = AudioService(settingsService);
    try {
      await audioService.init();
      debugPrint('>>> audio OK');
    } catch (e) {
      debugPrint('>>> audio FAILED: $e');
    }

    skinService = SkinService();
    await skinService.init();

    // Init IAP separately so purchases survive ad init failure
    final iapService = IapService();
    try {
      await iapService.init();
      debugPrint('>>> iap OK');
    } catch (e) {
      debugPrint('>>> iap FAILED: $e');
    }

    adService = AdService();
    try {
      await adService.init(skinService: skinService, iapService: iapService);
      debugPrint('>>> ad OK, isPro=${adService.isPro}');
    } catch (e) {
      debugPrint('>>> ad FAILED: $e');
    }

    // Migration: ensure existing Pro users have all preset skins unlocked
    if (adService.isPro) {
      await skinService.unlockAllPresets();
    }

    leaderboardService = LeaderboardService();

    statsService = StatsService();
    await statsService.init();

    achievementService = AchievementService();
    await achievementService.init();

    dailyChallengeService = DailyChallengeService();
    await dailyChallengeService.init();

    upgradeService = UpgradeService();
    await upgradeService.init();

    worldUnlockService = WorldUnlockService();
    await worldUnlockService.init();

    // Run GameCenter sign-in in background with timeout — don't block app startup.
    // Runs AFTER achievementService is initialized to avoid LateInitializationError.
    unawaited(
      leaderboardService.init()
          .timeout(const Duration(seconds: 5))
          .then((_) => achievementService.setSignedIn(leaderboardService.isSignedIn))
          .catchError((e) => debugPrint('>>> leaderboard init skipped: $e')),
    );

    debugPrint('>>> services done, setting up camera');
    camera.viewfinder.anchor = Anchor.topLeft;

    background = Background();
    mirrorLine = MirrorLine();
    spawner = ObstacleSpawner();
    powerUpSpawner = PowerUpSpawner();
    particleSystem = ParticleSystem();
    eventSystem = EventSystem();

    world.add(background);
    world.add(mirrorLine);
    world.add(particleSystem);
    world.add(BlackoutOverlay());
    floatingText = FloatingTextLayer();
    world.add(floatingText);

    overlays.add('MenuScreen');
  }

  /// Today's deterministic seed (same for all players on a calendar day).
  int _dailySeed() {
    final n = DateTime.now();
    return n.year * 10000 + n.month * 100 + n.day;
  }

  /// Starts a run at the given world (biome index). Index 0 = normal ranked
  /// run; any higher index is "Free Play" — it doesn't count toward
  /// leaderboard / highscore / daily / achievements / unlocks.
  void startGameAtWorld(int biomeIndex) {
    final idx = biomeIndex.clamp(0, BiomeManager.biomes.length - 1);
    overlays.remove('WorldPicker');
    startGame(startAtScore: BiomeManager.biomes[idx].startM, freePlay: idx > 0);
  }

  void startGame({bool seeded = false, int startAtScore = 0, bool freePlay = false}) {
    // If a previous run ended (dead) but the player chose to retry instead of
    // reviving, finalize that run's progression now (exactly once) before we
    // reset the run state — otherwise its best score would never be counted.
    if (playState == PlayState.dead && !_runFinalized) {
      _finalizeRunStats();
    }
    seedRunActive = seeded;
    _freePlayRun = freePlay;
    final seed = seeded ? _dailySeed() : null;
    playState = PlayState.countdown;
    _runStartTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final startScore =
        startAtScore > 0 ? startAtScore : (kDebugMode ? debugStartScore : 0);
    // Free Play: show distance run this session (from 0), not the world's
    // absolute start distance.
    _scoreDisplayOffset = freePlay ? startScore : 0;
    score = startScore;
    _frameAccumulator = 0;
    speed = 2.0;
    comboMultiplier = 1.0;
    _comboNearMisses = 0;
    _timeSinceNearMiss = 0;
    _scoreBaseAccumulator = startScore.toDouble();
    _scoreBonusAccumulator = 0;
    comboNotifier.value = 1.0;
    // Perk: head start — begin mid-combo (level 1/2/3 → x1.2/x1.5/x2.0), with a
    // grace window so the bought combo doesn't decay away in the first seconds.
    // Perks are disabled in Daily Seed Runs so the shared track stays fair.
    final headStart =
        seedRunActive ? 0 : upgradeService.startComboNearMisses;
    if (headStart > 0) {
      _comboNearMisses = headStart;
      _timeSinceNearMiss = -3.0;
      _updateComboTier();
    }
    _reviveUsedThisRun = false;
    _runFinalized = false;
    _invincibilityTimer = 0;
    _syncLockTimer = 0;
    _slowMoTimer = 0;
    _foresightTimer = 0;
    // Perk: start each run with a shield if owned (disabled in seed runs).
    shieldActive = !seedRunActive && upgradeService.startShield;
    _nextShieldRechargeScore = 0;
    _lastPowerUps = const [];
    powerUpsNotifier.value = const [];
    _updatePowerUpNotifier();
    floatingText.clearAll();
    _shakeTimer = 0;
    camera.viewfinder.position = _baseCameraPosition.clone();
    coinsService.resetSession();
    _lastBiomeIdx = BiomeManager.getBiomeIndex(startScore);
    _currentBiome = BiomeManager.getBiome(startScore);

    scoreNotifier.value = startScore - _scoreDisplayOffset;
    biomeNotifier.value = BiomeManager.getBiome(startScore).name;
    bestNotifier.value = highscoreService.getBest();
    _runStartBest = highscoreService.getBest();
    _beatRecordThisRun = false;
    beatRecordNotifier.value = false;
    newRecordNotifier.value = false;
    newSkinsNotifier.value = [];
    newAchievementsNotifier.value = [];
    eventNotifier.value = null;
    eventWarningNotifier.value = null;

    // Remove old components
    world.children.whereType<Player>().toList().forEach((p) => p.removeFromParent());
    world.children.whereType<Obstacle>().toList().forEach((o) => o.removeFromParent());

    if (world.children.contains(spawner)) {
      spawner.removeFromParent();
    }
    final oldEventSystem = eventSystem;
    if (world.children.contains(oldEventSystem)) {
      oldEventSystem.removeFromParent();
    }
    eventSystem = EventSystem(rng: seed != null ? Random(seed + 3) : null);
    eventSystem.reset();

    final startX = mirrorLanesL[1]; // center lane
    final skin = skinService.currentSkin;
    playerLeft = Player(
      side: 'left',
      color: skin.leftColor,
      glowColor: skin.leftGlow,
      targetX: startX,
    );
    playerRight = Player(
      side: 'right',
      color: skin.rightColor,
      glowColor: skin.rightGlow,
      targetX: vw - startX,
    );
    world.add(playerLeft!);
    world.add(playerRight!);

    spawner = ObstacleSpawner(rng: seed != null ? Random(seed) : null);
    world.add(spawner);
    world.add(eventSystem);

    // Remove old collectibles + spawner; create fresh
    world.children.whereType<Collectible>().toList().forEach((c) => c.removeFromParent());
    collectibleSpawner = CollectibleSpawner(rng: seed != null ? Random(seed + 1) : null);
    world.add(collectibleSpawner);

    // Power-ups: clear any leftovers and start a fresh spawner.
    world.children.whereType<PowerUp>().toList().forEach((p) => p.removeFromParent());
    if (world.children.contains(powerUpSpawner)) powerUpSpawner.removeFromParent();
    powerUpSpawner = PowerUpSpawner(rng: seed != null ? Random(seed + 2) : null);
    world.add(powerUpSpawner);

    background.spawnInitialDecos();
    background.clearAmbientParticles();

    overlays.remove('MenuScreen');
    overlays.remove('DeathScreen');
    overlays.add('HudOverlay');
    overlays.add('Countdown');
  }

  void endCountdown() {
    if (playState != PlayState.countdown) return;
    playState = PlayState.playing;
    overlays.remove('Countdown');
    unawaited(AnalyticsService.logGameStarted(skinName: skinService.currentSkin.name));
  }

  void die() {
    if (playState == PlayState.dead) return;
    playState = PlayState.dead;
    _deathTimer = 0;

    audioService.playDeath();
    if (settingsService.hapticEnabled) {
      HapticFeedback.heavyImpact();
    }
    _shakeTimer = _shakeDuration;

    particleSystem.spawnShards(Vector2(220, groundY));

    // Check highscore (update notifiers synchronously for immediate UI feedback)
    final best = highscoreService.getBest();
    final isNewRecord = !_freePlayRun && score > best;
    if (isNewRecord) {
      newRecordNotifier.value = true;
      bestNotifier.value = score;
    }
    adService.onDeath();

    final safeBiomeIdx = _lastBiomeIdx.clamp(0, BiomeManager.biomes.length - 1);
    final biomeName = BiomeManager.biomes[safeBiomeIdx].name;
    unawaited(AnalyticsService.logGameOver(
      score: score,
      biome: biomeName,
      durationSeconds: lastRunDuration.round(),
      wasNewRecord: isNewRecord,
    ));

    // Highscore feedback is idempotent (a max), so it can run on every death —
    // including a death that may still be revived. The *additive* progression
    // (stats / daily / coins / achievements / unlocks), however, must run only
    // once per run, at the final death (FIX: revive used to double-count it).
    _saveHighscoreIfNeeded(isNewRecord: isNewRecord);
    if (!canRevive) {
      // No revive possible anymore → this is the final death: finalize now so
      // the death screen shows the correct daily / new-skin / achievement state.
      _finalizeRunStats();
    }

    overlays.remove('HudOverlay');
    overlays.remove('Countdown');
    overlays.add('DeathScreen');
  }

  /// Persists the best score + submits to the leaderboard. Idempotent (a max),
  /// so it's safe to call on every death, even one that's later revived.
  void _saveHighscoreIfNeeded({required bool isNewRecord}) {
    if (_freePlayRun || !isNewRecord) return;
    unawaited(() async {
      try {
        await highscoreService.saveBest(score);
        unawaited(leaderboardService.submitScore(score));
      } catch (e, st) {
        debugPrint('_saveHighscoreIfNeeded error: $e\n$st');
      }
    }());
  }

  /// Records the run's additive progression exactly once. Called at the final
  /// death (when no revive is possible) or when leaving/retrying a dead run.
  void _finalizeRunStats() {
    if (_runFinalized) return;
    _runFinalized = true;
    unawaited(_recordRunAsync());
  }

  Future<void> _recordRunAsync() async {
    // Free Play (picked-world start): no progression is persisted at all, so
    // it can't game the leaderboard, highscore, daily, achievements or unlocks.
    if (_freePlayRun) return;
    try {
      await statsService.recordRun(
        distance: score,
        biomeIndex: _lastBiomeIdx,
        durationSeconds: lastRunDuration,
      );
      // Unlock worlds in the picker as they're reached naturally.
      unawaited(worldUnlockService.registerReached(statsService.furthestBiomeIndex));
      // Daily challenge + streak (record before awarding so run coins aren't
      // inflated by the reward itself).
      final daily = await dailyChallengeService.recordRun(
        distance: score,
        coinsThisRun: coinsService.sessionEarned,
      );
      final dailyCoins = daily.rewardEarned + daily.streakReward;
      if (dailyCoins > 0) {
        await coinsService.addCoins(dailyCoins);
      }
      dailyResultNotifier.value = daily;
      // Re-sync signed-in state in case GameCenter signed in late (background init)
      achievementService.setSignedIn(leaderboardService.isSignedIn);
      final newAchievements = await achievementService.checkAfterRun(
        runDistance: score,
        totalGames: statsService.totalGamesPlayed,
        currentBiome: _lastBiomeIdx,
      );
      if (newAchievements.isNotEmpty) {
        newAchievementsNotifier.value = newAchievements;
        for (final id in newAchievements) {
          unawaited(AnalyticsService.logAchievementUnlocked(achievementId: id));
        }
      }
      final newSkins = await skinService.checkUnlocks(statsService.furthestBiomeIndex);
      if (newSkins.isNotEmpty) {
        newSkinsNotifier.value = newSkins;
        for (final skinId in newSkins) {
          unawaited(AnalyticsService.logSkinUnlocked(skinName: skinId.name));
        }
      }
      // Update user properties
      unawaited(AnalyticsService.setTotalGames(statsService.totalGamesPlayed));
      final furthestIdx = statsService.furthestBiomeIndex
          .clamp(0, BiomeManager.biomes.length - 1);
      unawaited(AnalyticsService.setFurthestBiome(
        BiomeManager.biomes[furthestIdx].name,
      ));
    } catch (e, st) {
      debugPrint('_recordRunAsync error: $e\n$st');
    }
  }

  double get lastRunDuration =>
      DateTime.now().millisecondsSinceEpoch / 1000.0 - _runStartTime;

  void goToMenu() {
    // Leaving a dead run without reviving → finalize its progression once
    // (so the run still counts toward stats/daily/achievements/unlocks).
    if (playState == PlayState.dead && !_runFinalized) {
      _finalizeRunStats();
    }
    resumeEngine();
    playState = PlayState.menu;
    world.children.whereType<Player>().toList().forEach((p) => p.removeFromParent());
    world.children.whereType<Obstacle>().toList().forEach((o) => o.removeFromParent());
    world.children.whereType<Collectible>().toList().forEach((c) => c.removeFromParent());
    world.children.whereType<PowerUp>().toList().forEach((p) => p.removeFromParent());
    if (world.children.contains(spawner)) spawner.removeFromParent();
    if (world.children.contains(collectibleSpawner)) collectibleSpawner.removeFromParent();
    if (world.children.contains(powerUpSpawner)) powerUpSpawner.removeFromParent();
    if (world.children.contains(eventSystem)) eventSystem.removeFromParent();
    eventSystem.reset();
    eventNotifier.value = null;
    eventWarningNotifier.value = null;
    shieldActive = false;
    _nextShieldRechargeScore = 0;
    _syncLockTimer = 0;
    _slowMoTimer = 0;
    _foresightTimer = 0;
    _lastPowerUps = const [];
    powerUpsNotifier.value = const [];
    floatingText.clearAll();
    _shakeTimer = 0;
    camera.viewfinder.position = _baseCameraPosition.clone();
    seedRunActive = false;
    playerLeft = null;
    playerRight = null;
    // Reset run state so menu shows clean values
    score = 0;
    _scoreDisplayOffset = 0;
    _frameAccumulator = 0;
    speed = 2.0;
    comboMultiplier = 1.0;
    _comboNearMisses = 0;
    _timeSinceNearMiss = 0;
    _scoreBaseAccumulator = 0;
    _scoreBonusAccumulator = 0;
    _lastBiomeIdx = 0;
    _currentBiome = BiomeManager.biomes[0];
    scoreNotifier.value = 0;
    comboNotifier.value = 1.0;
    biomeNotifier.value = BiomeManager.biomes[0].name;
    background.clearAmbientParticles();

    // Remove every known overlay (except MenuScreen, added fresh below) so no
    // screen leaks back onto the menu regardless of where we came from.
    for (final key in _knownOverlayKeys) {
      overlays.remove(key);
    }
    overlays.add('MenuScreen');
  }

  /// All overlay keys the game manages — used to clear state on return to menu.
  static const List<String> _knownOverlayKeys = [
    'HudOverlay',
    'DeathScreen',
    'BiomeBanner',
    'Countdown',
    'SettingsScreen',
    'StatsScreen',
    'SkinSelector',
    'ProScreen',
    'PerkScreen',
    'AchievementsScreen',
    'SkinBuilder',
    'WorldPicker',
    'DebugOverlay',
    'MenuScreen',
  ];

  /// Called by SwipeController with the screen-space drag delta.
  void onDrag(double screenDx) {
    if (playState != PlayState.playing && playState != PlayState.countdown) return;

    // Under uniform-fit + letterboxing the playfield is scaled by [renderZoom]
    // (not by screenWidth/vw, which was only correct when the field filled the
    // full width). Dividing by the actual zoom keeps a finger-swipe of N screen
    // px move the player by the same N/zoom game-px on every device — including
    // a pillarboxed iPad, where the field is narrower than the screen.
    final z = _renderZoom > 0 ? _renderZoom : 1.0;
    final gameDx = screenDx / z;
    _movePlayer(gameDx);
  }

  /// Move player by a game-coordinate delta (keyboard or drag).
  void _movePlayer(double dx) {
    final pl = playerLeft;
    final pr = playerRight;
    if (pl == null || pr == null) return;

    // Mirror swap inverts controls
    final d = eventSystem.mirrorSwapped ? -dx : dx;

    pl.targetX = (pl.targetX + d).clamp(leftMinX, leftMaxX);
    if (syncLockActive) {
      // Controls un-mirrored: the right runner moves the same screen direction.
      pr.targetX = (pr.targetX + d).clamp(rightMinX, rightMaxX);
    } else {
      pr.targetX = vw - pl.targetX;
    }
  }

  bool get canRetry => playState == PlayState.dead && _deathTimer >= _deathDelay;

  @override
  void update(double dt) {
    super.update(dt);
    if (playState == PlayState.dead) {
      _deathTimer += dt.clamp(0, 0.5);
    }

    // Death screen-shake — decays the camera offset back to the centred base.
    if (_shakeTimer > 0) {
      _shakeTimer -= dt;
      if (_shakeTimer <= 0) {
        camera.viewfinder.position = _baseCameraPosition.clone();
      } else {
        final mag = (_shakeTimer / _shakeDuration) * 7.0;
        camera.viewfinder.position = _baseCameraPosition +
            Vector2(
              (_shakeRng.nextDouble() - 0.5) * mag,
              (_shakeRng.nextDouble() - 0.5) * mag,
            );
      }
    }

    if (playState != PlayState.playing && playState != PlayState.countdown) return;

    _frameAccumulator += dt;
    // Clamp accumulated time so a long hang (GC/biome load) can't trigger a
    // catch-up spiral; bounds the number of ticks per frame.
    if (_frameAccumulator > 0.25) _frameAccumulator = 0.25;
    const step = 1.0 / 60.0;
    while (_frameAccumulator >= step) {
      _frameAccumulator -= step;
      _tick(step);
    }

    scoreNotifier.value = score - _scoreDisplayOffset;
    _currentBiome = BiomeManager.getBiome(score);

    // In-run record cue: fire once when overtaking the previous best.
    if (!_freePlayRun && !_beatRecordThisRun && _runStartBest > 0 && score > _runStartBest) {
      _beatRecordThisRun = true;
      beatRecordNotifier.value = true;
    }

    // Biome change (display + transition), once per frame
    final curIdx = BiomeManager.getBiomeIndex(score);
    if (curIdx > _lastBiomeIdx) {
      final previousIdx = _lastBiomeIdx;
      _lastBiomeIdx = curIdx;
      final newBiome = BiomeManager.biomes[curIdx];
      biomeNotifier.value = newBiome.name;
      audioService.playBiomeTransition();
      overlays.add('BiomeBanner');
      background.startTransition(newBiome.lineL, newBiome.lineR);
      // Only log biome_reached when actually progressing forward (not on first biome at run start)
      if (previousIdx >= 0) {
        unawaited(AnalyticsService.logBiomeReached(biomeName: newBiome.name, score: score));
      }
    }
  }

  /// One fixed simulation step. World movement + collision run in lockstep so a
  /// frame spike can never let an obstacle teleport past the player (tunneling).
  void _tick(double step) {
    // Only simulate while actually running — no score/speed creep during the
    // countdown (the run should start exactly at the start score).
    if (playState != PlayState.playing) return;

    // Accumulate score at the current speed (no retroactive speed jumps).
    _scoreBaseAccumulator += speed * step;
    if (comboMultiplier > 1.0) {
      _scoreBonusAccumulator += speed * (comboMultiplier - 1.0) * step;
    }
    // Single floor on the sum avoids the ±1 flicker of flooring each part.
    score = (_scoreBaseAccumulator + _scoreBonusAccumulator).floor();
    // Primary ramp caps at 6.0 (≈1000m); a gentle late-game creep keeps the
    // pressure rising afterwards instead of plateauing.
    speed = score <= 1000
        ? 2.0 + score * 0.004
        : min(7.5, 6.0 + (score - 1000) * 0.0006);

    // Perk: recharging shield regrows once the player covers enough distance.
    if (!shieldActive &&
        _nextShieldRechargeScore > 0 &&
        score >= _nextShieldRechargeScore) {
      shieldActive = true;
      _nextShieldRechargeScore = 0;
      _updatePowerUpNotifier();
      if (settingsService.hapticEnabled) HapticFeedback.lightImpact();
    }

    if (_invincibilityTimer > 0) {
      _invincibilityTimer = (_invincibilityTimer - step).clamp(0.0, double.infinity);
    }

    // Power-up effect timers
    if (_syncLockTimer > 0) {
      _syncLockTimer = (_syncLockTimer - step).clamp(0.0, double.infinity);
      if (_syncLockTimer == 0) {
        // Re-mirror the right player when sync-lock expires.
        final pl = playerLeft;
        final pr = playerRight;
        if (pl != null && pr != null) pr.targetX = vw - pl.targetX;
      }
    }
    if (_slowMoTimer > 0) {
      _slowMoTimer = (_slowMoTimer - step).clamp(0.0, double.infinity);
    }
    if (_foresightTimer > 0) {
      _foresightTimer = (_foresightTimer - step).clamp(0.0, double.infinity);
    }
    _updatePowerUpNotifier();

    // Drive the event system in the fixed step BEFORE scrolling so this tick's
    // desync factors are applied to this tick's movement (deterministic timing).
    eventSystem.fixedUpdate(step);

    // Advance the scrolling world by this tick's distance, then check collisions
    // at the new position — same step, so nothing can pass through unchecked.
    // Slow-mo scales the whole world; desync scales each side independently.
    final base = speed * 60 * step * (slowMoActive ? _slowMoFactor : 1.0);
    final moveL = base * eventSystem.desyncLeftFactor;
    final moveR = base * eventSystem.desyncRightFactor;
    for (final o in world.children.whereType<Obstacle>()) {
      o.scrollPos += o.side == 'left' ? moveL : moveR;
    }
    for (final c in world.children.whereType<Collectible>()) {
      c.scrollPos += c.side == 'left' ? moveL : moveR;
    }
    for (final p in world.children.whereType<PowerUp>()) {
      p.scrollPos += p.side == 'left' ? moveL : moveR;
    }
    _checkCollisions();
    _checkCollectibles();
    _checkPowerUps();

    // Spawners run in the fixed step too, so spawn density / RNG draws are
    // framerate-independent and deterministic for a given daily seed. Run after
    // collisions so this tick's checks see the existing field, not new spawns.
    spawner.fixedUpdate(step);
    collectibleSpawner.fixedUpdate(step);
    powerUpSpawner.fixedUpdate(step);

    // Combo decay: lose one tier after sustained time without a near-miss.
    _timeSinceNearMiss += step;
    if (comboMultiplier > 1.0 && _timeSinceNearMiss >= _comboDecaySeconds) {
      _timeSinceNearMiss = 0;
      _decayCombo();
    }
  }

  void _updatePowerUpNotifier() {
    final active = <PowerUpType>[];
    if (shieldActive) active.add(PowerUpType.shield);
    if (syncLockActive) active.add(PowerUpType.syncLock);
    if (slowMoActive) active.add(PowerUpType.slowMo);
    if (foresightActive) active.add(PowerUpType.foresight);
    if (active.length != _lastPowerUps.length ||
        !_samePowerUps(active, _lastPowerUps)) {
      _lastPowerUps = active;
      powerUpsNotifier.value = active;
    }
  }

  bool _samePowerUps(List<PowerUpType> a, List<PowerUpType> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _checkPowerUps() {
    final pickups = world.children.whereType<PowerUp>().toList();
    for (final pu in pickups) {
      if (pu.collected) continue;
      final player = pu.side == 'left' ? playerLeft : playerRight;
      if (player == null || player.dead) continue;
      if (player.getPickupRect().overlaps(pu.getPickupRect())) {
        pu.collected = true;
        _activatePowerUp(pu.type);
        particleSystem.burst(Vector2(pu.laneCenterX, pu.scrollPos), pu.type.color);
        if (settingsService.hapticEnabled) {
          HapticFeedback.mediumImpact();
        }
        pu.removeFromParent();
      }
    }
  }

  void _activatePowerUp(PowerUpType type) {
    // Perk: longer power-ups (disabled in seed runs for fairness).
    final mult = seedRunActive ? 1.0 : upgradeService.powerUpDurationMult;
    switch (type) {
      case PowerUpType.shield:
        shieldActive = true;
      case PowerUpType.syncLock:
        _syncLockTimer = _syncLockDuration * mult;
      case PowerUpType.slowMo:
        _slowMoTimer = _slowMoDuration * mult;
      case PowerUpType.foresight:
        _foresightTimer = _foresightDuration * mult;
    }
    _updatePowerUpNotifier();
    unawaited(AnalyticsService.logEventTriggered(eventType: 'powerup_${type.name}'));
  }

  /// Drops the combo by exactly one tier (used by the decay timer).
  void _decayCombo() {
    int tier = 0;
    for (final t in _comboThresholds) {
      if (_comboNearMisses >= t) tier++;
    }
    if (tier == 0) {
      _comboNearMisses = 0;
    } else {
      // One below the current tier's threshold → recomputes to the tier below.
      _comboNearMisses = _comboThresholds[tier - 1] - 1;
    }
    _updateComboTier();
  }

  /// Resolves a lethal overlap: a shield absorbs it (with a brief grace
  /// window), otherwise the run ends.
  void _resolveHit(Player p, Color color) {
    final burstPos = Vector2(p.position.x, p.position.y - Player.ph / 2);
    if (shieldActive) {
      shieldActive = false;
      _invincibilityTimer = 0.8; // short grace so the same wave can't re-hit
      // Perk: a recharging shield regrows after some distance (not in seed runs).
      if (!seedRunActive && upgradeService.startShield) {
        _nextShieldRechargeScore = score + _shieldRechargeMeters;
      }
      _updatePowerUpNotifier();
      particleSystem.burst(burstPos, color);
      if (settingsService.hapticEnabled) {
        HapticFeedback.mediumImpact();
      }
      return;
    }
    p.dead = true;
    particleSystem.burst(burstPos, color);
    die();
  }

  void _checkCollisions() {
    // During invincibility (post-revive/shield grace) only the lethal hit is
    // skipped — near-misses still count so the combo doesn't silently freeze.
    final obstacles = world.children.whereType<Obstacle>().toList();
    // In the mirrored game a near-miss can happen on BOTH sides in the same
    // step. Count each side independently (each obstacle still only once, via
    // its `nearMissed` flag) so the combo rate isn't systematically halved.
    Player? nearMissLeft;
    Obstacle? nearMissLeftObs;
    Player? nearMissRight;
    Obstacle? nearMissRightObs;

    for (final obs in obstacles) {
      if (obs.side == 'left' && playerLeft != null && !playerLeft!.dead) {
        // Hit handling unchanged: the first lethal overlap ends the step.
        if (!isInvincible && _checkOverlap(playerLeft!, obs)) {
          _resolveHit(playerLeft!, skinService.currentSkin.leftColor);
          return;
        }
        if (nearMissLeft == null && !obs.nearMissed && _checkNearMiss(playerLeft!, obs)) {
          nearMissLeft = playerLeft;
          nearMissLeftObs = obs;
        }
      }
      if (obs.side == 'right' && playerRight != null && !playerRight!.dead) {
        if (!isInvincible && _checkOverlap(playerRight!, obs)) {
          _resolveHit(playerRight!, skinService.currentSkin.rightColor);
          return;
        }
        if (nearMissRight == null && !obs.nearMissed && _checkNearMiss(playerRight!, obs)) {
          nearMissRight = playerRight;
          nearMissRightObs = obs;
        }
      }
    }

    if (nearMissLeft != null && nearMissLeftObs != null) {
      _registerNearMiss(nearMissLeft, nearMissLeftObs);
    }
    if (nearMissRight != null && nearMissRightObs != null) {
      _registerNearMiss(nearMissRight, nearMissRightObs);
    }
  }

  /// Applies one near-miss: marks the obstacle, flashes the player, bumps the
  /// combo. Called per side so both sides can score in the same step.
  void _registerNearMiss(Player player, Obstacle obstacle) {
    obstacle.nearMissed = true; // prevent retrigger for same obstacle
    player.nearMissFlash = 1.0;
    if (settingsService.hapticEnabled) {
      HapticFeedback.lightImpact();
    }
    floatingText.spawn(
      'NEAR',
      Vector2(player.position.x, player.position.y - Player.ph),
      const Color(0xFF44DDFF),
    );
    _comboNearMisses++;
    _timeSinceNearMiss = 0; // refresh the decay window
    _updateComboTier();
  }

  /// Coins per pickup from the combo tier — one step per tier (1..5) so every
  /// combo level is rewarded (unlike the old round() which made x1.2 and x2.0
  /// give the same as their neighbours).
  int _comboCoinMultiplier() {
    if (comboMultiplier >= 3.0) return 5;
    if (comboMultiplier >= 2.0) return 4;
    if (comboMultiplier >= 1.5) return 3;
    if (comboMultiplier >= 1.2) return 2;
    return 1;
  }

  void _updateComboTier() {
    double newMultiplier;
    if (_comboNearMisses >= 15) {
      newMultiplier = 3.0;
    } else if (_comboNearMisses >= 10) {
      newMultiplier = 2.0;
    } else if (_comboNearMisses >= 6) {
      newMultiplier = 1.5;
    } else if (_comboNearMisses >= 3) {
      newMultiplier = 1.2;
    } else {
      newMultiplier = 1.0;
    }
    if (newMultiplier != comboMultiplier) {
      final increased = newMultiplier > comboMultiplier;
      comboMultiplier = newMultiplier;
      comboNotifier.value = newMultiplier;
      if (increased) audioService.playComboMilestone();
    }
  }

  bool _checkOverlap(Player p, Obstacle o) {
    return p.getHitRect().overlaps(o.getHitRect());
  }

  bool _checkNearMiss(Player p, Obstacle o) {
    final pRect = p.getHitRect();
    final oRect = o.getHitRect();
    // Must vertically overlap (obstacle currently passing through player's row)
    if (oRect.bottom < pRect.top || oRect.top > pRect.bottom) return false;
    // Horizontal-only near-miss: within 15px to the side but not overlapping
    final expandedP = Rect.fromLTWH(
      pRect.left - 15, pRect.top,
      pRect.width + 30, pRect.height,
    );
    return expandedP.overlaps(oRect) && !pRect.overlaps(oRect);
  }

  void _checkCollectibles() {
    final collectibles = world.children.whereType<Collectible>().toList();
    for (final coll in collectibles) {
      if (coll.collected) continue;
      final player = coll.side == 'left' ? playerLeft : playerRight;
      if (player == null || player.dead) continue;

      // Perk: coin magnet widens the pickup range (disabled in seed runs).
      final pad = seedRunActive ? 0.0 : upgradeService.coinMagnetPadding;
      final pRect = pad > 0
          ? player.getPickupRect().inflate(pad)
          : player.getPickupRect();
      if (pRect.overlaps(coll.getPickupRect())) {
        coll.collected = true;
        // Coin value steps cleanly with each combo tier (1/2/3/4/5) so every
        // tier-up is felt, plus the coin-bonus perk.
        final value = _comboCoinMultiplier() +
            (seedRunActive ? 0 : upgradeService.coinBonusPerPickup);
        // Free Play (picked world) doesn't credit coins — otherwise unlocking a
        // late world once would enable an endless coin farm.
        if (!_freePlayRun) unawaited(coinsService.addCoins(value));
        particleSystem.burstCoin(Vector2(coll.laneCenterX, coll.scrollPos));
        floatingText.spawn(
          '+$value',
          Vector2(coll.laneCenterX, coll.scrollPos),
          const Color(0xFFFFD700),
        );
        if (settingsService.hapticEnabled) {
          HapticFeedback.selectionClick();
        }
        unawaited(AnalyticsService.logCoinCollected(total: coinsService.totalCoins));
        coll.removeFromParent();
      }
    }
  }

  void revivePlayer({required bool viaAd}) {
    if (playState != PlayState.dead || _reviveUsedThisRun) return;

    _reviveUsedThisRun = true;
    _invincibilityTimer = _invincibilityDuration;
    playState = PlayState.playing;
    _deathTimer = 0;

    // Players are still in the world, just flagged dead — revive them
    playerLeft?.dead = false;
    playerRight?.dead = false;

    // Clear obstacles near the player to give a safe window after revive
    final obstacles = world.children.whereType<Obstacle>().toList();
    for (final o in obstacles) {
      if (o.scrollPos > groundY - 200 && o.scrollPos < groundY + 80) {
        o.removeFromParent();
      }
    }

    // Reset any event that was active at death — otherwise inverted controls
    // (mirror swap), desync speeds or a blackout would persist after reviving.
    eventSystem.reset();
    eventNotifier.value = null;
    eventWarningNotifier.value = null;

    // Clear active power-up effects too — a lingering sync-lock would leave the
    // controls desynced against the just re-mirrored players.
    _syncLockTimer = 0;
    _slowMoTimer = 0;
    _foresightTimer = 0;
    _updatePowerUpNotifier();

    // Re-mirror the right player in case sync-lock/swap left it desynced.
    final pl = playerLeft;
    final pr = playerRight;
    if (pl != null && pr != null) pr.targetX = vw - pl.targetX;

    // We're continuing the run — clear "new record" banner state
    newRecordNotifier.value = false;

    overlays.remove('DeathScreen');
    overlays.add('HudOverlay');
    resumeEngine();

    if (viaAd) {
      unawaited(AnalyticsService.logReviveUsedWithAd(score: score));
    } else {
      unawaited(AnalyticsService.logReviveUsedFreePro(score: score));
    }
  }

  @override
  KeyEventResult onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (playState == PlayState.menu) {
      if (event.logicalKey == LogicalKeyboardKey.space ||
          event.logicalKey == LogicalKeyboardKey.arrowUp) {
        startGame();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (playState == PlayState.dead) {
      if (canRetry &&
          (event.logicalKey == LogicalKeyboardKey.space ||
           event.logicalKey == LogicalKeyboardKey.enter ||
           event.logicalKey == LogicalKeyboardKey.arrowUp)) {
        startGame();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.keyA) {
      _movePlayer(-_keyStep);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.keyD) {
      _movePlayer(_keyStep);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }
}
