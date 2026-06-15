import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../game/components/event_system.dart';
import '../game/components/power_up.dart';
import '../game/game_state.dart';
import '../game/mirror_run_game.dart';
import '../game/world/biome.dart';
import 'tap_scale.dart';
import 'theme.dart';

class HudOverlay extends StatefulWidget {
  final MirrorRunGame game;
  const HudOverlay({super.key, required this.game});

  @override
  State<HudOverlay> createState() => _HudOverlayState();
}

class _HudOverlayState extends State<HudOverlay> with WidgetsBindingObserver {
  bool _showQuitConfirm = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Show pause screen when app goes to background during gameplay
    if ((state == AppLifecycleState.paused ||
         state == AppLifecycleState.inactive) &&
        widget.game.playState == PlayState.playing &&
        !_showQuitConfirm) {
      widget.game.pauseEngine();
      setState(() => _showQuitConfirm = true);
    }
  }

  void _toggleQuit() {
    if (_showQuitConfirm) {
      setState(() => _showQuitConfirm = false);
      widget.game.resumeEngine();
    } else {
      widget.game.pauseEngine();
      setState(() => _showQuitConfirm = true);
    }
  }

  void _quit() {
    setState(() => _showQuitConfirm = false);
    widget.game.goToMenu();
  }

  Color _comboColor(double combo) {
    if (combo >= 3.0) return const Color(0xFFFF3366); // Hot pink/red
    if (combo >= 2.0) return const Color(0xFFFFAA00); // Orange
    if (combo >= 1.5) return const Color(0xFFFFDD00); // Yellow
    return MR.cyan; // Cyan
  }

  int _comboTier(double combo) {
    if (combo >= 3.0) return 3;
    if (combo >= 2.0) return 2;
    if (combo >= 1.5) return 1;
    if (combo >= 1.2) return 0;
    return -1;
  }

  /// Color per event, keyed by its (warning or active) label.
  Color _eventColorFromLabel(String label) {
    switch (label) {
      case 'PHANTOM':
        return MR.cyan;
      case 'SWAP':
      case 'SWAPPED':
        return const Color(0xFFFF5028);
      case 'DESYNC':
        return MR.accent;
      case 'BLACKOUT':
        return const Color(0xFF8FA3B8);
      default:
        return MR.cyan;
    }
  }

  String _activeLabel(GameEvent e) =>
      e == GameEvent.mirrorSwap ? 'SWAPPED' : eventLabel(e);

  Widget _buildEventIndicator() {
    return ValueListenableBuilder<String?>(
      valueListenable: widget.game.eventWarningNotifier,
      builder: (context, warning, _) {
        return ValueListenableBuilder<GameEvent?>(
          valueListenable: widget.game.eventNotifier,
          builder: (context, event, _) {
            return Stack(
              children: [
                // Warning: full-screen vignette + big text
                if (warning != null && event == null)
                  _buildWarningOverlay(warning),

                // Active event: edge glow + label
                if (event != null)
                  _buildActiveEventOverlay(event),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildWarningOverlay(String warning) {
    final color = _eventColorFromLabel(warning);
    return Positioned.fill(
      key: ValueKey('warning_$warning'),
      child: IgnorePointer(
        child: Stack(
          children: [
            // Colored vignette around screen edges
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.9,
                  colors: [
                    Colors.transparent,
                    color.withValues(alpha: 0.25),
                  ],
                ),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fadeIn(duration: 300.ms)
                .then()
                .fadeOut(duration: 300.ms),

            // Big centered warning text
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 36,
                    color: color.withValues(alpha: 0.9),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    warning,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: color,
                      letterSpacing: 8,
                      shadows: [
                        Shadow(color: color.withValues(alpha: 0.8), blurRadius: 30),
                        Shadow(color: color.withValues(alpha: 0.4), blurRadius: 60),
                      ],
                    ),
                  ),
                ],
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 0.95, end: 1.05, duration: 300.ms)
                  .fadeIn(duration: 200.ms)
                  .then()
                  .fadeOut(duration: 200.ms),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveEventOverlay(GameEvent event) {
    final label = _activeLabel(event);
    final color = _eventColorFromLabel(eventLabel(event));
    return Positioned.fill(
      key: ValueKey('active_$label'),
      child: IgnorePointer(
        child: Stack(
          children: [
            // Persistent colored edge glow
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
              ),
            )
                .animate()
                .fadeIn(duration: 200.ms),

            // Event label bar (kept clear of the home indicator)
            Positioned(
              bottom: 110 + MediaQuery.of(context).padding.bottom,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: color.withValues(alpha: 0.7), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: 4,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 150.ms)
                    .scaleXY(begin: 1.3, end: 1.0, duration: 200.ms, curve: Curves.easeOutBack),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildPowerUpIndicator() {
    return Positioned(
      bottom: 28 + MediaQuery.of(context).padding.bottom,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: ValueListenableBuilder<List<PowerUpType>>(
          valueListenable: widget.game.powerUpsNotifier,
          builder: (context, active, _) {
            if (active.isEmpty) return const SizedBox.shrink();
            return Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final p in active)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: p.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: p.color.withValues(alpha: 0.7), width: 1),
                      ),
                      child: Text(
                        p.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: p.color,
                          letterSpacing: 2,
                        ),
                      ),
                    ).animate().fadeIn(duration: 200.ms).scaleXY(begin: 0.8, end: 1.0, duration: 200.ms),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRecordCue() {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.game.beatRecordNotifier,
      builder: (context, beat, _) {
        if (!beat) return const SizedBox.shrink();
        return Positioned(
          top: MediaQuery.of(context).padding.top + 64,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: Center(
              child: Text(
                'NEW BEST!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: MR.gold,
                  letterSpacing: 4,
                  shadows: [
                    Shadow(color: MR.gold.withValues(alpha: 0.8), blurRadius: 20),
                  ],
                ),
              )
                  .animate(key: const ValueKey('record_cue'))
                  .fadeIn(duration: 250.ms)
                  .scaleXY(begin: 1.4, end: 1.0, duration: 350.ms, curve: Curves.easeOutBack)
                  .then(delay: 1200.ms)
                  .fadeOut(duration: 500.ms)
                  .moveY(begin: 0, end: -14, duration: 500.ms),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Event indicator (centered)
        _buildEventIndicator(),

        // Active power-up chips (bottom-center, above the home indicator)
        _buildPowerUpIndicator(),

        // In-run "new best" cue
        _buildRecordCue(),

        // Score + Combo — centered horizontally, top
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Align(
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder<int>(
                    valueListenable: widget.game.scoreNotifier,
                    builder: (context, score, child) {
                      final biome = BiomeManager.getBiome(score);
                      final glowColor = biome.lineL;
                      return Text(
                        '$score',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                          height: 1,
                          shadows: [
                            Shadow(color: glowColor.withValues(alpha: 0.9), blurRadius: 20),
                            Shadow(color: glowColor.withValues(alpha: 0.5), blurRadius: 40),
                          ],
                        ),
                      );
                    },
                  ),
                  ValueListenableBuilder<double>(
                    valueListenable: widget.game.comboNotifier,
                    builder: (context, combo, child) {
                      // Reserved height for layout stability (avoids score jitter)
                      const rowHeight = 22.0;
                      if (combo <= 1.0) return const SizedBox(height: rowHeight);
                      final tier = _comboTier(combo);
                      final comboColor = _comboColor(combo);
                      // Use fixed display per tier to avoid rounding mismatch with color
                      final display = combo < 2.0
                          ? combo.toStringAsFixed(1)
                          : combo.floor().toString();
                      return SizedBox(
                        height: rowHeight,
                        child: Text(
                          'x$display',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: comboColor,
                            letterSpacing: 3,
                            shadows: [
                              Shadow(color: comboColor.withValues(alpha: 0.8), blurRadius: 12),
                              Shadow(color: comboColor.withValues(alpha: 0.4), blurRadius: 24),
                            ],
                          ),
                        )
                            .animate(key: ValueKey('combo_tier_$tier'))
                            .scaleXY(begin: 1.6, end: 1.0, duration: 300.ms, curve: Curves.easeOutBack)
                            .then()
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scaleXY(begin: 1.0, end: 1.08, duration: 800.ms, curve: Curves.easeInOut),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),

        // Left/right HUD elements
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                TapScale(
                  onTap: _toggleQuit,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _showQuitConfirm
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: _showQuitConfirm
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.06),
                        width: 0.5,
                      ),
                    ),
                    child: Icon(
                      _showQuitConfirm ? Icons.close_rounded : Icons.pause_rounded,
                      size: 20,
                      color: Colors.white.withValues(alpha: _showQuitConfirm ? 0.7 : 0.55),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Biome indicator
                ValueListenableBuilder<String>(
                  valueListenable: widget.game.biomeNotifier,
                  builder: (context, biome, child) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      biome,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.45),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Best score
                ValueListenableBuilder<int>(
                  valueListenable: widget.game.bestNotifier,
                  builder: (context, best, child) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.06),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      'BEST $best',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.35),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Coin balance
                ValueListenableBuilder<int>(
                  valueListenable: widget.game.coinsService.coinsNotifier,
                  builder: (context, coins, child) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: MR.gold.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: MR.gold.withValues(alpha: 0.25),
                        width: 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.circle,
                          color: MR.gold,
                          size: 8,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$coins',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: MR.gold.withValues(alpha: 0.85),
                            letterSpacing: 1,
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

        // Quit confirmation overlay
        if (_showQuitConfirm)
          GestureDetector(
            onTap: _toggleQuit,
            child: Container(
              color: const Color(0xCC000000),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pause icon
                    Icon(
                      Icons.pause_rounded,
                      size: 32,
                      color: Colors.white.withValues(alpha: 0.15),
                    )
                        .animate()
                        .fadeIn(duration: 200.ms)
                        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 200.ms),
                    const SizedBox(height: 24),

                    // Buttons row
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Continue button
                        TapScale(
                          onTap: _toggleQuit,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              'RESUME',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.7),
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 200.ms, delay: 100.ms)
                            .slideX(begin: -0.1, end: 0, duration: 200.ms, delay: 100.ms),
                        const SizedBox(width: 16),

                        // Quit button
                        TapScale(
                          onTap: _quit,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: MR.danger.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: MR.danger.withValues(alpha: 0.4),
                                width: 0.5,
                              ),
                            ),
                            child: const Text(
                              'QUIT',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: MR.danger,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 200.ms, delay: 150.ms)
                            .slideX(begin: 0.1, end: 0, duration: 200.ms, delay: 150.ms),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
