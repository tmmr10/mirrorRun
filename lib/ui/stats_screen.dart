import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../game/mirror_run_game.dart';
import '../game/world/biome.dart';
import '../l10n/game_l10n.dart';
import '../l10n/l10n_ext.dart';
import 'overlay_shell.dart';
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
        ? biomeNameLocalized(
            context, BiomeManager.biomes[stats.furthestBiomeIndex].name)
        : context.l10n.statsUnknownBiome;

    return Container(
      decoration: const BoxDecoration(gradient: MR.bgGradient),
      child: SafeArea(
        child: OverlayShell(
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
                    context.l10n.statsTitle,
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
              Expanded(
                child: CenterableScroll(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _statRow(context.l10n.statsTotalDistance, context.l10n.statsMeters(stats.totalDistance)),
                      _statRow(context.l10n.statsGamesPlayed, '${stats.totalGamesPlayed}'),
                      _statRow(context.l10n.statsPlaytime, _formatPlaytime(context, stats.totalPlaytimeSeconds)),
                      _statRow(context.l10n.statsFurthestBiome, furthestBiomeName),
                      _statRow(context.l10n.statsBestScore, context.l10n.statsMeters(best)),
                      const SizedBox(height: 20),
                      Builder(
                        builder: (ctx) => TapScale(
                          minSize: MR.minTouchTarget,
                          onTap: () {
                            final box = ctx.findRenderObject() as RenderBox?;
                            final origin = box != null
                                ? box.localToGlobal(Offset.zero) & box.size
                                : null;
                            final playtime = _formatPlaytime(ctx, stats.totalPlaytimeSeconds);
                            Share.share(
                              ctx.l10n.statsShareText(
                                best,
                                stats.totalGamesPlayed,
                                playtime,
                                furthestBiomeName,
                              ),
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
                                  ctx.l10n.statsShare,
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
                    ],
                  ),
                ),
              ),
            ],
          ),
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

  String _formatPlaytime(BuildContext context, double seconds) {
    final totalMinutes = (seconds / 60).floor();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0) return context.l10n.statsPlaytimeHoursMinutes(hours, minutes);
    return context.l10n.statsPlaytimeMinutes(minutes);
  }
}
