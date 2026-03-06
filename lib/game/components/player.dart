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
  static const double groundY = 540;
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

    // Decoration
    final decoration = game.skinService.currentSkin.decoration;
    _drawDecoration(canvas, decoration, bodyColor);

    // Eyes
    final eyePaint = Paint()..color = const Color(0x80000000);
    final eyeY = decoration == SkinDecoration.goggles ? 10.0 : 10.0;
    canvas.drawCircle(Offset(pw / 2 - 4, eyeY), 2.5, eyePaint);
    canvas.drawCircle(Offset(pw / 2 + 4, eyeY), 2.5, eyePaint);

    // Goggles drawn over eyes
    if (decoration == SkinDecoration.goggles) {
      _drawGoggles(canvas, bodyColor);
    }
  }

  void _drawDecoration(Canvas canvas, SkinDecoration decoration, Color bodyColor) {
    switch (decoration) {
      case SkinDecoration.none:
        break;
      case SkinDecoration.iceCrown:
        _drawIceCrown(canvas, bodyColor);
      case SkinDecoration.flames:
        _drawFlames(canvas, bodyColor);
      case SkinDecoration.crown:
        _drawCrown(canvas);
      case SkinDecoration.goggles:
        break; // drawn after eyes
      case SkinDecoration.antenna:
        _drawAntenna(canvas, bodyColor);
      case SkinDecoration.halo:
        _drawHalo(canvas, bodyColor);
    }
  }

  void _drawIceCrown(Canvas canvas, Color bodyColor) {
    final paint = Paint()..color = const Color(0xCCAAEEFF);
    final glowPaint = Paint()
      ..color = const Color(0x4400CCFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    // Three ice crystal spikes
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

    // Jewels
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

    // Strap
    canvas.drawLine(Offset(0, 10), Offset(pw, 10), strapPaint);

    // Left lens
    final ll = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(pw / 2 - 4, 10), width: 7, height: 6),
      const Radius.circular(2),
    );
    canvas.drawRRect(ll, lensPaint);
    canvas.drawRRect(ll, framePaint);
    canvas.drawCircle(Offset(pw / 2 - 5.5, 8.5), 1, lensGlare);

    // Right lens
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

    // Antenna stick
    final stickPaint = Paint()
      ..color = const Color(0x99FFFFFF)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(pw / 2, 2), Offset(pw / 2, -8 + bobY), stickPaint);

    // Glowing tip
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

    // Halo glow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pw / 2, haloY), width: 20, height: 6),
      Paint()
        ..color = const Color(0x30FFFFFF)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Halo ring
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pw / 2, haloY), width: 18, height: 5),
      Paint()
        ..color = const Color(0xCCFFFFFF)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }
}

class _TrailPoint {
  final double x, y;
  _TrailPoint(this.x, this.y);
}
