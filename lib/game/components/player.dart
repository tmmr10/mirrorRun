import 'dart:math';
import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import '../../models/player_skin.dart';
import '../mirror_run_game.dart';

class Player extends PositionComponent with CollisionCallbacks, HasGameReference<MirrorRunGame> {
  final String side; // 'left', 'right'
  final Color color;
  final Color glowColor;
  double targetX;
  bool dead = false;

  static const double pw = 24;
  static const double ph = 34;
  static double get groundY => MirrorRunGame.groundY;
  static const double moveLerp = 0.25;
  static const double _fixedDt = 1.0 / 60.0;

  double _accumulator = 0;
  double _totalTime = 0;
  final List<_TrailPoint> _trail = [];

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

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox(
      size: Vector2(pw - 14, ph),
      position: Vector2(7, 0),
      collisionType: CollisionType.active,
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (dead) return;

    _totalTime += dt;
    _accumulator += dt;
    while (_accumulator >= _fixedDt) {
      _accumulator -= _fixedDt;
      _fixedUpdate();
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

    // Trail
    for (int i = 0; i < _trail.length; i++) {
      final t = _trail[i];
      final a = (1 - i / _trail.length) * 0.12;
      final trailPaint = Paint()..color = color.withValues(alpha: a);
      final trailRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          t.x - position.x + 2,
          t.y - position.y + 2,
          pw - 4,
          ph - 4,
        ),
        const Radius.circular(5),
      );
      canvas.drawRRect(trailRect, trailPaint);
    }

    // Glow
    final glowPaint = Paint()
      ..color = glowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, pw, ph),
      const Radius.circular(7),
    );
    canvas.drawRRect(bodyRect, glowPaint);

    // Body - tint during mirror swap
    final swapped = game.eventSystem.mirrorSwapped;
    final skin = game.skinService.currentSkin;
    final bodyColor = swapped
        ? (side == 'left' ? skin.rightColor : skin.leftColor)
        : color;
    canvas.drawRRect(bodyRect, Paint()..color = bodyColor);

    // Head decoration
    _drawHeadDecoration(canvas, skin.headDecoration, bodyColor);

    // Eyes
    final eyePaint = Paint()..color = const Color(0x80000000);
    canvas.drawCircle(Offset(pw / 2 - 4, 10), 2.5, eyePaint);
    canvas.drawCircle(Offset(pw / 2 + 4, 10), 2.5, eyePaint);

    // Face decoration (over eyes)
    _drawFaceDecoration(canvas, skin.faceDecoration, bodyColor);
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
    final paint = Paint()..color = const Color(0xCCAAEEFF);
    final glowPaint = Paint()
      ..color = const Color(0x4400CCFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    for (final dx in [-5.0, 0.0, 5.0]) {
      final h = dx == 0 ? -8.0 : -5.5;
      final path = Path()
        ..moveTo(pw / 2 + dx - 2, 0)
        ..lineTo(pw / 2 + dx, h)
        ..lineTo(pw / 2 + dx + 2, 0)
        ..close();
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, paint);
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

      canvas.drawPath(path, Paint()
        ..color = flameColors[i].withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      canvas.drawPath(path, Paint()..color = flameColors[i]);
    }
  }

  void _drawCrown(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFFFFD700);
    final glowPaint = Paint()
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

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);

    final jewelPaint = Paint()..color = const Color(0xFFFF4444);
    canvas.drawCircle(Offset(pw / 2, -4), 1.2, jewelPaint);
  }

  void _drawGoggles(Canvas canvas, Color bodyColor) {
    final strapPaint = Paint()
      ..color = const Color(0xBB000000)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final lensPaint = Paint()..color = const Color(0xCC88DDFF);
    final lensGlare = Paint()..color = const Color(0x55FFFFFF);
    final framePaint = Paint()
      ..color = const Color(0xCC444444)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, 10), Offset(pw, 10), strapPaint);

    final ll = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(pw / 2 - 4, 10), width: 7, height: 6),
      const Radius.circular(2),
    );
    canvas.drawRRect(ll, lensPaint);
    canvas.drawRRect(ll, framePaint);
    canvas.drawCircle(Offset(pw / 2 - 5.5, 8.5), 1, lensGlare);

    final rl = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(pw / 2 + 4, 10), width: 7, height: 6),
      const Radius.circular(2),
    );
    canvas.drawRRect(rl, lensPaint);
    canvas.drawRRect(rl, framePaint);
    canvas.drawCircle(Offset(pw / 2 + 2.5, 8.5), 1, lensGlare);
  }

  void _drawAntenna(Canvas canvas, Color bodyColor) {
    final t = _totalTime * 3;
    final bobY = sin(t) * 2;

    final stickPaint = Paint()
      ..color = const Color(0x99FFFFFF)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(pw / 2, 2), Offset(pw / 2, -8 + bobY), stickPaint);

    final tipY = -9.0 + bobY;
    canvas.drawCircle(
      Offset(pw / 2, tipY),
      3,
      Paint()
        ..color = bodyColor.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(
      Offset(pw / 2, tipY),
      2,
      Paint()..color = bodyColor,
    );
  }

  void _drawHalo(Canvas canvas, Color bodyColor) {
    final t = _totalTime * 2;
    final bobY = sin(t) * 1.5;
    final haloY = -6.0 + bobY;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(pw / 2, haloY), width: 20, height: 6),
      Paint()
        ..color = const Color(0x30FFFFFF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    canvas.drawOval(
      Rect.fromCenter(center: Offset(pw / 2, haloY), width: 18, height: 5),
      Paint()
        ..color = const Color(0xCCFFFFFF)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawHorns(Canvas canvas, Color bodyColor) {
    final paint = Paint()..color = const Color(0xDDCC2222);
    final glow = Paint()
      ..color = const Color(0x40FF0000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    for (final side in [-1.0, 1.0]) {
      final path = Path()
        ..moveTo(pw / 2 + side * 4, 2)
        ..quadraticBezierTo(pw / 2 + side * 9, -2, pw / 2 + side * 8, -8)
        ..lineTo(pw / 2 + side * 6, -1)
        ..close();
      canvas.drawPath(path, glow);
      canvas.drawPath(path, paint);
    }
  }

  void _drawWings(Canvas canvas, Color bodyColor) {
    final flapY = sin(_totalTime * 6) * 2;
    final paint = Paint()..color = bodyColor.withValues(alpha: 0.6);
    final glow = Paint()
      ..color = bodyColor.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    for (final side in [-1.0, 1.0]) {
      final wingX = pw / 2 + side * 14;
      final path = Path()
        ..moveTo(pw / 2 + side * 10, 8)
        ..quadraticBezierTo(wingX + side * 4, 2 + flapY, wingX + side * 2, -2 + flapY)
        ..quadraticBezierTo(wingX, 6 + flapY, pw / 2 + side * 10, 18)
        ..close();
      canvas.drawPath(path, glow);
      canvas.drawPath(path, paint);
    }
  }

  void _drawMohawk(Canvas canvas, Color bodyColor) {
    final paint = Paint()..color = bodyColor;
    final glow = Paint()
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
      canvas.drawPath(path, glow);
      canvas.drawPath(path, paint);
    }
  }

  void _drawStar(Canvas canvas, Color bodyColor) {
    final bobY = sin(_totalTime * 4) * 2;
    final starY = -10.0 + bobY;
    final cx = pw / 2;
    final starPaint = Paint()..color = const Color(0xFFFFDD44);
    final starGlow = Paint()
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
    canvas.drawPath(path, starGlow);
    canvas.drawPath(path, starPaint);
  }

  void _drawVisor(Canvas canvas, Color bodyColor) {
    final visorRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(pw / 2, 10), width: pw - 2, height: 5),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(visorRect, Paint()
      ..color = bodyColor.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawRRect(visorRect, Paint()..color = bodyColor.withValues(alpha: 0.7));
    canvas.drawLine(
      Offset(3, 9),
      Offset(pw - 3, 9),
      Paint()
        ..color = const Color(0x55FFFFFF)
        ..strokeWidth = 0.8,
    );
  }
  void _drawMask(Canvas canvas, Color bodyColor) {
    final maskRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(pw / 2, 10), width: pw + 2, height: 7),
      const Radius.circular(3.5),
    );
    canvas.drawRRect(maskRect, Paint()..color = const Color(0xDD111111));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pw / 2 - 4, 10), width: 6, height: 5),
      Paint()..color = const Color(0xFF222222),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pw / 2 + 4, 10), width: 6, height: 5),
      Paint()..color = const Color(0xFF222222),
    );
  }

  void _drawMonocle(Canvas canvas, Color bodyColor) {
    canvas.drawLine(
      Offset(pw / 2 + 4, 13),
      Offset(pw / 2 + 7, 22),
      Paint()
        ..color = const Color(0x99FFD700)
        ..strokeWidth = 0.7,
    );
    canvas.drawCircle(
      Offset(pw / 2 + 4, 10),
      4.5,
      Paint()
        ..color = const Color(0xCCFFD700)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );
    canvas.drawCircle(
      Offset(pw / 2 + 3, 8.5),
      1.2,
      Paint()..color = const Color(0x44FFFFFF),
    );
  }

  void _drawScar(Canvas canvas, Color bodyColor) {
    final scarPaint = Paint()
      ..color = const Color(0xCCCC4444)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(pw / 2 - 7, 5), Offset(pw / 2 - 1, 15), scarPaint);
    for (final dy in [-2.0, 1.0, 4.0]) {
      final cx = pw / 2 - 4 + dy * 0.5;
      canvas.drawLine(
        Offset(cx - 1.5, 10 + dy - 0.5),
        Offset(cx + 1.5, 10 + dy + 0.5),
        Paint()
          ..color = const Color(0x88CC4444)
          ..strokeWidth = 0.9,
      );
    }
  }

  void _drawShades(Canvas canvas, Color bodyColor) {
    canvas.drawLine(
      Offset(pw / 2 - 3.5, 9), Offset(pw / 2 + 3.5, 9),
      Paint()..color = const Color(0xCC111111)..strokeWidth = 1.2,
    );
    final ll = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(pw / 2 - 4.5, 10), width: 9, height: 6),
      const Radius.circular(1.8),
    );
    canvas.drawRRect(ll, Paint()..color = const Color(0xEE111111));
    canvas.drawRRect(ll, Paint()
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke);
    final rl = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(pw / 2 + 4.5, 10), width: 9, height: 6),
      const Radius.circular(1.8),
    );
    canvas.drawRRect(rl, Paint()..color = const Color(0xEE111111));
    canvas.drawRRect(rl, Paint()
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke);
    canvas.drawLine(
      Offset(pw / 2 - 7, 8.5), Offset(pw / 2 - 2, 8.5),
      Paint()..color = const Color(0x33FFFFFF)..strokeWidth = 0.8,
    );
  }
}

class _TrailPoint {
  final double x, y;
  _TrailPoint(this.x, this.y);
}
