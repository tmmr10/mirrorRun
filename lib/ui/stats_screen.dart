import 'package:flutter/material.dart';
import '../game/mirror_run_game.dart';
import '../game/world/biome.dart';

class StatsScreen extends StatelessWidget {
  final MirrorRunGame game;
  const StatsScreen({super.key, required this.game});

  static const _accent = Color(0xFFB48CFF);

  @override
  Widget build(BuildContext context) {
    final stats = game.statsService;
    final best = game.highscoreService.getBest();
    final furthestBiomeName = stats.furthestBiomeIndex < BiomeManager.biomes.length
        ? BiomeManager.biomes[stats.furthestBiomeIndex].name
        : 'UNKNOWN';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xF00a0a0f), Color(0xF0080812), Color(0xF00f0a14)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'STATISTICS',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _accent,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 40),
              _statRow('TOTAL DISTANCE', '${stats.totalDistance}m'),
              _statRow('GAMES PLAYED', '${stats.totalGamesPlayed}'),
              _statRow('PLAYTIME', _formatPlaytime(stats.totalPlaytimeSeconds)),
              _statRow('FURTHEST BIOME', furthestBiomeName),
              _statRow('BEST SCORE', '${best}m'),
              const Spacer(),
              Center(
                child: GestureDetector(
                  onTap: () {
                    game.overlays.remove('StatsScreen');
                    game.overlays.add('SettingsScreen');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: _accent.withValues(alpha: 0.3), width: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'BACK',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _accent.withValues(alpha: 0.7),
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
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
