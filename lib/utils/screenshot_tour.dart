import 'package:flutter/foundation.dart';
import '../game/mirror_run_game.dart';
import '../game/components/event_system.dart';
import '../models/player_skin.dart';

/// Automated screenshot tour.
/// Cycles through game states and prints SCREENSHOT_READY:<name> markers.
/// An external script watches for these markers and takes screenshots.
Future<void> runScreenshotTour(MirrorRunGame game) async {
  debugPrint('>>> SCREENSHOT_TOUR_START');
  game.screenshotMode = true;

  // 1. Menu — Default skin
  await game.skinService.selectSkin(SkinId.default_);
  game.goToMenu();
  game.debugStartScore = 0;
  await Future.delayed(const Duration(milliseconds: 2500));
  debugPrint('>>> SCREENSHOT_READY:01_menu');
  await Future.delayed(const Duration(milliseconds: 3000));

  // 2. Crystal biome gameplay — Ice skin
  await game.skinService.selectSkin(SkinId.ice);
  game.debugStartScore = 175;
  game.startGame();
  game.endCountdown();
  game.speed = 2.2;
  await Future.delayed(const Duration(milliseconds: 3000));
  game.pauseEngine();
  debugPrint('>>> SCREENSHOT_READY:02_gameplay');
  await Future.delayed(const Duration(milliseconds: 3000));
  game.resumeEngine();

  // 3. Phantom mode — Neon skin (glows nicely)
  await game.skinService.selectSkin(SkinId.neon);
  game.goToMenu();
  game.debugStartScore = 175;
  game.startGame();
  game.endCountdown();
  game.speed = 1.8;
  await Future.delayed(const Duration(milliseconds: 3000));
  game.eventSystem.forceEvent(GameEvent.phantom);
  await Future.delayed(const Duration(milliseconds: 800));
  game.pauseEngine();
  debugPrint('>>> SCREENSHOT_READY:03_phantom');
  await Future.delayed(const Duration(milliseconds: 3000));
  game.resumeEngine();

  // 4. Swap mode — Volcano biome — Gold skin
  await game.skinService.selectSkin(SkinId.gold);
  game.goToMenu();
  game.debugStartScore = 300;
  game.startGame();
  game.endCountdown();
  game.speed = 2.0;
  await Future.delayed(const Duration(milliseconds: 2500));
  game.eventSystem.forceEvent(GameEvent.mirrorSwap);
  await Future.delayed(const Duration(milliseconds: 800));
  game.pauseEngine();
  debugPrint('>>> SCREENSHOT_READY:04_swap');
  await Future.delayed(const Duration(milliseconds: 3000));
  game.resumeEngine();

  // 5. Skins screen — Fire skin (selected, looks vibrant)
  await game.skinService.selectSkin(SkinId.fire);
  game.goToMenu();
  game.debugStartScore = 0;
  await Future.delayed(const Duration(milliseconds: 500));
  game.overlays.remove('MenuScreen');
  game.overlays.add('SkinSelector');
  await Future.delayed(const Duration(milliseconds: 800));
  debugPrint('>>> SCREENSHOT_READY:05_skins');
  await Future.delayed(const Duration(milliseconds: 3000));

  // 6. Skin Creator screen — with nice preset values
  await game.skinService.selectSkin(SkinId.ocean);
  game.skinBuilderPreset = {
    'leftHue': 160.0,    // Teal/cyan
    'leftSat': 0.9,
    'rightHue': 280.0,   // Purple
    'rightSat': 0.85,
    'head': HeadDecoration.flames,
    'face': FaceDecoration.visor,
    'name': 'NEBULA',
  };
  game.overlays.remove('SkinSelector');
  game.overlays.add('SkinBuilder');
  await Future.delayed(const Duration(milliseconds: 800));
  debugPrint('>>> SCREENSHOT_READY:06_creator');
  await Future.delayed(const Duration(milliseconds: 3000));

  // Back to menu — restore default
  await game.skinService.selectSkin(SkinId.default_);
  game.overlays.remove('SkinBuilder');
  game.overlays.add('MenuScreen');

  game.screenshotMode = false;
  debugPrint('>>> SCREENSHOT_TOUR_DONE');
}
