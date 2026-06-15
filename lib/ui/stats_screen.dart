import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../game/mirror_run_game.dart';
import '../game/world/biome.dart';
import 'tap_scale.dart';
import 'theme.dart';

class StatsScreen extends StatelessWidget {
  final MirrorRunGame game;
  const StatsScreen({super.key, required this.game});

  static const _accent = MR.accent;

  @override
  Widget build(BuildContext context) {
    final stats = game.statsService;
    final best = game.highscoreService.getBest();
    final furthestBiomeName = stats.furthestBiomeIndex < BiomeManager.biomes.length
        ? BiomeManager.biomes[stats.furthestBiomeIndex].name
        : 'UNKNOWN';

    return Container(
      decoration: const BoxDecoration(gradient: MR.bgGradient),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TapScale(
                    onTap: () {
                      game.overlays.remove('StatsScreen');
                      game.overlays.add('SettingsScreen');
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: _accent.withValues(alpha: 0.5),
                        size: 20,
                      ),
                    ),
                  ),
                  Text(
                    'STATISTICS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _accent,
                      letterSpacing: 6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              _statRow('TOTAL DISTANCE', '${stats.totalDistance}m'),
              _statRow('GAMES PLAYED', '${stats.totalGamesPlayed}'),
              _statRow('PLAYTIME', _formatPlaytime(stats.totalPlaytimeSeconds)),
              _statRow('FURTHEST BIOME', furthestBiomeName),
              _statRow('BEST SCORE', '${best}m'),
              const SizedBox(height: 20),
              Builder(
                builder: (ctx) => TapScale(
                  minSize: MR.minTouchTarget,
                  onTap: () {
                    final box = ctx.findRenderObject() as RenderBox?;
                    final origin = box != null
                        ? box.localToGlobal(Offset.zero) & box.size
                        : null;
                    final playtime = _formatPlaytime(stats.totalPlaytimeSeconds);
                    Share.share(
                      'Mirror Runners Stats:\n'
                      '${best}m best · ${stats.totalGamesPlayed} games · $playtime played · $furthestBiomeName reached',
                      sharePositionOrigin: origin,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _accent.withValues(alpha: 0.2),
                        width: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.share_rounded, size: 13, color: _accent.withValues(alpha: 0.5)),
                        const SizedBox(width: 6),
                        Text(
                          'SHARE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: _accent.withValues(alpha: 0.5),
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 3,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _accent.withValues(alpha: 0.9),
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPlaytime(double seconds) {
    final totalMinutes = (seconds / 60).floor();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }
}
