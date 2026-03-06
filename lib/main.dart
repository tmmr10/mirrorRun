import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game/mirror_run_game.dart';
import 'game/input/swipe_controller.dart';
import 'ui/menu_screen.dart';
import 'ui/hud_overlay.dart';
import 'ui/biome_banner.dart';
import 'ui/countdown_overlay.dart';
import 'ui/death_screen.dart';
import 'ui/settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final game = MirrorRunGame();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0a0a0f),
      ),
      home: Scaffold(
        backgroundColor: const Color(0xFF0a0a0f),
        body: SwipeController(
          game: game,
          child: GameWidget(
            game: game,
            overlayBuilderMap: {
              'MenuScreen': (context, game) =>
                  MenuScreen(game: game as MirrorRunGame),
              'HudOverlay': (context, game) =>
                  HudOverlay(game: game as MirrorRunGame),
              'BiomeBanner': (context, game) =>
                  BiomeBanner(game: game as MirrorRunGame),
              'Countdown': (context, game) =>
                  CountdownOverlay(game: game as MirrorRunGame),
              'DeathScreen': (context, game) =>
                  DeathScreen(game: game as MirrorRunGame),
              'SettingsScreen': (context, game) =>
                  SettingsScreen(game: game as MirrorRunGame),
            },
          ),
        ),
      ),
    ),
  );
}
