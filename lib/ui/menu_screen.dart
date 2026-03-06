import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../game/mirror_run_game.dart';
import '../models/player_skin.dart';

class MenuScreen extends StatefulWidget {
  final MirrorRunGame game;
  const MenuScreen({super.key, required this.game});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFB48CFF);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xF00a0a0f),
            const Color(0xF0080812),
            const Color(0xF00f0a14),
          ],
        ),
      ),
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
                        accentColor.withValues(alpha: 0.4 + 0.3 * sin(t * pi * 2)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
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

                // Center: tappable area with title, prompt, roadmap
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => widget.game.startGame(),
                    onVerticalDragEnd: (details) {
                      if (details.velocity.pixelsPerSecond.dy < -100) {
                        widget.game.startGame();
                      }
                    },
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTitle(accentColor),
                          const SizedBox(height: 16),
                          _buildSkinIndicator(accentColor),
                          const SizedBox(height: 40),
                          _buildStartPrompt(accentColor),
                          const SizedBox(height: 48),
                          _buildBiomeRoadmap(),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom: ad free button
                if (!widget.game.adService.isAdFree)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: GestureDetector(
                      onTap: () => widget.game.adService.purchaseAdFree(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.5),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.3),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Text(
                          'AD FREE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 3,
                            shadows: [
                              Shadow(color: accentColor.withValues(alpha: 0.8), blurRadius: 20),
                              Shadow(color: accentColor.withValues(alpha: 0.4), blurRadius: 40),
                            ],
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 400.ms, delay: 1600.ms),
                  ),
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
            .fadeIn(duration: 800.ms, delay: 200.ms)
            .slideY(begin: -0.3, end: 0, duration: 600.ms, curve: Curves.easeOutCubic),

        Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(1.0, -1.0, 1.0),
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [accent.withValues(alpha: 0.5), Colors.transparent],
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
        )
            .animate()
            .fadeIn(duration: 800.ms, delay: 400.ms),

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
            .fadeIn(duration: 600.ms, delay: 600.ms)
            .scaleX(begin: 0, end: 1, duration: 500.ms, delay: 600.ms, curve: Curves.easeOutCubic),

        const SizedBox(height: 12),

        // "RUN" bold
        Text(
          'RUN',
          style: TextStyle(
            fontSize: 52,
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
            .fadeIn(duration: 600.ms, delay: 500.ms)
            .slideY(begin: 0.3, end: 0, duration: 500.ms, curve: Curves.easeOutCubic),
      ],
    );
  }

  Widget _buildSkinIndicator(Color accent) {
    final skin = widget.game.skinService.currentSkin;
    return GestureDetector(
      onTap: () {
        widget.game.overlays.remove('MenuScreen');
        widget.game.overlays.add('SkinSelector');
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _shimmerController,
            builder: (context, _) {
              return CustomPaint(
                size: const Size(70, 50),
                painter: _MiniSkinPainter(
                  leftColor: skin.leftColor,
                  rightColor: skin.rightColor,
                  glowT: _shimmerController.value,
                  decoration: skin.decoration,
                ),
              );
            },
          ),
          Icon(
            Icons.chevron_right,
            color: accent.withValues(alpha: 0.4),
            size: 16,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 800.ms);
  }

  Widget _buildStartPrompt(Color accent) {
    return Column(
      children: [
        // Animated arrow up
        Icon(
          Icons.keyboard_arrow_up_rounded,
          color: accent.withValues(alpha: 0.5),
          size: 28,
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: 0, end: -6, duration: 800.ms, curve: Curves.easeInOut),
        const SizedBox(height: 4),
        Text(
          'TAP TO START',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: accent.withValues(alpha: 0.7),
            letterSpacing: 4,
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .fadeIn(duration: 1200.ms)
            .then()
            .fadeOut(duration: 1200.ms),
      ],
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 1200.ms);
  }

  Widget _buildBiomeRoadmap() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: [
        _biomeChip('FOREST', const Color(0xFF2d8c3a)),
        _biomeDot(),
        _biomeChip('CITY', const Color(0xFF4a5a7a)),
        _biomeDot(),
        _biomeChip('CRYSTAL', const Color(0xFF40CCEE)),
        _biomeDot(),
        _biomeChip('VOLCANO', const Color(0xFFaa4422)),
        _biomeDot(),
        _biomeChip('DESERT', const Color(0xFFCC9933)),
        _biomeDot(),
        _biomeChip('OCEAN', const Color(0xFF1a6090)),
        _biomeDot(),
        _biomeChip('RUINS', const Color(0xFF5A8A5A)),
        _biomeDot(),
        _biomeChip('SPACE', const Color(0xFF2020aa)),
        _biomeDot(),
        _biomeChip('STORM', const Color(0xFF7744BB)),
        _biomeDot(),
        _biomeChip('NEON', const Color(0xFF8800ff)),
        _biomeDot(),
        _biomeChip('VOID', const Color(0xFF333333)),
      ],
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 1400.ms);
  }

  Widget _biomeChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: color.withValues(alpha: 0.6),
          letterSpacing: 1.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _biomeDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: 3,
        height: 3,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _MiniSkinPainter extends CustomPainter {
  final Color leftColor;
  final Color rightColor;
  final double glowT;
  final SkinDecoration decoration;

  _MiniSkinPainter({
    required this.leftColor,
    required this.rightColor,
    required this.glowT,
    required this.decoration,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final mid = w / 2;

    // Mirror line (vertical, glowing)
    final mirrorPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(mid, 0),
        Offset(mid, h),
        [
          Colors.transparent,
          Color.lerp(leftColor, rightColor, 0.5)!.withValues(alpha: 0.15 + glowT * 0.1),
          Colors.transparent,
        ],
        [0.0, 0.5, 1.0],
      );
    canvas.drawLine(Offset(mid, h * 0.1), Offset(mid, h * 0.95), mirrorPaint);

    // Left player
    _drawPlayer(canvas, mid * 0.5, h * 0.82, leftColor);

    // Right player
    _drawPlayer(canvas, mid + mid * 0.5, h * 0.82, rightColor);
  }

  void _drawPlayer(Canvas canvas, double x, double groundY, Color color) {
    const bodyW = 14.0;
    const bodyH = 20.0;
    final bodyTop = groundY - bodyH;
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x - bodyW / 2, bodyTop, bodyW, bodyH),
      const Radius.circular(5),
    );

    // Outer glow
    canvas.drawRRect(
      bodyRect.inflate(3 + glowT * 2),
      Paint()
        ..color = color.withValues(alpha: 0.08 + glowT * 0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Inner glow
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..color = color.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Body
    canvas.drawRRect(bodyRect, Paint()..color = color);

    // Decoration
    _drawDecoration(canvas, x, bodyTop, bodyW, color);

    // Eyes
    final eyeY = bodyTop + 6;
    final eyePaint = Paint()..color = const Color(0x80000000);
    canvas.drawCircle(Offset(x - 2.5, eyeY), 1.5, eyePaint);
    canvas.drawCircle(Offset(x + 2.5, eyeY), 1.5, eyePaint);

    // Goggles over eyes
    if (decoration == SkinDecoration.goggles) {
      _drawGoggles(canvas, x, eyeY, bodyW);
    }
  }

  void _drawDecoration(Canvas canvas, double x, double bodyTop, double bodyW, Color color) {
    switch (decoration) {
      case SkinDecoration.none:
        break;
      case SkinDecoration.iceCrown:
        final paint = Paint()..color = const Color(0xCCAAEEFF);
        final glow = Paint()
          ..color = const Color(0x4400CCFF)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        for (final dx in [-3.0, 0.0, 3.0]) {
          final h = dx == 0 ? -5.0 : -3.5;
          final path = Path()
            ..moveTo(x + dx - 1.2, bodyTop)
            ..lineTo(x + dx, bodyTop + h)
            ..lineTo(x + dx + 1.2, bodyTop)
            ..close();
          canvas.drawPath(path, glow);
          canvas.drawPath(path, paint);
        }
      case SkinDecoration.flames:
        final t = glowT * pi * 4;
        final colors = [const Color(0xDDFF6600), const Color(0xBBFFAA00), const Color(0x99FF3300)];
        for (int i = 0; i < 3; i++) {
          final dx = (i - 1) * 3.0;
          final phase = t + i * 2.1;
          final fh = -2.5 - sin(phase) * 2.5 - (i == 1 ? 2 : 0);
          final fw = 2.0 + sin(phase * 0.7);
          final path = Path()
            ..moveTo(x + dx - fw, bodyTop + 1)
            ..quadraticBezierTo(x + dx - fw * 0.3, bodyTop + fh - 1.2, x + dx, bodyTop + fh)
            ..quadraticBezierTo(x + dx + fw * 0.3, bodyTop + fh - 1.2, x + dx + fw, bodyTop + 1)
            ..close();
          canvas.drawPath(path, Paint()
            ..color = colors[i].withValues(alpha: 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
          canvas.drawPath(path, Paint()..color = colors[i]);
        }
      case SkinDecoration.crown:
        final paint = Paint()..color = const Color(0xFFFFD700);
        final glow = Paint()
          ..color = const Color(0x60FFD700)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        final path = Path()
          ..moveTo(x - 5, bodyTop + 1)
          ..lineTo(x - 5, bodyTop - 2.5)
          ..lineTo(x - 2.5, bodyTop - 0.5)
          ..lineTo(x, bodyTop - 4.5)
          ..lineTo(x + 2.5, bodyTop - 0.5)
          ..lineTo(x + 5, bodyTop - 2.5)
          ..lineTo(x + 5, bodyTop + 1)
          ..close();
        canvas.drawPath(path, glow);
        canvas.drawPath(path, paint);
        canvas.drawCircle(Offset(x, bodyTop - 2.5), 0.8, Paint()..color = const Color(0xFFFF4444));
      case SkinDecoration.goggles:
        break; // drawn after eyes
      case SkinDecoration.antenna:
        final bobY = sin(glowT * pi * 2) * 1.2;
        canvas.drawLine(
          Offset(x, bodyTop + 1),
          Offset(x, bodyTop - 5 + bobY),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.6)
            ..strokeWidth = 1
            ..strokeCap = ui.StrokeCap.round,
        );
        final tipY = bodyTop - 5.5 + bobY;
        canvas.drawCircle(Offset(x, tipY), 2, Paint()
          ..color = color.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
        canvas.drawCircle(Offset(x, tipY), 1.3, Paint()..color = color);
      case SkinDecoration.halo:
        final bobY = sin(glowT * pi * 2) * 1.0;
        final haloY = bodyTop - 4 + bobY;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, haloY), width: 13, height: 4),
          Paint()
            ..color = const Color(0x30FFFFFF)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, haloY), width: 12, height: 3.5),
          Paint()
            ..color = const Color(0xCCFFFFFF)
            ..strokeWidth = 1
            ..style = ui.PaintingStyle.stroke,
        );
    }
  }

  void _drawGoggles(Canvas canvas, double x, double eyeY, double bodyW) {
    final strap = Paint()
      ..color = const Color(0xBB000000)
      ..strokeWidth = 1
      ..style = ui.PaintingStyle.stroke;
    final lens = Paint()..color = const Color(0xCC88DDFF);
    final frame = Paint()
      ..color = const Color(0xCC444444)
      ..strokeWidth = 0.8
      ..style = ui.PaintingStyle.stroke;

    canvas.drawLine(Offset(x - bodyW / 2, eyeY), Offset(x + bodyW / 2, eyeY), strap);

    for (final dx in [-2.5, 2.5]) {
      final lr = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x + dx, eyeY), width: 5, height: 4),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(lr, lens);
      canvas.drawRRect(lr, frame);
      canvas.drawCircle(Offset(x + dx - 1, eyeY - 1), 0.7, Paint()..color = const Color(0x55FFFFFF));
    }
  }

  @override
  bool shouldRepaint(covariant _MiniSkinPainter old) =>
      old.glowT != glowT || old.leftColor != leftColor || old.rightColor != rightColor || old.decoration != decoration;
}
