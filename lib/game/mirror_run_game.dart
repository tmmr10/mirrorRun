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

class MirrorRunGame extends FlameGame with KeyboardEvents {
  static const double vw = 440;
  static double vh = 956; // dynamic, updated in onGameResize
  static double get groundY => vh - 160;
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
  int _lastBiomeIdx = -1;

  // Revive + invincibility state
  bool _reviveUsedThisRun = false;
  double _invincibilityTimer = 0;
  static const double _invincibilityDuration = 2.0;

  // Power-up state
  late PowerUpSpawner powerUpSpawner;
  bool shieldActive = false;
  double _syncLockTimer = 0;
  double _slowMoTimer = 0;
  static const double _syncLockDuration = 4.0;
  static const double _slowMoDuration = 3.5;
  static const double _slowMoFactor = 0.55;
  bool get syncLockActive => _syncLockTimer > 0;
  bool get slowMoActive => _slowMoTimer > 0;
  bool get shieldUp => shieldActive;

  /// Currently-active power-ups, for the HUD indicator.
  final ValueNotifier<List<PowerUpType>> powerUpsNotifier = ValueNotifier([]);
  List<PowerUpType> _lastPowerUps = const [];

  bool get canRevive => playState == PlayState.dead && !_reviveUsedThisRun;
  bool get isInvincible => _invincibilityTimer > 0;
  double get invincibilityTimer => _invincibilityTimer;

  MirrorRunGame() : super();

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final zoom = size.x / vw;
    camera.viewfinder.zoom = zoom;
    vh = size.y / zoom;
  }

  @override
  Future<void> onLoad() async {
    debugPrint('>>> onLoad START');

    highscoreService = HighscoreService();
    await highscoreService.init();
    debugPrint('>>> highscore OK');

    settingsService = SettingsService();
    await settingsService.init();
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

    overlays.add('MenuScreen');
  }

  void startGame() {
    playState = PlayState.countdown;
    _runStartTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final startScore = kDebugMode ? debugStartScore : 0;
    score = startScore;
    _frameAccumulator = 0;
    speed = 2.0;
    comboMultiplier = 1.0;
    _comboNearMisses = 0;
    _timeSinceNearMiss = 0;
    _scoreBaseAccumulator = startScore.toDouble();
    _scoreBonusAccumulator = 0;
    comboNotifier.value = 1.0;
    _reviveUsedThisRun = false;
    _invincibilityTimer = 0;
    shieldActive = false;
    _syncLockTimer = 0;
    _slowMoTimer = 0;
    _lastPowerUps = const [];
    powerUpsNotifier.value = const [];
    coinsService.resetSession();
    _lastBiomeIdx = BiomeManager.getBiomeIndex(startScore);
    _currentBiome = BiomeManager.getBiome(startScore);

    scoreNotifier.value = startScore;
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
    eventSystem = EventSystem();
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

    spawner = ObstacleSpawner();
    world.add(spawner);
    world.add(eventSystem);

    // Remove old collectibles + spawner; create fresh
    world.children.whereType<Collectible>().toList().forEach((c) => c.removeFromParent());
    collectibleSpawner = CollectibleSpawner();
    world.add(collectibleSpawner);

    // Power-ups: clear any leftovers and start a fresh spawner.
    world.children.whereType<PowerUp>().toList().forEach((p) => p.removeFromParent());
    if (world.children.contains(powerUpSpawner)) powerUpSpawner.removeFromParent();
    powerUpSpawner = PowerUpSpawner();
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

    particleSystem.spawnShards(Vector2(220, groundY));

    // Check highscore (update notifiers synchronously for immediate UI feedback)
    final best = highscoreService.getBest();
    final isNewRecord = score > best;
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

    _recordRunAsync(isNewRecord: isNewRecord);

    overlays.remove('HudOverlay');
    overlays.remove('Countdown');
    overlays.add('DeathScreen');
  }

  Future<void> _recordRunAsync({bool isNewRecord = false}) async {
    try {
      if (isNewRecord) {
        await highscoreService.saveBest(score);
        unawaited(leaderboardService.submitScore(score));
      }
      await statsService.recordRun(
        distance: score,
        biomeIndex: _lastBiomeIdx,
        durationSeconds: lastRunDuration,
      );
      // Daily challenge + streak (record before awarding so run coins aren't
      // inflated by the reward itself).
      final daily = dailyChallengeService.recordRun(
        distance: score,
        coinsThisRun: coinsService.sessionEarned,
      );
      if (daily.rewardEarned > 0) {
        await coinsService.addCoins(daily.rewardEarned);
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
    _syncLockTimer = 0;
    _slowMoTimer = 0;
    _lastPowerUps = const [];
    powerUpsNotifier.value = const [];
    playerLeft = null;
    playerRight = null;
    // Reset run state so menu shows clean values
    score = 0;
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

    overlays.remove('HudOverlay');
    overlays.remove('DeathScreen');
    overlays.remove('BiomeBanner');
    overlays.remove('Countdown');
    overlays.remove('SettingsScreen');
    overlays.remove('StatsScreen');
    overlays.remove('SkinSelector');
    overlays.remove('ProScreen');
    overlays.remove('MenuScreen');
    overlays.add('MenuScreen');
  }

  /// Called by SwipeController with the screen-space drag delta.
  void onDrag(double screenDx, double screenWidth) {
    if (playState != PlayState.playing && playState != PlayState.countdown) return;

    final gameDx = screenDx * (vw / screenWidth);
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

    scoreNotifier.value = score;
    _currentBiome = BiomeManager.getBiome(score);

    // In-run record cue: fire once when overtaking the previous best.
    if (!_beatRecordThisRun && _runStartBest > 0 && score > _runStartBest) {
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
    if (playState != PlayState.playing && playState != PlayState.countdown) return;

    // Accumulate score at the current speed (no retroactive speed jumps).
    _scoreBaseAccumulator += speed * step;
    if (comboMultiplier > 1.0) {
      _scoreBonusAccumulator += speed * (comboMultiplier - 1.0) * step;
    }
    // Single floor on the sum avoids the ±1 flicker of flooring each part.
    score = (_scoreBaseAccumulator + _scoreBonusAccumulator).floor();
    speed = min(6.0, 2.0 + score * 0.004);

    if (_invincibilityTimer > 0) {
      _invincibilityTimer = (_invincibilityTimer - step).clamp(0.0, double.infinity);
    }

    if (playState != PlayState.playing) return;

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
    _updatePowerUpNotifier();

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
    if (active.length != _lastPowerUps.length ||
        !_samePowerUps(active, _lastPowerUps)) {
      _lastPowerUps = active;
      powerUpsNotifier.value = active;
    }
  }

  bool _samePowerUps(List<PowerUpType> a, List<PowerUpType> b) {
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
    switch (type) {
      case PowerUpType.shield:
        shieldActive = true;
      case PowerUpType.syncLock:
        _syncLockTimer = _syncLockDuration;
      case PowerUpType.slowMo:
        _slowMoTimer = _slowMoDuration;
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
    // During invincibility (post-revive), skip collision + near-miss checks
    if (isInvincible) return;

    final obstacles = world.children.whereType<Obstacle>().toList();
    Player? nearMissPlayer;
    Obstacle? nearMissObstacle;

    for (final obs in obstacles) {
      if (obs.side == 'left' && playerLeft != null && !playerLeft!.dead) {
        if (_checkOverlap(playerLeft!, obs)) {
          _resolveHit(playerLeft!, skinService.currentSkin.leftColor);
          return;
        }
        if (nearMissPlayer == null && !obs.nearMissed && _checkNearMiss(playerLeft!, obs)) {
          nearMissPlayer = playerLeft;
          nearMissObstacle = obs;
        }
      }
      if (obs.side == 'right' && playerRight != null && !playerRight!.dead) {
        if (_checkOverlap(playerRight!, obs)) {
          _resolveHit(playerRight!, skinService.currentSkin.rightColor);
          return;
        }
        if (nearMissPlayer == null && !obs.nearMissed && _checkNearMiss(playerRight!, obs)) {
          nearMissPlayer = playerRight;
          nearMissObstacle = obs;
        }
      }
    }

    if (nearMissPlayer != null && nearMissObstacle != null) {
      nearMissObstacle.nearMissed = true; // prevent retrigger for same obstacle
      nearMissPlayer.nearMissFlash = 1.0;
      if (settingsService.hapticEnabled) {
        HapticFeedback.lightImpact();
      }
      _comboNearMisses++;
      _timeSinceNearMiss = 0; // refresh the decay window
      _updateComboTier();
    }
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
      comboMultiplier = newMultiplier;
      comboNotifier.value = newMultiplier;
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

      if (player.getPickupRect().overlaps(coll.getPickupRect())) {
        coll.collected = true;
        // Coin value scales with the active combo tier (1×/1×/2×/2×/3×).
        final value = comboMultiplier.round().clamp(1, 3);
        unawaited(coinsService.addCoins(value));
        particleSystem.burstCoin(Vector2(coll.laneCenterX, coll.scrollPos));
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
