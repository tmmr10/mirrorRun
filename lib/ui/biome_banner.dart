import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../game/mirror_run_game.dart';
import '../game/world/biome.dart';
import '../l10n/game_l10n.dart';
import '../l10n/l10n_ext.dart';

class BiomeBanner extends StatelessWidget {
  final MirrorRunGame game;
  const BiomeBanner({super.key, required this.game});

  Color _biomeAccent(String biome) {
    for (final b in BiomeManager.biomes) {
      if (b.name == biome) return b.lineL;
    }
    return const Color(0xFF3A8C3A);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ValueListenableBuilder<String>(
        valueListenable: game.biomeNotifier,
        builder: (context, biome, child) {
          final accent = _biomeAccent(biome);
          return Container(
            key: ValueKey(biome),
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xE0000000),
              border: Border(
                top: BorderSide(color: accent.withValues(alpha: 0.4), width: 0.5),
                bottom: BorderSide(color: accent.withValues(alpha: 0.4), width: 0.5),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Thin label above
                Text(
                  context.l10n.biomeBannerEntering,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                    color: accent.withValues(alpha: 0.5),
                    letterSpacing: 6,
                  ),
                ),
                const SizedBox(height: 8),
                // Biome name
                Text(
                  biomeNameLocalized(context, biome),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 6,
                    shadows: [
                      Shadow(color: accent.withValues(alpha: 0.5), blurRadius: 30),
                    ],
                  ),
                ),
              ],
            ),
          )
              .animate(
                onComplete: (controller) {
                  game.overlays.remove('BiomeBanner');
                },
              )
              .fadeIn(duration: 200.ms)
              .slideY(begin: 0.05, end: 0, duration: 300.ms, curve: Curves.easeOutCubic)
              .then(delay: 1500.ms)
              .fadeOut(duration: 400.ms)
              .slideY(begin: 0, end: -0.05, duration: 400.ms);
        },
      ),
    );
  }
}
