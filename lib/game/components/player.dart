import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import '../../models/player_skin.dart';
import '../mirror_run_game.dart';

class Player extends PositionComponent with HasGameReference<MirrorRunGame> {
  final String side; // 'left', 'right'
  final Color color;
  final Color glowColor;
  double targetX;
  bool dead = false;
  double nearMissFlash = 0; // 0..1, decays after near miss

  static const double pw = 24;
  static const double ph = 34;
  static double get groundY => MirrorRunGame.groundY;
  static const double moveLerp = 0.25;
  static const double _fixedDt = 1.0 / 60.0;

  double _accumulator = 0;
  double _totalTime = 0;
  final List<_TrailPoint> _trail = [];

  // Reusable paints (avoid per-frame allocation in render()).
  final Paint _trailPaint = Paint();
  final Paint _bodyPaint = Paint();
  final Paint _fillPaint = Paint();
  final Paint _glowBlurPaint = Paint();
  final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;

  Player({
    required this.side,
    required this.color,
    required this.glowColor,
    required this.targetX,
  }) : super(
          size: Vector2(pw, ph),
          anchor: Anchor.bottomCenter,
        ) {
    position = Vector2(targetX, groundY);
  }

  /// Collision rect (slightly inset from the visual body for fair hit testing).
  Rect getHitRect() => Rect.fromLTWH(
        position.x - pw / 2 + 5,
        position.y - ph,
        pw - 10,
        ph,
      );

  /// Generous rect for picking up collectibles (full body width).
  Rect getPickupRect() => Rect.fromLTWH(
        position.x - pw / 2,
        position.y - ph,
        pw,
        ph,
      );

  @override
  void update(double dt) {
    super.update(dt);
    if (dead) return;

    _totalTime += dt;
    _accumulator += dt;
    while (_accumulator >= _fixedDt) {
      _accumulator -= _fixedDt;
      _fixedUpdate();
      if (nearMissFlash > 0) {
        nearMissFlash = (nearMissFlash - _fixedDt * 2.5).clamp(0.0, 1.0);
      }
    }
  }

  void _fixedUpdate() {
    position.x += (targetX - position.x) * moveLerp;
    position.y = groundY;

    _trail.insert(0, _TrailPoint(position.x, position.y));
    if (_trail.length > 7) _trail.removeLast();
  }

  @override
  void render(Canvas canvas) {
    if (dead) return;

    // Invincibility blinker — skip every other ~100ms tick
    if (game.isInvincible) {
      final blinkPhase = (game.invincibilityTimer * 10).floor() % 2 == 0;
      if (!blinkPhase) return;
    }

    // Trail
    for (int i = 0; i < _trail.length; i++) {
      final t = _trail[i];
      final a = (1 - i / _trail.length) * 0.12;
      _trailPaint.color = color.withValues(alpha: a);
      final trailRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          t.x - position.x + 2,
          t.y - position.y + 2,
          pw - 4,
          ph - 4,
        ),
        const Radius.circular(5),
      );
      canvas.drawRRect(trailRect, _trailPaint);
    }

    // Base glow (intensified during near-miss)
    _bodyPaint
      ..color = glowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, pw, ph),
      const Radius.circular(7),
    );
    canvas.drawRRect(bodyRect, _bodyPaint);

    // Invincibility: white outer ring
    if (game.isInvincible) {
      _strokePaint
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.6)
        ..strokeWidth = 1.5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-3, -3, pw + 6, ph + 6),
          const Radius.circular(10),
        ),
        _strokePaint,
      );
    }

    // Near-miss: soft expanding aura in skin color (radiates outward)
    if (nearMissFlash > 0) {
      final expandT = 1.0 - nearMissFlash; // 0→1 as flash decays
      final expandSize = 4.0 + expandT * 18; // grows outward
      final auraAlpha = nearMissFlash * 0.55;
      _glowBlurPaint
        ..color = glowColor.withValues(alpha: auraAlpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 14 + expandT * 10);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(-expandSize, -expandSize, pw + expandSize * 2, ph + expandSize * 2),
          Radius.circular(7 + expandSize),
        ),
        _glowBlurPaint,
      );
    }

    // Body - tint during mirror swap
    final swapped = game.eventSystem.mirrorSwapped;
    final skin = game.skinService.currentSkin;
    final bodyColor = swapped
        ? (side == 'left' ? skin.rightColor : skin.leftColor)
        : color;
    _bodyPaint
      ..color = bodyColor
      ..maskFilter = null;
    canvas.drawRRect(bodyRect, _bodyPaint);

    // Head decoration
    _drawHeadDecoration(canvas, skin.headDecoration, bodyColor);

    // Eyes
    _fillPaint.color = const Color(0x80000000);
    canvas.drawCircle(Offset(pw / 2 - 4, 10), 2.5, _fillPaint);
    canvas.drawCircle(Offset(pw / 2 + 4, 10), 2.5, _fillPaint);

    // Face decoration (over eyes)
    _drawFaceDecoration(canvas, skin.faceDecoration, bodyColor);

    // Shield helmet — visible on the figure while a shield is active.
    if (game.shieldUp) _drawShieldHelmet(canvas);
  }

  void _drawShieldHelmet(Canvas canvas) {
    const c = Color(0xFF44DDFF); // shield cyan
    final domeRect = Rect.fromLTWH(-2, -4, pw + 4, 22);
    // soft glow behind the dome
    _glowBlurPaint
      ..color = c.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawArc(domeRect, pi, pi, true, _glowBlurPaint);
    // translucent helmet shell
    _fillPaint
      ..color = c.withValues(alpha: 0.3)
      ..maskFilter = null;
    canvas.drawArc(domeRect, pi, pi, true, _fillPaint);
    // bright rim along the dome edge
    _strokePaint
      ..color = c.withValues(alpha: 0.95)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..maskFilter = null;
    canvas.drawArc(domeRect, pi, pi, false, _strokePaint);
  }

  void _drawHeadDecoration(Canvas canvas, HeadDecoration deco, Color bodyColor) {
    switch (deco) {
      case HeadDecoration.none:
        break;
      case HeadDecoration.iceCrown:
        _drawIceCrown(canvas, bodyColor);
      case HeadDecoration.flames:
        _drawFlames(canvas, bodyColor);
      case HeadDecoration.crown:
        _drawCrown(canvas);
      case HeadDecoration.antenna:
        _drawAntenna(canvas, bodyColor);
      case HeadDecoration.halo:
        _drawHalo(canvas, bodyColor);
      case HeadDecoration.horns:
        _drawHorns(canvas, bodyColor);
      case HeadDecoration.wings:
        _drawWings(canvas, bodyColor);
      case HeadDecoration.mohawk:
        _drawMohawk(canvas, bodyColor);
      case HeadDecoration.star:
        _drawStar(canvas, bodyColor);
    }
  }

  void _drawFaceDecoration(Canvas canvas, FaceDecoration deco, Color bodyColor) {
    switch (deco) {
      case FaceDecoration.none:
        break;
      case FaceDecoration.goggles:
        _drawGoggles(canvas, bodyColor);
      case FaceDecoration.visor:
        _drawVisor(canvas, bodyColor);
      case FaceDecoration.mask:
        _drawMask(canvas, bodyColor);
      case FaceDecoration.monocle:
        _drawMonocle(canvas, bodyColor);
      case FaceDecoration.scar:
        _drawScar(canvas, bodyColor);
      case FaceDecoration.shades:
        _drawShades(canvas, bodyColor);
    }
  }

  void _drawIceCrown(Canvas canvas, Color bodyColor) {
    _fillPaint.color = const Color(0xCCAAEEFF);
    _glowBlurPaint
      ..color = const Color(0x4400CCFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    for (final dx in [-5.0, 0.0, 5.0]) {
      final h = dx == 0 ? -8.0 : -5.5;
      final path = Path()
        ..moveTo(pw / 2 + dx - 2, 0)
        ..lineTo(pw / 2 + dx, h)
        ..lineTo(pw / 2 + dx + 2, 0)
        ..close();
      canvas.drawPath(path, _glowBlurPaint);
      canvas.drawPath(path, _fillPaint);
    }
  }

  void _drawFlames(Canvas canvas, Color bodyColor) {
    final t = _totalTime * 8;
    final flameColors = [
      const Color(0xDDFF6600),
      const Color(0xBBFFAA00),
      const Color(0x99FF3300),
    ];

    for (int i = 0; i < 3; i++) {
      final dx = (i - 1) * 5.0;
      final phase = t + i * 2.1;
      final h = -4.0 - sin(phase) * 4 - (i == 1 ? 3 : 0);
      final w = 3.0 + sin(phase * 0.7) * 1;

      final path = Path()
        ..moveTo(pw / 2 + dx - w, 1)
        ..quadraticBezierTo(pw / 2 + dx - w * 0.3, h - 2, pw / 2 + dx, h)
        ..quadraticBezierTo(pw / 2 + dx + w * 0.3, h - 2, pw / 2 + dx + w, 1)
        ..close();

      _glowBlurPaint
        ..color = flameColors[i].withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawPath(path, _glowBlurPaint);
      _fillPaint.color = flameColors[i];
      canvas.drawPath(path, _fillPaint);
    }
  }

  void _drawCrown(Canvas canvas) {
    _glowBlurPaint
      ..color = const Color(0x60FFD700)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final path = Path()
      ..moveTo(pw / 2 - 8, 2)
      ..lineTo(pw / 2 - 8, -4)
      ..lineTo(pw / 2 - 4, -1)
      ..lineTo(pw / 2, -7)
      ..lineTo(pw / 2 + 4, -1)
      ..lineTo(pw / 2 + 8, -4)
      ..lineTo(pw / 2 + 8, 2)
      ..close();

    canvas.drawPath(path, _glowBlurPaint);
    _fillPaint.color = const Color(0xFFFFD700);
    canvas.drawPath(path, _fillPaint);

    _fillPaint.color = const Color(0xFFFF4444);
    canvas.drawCircle(Offset(pw / 2, -4), 1.2, _fillPaint);
  }

  void _drawGoggles(Canvas canvas, Color bodyColor) {
    _strokePaint
      ..color = const Color(0xBB000000)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.butt;
    canvas.drawLine(Offset(0, 10), Offset(pw, 10), _strokePaint);

    _strokePaint
      ..color = const Color(0xCC444444)
      ..strokeWidth = 1;

    final ll = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(pw / 2 - 4, 10), width: 7, height: 6),
      const Radius.circular(2),
    );
    _fillPaint.color = const Color(0xCC88DDFF);
    canvas.drawRRect(ll, _fillPaint);
    canvas.drawRRect(ll, _strokePaint);
    _fillPaint.color = const Color(0x55FFFFFF);
    canvas.drawCircle(Offset(pw / 2 - 5.5, 8.5), 1, _fillPaint);

    final rl = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(pw / 2 + 4, 10), width: 7, height: 6),
      const Radius.circular(2),
    );
    _fillPaint.color = const Color(0xCC88DDFF);
    canvas.drawRRect(rl, _fillPaint);
    canvas.drawRRect(rl, _strokePaint);
    _fillPaint.color = const Color(0x55FFFFFF);
    canvas.drawCircle(Offset(pw / 2 + 2.5, 8.5), 1, _fillPaint);
  }

  void _drawAntenna(Canvas canvas, Color bodyColor) {
    final t = _totalTime * 3;
    final bobY = sin(t) * 2;

    _strokePaint
      ..color = const Color(0x99FFFFFF)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(pw / 2, 2), Offset(pw / 2, -8 + bobY), _strokePaint);

    final tipY = -9.0 + bobY;
    _glowBlurPaint
      ..color = bodyColor.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(pw / 2, tipY), 3, _glowBlurPaint);
    _fillPaint.color = bodyColor;
    canvas.drawCircle(Offset(pw / 2, tipY), 2, _fillPaint);
  }

  void _drawHalo(Canvas canvas, Color bodyColor) {
    final t = _totalTime * 2;
    final bobY = sin(t) * 1.5;
    final haloY = -6.0 + bobY;

    _glowBlurPaint
      ..color = const Color(0x30FFFFFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pw / 2, haloY), width: 20, height: 6),
      _glowBlurPaint,
    );

    _strokePaint
      ..color = const Color(0xCCFFFFFF)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.butt;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pw / 2, haloY), width: 18, height: 5),
      _strokePaint,
    );
  }

  void _drawHorns(Canvas canvas, Color bodyColor) {
    _fillPaint.color = const Color(0xDDCC2222);
    _glowBlurPaint
      ..color = const Color(0x40FF0000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    for (final side in [-1.0, 1.0]) {
      final path = Path()
        ..moveTo(pw / 2 + side * 4, 2)
        ..quadraticBezierTo(pw / 2 + side * 9, -2, pw / 2 + side * 8, -8)
        ..lineTo(pw / 2 + side * 6, -1)
        ..close();
      canvas.drawPath(path, _glowBlurPaint);
      canvas.drawPath(path, _fillPaint);
    }
  }

  void _drawWings(Canvas canvas, Color bodyColor) {
    final flapY = sin(_totalTime * 6) * 2;
    _fillPaint.color = bodyColor.withValues(alpha: 0.6);
    _glowBlurPaint
      ..color = bodyColor.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    for (final side in [-1.0, 1.0]) {
      final wingX = pw / 2 + side * 14;
      final path = Path()
        ..moveTo(pw / 2 + side * 10, 8)
        ..quadraticBezierTo(wingX + side * 4, 2 + flapY, wingX + side * 2, -2 + flapY)
        ..quadraticBezierTo(wingX, 6 + flapY, pw / 2 + side * 10, 18)
        ..close();
      canvas.drawPath(path, _glowBlurPaint);
      canvas.drawPath(path, _fillPaint);
    }
  }

  void _drawMohawk(Canvas canvas, Color bodyColor) {
    _fillPaint.color = bodyColor;
    _glowBlurPaint
      ..color = bodyColor.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    for (int i = 0; i < 5; i++) {
      final dx = (i - 2) * 3.0;
      final h = i == 2 ? -10.0 : (i == 1 || i == 3 ? -7.0 : -4.0);
      final path = Path()
        ..moveTo(pw / 2 + dx - 1.5, 1)
        ..lineTo(pw / 2 + dx, h)
        ..lineTo(pw / 2 + dx + 1.5, 1)
        ..close();
      canvas.drawPath(path, _glowBlurPaint);
      canvas.drawPath(path, _fillPaint);
    }
  }

  void _drawStar(Canvas canvas, Color bodyColor) {
    final bobY = sin(_totalTime * 4) * 2;
    final starY = -10.0 + bobY;
    final cx = pw / 2;
    _glowBlurPaint
      ..color = const Color(0x60FFDD44)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final outerAngle = -pi / 2 + i * 2 * pi / 5;
      final innerAngle = outerAngle + pi / 5;
      final ox = cx + cos(outerAngle) * 5;
      final oy = starY + sin(outerAngle) * 5;
      final ix = cx + cos(innerAngle) * 2;
      final iy = starY + sin(innerAngle) * 2;
      if (i == 0) {
        path.moveTo(ox, oy);
      } else {
        path.lineTo(ox, oy);
      }
      path.lineTo(ix, iy);
    }
    path.close();
    canvas.drawPath(path, _glowBlurPaint);
    _fillPaint.color = const Color(0xFFFFDD44);
    canvas.drawPath(path, _fillPaint);
  }

  void _drawVisor(Canvas canvas, Color bodyColor) {
    final visorRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(pw / 2, 10), width: pw - 2, height: 5),
      const Radius.circular(2.5),
    );
    _glowBlurPaint
      ..color = bodyColor.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawRRect(visorRect, _glowBlurPaint);
    _fillPaint.color = bodyColor.withValues(alpha: 0.7);
    canvas.drawRRect(visorRect, _fillPaint);
    _strokePaint
      ..color = const Color(0x55FFFFFF)
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.butt;
    canvas.drawLine(Offset(3, 9), Offset(pw - 3, 9), _strokePaint);
  }
  void _drawMask(Canvas canvas, Color bodyColor) {
    final maskRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(pw / 2, 10), width: pw + 2, height: 7),
      const Radius.circular(3.5),
    );
    _fillPaint.color = const Color(0xDD111111);
    canvas.drawRRect(maskRect, _fillPaint);
    _fillPaint.color = const Color(0xFF222222);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pw / 2 - 4, 10), width: 6, height: 5),
      _fillPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pw / 2 + 4, 10), width: 6, height: 5),
      _fillPaint,
    );
  }

  void _drawMonocle(Canvas canvas, Color bodyColor) {
    _strokePaint
      ..color = const Color(0x99FFD700)
      ..strokeWidth = 0.7
      ..strokeCap = StrokeCap.butt;
    canvas.drawLine(Offset(pw / 2 + 4, 13), Offset(pw / 2 + 7, 22), _strokePaint);
    _strokePaint
      ..color = const Color(0xCCFFD700)
      ..strokeWidth = 1.2;
    canvas.drawCircle(Offset(pw / 2 + 4, 10), 4.5, _strokePaint);
    _fillPaint.color = const Color(0x44FFFFFF);
    canvas.drawCircle(Offset(pw / 2 + 3, 8.5), 1.2, _fillPaint);
  }

  void _drawScar(Canvas canvas, Color bodyColor) {
    _strokePaint
      ..color = const Color(0xCCCC4444)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(pw / 2 - 7, 5), Offset(pw / 2 - 1, 15), _strokePaint);
    _strokePaint
      ..color = const Color(0x88CC4444)
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.butt;
    for (final dy in [-2.0, 1.0, 4.0]) {
      final cx = pw / 2 - 4 + dy * 0.5;
      canvas.drawLine(
        Offset(cx - 1.5, 10 + dy - 0.5),
        Offset(cx + 1.5, 10 + dy + 0.5),
        _strokePaint,
      );
    }
  }

  void _drawShades(Canvas canvas, Color bodyColor) {
    _strokePaint
      ..color = const Color(0xCC111111)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.butt;
    canvas.drawLine(Offset(pw / 2 - 3.5, 9), Offset(pw / 2 + 3.5, 9), _strokePaint);
    final ll = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(pw / 2 - 4.5, 10), width: 9, height: 6),
      const Radius.circular(1.8),
    );
    _fillPaint.color = const Color(0xEE111111);
    canvas.drawRRect(ll, _fillPaint);
    _strokePaint
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = 0.5;
    canvas.drawRRect(ll, _strokePaint);
    final rl = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(pw / 2 + 4.5, 10), width: 9, height: 6),
      const Radius.circular(1.8),
    );
    canvas.drawRRect(rl, _fillPaint);
    canvas.drawRRect(rl, _strokePaint);
    _strokePaint.strokeWidth = 0.8;
    canvas.drawLine(Offset(pw / 2 - 7, 8.5), Offset(pw / 2 - 2, 8.5), _strokePaint);
  }
}

class _TrailPoint {
  final double x, y;
  _TrailPoint(this.x, this.y);
}
