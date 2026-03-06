import 'package:flutter/material.dart';
import '../game/mirror_run_game.dart';

class CountdownOverlay extends StatefulWidget {
  final MirrorRunGame game;
  const CountdownOverlay({super.key, required this.game});

  @override
  State<CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<CountdownOverlay> {
  int _count = 3;

  @override
  void initState() {
    super.initState();
    _tick();
  }

  void _tick() async {
    for (int i = 3; i >= 1; i--) {
      if (!mounted) return;
      setState(() => _count = i);
      await Future.delayed(const Duration(milliseconds: 700));
    }
    if (!mounted) return;
    setState(() => _count = 0); // "GO"
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    widget.game.endCountdown();
  }

  @override
  Widget build(BuildContext context) {
    final label = _count > 0 ? '$_count' : 'GO';
    final isGo = _count == 0;

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
            fontSize: isGo ? 48 : 64,
            fontWeight: isGo ? FontWeight.w800 : FontWeight.w200,
            color: isGo
                ? Colors.white
                : Colors.white.withValues(alpha: 0.6),
            letterSpacing: isGo ? 12 : 4,
            height: 1,
            shadows: [
              Shadow(
                color: (isGo ? const Color(0xFF44FF44) : Colors.white)
                    .withValues(alpha: 0.3),
                blurRadius: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
