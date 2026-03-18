import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/widgets.dart' show WidgetsBindingObserver, AppLifecycleState, WidgetsBinding;
import '../game/components/event_system.dart';
import '../game/game_state.dart';
import '../game/mirror_run_game.dart';
import '../game/world/biome.dart';
import 'tap_scale.dart';

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
    final color = warning == 'PHANTOM'
        ? const Color(0xFF44DDFF)
        : const Color(0xFFFF5028);
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
    final isPhantom = event == GameEvent.phantom;
    final label = isPhantom ? 'PHANTOM' : 'SWAPPED';
    final color = isPhantom
        ? const Color(0xFF44DDFF)
        : const Color(0xFFFF5028);
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

            // Top-center label bar
            Positioned(
              bottom: 120,
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


  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Event indicator (centered)
        _buildEventIndicator(),

        // Score — centered horizontally, top
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Align(
              alignment: Alignment.topCenter,
              child: ValueListenableBuilder<int>(
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
                      _showQuitConfirm ? Icons.close_rounded : Icons.arrow_back_rounded,
                      size: 14,
                      color: Colors.white.withValues(alpha: _showQuitConfirm ? 0.6 : 0.35),
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
                              color: const Color(0xFFFF6B35).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: const Color(0xFFFF6B35).withValues(alpha: 0.4),
                                width: 0.5,
                              ),
                            ),
                            child: const Text(
                              'QUIT',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFF6B35),
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
