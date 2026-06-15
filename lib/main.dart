import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'game/mirror_run_game.dart';
import 'utils/screenshot_tour.dart';
import 'utils/icon_capture.dart';
import 'game/input/swipe_controller.dart';
import 'ui/menu_screen.dart';
import 'ui/hud_overlay.dart';
import 'ui/biome_banner.dart';
import 'ui/countdown_overlay.dart';
import 'ui/death_screen.dart';
import 'ui/settings_screen.dart';
import 'ui/stats_screen.dart';
import 'ui/skin_selector.dart';
import 'ui/skin_builder.dart';
import 'ui/pro_screen.dart';
import 'ui/perk_screen.dart';
import 'ui/achievements_screen.dart';
import 'ui/debug_overlay.dart';

/// Global game reference for debug tooling (screenshot tour via VM service).
late MirrorRunGame _game;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  try {
    await Firebase.initializeApp();
    debugPrint('>>> Firebase OK');
  } catch (e, st) {
    // Silent-in-release would make monitoring impossible — at least surface in debug
    debugPrint('>>> Firebase init failed: $e\n$st');
    if (kDebugMode) {
      // ignore: avoid_print
      print('FATAL: Firebase init failed. Analytics disabled for this session.');
    }
  }

  final game = MirrorRunGame();
  _game = game;

  if (kDebugMode) {
    developer.registerExtension('ext.mirror_run.screenshotTour',
        (String method, Map<String, String> params) async {
      runScreenshotTour(_game);
      return developer.ServiceExtensionResponse.result('{"ok":true}');
    });
    developer.registerExtension('ext.mirror_run.iconCapture',
        (String method, Map<String, String> params) async {
      runIconCapture(_game);
      return developer.ServiceExtensionResponse.result('{"ok":true}');
    });
  }

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Clamp system text scaling so large accessibility font sizes can't
        // overflow the caps/letter-spaced game UI.
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(minScaleFactor: 1.0, maxScaleFactor: 1.3),
          ),
          child: child!,
        );
      },
      home: Scaffold(
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
              'Countdown': (context, game) =>
                  CountdownOverlay(game: game as MirrorRunGame),
              'BiomeBanner': (context, game) =>
                  BiomeBanner(game: game as MirrorRunGame),
              'HudOverlay': (context, game) =>
                  HudOverlay(game: game as MirrorRunGame),
              'DeathScreen': (context, game) =>
                  DeathScreen(game: game as MirrorRunGame),
              'SettingsScreen': (context, game) =>
                  SettingsScreen(game: game as MirrorRunGame),
              'StatsScreen': (context, game) =>
                  StatsScreen(game: game as MirrorRunGame),
              'SkinSelector': (context, game) =>
                  SkinSelector(game: game as MirrorRunGame),
              'SkinBuilder': (context, game) =>
                  SkinBuilder(game: game as MirrorRunGame),
              'ProScreen': (context, game) =>
                  ProScreen(game: game as MirrorRunGame),
              'PerkScreen': (context, game) =>
                  PerkScreen(game: game as MirrorRunGame),
              'AchievementsScreen': (context, game) =>
                  AchievementsScreen(game: game as MirrorRunGame),
              if (kDebugMode)
                'DebugOverlay': (context, game) =>
                    DebugOverlay(game: game as MirrorRunGame),
            },
          ),
        ),
      ),
    ),
  );
}
