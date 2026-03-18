import 'package:flutter/foundation.dart';
import '../game/mirror_run_game.dart';
import '../models/player_skin.dart';

/// Capture game states for icon extraction.
/// Takes screenshots with fire and ice skins in gameplay.
Future<void> runIconCapture(MirrorRunGame game) async {
  debugPrint('>>> ICON_CAPTURE_START');
  game.screenshotMode = true;

  // 1. Fire skin — Void biome (black background for clean extraction)
  await game.skinService.selectSkin(SkinId.fire);
  game.goToMenu();
  game.debugStartScore = 3200; // Void biome (pure black bg)
  game.startGame();
  game.endCountdown();
  game.speed = 2.5;
  // Move player to left lane for clear shot
  game.playerLeft!.targetX = 110;
  game.playerRight!.targetX = 330;
  await Future.delayed(const Duration(milliseconds: 2000));
  game.pauseEngine();
  debugPrint('>>> ICON_READY:fire');
  await Future.delayed(const Duration(milliseconds: 3000));
  game.resumeEngine();

  // 2. Ice skin — Void biome (black background)
  await game.skinService.selectSkin(SkinId.ice);
  game.goToMenu();
  game.debugStartScore = 3200; // Void biome
  game.startGame();
  game.endCountdown();
  game.speed = 2.5;
  game.playerLeft!.targetX = 110;
  game.playerRight!.targetX = 330;
  await Future.delayed(const Duration(milliseconds: 2000));
  game.pauseEngine();
  debugPrint('>>> ICON_READY:ice');
  await Future.delayed(const Duration(milliseconds: 3000));
  game.resumeEngine();

  // 3. Both side by side — use default skin in forest for variety
  await game.skinService.selectSkin(SkinId.default_);
  game.goToMenu();
  game.debugStartScore = 0;
  game.startGame();
  game.endCountdown();
  game.speed = 2.0;
  game.playerLeft!.targetX = 110;
  game.playerRight!.targetX = 330;
  await Future.delayed(const Duration(milliseconds: 1500));
  game.pauseEngine();
  debugPrint('>>> ICON_READY:default');
  await Future.delayed(const Duration(milliseconds: 3000));
  game.resumeEngine();

  // Back to menu
  await game.skinService.selectSkin(SkinId.default_);
  game.goToMenu();
  game.screenshotMode = false;
  debugPrint('>>> ICON_CAPTURE_DONE');
}
