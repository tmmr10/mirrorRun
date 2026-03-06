import 'package:flutter/material.dart';
import '../game/game_state.dart';
import '../game/mirror_run_game.dart';
import '../game/world/biome.dart';

class CountdownOverlay extends StatefulWidget {
  final MirrorRunGame game;
  const CountdownOverlay({super.key, required this.game});

  @override
  State<CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<CountdownOverlay> {
  int _count = 3;
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  bool get _alive =>
      mounted &&
      !_cancelled &&
      widget.game.playState == PlayState.countdown;

  /// Delay that freezes while the engine is paused.
  Future<bool> _pauseAwareDelay(int ms) async {
    final sw = Stopwatch()..start();
    while (sw.elapsedMilliseconds < ms) {
      if (!_alive) return false;
      await Future.delayed(const Duration(milliseconds: 30));
      // While paused, don't count elapsed time
      if (widget.game.paused) {
        sw.stop();
        // Wait until unpaused or cancelled
        while (widget.game.paused && _alive) {
          await Future.delayed(const Duration(milliseconds: 30));
        }
        if (!_alive) return false;
        sw.start();
      }
    }
    return _alive;
  }

  void _tick() async {
    for (int i = 3; i >= 1; i--) {
      if (!_alive) return;
      if (mounted) setState(() => _count = i);
      if (!await _pauseAwareDelay(700)) return;
    }
    if (!_alive) return;
    if (mounted) setState(() => _count = 0); // "GO"
    if (!await _pauseAwareDelay(500)) return;
    widget.game.endCountdown();
  }

  @override
  void dispose() {
    _cancelled = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = _count > 0 ? '$_count' : 'GO';
    final isGo = _count == 0;
    final biome = BiomeManager.getBiome(widget.game.score);
    final glowColor = isGo ? const Color(0xFF44FF44) : biome.lineL;

    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Text(
          label,
          key: ValueKey(_count),
          style: TextStyle(
            fontSize: isGo ? 56 : 72,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: isGo ? 14 : 6,
            height: 1,
            shadows: [
              Shadow(color: glowColor.withValues(alpha: 0.9), blurRadius: 24),
              Shadow(color: glowColor.withValues(alpha: 0.6), blurRadius: 48),
              Shadow(color: glowColor.withValues(alpha: 0.3), blurRadius: 80),
            ],
          ),
        ),
      ),
    );
  }
}
