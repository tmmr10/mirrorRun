import 'package:flutter/material.dart';
import '../game/game_state.dart';
import '../game/mirror_run_game.dart';

class CountdownOverlay extends StatefulWidget {
  final MirrorRunGame game;
  const CountdownOverlay({super.key, required this.game});

  @override
  State<CountdownOverlay> createState() => _CountdownOverlayState();
}

class _CountdownOverlayState extends State<CountdownOverlay>
    with TickerProviderStateMixin {
  bool _cancelled = false;

  /// 3 pulses + final expand = 4 phases
  late AnimationController _pulseAnim;
  late AnimationController _expandAnim;
  int _pulseIndex = 0;
  bool _finalExpand = false;

  static const _pulseDuration = Duration(milliseconds: 650);
  static const _pauseBetween = 200; // ms gap between pulses
  static const _expandDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _pulseAnim = AnimationController(vsync: this, duration: _pulseDuration);
    _expandAnim = AnimationController(vsync: this, duration: _expandDuration);
    _runCountdown();
  }

  bool get _alive =>
      mounted &&
      !_cancelled &&
      widget.game.playState == PlayState.countdown;

  Future<bool> _pauseAwareDelay(int ms) async {
    final sw = Stopwatch()..start();
    while (sw.elapsedMilliseconds < ms) {
      if (!_alive) return false;
      await Future.delayed(const Duration(milliseconds: 16));
      if (widget.game.paused) {
        sw.stop();
        while (widget.game.paused && _alive) {
          await Future.delayed(const Duration(milliseconds: 30));
        }
        if (!_alive) return false;
        sw.start();
      }
    }
    return _alive;
  }

  void _runCountdown() async {
    // 3 heartbeat pulses
    for (int i = 0; i < 3; i++) {
      if (!_alive) return;
      setState(() => _pulseIndex = i);
      _pulseAnim.forward(from: 0);
      if (!await _pauseAwareDelay(_pulseDuration.inMilliseconds + _pauseBetween)) return;
    }

    // Final expand
    if (!_alive) return;
    setState(() => _finalExpand = true);
    _expandAnim.forward(from: 0);
    if (!await _pauseAwareDelay(_expandDuration.inMilliseconds)) return;

    widget.game.endCountdown();
  }

  @override
  void dispose() {
    _cancelled = true;
    _pulseAnim.dispose();
    _expandAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skin = widget.game.skinService.currentSkin;
    final leftColor = skin.leftColor;
    final rightColor = skin.rightColor;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final centerX = screenWidth / 2;

    return AnimatedBuilder(
      animation: _finalExpand ? _expandAnim : _pulseAnim,
      builder: (context, _) {
        if (_finalExpand) {
          return _buildFinalExpand(_expandAnim.value, centerX, screenWidth, screenHeight, leftColor, rightColor);
        }

        return _buildPulse(_pulseAnim.value, centerX, screenHeight, leftColor, rightColor);
      },
    );
  }

  Widget _buildPulse(double t, double centerX, double screenHeight, Color leftColor, Color rightColor) {
    // Heartbeat: quick expand then contract
    // Sharp attack, soft release
    final curve = t < 0.3
        ? Curves.easeOut.transform(t / 0.3) // fast expand
        : Curves.easeInCubic.transform((1.0 - t) / 0.7); // slow contract
    final intensity = curve;

    // Each pulse gets stronger
    final pulseStrength = 0.4 + _pulseIndex * 0.3; // 0.4, 0.7, 1.0
    final width = 1.0 + intensity * 8 * pulseStrength;
    final alpha = intensity * 0.5 * pulseStrength;
    final glowRadius = 4.0 + intensity * 20 * pulseStrength;

    return Stack(
      children: [
        // Glow behind the line
        Positioned(
          left: centerX - glowRadius,
          top: 0,
          bottom: 0,
          width: glowRadius * 2,
          child: Opacity(
            opacity: alpha * 0.4,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.transparent,
                    Color.lerp(leftColor, rightColor, 0.5)!.withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        // Main mirror line
        Positioned(
          left: centerX - width / 2,
          top: 0,
          bottom: 0,
          child: Container(
            width: width,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  leftColor.withValues(alpha: alpha * 0.6),
                  Color.lerp(leftColor, rightColor, 0.5)!.withValues(alpha: alpha),
                  rightColor.withValues(alpha: alpha * 0.6),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
              ),
            ),
          ),
        ),

        // Bright center core
        Positioned(
          left: centerX - width * 0.3,
          top: screenHeight * 0.3,
          bottom: screenHeight * 0.3,
          child: Container(
            width: width * 0.6,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.white.withValues(alpha: alpha * 0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinalExpand(double t, double centerX, double screenWidth, double screenHeight, Color leftColor, Color rightColor) {
    final expandT = Curves.easeOutCubic.transform(t);
    final fadeT = Curves.easeIn.transform(t);

    // Line expands from thin to full screen width
    final width = 2.0 + expandT * screenWidth;
    final alpha = (1.0 - fadeT) * 0.35;

    return Stack(
      children: [
        // Expanding flash
        Positioned(
          left: centerX - width / 2,
          top: 0,
          bottom: 0,
          child: Opacity(
            opacity: alpha,
            child: Container(
              width: width,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    leftColor.withValues(alpha: 0.0),
                    leftColor,
                    Colors.white,
                    rightColor,
                    rightColor.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
