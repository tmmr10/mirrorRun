import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../game/mirror_run_game.dart';
import '../models/player_skin.dart';
import 'tap_scale.dart';

class MenuScreen extends StatefulWidget {
  final MirrorRunGame game;
  const MenuScreen({super.key, required this.game});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  static bool _firstOpen = true;
  late AnimationController _shimmerController;
  bool _isPurchasing = false;

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
    widget.game.adService.onAdFreeChanged = () {
      if (mounted) setState(() {});
    };
  }

  @override
  void dispose() {
    widget.game.adService.onAdFreeChanged = null;
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
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (kDebugMode && !widget.game.screenshotMode)
                        TapScale(
                          onTap: () {
                            widget.game.overlays.remove('MenuScreen');
                            widget.game.overlays.add('DebugOverlay');
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.bug_report,
                              color: const Color(
                                0xFFFF4444,
                              ).withValues(alpha: 0.5),
                              size: 24,
                            ),
                          ),
                        ),
                      TapScale(
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
                    child: Column(
                      children: [
                        const Spacer(flex: 3),
                        _buildTitle(accentColor),
                        const SizedBox(height: 40),
                        _buildStartPrompt(accentColor),
                        const SizedBox(height: 48),
                        _buildBiomeRoadmap(),
                        const Spacer(),
                        _buildSkinIndicator(accentColor),
                        SizedBox(height: MediaQuery.of(context).size.height * 0.17),
                      ],
                    ),
                  ),
                ),

                // Bottom: ad free button
                if (!widget.game.adService.isAdFree &&
                    !widget.game.screenshotMode)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: TapScale(
                      onTap: _isPurchasing
                          ? null
                          : () async {
                              setState(() => _isPurchasing = true);
                              await widget.game.adService.purchaseAdFree();
                              if (mounted)
                                setState(() => _isPurchasing = false);
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: accentColor.withValues(alpha: 0.25),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: _isPurchasing
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: accentColor.withValues(alpha: 0.5),
                                ),
                              )
                            : Text(
                                'AD FREE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.5),
                                  letterSpacing: 3,
                                  shadows: [
                                    Shadow(
                                      color: accentColor.withValues(alpha: 0.3),
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: _d(1600)),
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

  Widget _buildSkinIndicator(Color accent) {
    final skin = widget.game.skinService.currentSkin;
    return TapScale(
      onTap: () {
        widget.game.overlays.remove('MenuScreen');
        widget.game.overlays.add('SkinSelector');
      },
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, _) {
          final glowT = _shimmerController.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Color.lerp(
                  skin.leftColor,
                  skin.rightColor,
                  glowT,
                )!.withValues(alpha: 0.25 + glowT * 0.1),
                width: 0.8,
              ),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  skin.leftColor.withValues(alpha: 0.06),
                  Colors.transparent,
                  skin.rightColor.withValues(alpha: 0.06),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: skin.leftColor.withValues(alpha: 0.08 + glowT * 0.06),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: skin.rightColor.withValues(alpha: 0.06 + glowT * 0.04),
                  blurRadius: 20,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomPaint(
                  size: const Size(70, 50),
                  painter: _MiniSkinPainter(
                    leftColor: skin.leftColor,
                    rightColor: skin.rightColor,
                    glowT: glowT,
                    headDecoration: skin.headDecoration,
                    faceDecoration: skin.faceDecoration,
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skin.name,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'CHANGE SKIN',
                      style: TextStyle(
                        fontSize: 8,
                        color: accent.withValues(alpha: 0.45),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_right,
                  color: accent.withValues(alpha: 0.35),
                  size: 16,
                ),
              ],
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 400.ms, delay: _d(800));
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
            .moveY(
              begin: 0,
              end: -6,
              duration: 800.ms,
              curve: Curves.easeInOut,
            ),
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
    ).animate().fadeIn(duration: 400.ms, delay: _d(1200));
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
    ).animate().fadeIn(duration: 500.ms, delay: _d(1400));
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
  final HeadDecoration headDecoration;
  final FaceDecoration faceDecoration;

  _MiniSkinPainter({
    required this.leftColor,
    required this.rightColor,
    required this.glowT,
    this.headDecoration = HeadDecoration.none,
    this.faceDecoration = FaceDecoration.none,
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
          Color.lerp(
            leftColor,
            rightColor,
            0.5,
          )!.withValues(alpha: 0.15 + glowT * 0.1),
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

    // Head decoration
    _drawHeadDecoration(canvas, x, bodyTop, bodyW, color);

    // Eyes
    final eyeY = bodyTop + 6;
    final eyePaint = Paint()..color = const Color(0x80000000);
    canvas.drawCircle(Offset(x - 2.5, eyeY), 1.5, eyePaint);
    canvas.drawCircle(Offset(x + 2.5, eyeY), 1.5, eyePaint);

    // Face decoration
    _drawFaceDecoration(canvas, x, eyeY, bodyW, color);
  }

  void _drawFaceDecoration(
    Canvas canvas,
    double x,
    double eyeY,
    double bodyW,
    Color color,
  ) {
    switch (faceDecoration) {
      case FaceDecoration.none:
        break;
      case FaceDecoration.goggles:
        _drawGoggles(canvas, x, eyeY, bodyW);
      case FaceDecoration.visor:
        _drawVisor(canvas, x, eyeY, bodyW, color);
      case FaceDecoration.mask:
        _drawMask(canvas, x, eyeY, bodyW);
      case FaceDecoration.monocle:
        _drawMonocle(canvas, x, eyeY);
      case FaceDecoration.scar:
        _drawScar(canvas, x, eyeY);
      case FaceDecoration.shades:
        _drawShades(canvas, x, eyeY, bodyW);
    }
  }

  void _drawHeadDecoration(
    Canvas canvas,
    double x,
    double bodyTop,
    double bodyW,
    Color color,
  ) {
    switch (headDecoration) {
      case HeadDecoration.none:
        break;
      case HeadDecoration.iceCrown:
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
      case HeadDecoration.flames:
        final t = glowT * pi * 4;
        final colors = [
          const Color(0xDDFF6600),
          const Color(0xBBFFAA00),
          const Color(0x99FF3300),
        ];
        for (int i = 0; i < 3; i++) {
          final dx = (i - 1) * 3.0;
          final phase = t + i * 2.1;
          final fh = -2.5 - sin(phase) * 2.5 - (i == 1 ? 2 : 0);
          final fw = 2.0 + sin(phase * 0.7);
          final path = Path()
            ..moveTo(x + dx - fw, bodyTop + 1)
            ..quadraticBezierTo(
              x + dx - fw * 0.3,
              bodyTop + fh - 1.2,
              x + dx,
              bodyTop + fh,
            )
            ..quadraticBezierTo(
              x + dx + fw * 0.3,
              bodyTop + fh - 1.2,
              x + dx + fw,
              bodyTop + 1,
            )
            ..close();
          canvas.drawPath(
            path,
            Paint()
              ..color = colors[i].withValues(alpha: 0.3)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
          );
          canvas.drawPath(path, Paint()..color = colors[i]);
        }
      case HeadDecoration.crown:
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
        canvas.drawCircle(
          Offset(x, bodyTop - 2.5),
          0.8,
          Paint()..color = const Color(0xFFFF4444),
        );
      case HeadDecoration.antenna:
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
        canvas.drawCircle(
          Offset(x, tipY),
          2,
          Paint()
            ..color = color.withValues(alpha: 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawCircle(Offset(x, tipY), 1.3, Paint()..color = color);
      case HeadDecoration.halo:
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
      case HeadDecoration.horns:
        final paint = Paint()..color = const Color(0xDDCC2222);
        final glow = Paint()
          ..color = const Color(0x40FF0000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        for (final side in [-1.0, 1.0]) {
          final path = Path()
            ..moveTo(x + side * 3, bodyTop + 1)
            ..quadraticBezierTo(
              x + side * 6,
              bodyTop - 1,
              x + side * 5.5,
              bodyTop - 5,
            )
            ..lineTo(x + side * 4, bodyTop - 0.5)
            ..close();
          canvas.drawPath(path, glow);
          canvas.drawPath(path, paint);
        }
      case HeadDecoration.wings:
        final flapY = sin(glowT * pi * 3) * 1.2;
        final paint = Paint()..color = color.withValues(alpha: 0.6);
        final glow = Paint()
          ..color = color.withValues(alpha: 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        for (final side in [-1.0, 1.0]) {
          final wingX = x + side * 8;
          final path = Path()
            ..moveTo(x + side * 5, bodyTop + 5)
            ..quadraticBezierTo(
              wingX + side * 3,
              bodyTop + 1 + flapY,
              wingX + side * 1.5,
              bodyTop - 1 + flapY,
            )
            ..quadraticBezierTo(
              wingX,
              bodyTop + 4 + flapY,
              x + side * 5,
              bodyTop + 12,
            )
            ..close();
          canvas.drawPath(path, glow);
          canvas.drawPath(path, paint);
        }
      case HeadDecoration.mohawk:
        final paint = Paint()..color = color;
        final glow = Paint()
          ..color = color.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        for (int i = 0; i < 5; i++) {
          final dx = (i - 2) * 2.0;
          final h = i == 2 ? -7.0 : (i == 1 || i == 3 ? -5.0 : -3.0);
          final path = Path()
            ..moveTo(x + dx - 1, bodyTop + 1)
            ..lineTo(x + dx, bodyTop + h)
            ..lineTo(x + dx + 1, bodyTop + 1)
            ..close();
          canvas.drawPath(path, glow);
          canvas.drawPath(path, paint);
        }
      case HeadDecoration.star:
        final bobY = sin(glowT * pi * 2) * 1.2;
        final starY = bodyTop - 7 + bobY;
        final starPaint = Paint()..color = const Color(0xFFFFDD44);
        final starGlow = Paint()
          ..color = const Color(0x60FFDD44)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        final path = Path();
        for (int i = 0; i < 5; i++) {
          final outerAngle = -pi / 2 + i * 2 * pi / 5;
          final innerAngle = outerAngle + pi / 5;
          final ox = x + cos(outerAngle) * 3.5;
          final oy = starY + sin(outerAngle) * 3.5;
          final ix = x + cos(innerAngle) * 1.4;
          final iy = starY + sin(innerAngle) * 1.4;
          if (i == 0) {
            path.moveTo(ox, oy);
          } else {
            path.lineTo(ox, oy);
          }
          path.lineTo(ix, iy);
        }
        path.close();
        canvas.drawPath(path, starGlow);
        canvas.drawPath(path, starPaint);
    }
  }

  void _drawVisor(
    Canvas canvas,
    double x,
    double eyeY,
    double bodyW,
    Color color,
  ) {
    final visorRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(x, eyeY), width: bodyW - 1, height: 3.5),
      const Radius.circular(1.8),
    );
    canvas.drawRRect(
      visorRect,
      Paint()
        ..color = color.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawRRect(visorRect, Paint()..color = color.withValues(alpha: 0.7));
    canvas.drawLine(
      Offset(x - bodyW / 2 + 2, eyeY - 0.7),
      Offset(x + bodyW / 2 - 2, eyeY - 0.7),
      Paint()
        ..color = const Color(0x55FFFFFF)
        ..strokeWidth = 0.6,
    );
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

    canvas.drawLine(
      Offset(x - bodyW / 2, eyeY),
      Offset(x + bodyW / 2, eyeY),
      strap,
    );

    for (final dx in [-2.5, 2.5]) {
      final lr = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x + dx, eyeY), width: 5, height: 4),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(lr, lens);
      canvas.drawRRect(lr, frame);
      canvas.drawCircle(
        Offset(x + dx - 1, eyeY - 1),
        0.7,
        Paint()..color = const Color(0x55FFFFFF),
      );
    }
  }

  void _drawMask(Canvas canvas, double x, double eyeY, double bodyW) {
    final maskRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(x, eyeY), width: bodyW + 1, height: 4.5),
      const Radius.circular(2.2),
    );
    canvas.drawRRect(maskRect, Paint()..color = const Color(0xDD111111));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x - 2.5, eyeY), width: 4, height: 3),
      Paint()..color = const Color(0xFF222222),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x + 2.5, eyeY), width: 4, height: 3),
      Paint()..color = const Color(0xFF222222),
    );
  }

  void _drawMonocle(Canvas canvas, double x, double eyeY) {
    canvas.drawLine(
      Offset(x + 2.5, eyeY + 2),
      Offset(x + 4, eyeY + 7),
      Paint()
        ..color = const Color(0x99FFD700)
        ..strokeWidth = 0.5,
    );
    canvas.drawCircle(
      Offset(x + 2.5, eyeY),
      3,
      Paint()
        ..color = const Color(0xCCFFD700)
        ..strokeWidth = 0.8
        ..style = ui.PaintingStyle.stroke,
    );
    canvas.drawCircle(
      Offset(x + 1.8, eyeY - 0.8),
      0.7,
      Paint()..color = const Color(0x44FFFFFF),
    );
  }

  void _drawScar(Canvas canvas, double x, double eyeY) {
    canvas.drawLine(
      Offset(x - 4, eyeY - 3.5),
      Offset(x - 0.5, eyeY + 3.5),
      Paint()
        ..color = const Color(0xCCCC4444)
        ..strokeWidth = 1.2
        ..strokeCap = ui.StrokeCap.round,
    );
    for (final dy in [-1.5, 0.8, 3.0]) {
      final cx = x - 2.2 + dy * 0.35;
      canvas.drawLine(
        Offset(cx - 0.8, eyeY + dy - 0.3),
        Offset(cx + 0.8, eyeY + dy + 0.3),
        Paint()
          ..color = const Color(0x88CC4444)
          ..strokeWidth = 0.6,
      );
    }
  }

  void _drawShades(Canvas canvas, double x, double eyeY, double bodyW) {
    canvas.drawLine(
      Offset(x - 2, eyeY - 0.7),
      Offset(x + 2, eyeY - 0.7),
      Paint()
        ..color = const Color(0xCC111111)
        ..strokeWidth = 0.8,
    );
    for (final dx in [-2.8, 2.8]) {
      final lr = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x + dx, eyeY), width: 6, height: 4),
        const Radius.circular(1.2),
      );
      canvas.drawRRect(lr, Paint()..color = const Color(0xEE111111));
      canvas.drawRRect(
        lr,
        Paint()
          ..color = const Color(0x33FFFFFF)
          ..strokeWidth = 0.4
          ..style = ui.PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MiniSkinPainter old) =>
      old.glowT != glowT ||
      old.leftColor != leftColor ||
      old.rightColor != rightColor ||
      old.headDecoration != headDecoration ||
      old.faceDecoration != faceDecoration;
}
