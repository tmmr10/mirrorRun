import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../game/mirror_run_game.dart';
import '../game/world/biome.dart';

class DeathScreen extends StatefulWidget {
  final MirrorRunGame game;
  const DeathScreen({super.key, required this.game});

  @override
  State<DeathScreen> createState() => _DeathScreenState();
}

class _DeathScreenState extends State<DeathScreen> {
  bool _canInteract = false;
  bool _adWasShown = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _canInteract = true);
    });
  }

  void _retry() {
    if (!_canInteract) return;
    final adService = widget.game.adService;
    if (adService.shouldShowAd(widget.game.lastRunDuration)) {
      adService.showAd(() {
        if (mounted) {
          setState(() => _adWasShown = true);
          widget.game.startGame();
        }
      });
    } else {
      widget.game.startGame();
    }
  }

  void _menu() {
    if (!_canInteract) return;
    widget.game.goToMenu();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _retry,
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.8,
            colors: [
              const Color(0xE0100008),
              const Color(0xE0000000),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Shattered line top
              Container(
                width: 60,
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      const Color(0xFFFF3333).withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                  ),
                ),
              )
                  .animate()
                  .scaleX(begin: 0, end: 1, duration: 400.ms, delay: 600.ms, curve: Curves.easeOutCubic),

              const SizedBox(height: 24),

              // Score
              ValueListenableBuilder<int>(
                valueListenable: widget.game.scoreNotifier,
                builder: (context, score, child) => Column(
                  children: [
                    Text(
                      '$score',
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w100,
                        color: Colors.white,
                        letterSpacing: 4,
                        height: 1,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 300.ms, delay: 800.ms)
                        .scale(begin: const Offset(1.5, 1.5), end: const Offset(1, 1), duration: 400.ms, delay: 800.ms, curve: Curves.easeOutCubic),
                    const SizedBox(height: 4),
                    Text(
                      'METER',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.3),
                        letterSpacing: 6,
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 1000.ms),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // New record badge
              ValueListenableBuilder<bool>(
                valueListenable: widget.game.newRecordNotifier,
                builder: (context, isNew, child) {
                  if (!isNew) return const SizedBox(height: 28);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFFFCC44).withValues(alpha: 0.5),
                        width: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(2),
                      color: const Color(0xFFFFCC44).withValues(alpha: 0.06),
                    ),
                    child: const Text(
                      'NEW RECORD',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFFCC44),
                        letterSpacing: 4,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 300.ms, delay: 1200.ms)
                      .shimmer(duration: 1500.ms, delay: 1400.ms, color: const Color(0x40FFCC44));
                },
              ),

              const SizedBox(height: 24),

              // Bottom divider
              Container(
                width: 40,
                height: 1,
                color: Colors.white.withValues(alpha: 0.08),
              )
                  .animate()
                  .fadeIn(duration: 300.ms, delay: 1400.ms),

              const SizedBox(height: 24),

              // Retry prompt
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 0.5,
                      ),
                    ),
                    child: Icon(
                      Icons.refresh_rounded,
                      size: 12,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'TAP TO RETRY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.3),
                      letterSpacing: 3,
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 1600.ms),

              const SizedBox(height: 20),

              // Menu button
              GestureDetector(
                onTap: _menu,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'MENU',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.35),
                      letterSpacing: 3,
                    ),
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 1800.ms),

              const SizedBox(height: 12),

              // Leaderboard button
              GestureDetector(
                onTap: () {
                  if (_canInteract) widget.game.leaderboardService.showLeaderboard();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFB48CFF).withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.leaderboard_rounded,
                        size: 14,
                        color: const Color(0xFFB48CFF).withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'LEADERBOARD',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFB48CFF).withValues(alpha: 0.5),
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 1900.ms),

              const SizedBox(height: 12),

              // Share button
              GestureDetector(
                onTap: () {
                  if (!_canInteract) return;
                  try {
                    final score = widget.game.scoreNotifier.value;
                    final biomeIdx = BiomeManager.getBiomeIndex(score);
                    final biomeName = BiomeManager.biomes[biomeIdx].name;
                    Share.share('I ran ${score}m through $biomeName in Mirror Runners!');
                  } catch (_) {}
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFff6b35).withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.share_rounded,
                        size: 14,
                        color: const Color(0xFFff6b35).withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'SHARE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFff6b35).withValues(alpha: 0.6),
                          letterSpacing: 3,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 2000.ms),

              // Ad-free hint (shown after an ad was displayed)
              if (_adWasShown && !widget.game.adService.isAdFree) ...[
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => widget.game.adService.purchaseAdFree(),
                  child: Text(
                    'No more ads? Go ad free!',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.25),
                      letterSpacing: 1,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 2000.ms),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
