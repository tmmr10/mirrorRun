import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../game/mirror_run_game.dart';
import '../models/player_skin.dart';

class SkinSelector extends StatefulWidget {
  final MirrorRunGame game;
  const SkinSelector({super.key, required this.game});

  @override
  State<SkinSelector> createState() => _SkinSelectorState();
}

class _SkinSelectorState extends State<SkinSelector> with SingleTickerProviderStateMixin {
  static const _accent = Color(0xFFB48CFF);
  late final PageController _pageController;
  late final AnimationController _glowController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Start on selected skin
    final selectedIdx = PlayerSkin.all.indexWhere(
      (s) => s.id == widget.game.skinService.selectedId,
    );
    _currentPage = selectedIdx >= 0 ? selectedIdx : 0;
    _pageController = PageController(
      viewportFraction: 0.65,
      initialPage: _currentPage,
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skinService = widget.game.skinService;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0a0a0f), Color(0xFF080812), Color(0xFF0a060f)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              'SKINS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: _accent,
                letterSpacing: 6,
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms),
            const SizedBox(height: 8),
            Text(
              'SWIPE TO BROWSE',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.25),
                letterSpacing: 3,
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 200.ms),

            // Main carousel
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: PlayerSkin.all.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final skin = PlayerSkin.all[index];
                  final unlocked = skinService.isUnlocked(skin.id);
                  final selected = skinService.selectedId == skin.id;
                  final isCurrent = index == _currentPage;

                  return AnimatedScale(
                    scale: isCurrent ? 1.0 : 0.85,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    child: AnimatedOpacity(
                      opacity: isCurrent ? 1.0 : 0.4,
                      duration: const Duration(milliseconds: 250),
                      child: GestureDetector(
                        onTap: () {
                          if (unlocked) {
                            skinService.selectSkin(skin.id);
                            setState(() {});
                          }
                        },
                        child: _SkinPreview(
                          skin: skin,
                          unlocked: unlocked,
                          selected: selected,
                          glowAnimation: _glowController,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Page dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(PlayerSkin.all.length, (i) {
                final isActive = i == _currentPage;
                final skin = PlayerSkin.all[i];
                final unlocked = skinService.isUnlocked(skin.id);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: isActive
                        ? (unlocked ? skin.leftColor.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.3))
                        : Colors.white.withValues(alpha: 0.12),
                  ),
                );
              }),
            ),

            const SizedBox(height: 32),

            // Back button
            GestureDetector(
              onTap: () {
                widget.game.overlays.remove('SkinSelector');
                widget.game.overlays.add('MenuScreen');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: _accent.withValues(alpha: 0.3), width: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'BACK',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _accent.withValues(alpha: 0.7),
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SkinPreview extends StatelessWidget {
  final PlayerSkin skin;
  final bool unlocked;
  final bool selected;
  final Animation<double> glowAnimation;

  const _SkinPreview({
    required this.skin,
    required this.unlocked,
    required this.selected,
    required this.glowAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: AnimatedBuilder(
        animation: glowAnimation,
        builder: (context, child) {
          final glowT = glowAnimation.value;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? Color.lerp(skin.leftColor, skin.rightColor, glowT)!.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.06),
                width: selected ? 1.5 : 0.5,
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: unlocked ? 0.04 : 0.02),
                  Colors.white.withValues(alpha: 0.01),
                  Colors.transparent,
                ],
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: skin.leftColor.withValues(alpha: 0.15 + glowT * 0.1),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                      BoxShadow(
                        color: skin.rightColor.withValues(alpha: 0.1 + glowT * 0.08),
                        blurRadius: 32,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: unlocked ? _buildUnlockedContent(glowT) : _buildLockedContent(),
          );
        },
      ),
    );
  }

  Widget _buildUnlockedContent(double glowT) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(flex: 2),
        // Mirror scene preview
        SizedBox(
          height: 160,
          child: CustomPaint(
            painter: _PlayerScenePainter(
              leftColor: skin.leftColor,
              rightColor: skin.rightColor,
              glowT: glowT,
              decoration: skin.decoration,
            ),
            size: const Size(200, 160),
          ),
        ),
        const Spacer(),
        // Skin name
        Text(
          skin.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white.withValues(alpha: 0.9),
            letterSpacing: 6,
          ),
        ),
        const SizedBox(height: 8),
        if (selected)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: skin.leftColor.withValues(alpha: 0.15),
              border: Border.all(color: skin.leftColor.withValues(alpha: 0.3), width: 0.5),
            ),
            child: Text(
              'EQUIPPED',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: skin.leftColor.withValues(alpha: 0.8),
                letterSpacing: 3,
              ),
            ),
          )
        else
          Text(
            'TAP TO EQUIP',
            style: TextStyle(
              fontSize: 9,
              color: Colors.white.withValues(alpha: 0.25),
              letterSpacing: 3,
            ),
          ),
        const Spacer(flex: 2),
      ],
    );
  }

  Widget _buildLockedContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(flex: 2),
        Icon(
          Icons.lock_outline_rounded,
          color: Colors.white.withValues(alpha: 0.12),
          size: 48,
        ),
        const SizedBox(height: 20),
        Text(
          skin.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white.withValues(alpha: 0.2),
            letterSpacing: 6,
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            skin.unlockDescription,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.2),
              letterSpacing: 1,
              height: 1.4,
            ),
          ),
        ),
        const Spacer(flex: 2),
      ],
    );
  }
}

class _PlayerScenePainter extends CustomPainter {
  final Color leftColor;
  final Color rightColor;
  final double glowT;
  final SkinDecoration decoration;

  _PlayerScenePainter({
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
    final groundY = h * 0.75;

    // Ground line
    canvas.drawLine(
      Offset(w * 0.1, groundY),
      Offset(w * 0.9, groundY),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.06)
        ..strokeWidth = 0.5,
    );

    // Mirror line (vertical, glowing)
    final mirrorPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Color.lerp(leftColor, rightColor, 0.5)!.withValues(alpha: 0.15 + glowT * 0.1),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(mid, 0, 1, h));
    canvas.drawLine(Offset(mid, h * 0.15), Offset(mid, groundY + 10), mirrorPaint);

    // Left player
    _drawPlayer(canvas, mid * 0.55, groundY, leftColor, decoration);

    // Right player (mirrored)
    _drawPlayer(canvas, mid + mid * 0.45, groundY, rightColor, decoration);
  }

  void _drawPlayer(Canvas canvas, double x, double groundY, Color color, SkinDecoration deco) {
    final bodyW = 20.0;
    final bodyH = 30.0;
    final bodyTop = groundY - bodyH;
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x - bodyW / 2, bodyTop, bodyW, bodyH),
      const Radius.circular(6),
    );

    // Outer glow
    canvas.drawRRect(
      bodyRect.inflate(4 + glowT * 3),
      Paint()
        ..color = color.withValues(alpha: 0.08 + glowT * 0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Inner glow
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..color = color.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Body
    canvas.drawRRect(bodyRect, Paint()..color = color);

    // Decoration
    _drawDecoration(canvas, x, bodyTop, bodyW, deco, color);

    // Eyes
    final eyeY = bodyTop + 9;
    final eyePaint = Paint()..color = const Color(0x80000000);
    canvas.drawCircle(Offset(x - 3.5, eyeY), 2.2, eyePaint);
    canvas.drawCircle(Offset(x + 3.5, eyeY), 2.2, eyePaint);

    // Goggles over eyes
    if (deco == SkinDecoration.goggles) {
      _drawGoggles(canvas, x, eyeY, bodyW);
    }

    // Trail particles below
    final rng = Random(color.toARGB32());
    for (int i = 0; i < 3; i++) {
      final trailAlpha = (0.15 - i * 0.04).clamp(0.0, 1.0);
      final trailY = groundY + 4 + i * 6.0;
      final trailX = x + (rng.nextDouble() - 0.5) * 8;
      canvas.drawCircle(
        Offset(trailX, trailY),
        2 - i * 0.4,
        Paint()..color = color.withValues(alpha: trailAlpha),
      );
    }
  }

  void _drawDecoration(Canvas canvas, double x, double bodyTop, double bodyW, SkinDecoration deco, Color color) {
    switch (deco) {
      case SkinDecoration.none:
        break;
      case SkinDecoration.iceCrown:
        final paint = Paint()..color = const Color(0xCCAAEEFF);
        final glow = Paint()
          ..color = const Color(0x4400CCFF)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        for (final dx in [-5.0, 0.0, 5.0]) {
          final h = dx == 0 ? -8.0 : -5.5;
          final path = Path()
            ..moveTo(x + dx - 2, bodyTop)
            ..lineTo(x + dx, bodyTop + h)
            ..lineTo(x + dx + 2, bodyTop)
            ..close();
          canvas.drawPath(path, glow);
          canvas.drawPath(path, paint);
        }
      case SkinDecoration.flames:
        final t = glowT * pi * 4;
        final colors = [const Color(0xDDFF6600), const Color(0xBBFFAA00), const Color(0x99FF3300)];
        for (int i = 0; i < 3; i++) {
          final dx = (i - 1) * 5.0;
          final phase = t + i * 2.1;
          final fh = -4.0 - sin(phase) * 4 - (i == 1 ? 3 : 0);
          final fw = 3.0 + sin(phase * 0.7);
          final path = Path()
            ..moveTo(x + dx - fw, bodyTop + 1)
            ..quadraticBezierTo(x + dx - fw * 0.3, bodyTop + fh - 2, x + dx, bodyTop + fh)
            ..quadraticBezierTo(x + dx + fw * 0.3, bodyTop + fh - 2, x + dx + fw, bodyTop + 1)
            ..close();
          canvas.drawPath(path, Paint()
            ..color = colors[i].withValues(alpha: 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
          canvas.drawPath(path, Paint()..color = colors[i]);
        }
      case SkinDecoration.crown:
        final paint = Paint()..color = const Color(0xFFFFD700);
        final glow = Paint()
          ..color = const Color(0x60FFD700)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        final path = Path()
          ..moveTo(x - 8, bodyTop + 2)
          ..lineTo(x - 8, bodyTop - 4)
          ..lineTo(x - 4, bodyTop - 1)
          ..lineTo(x, bodyTop - 7)
          ..lineTo(x + 4, bodyTop - 1)
          ..lineTo(x + 8, bodyTop - 4)
          ..lineTo(x + 8, bodyTop + 2)
          ..close();
        canvas.drawPath(path, glow);
        canvas.drawPath(path, paint);
        canvas.drawCircle(Offset(x, bodyTop - 4), 1.2, Paint()..color = const Color(0xFFFF4444));
      case SkinDecoration.goggles:
        break; // drawn after eyes
      case SkinDecoration.antenna:
        final bobY = sin(glowT * pi * 2) * 2;
        canvas.drawLine(
          Offset(x, bodyTop + 2),
          Offset(x, bodyTop - 8 + bobY),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.6)
            ..strokeWidth = 1.5
            ..strokeCap = ui.StrokeCap.round,
        );
        final tipY = bodyTop - 9 + bobY;
        canvas.drawCircle(Offset(x, tipY), 3, Paint()
          ..color = color.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
        canvas.drawCircle(Offset(x, tipY), 2, Paint()..color = color);
      case SkinDecoration.halo:
        final bobY = sin(glowT * pi * 2) * 1.5;
        final haloY = bodyTop - 6 + bobY;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, haloY), width: 20, height: 6),
          Paint()
            ..color = const Color(0x30FFFFFF)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, haloY), width: 18, height: 5),
          Paint()
            ..color = const Color(0xCCFFFFFF)
            ..strokeWidth = 1.5
            ..style = ui.PaintingStyle.stroke,
        );
    }
  }

  void _drawGoggles(Canvas canvas, double x, double eyeY, double bodyW) {
    final strap = Paint()
      ..color = const Color(0xBB000000)
      ..strokeWidth = 1.5
      ..style = ui.PaintingStyle.stroke;
    final lens = Paint()..color = const Color(0xCC88DDFF);
    final glare = Paint()..color = const Color(0x55FFFFFF);
    final frame = Paint()
      ..color = const Color(0xCC444444)
      ..strokeWidth = 1
      ..style = ui.PaintingStyle.stroke;

    canvas.drawLine(Offset(x - bodyW / 2, eyeY), Offset(x + bodyW / 2, eyeY), strap);

    for (final dx in [-3.5, 3.5]) {
      final lr = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x + dx, eyeY), width: 7, height: 6),
        const Radius.circular(2),
      );
      canvas.drawRRect(lr, lens);
      canvas.drawRRect(lr, frame);
      canvas.drawCircle(Offset(x + dx - 1.5, eyeY - 1.5), 1, glare);
    }
  }

  @override
  bool shouldRepaint(covariant _PlayerScenePainter old) =>
      old.glowT != glowT || old.leftColor != leftColor || old.rightColor != rightColor || old.decoration != decoration;
}
