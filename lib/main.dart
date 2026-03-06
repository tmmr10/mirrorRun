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
import 'ui/stats_screen.dart';
import 'ui/skin_selector.dart';

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
            backgroundBuilder: (context) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0a0a0f),
                    Color(0xFF080812),
                    Color(0xFF0f0a14),
                  ],
                ),
              ),
            ),
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
              'StatsScreen': (context, game) =>
                  StatsScreen(game: game as MirrorRunGame),
              'SkinSelector': (context, game) =>
                  SkinSelector(game: game as MirrorRunGame),
            },
          ),
        ),
      ),
    ),
  );
}
