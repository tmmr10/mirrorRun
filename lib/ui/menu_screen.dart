import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../game/mirror_run_game.dart';
import '../game/world/biome.dart';
import '../services/daily_challenge_service.dart';
import 'player_scene_painter.dart';
import 'tap_scale.dart';
import 'theme.dart';

class MenuScreen extends StatefulWidget {
  final MirrorRunGame game;
  const MenuScreen({super.key, required this.game});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  static bool _firstOpen = true;
  late AnimationController _shimmerController;

  /// Scale animation delays: full on first open, fast on return.
  Duration _d(int ms) => Duration(milliseconds: _firstOpen ? ms : ms ~/ 4);

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
    // Mark first open as done after build
    if (_firstOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _firstOpen = false);
    }
    widget.game.adService.proStatusNotifier.addListener(_onProStatus);
  }

  void _onProStatus() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.game.adService.proStatusNotifier.removeListener(_onProStatus);
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = MR.accent;

    return Container(
      decoration: const BoxDecoration(gradient: MR.bgGradient),
      child: Stack(
        children: [
          // Vertical mirror line accent
          Align(
            alignment: Alignment.center,
            child: AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                final t = _shimmerController.value;
                return Container(
                  width: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        accentColor.withValues(alpha: 0.0),
                        accentColor.withValues(
                          alpha: 0.4 + 0.3 * sin(t * pi * 2),
                        ),
                        accentColor.withValues(alpha: 0.0),
                        Colors.transparent,
                      ],
                      stops: [
                        0.0,
                        (0.3 + t * 0.4).clamp(0.0, 0.95),
                        (0.4 + t * 0.4).clamp(0.05, 0.98),
                        (0.5 + t * 0.4).clamp(0.1, 1.0),
                        1.0,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Main layout
          SafeArea(
            child: Column(
              children: [
                // Top bar: settings gear (right)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      if (!widget.game.screenshotMode)
                        TapScale(
                          minSize: MR.minTouchTarget,
                          onTap: () {
                            widget.game.overlays.remove('MenuScreen');
                            widget.game.overlays.add('AchievementsScreen');
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.emoji_events_outlined,
                              color: accentColor.withValues(alpha: 0.5),
                              size: 24,
                            ),
                          ),
                        ).animate().fadeIn(duration: 400.ms, delay: _d(800)),
                      const SizedBox(width: 4),
                      if (!widget.game.screenshotMode)
                        ValueListenableBuilder<int>(
                          valueListenable: widget.game.coinsService.coinsNotifier,
                          builder: (context, coins, _) => _topChip(
                            accent: MR.gold,
                            onTap: () {
                              // Coins are spent on perks → tap the balance to shop.
                              widget.game.overlays.remove('MenuScreen');
                              widget.game.overlays.add('PerkScreen');
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.circle, color: MR.gold, size: 9),
                                const SizedBox(width: 5),
                                Text(
                                  '$coins',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: MR.gold.withValues(alpha: 0.9),
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(duration: 400.ms, delay: _d(900)),
                      const Spacer(),
                      if (kDebugMode && !widget.game.screenshotMode)
                        TapScale(
                          minSize: MR.minTouchTarget,
                          onTap: () {
                            widget.game.overlays.remove('MenuScreen');
                            widget.game.overlays.add('DebugOverlay');
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.bug_report,
                              color: MR.alert.withValues(alpha: 0.5),
                              size: 24,
                            ),
                          ),
                        ),
                      if (!widget.game.screenshotMode)
                        TapScale(
                          minSize: MR.minTouchTarget,
                          onTap: () {
                            widget.game.overlays.remove('MenuScreen');
                            widget.game.overlays.add('SettingsScreen');
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.settings,
                              color: accentColor.withValues(alpha: 0.5),
                              size: 24,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Center layout — Minimal Hero: logo, prominent PLAY, biome
                // teaser, daily. (Skin lives in the top-bar chip; detailed
                // next-biome/skin progress lives in the Stats screen.)
                Expanded(
                  child: Column(
                    children: [
                      const Spacer(flex: 3),
                      _buildTitle(accentColor),
                      const Spacer(flex: 3),
                      _buildPlayButton(accentColor),
                      const SizedBox(height: 28),
                      if (!widget.game.screenshotMode) _buildBiomeRoadmap(),
                      const Spacer(flex: 4),
                      if (!widget.game.screenshotMode) _buildDailyCard(accentColor),
                      SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                    ],
                  ),
                ),

                // Bottom: skin showcase — entry to skins + Creator (Pro pitch),
                // replaces the old GO PRO button.
                if (!widget.game.screenshotMode) _buildSkinShowcase(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(Color accent) {
    return Column(
      children: [
        // "MIRROR" reflected
        Text(
              'MIRROR',
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w100,
                color: Colors.white.withValues(alpha: 0.15),
                letterSpacing: 18,
                height: 1,
              ),
            )
            .animate()
            .fadeIn(duration: 800.ms, delay: _d(200))
            .slideY(
              begin: -0.3,
              end: 0,
              duration: 600.ms,
              curve: Curves.easeOutCubic,
            ),

        Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(1.0, -1.0, 1.0),
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [accent.withValues(alpha: 0.8), Colors.transparent],
            ).createShader(bounds),
            child: Text(
              'MIRROR',
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w100,
                color: Colors.white,
                letterSpacing: 18,
                height: 1,
              ),
            ),
          ),
        ).animate().fadeIn(duration: 800.ms, delay: _d(400)),

        const SizedBox(height: 8),

        // Divider line
        Container(
              width: 180,
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    accent.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
            )
            .animate()
            .fadeIn(duration: 600.ms, delay: _d(600))
            .scaleX(
              begin: 0,
              end: 1,
              duration: 500.ms,
              delay: _d(600),
              curve: Curves.easeOutCubic,
            ),

        const SizedBox(height: 12),

        // "RUN" bold
        Text(
              'RUNNERS',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 24,
                height: 1,
                shadows: [
                  Shadow(color: accent.withValues(alpha: 0.6), blurRadius: 40),
                  Shadow(color: accent.withValues(alpha: 0.3), blurRadius: 80),
                ],
              ),
            )
            .animate()
            .fadeIn(duration: 600.ms, delay: _d(500))
            .slideY(
              begin: 0.3,
              end: 0,
              duration: 500.ms,
              curve: Curves.easeOutCubic,
            ),
      ],
    );
  }

  /// Shared top-bar chip — fixed height so coin/skin chips align perfectly.
  Widget _topChip({
    required Color accent,
    required Widget child,
    VoidCallback? onTap,
  }) {
    final chip = Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.3), width: 0.5),
      ),
      child: child,
    );
    if (onTap == null) return chip;
    return TapScale(minSize: MR.minTouchTarget, onTap: onTap, child: chip);
  }

  /// Compact current-skin chip for the top bar → opens the Skin selector
  /// (which in turn hosts the Skin Creator/Builder).
  /// Bottom skin showcase — entry to the Skin selector + Creator. Doubles as the
  /// Pro pitch (the Creator is a Pro feature), replacing the old GO PRO button.
  Widget _buildSkinShowcase() {
    final skin = widget.game.skinService.currentSkin;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 22),
      child: ValueListenableBuilder<bool>(
        valueListenable: widget.game.adService.proStatusNotifier,
        builder: (context, isPro, _) => TapScale(
          onTap: () {
            widget.game.overlays.remove('MenuScreen');
            widget.game.overlays.add('SkinSelector');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: MR.accent.withValues(alpha: 0.3), width: 0.5),
              gradient: LinearGradient(
                colors: [
                  MR.accent.withValues(alpha: 0.10),
                  Colors.white.withValues(alpha: 0.02),
                ],
              ),
              boxShadow: [
                BoxShadow(color: MR.accent.withValues(alpha: 0.12), blurRadius: 18, spreadRadius: 1),
              ],
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 70,
                  height: 60,
                  child: ClipRect(
                    child: AnimatedBuilder(
                      animation: _shimmerController,
                      builder: (context, _) => CustomPaint(
                        painter: PlayerScenePainter(
                          leftColor: skin.leftColor,
                          rightColor: skin.rightColor,
                          glowT: _shimmerController.value,
                          headDecoration: skin.headDecoration,
                          faceDecoration: skin.faceDecoration,
                          showScene: false,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        skin.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        isPro ? 'CHANGE SKIN' : 'CREATE YOUR OWN',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.5),
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (!isPro)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: MR.gold.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      '★ PRO',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: MR.gold,
                        letterSpacing: 1,
                      ),
                    ),
                  )
                else
                  Icon(Icons.chevron_right,
                      color: MR.accent.withValues(alpha: 0.5), size: 18),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: _d(1200));
  }

  /// Prominent primary action. Tap or swipe up to start.
  Widget _buildPlayButton(Color accent) {
    return TapScale(
      onTap: () => widget.game.startGame(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragEnd: (details) {
          if (details.velocity.pixelsPerSecond.dy < -100) {
            widget.game.startGame();
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [
                accent.withValues(alpha: 0.35),
                accent.withValues(alpha: 0.12),
              ],
            ),
            border: Border.all(color: accent.withValues(alpha: 0.6), width: 1),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.3),
                blurRadius: 28,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Text(
            'PLAY',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 8,
              color: Colors.white,
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 500.ms, delay: _d(900)).slideY(
          begin: 0.2,
          end: 0,
          duration: 500.ms,
          delay: _d(900),
          curve: Curves.easeOutCubic,
        );
  }

  /// Compact single-row biome progress: one dot per biome, lit up to the
  /// furthest reached. Replaces the dense 11-chip grid.
  Widget _buildBiomeRoadmap() {
    final biomes = BiomeManager.biomes;
    final reached = widget.game.statsService.furthestBiomeIndex
        .clamp(0, biomes.length - 1);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < biomes.length; i++) ...[
              if (i > 0)
                Container(
                  width: 10,
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              _biomeProgressDot(biomes[i].lineL, i <= reached, i == reached),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          biomes[reached].name,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
            color: biomes[reached].lineL.withValues(alpha: 0.8),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: _d(1400));
  }

  Widget _biomeProgressDot(Color color, bool lit, bool current) {
    return Container(
      width: current ? 9 : 7,
      height: current ? 9 : 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: lit ? color.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.12),
        boxShadow: current
            ? [BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 8)]
            : null,
      ),
    );
  }

  Widget _buildDailyCard(Color accent) {
    const gold = MR.gold;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: ValueListenableBuilder<DailyChallenge>(
        valueListenable: widget.game.dailyChallengeService.challengeNotifier,
        builder: (context, daily, _) {
          final streak = widget.game.dailyChallengeService.streak;
          final done = daily.completed;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (done ? gold : accent).withValues(alpha: 0.3),
                width: 0.5,
              ),
              color: Colors.white.withValues(alpha: 0.03),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'DAILY CHALLENGE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                    const Spacer(),
                    if (streak > 0) ...[
                      const Icon(Icons.local_fire_department_rounded,
                          color: gold, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        '$streak',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: gold,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        daily.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: done ? 0.5 : 0.85),
                          decoration:
                              done ? TextDecoration.lineThrough : TextDecoration.none,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (done)
                      const Icon(Icons.check_circle_rounded, color: gold, size: 16)
                    else
                      Text(
                        '+${daily.reward}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: gold,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: daily.fraction,
                    minHeight: 4,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation(done ? gold : accent),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${daily.progress} / ${daily.target}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 10),
                Container(height: 0.5, color: Colors.white.withValues(alpha: 0.08)),
                const SizedBox(height: 8),
                // Daily Seed Run — same obstacle/event patterns for everyone today.
                TapScale(
                  minSize: 40,
                  onTap: () => widget.game.startGame(seeded: true),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.casino_outlined,
                          size: 14, color: accent.withValues(alpha: 0.9)),
                      const SizedBox(width: 6),
                      Text(
                        'PLAY DAILY SEED RUN',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: accent.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 400.ms, delay: _d(1100));
  }
}
