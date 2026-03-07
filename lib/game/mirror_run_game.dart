import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game_state.dart';
import 'components/background.dart';
import 'components/mirror_line.dart';
import 'components/obstacle.dart';
import 'components/obstacle_spawner.dart';
import 'components/event_system.dart';
import 'components/particle_system.dart';
import 'components/player.dart';
import 'world/biome.dart';
import '../services/ad_service.dart';
import '../services/achievement_service.dart';
import '../services/audio_service.dart';
import '../services/highscore_service.dart';
import '../services/leaderboard_service.dart';
import '../services/settings_service.dart';
import '../services/skin_service.dart';
import '../services/stats_service.dart';

class MirrorRunGame extends FlameGame
    with HasCollisionDetection, KeyboardEvents {
  static const double vw = 440;
  static const double vh = 640;
  static const List<double> mirrorLanesL = [55, 120, 185];
  static const List<double> mirrorLanesR = [255, 320, 385];

  /// Free-movement bounds for the left player.
  static const double leftMinX = 55;
  static const double leftMaxX = 185;
  /// Fixed step for keyboard input.
  static const double _keyStep = 65;

  late HighscoreService highscoreService;
  late AdService adService;
  late SettingsService settingsService;
  late AudioService audioService;
  late LeaderboardService leaderboardService;
  late StatsService statsService;
  late AchievementService achievementService;
  late SkinService skinService;

  /// Used by SkinSelector to pass edit index to SkinBuilder overlay.
  int? skinBuilderEditIndex;

  /// Optional preset values for SkinBuilder (used by screenshot tour).
  Map<String, dynamic>? skinBuilderPreset;

  PlayState playState = PlayState.menu;

  int debugStartScore = 0;

  int score = 0;
  double speed = 1.4;
  double _frameAccumulator = 0;
  int _frame = 0;
  double _deathTimer = 0;
  static const double _deathDelay = 2.5;
  double _runStartTime = 0;

  final ValueNotifier<int> scoreNotifier = ValueNotifier(0);
  final ValueNotifier<String> biomeNotifier = ValueNotifier('FOREST');
  final ValueNotifier<int> bestNotifier = ValueNotifier(0);
  final ValueNotifier<bool> newRecordNotifier = ValueNotifier(false);
  final ValueNotifier<GameEvent?> eventNotifier = ValueNotifier(null);
  final ValueNotifier<String?> eventWarningNotifier = ValueNotifier(null);
  /// Incremented when an event ends, to trigger "NORMAL" flash.
  final ValueNotifier<int> eventEndNotifier = ValueNotifier(0);

  Player? playerLeft;
  Player? playerRight;
  late Background background;
  late MirrorLine mirrorLine;
  late ObstacleSpawner spawner;
  late ParticleSystem particleSystem;
  late EventSystem eventSystem;
  int _lastBiomeIdx = -1;

  MirrorRunGame()
      : super(
          camera: CameraComponent.withFixedResolution(
            width: vw,
            height: vh,
          ),
        );

  @override
  Future<void> onLoad() async {
    debugPrint('>>> onLoad START');

    highscoreService = HighscoreService();
    await highscoreService.init();
    debugPrint('>>> highscore OK');

    settingsService = SettingsService();
    await settingsService.init();
    debugPrint('>>> settings OK');

    audioService = AudioService(settingsService);
    try {
      await audioService.init();
      debugPrint('>>> audio OK');
    } catch (e) {
      debugPrint('>>> audio FAILED: $e');
    }

    skinService = SkinService();
    await skinService.init();

    adService = AdService();
    try {
      await adService.init(skinService: skinService);
      debugPrint('>>> ad OK, isAdFree=${adService.isAdFree}');
    } catch (e) {
      debugPrint('>>> ad FAILED: $e');
    }

    leaderboardService = LeaderboardService();
    try { await leaderboardService.init(); } catch (_) {}

    statsService = StatsService();
    await statsService.init();

    achievementService = AchievementService();
    achievementService.setSignedIn(leaderboardService.isSignedIn);

    debugPrint('>>> services done, setting up camera');
    camera.viewfinder.anchor = Anchor.topLeft;

    background = Background();
    mirrorLine = MirrorLine();
    spawner = ObstacleSpawner();
    particleSystem = ParticleSystem();
    eventSystem = EventSystem();

    world.add(background);
    world.add(mirrorLine);
    world.add(particleSystem);

    overlays.add('MenuScreen');
  }

  void startGame() {
    playState = PlayState.countdown;
    _runStartTime = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final startScore = kDebugMode ? debugStartScore : 0;
    score = startScore;
    _frame = 0;
    _frameAccumulator = 0;
    speed = 1.8;
    _lastBiomeIdx = BiomeManager.getBiomeIndex(startScore);

    scoreNotifier.value = startScore;
    biomeNotifier.value = BiomeManager.getBiome(startScore).name;
    bestNotifier.value = highscoreService.getBest();
    newRecordNotifier.value = false;
    eventNotifier.value = null;
    eventWarningNotifier.value = null;

    // Remove old components
    world.children.whereType<Player>().toList().forEach((p) => p.removeFromParent());
    world.children.whereType<Obstacle>().toList().forEach((o) => o.removeFromParent());

    if (world.children.contains(spawner)) {
      spawner.removeFromParent();
    }
    if (world.children.contains(eventSystem)) {
      eventSystem.removeFromParent();
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
    background.spawnInitialDecos();

    overlays.remove('MenuScreen');
    overlays.remove('DeathScreen');
    overlays.add('HudOverlay');
    overlays.add('Countdown');
  }

  void endCountdown() {
    if (playState != PlayState.countdown) return;
    playState = PlayState.playing;
    overlays.remove('Countdown');
  }

  void die() {
    if (playState == PlayState.dead) return;
    playState = PlayState.dead;
    _deathTimer = 0;

    audioService.playDeath();
    if (settingsService.hapticEnabled) {
      HapticFeedback.heavyImpact();
    }

    particleSystem.spawnShards(Vector2(220, 320));

    // Check highscore
    final best = highscoreService.getBest();
    if (score > best) {
      highscoreService.saveBest(score);
      newRecordNotifier.value = true;
      bestNotifier.value = score;
    }

    leaderboardService.submitScore(score);
    adService.onDeath();

    _recordRunAsync();

    overlays.remove('HudOverlay');
    overlays.remove('Countdown');
    overlays.add('DeathScreen');
  }

  Future<void> _recordRunAsync() async {
    await statsService.recordRun(
      distance: score,
      biomeIndex: _lastBiomeIdx,
      durationSeconds: lastRunDuration,
    );
    achievementService.checkAfterRun(
      runDistance: score,
      totalGames: statsService.totalGamesPlayed,
      currentBiome: _lastBiomeIdx,
    );
    skinService.checkUnlocks(statsService.furthestBiomeIndex);
  }

  double get lastRunDuration =>
      DateTime.now().millisecondsSinceEpoch / 1000.0 - _runStartTime;

  void goToMenu() {
    resumeEngine();
    playState = PlayState.menu;
    world.children.whereType<Player>().toList().forEach((p) => p.removeFromParent());
    world.children.whereType<Obstacle>().toList().forEach((o) => o.removeFromParent());
    if (world.children.contains(spawner)) spawner.removeFromParent();
    if (world.children.contains(eventSystem)) eventSystem.removeFromParent();
    eventSystem.reset();
    eventNotifier.value = null;
    eventWarningNotifier.value = null;
    playerLeft = null;
    playerRight = null;

    overlays.remove('HudOverlay');
    overlays.remove('DeathScreen');
    overlays.remove('BiomeBanner');
    overlays.remove('Countdown');
    overlays.remove('SettingsScreen');
    overlays.remove('StatsScreen');
    overlays.remove('SkinSelector');
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
    // Mirror swap inverts controls
    final d = eventSystem.mirrorSwapped ? -dx : dx;

    final pl = playerLeft!;
    pl.targetX = (pl.targetX + d).clamp(leftMinX, leftMaxX);
    playerRight!.targetX = vw - pl.targetX;
  }

  bool get canRetry => playState == PlayState.dead && _deathTimer >= _deathDelay;

  @override
  void update(double dt) {
    super.update(dt);
    if (playState == PlayState.dead) {
      _deathTimer += dt;
    }
    if (playState != PlayState.playing && playState != PlayState.countdown) return;

    _frameAccumulator += dt;
    while (_frameAccumulator >= 1.0 / 60.0) {
      _frameAccumulator -= 1.0 / 60.0;
      _frame++;
    }
    final base = kDebugMode ? debugStartScore : 0;
    score = base + (_frame * speed / 60).floor();
    speed = min(6.0, 1.8 + score * 0.003);
    scoreNotifier.value = score;

    // Biome change
    final curIdx = BiomeManager.getBiomeIndex(score);
    if (curIdx != _lastBiomeIdx) {
      _lastBiomeIdx = curIdx;
      biomeNotifier.value = BiomeManager.biomes[curIdx].name;
      audioService.playBiomeTransition();
      overlays.add('BiomeBanner');
    }

    if (playState == PlayState.playing) _checkCollisions();
  }

  void _checkCollisions() {
    final obstacles = world.children.whereType<Obstacle>().toList();

    for (final obs in obstacles) {
      if (obs.side == 'left' && playerLeft != null && !playerLeft!.dead) {
        if (_checkOverlap(playerLeft!, obs)) {
          playerLeft!.dead = true;
          particleSystem.burst(
            Vector2(playerLeft!.position.x, playerLeft!.position.y - Player.ph / 2),
            skinService.currentSkin.leftColor,
          );
          die();
          return;
        }
      }
      if (obs.side == 'right' && playerRight != null && !playerRight!.dead) {
        if (_checkOverlap(playerRight!, obs)) {
          playerRight!.dead = true;
          particleSystem.burst(
            Vector2(playerRight!.position.x, playerRight!.position.y - Player.ph / 2),
            skinService.currentSkin.rightColor,
          );
          die();
          return;
        }
      }
    }
  }

  bool _checkOverlap(Player p, Obstacle o) {
    final pRect = Rect.fromLTWH(
      p.position.x - Player.pw / 2 + 7,
      p.position.y - Player.ph,
      Player.pw - 14,
      Player.ph,
    );
    return pRect.overlaps(o.getHitRect());
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
      if (canRetry) startGame();
      return KeyEventResult.handled;
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
