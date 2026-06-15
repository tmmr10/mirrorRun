import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import '../mirror_run_game.dart';

/// Rare mid-run pickups that grant a temporary advantage.
enum PowerUpType { shield, syncLock, slowMo }

extension PowerUpVisuals on PowerUpType {
  Color get color {
    switch (this) {
      case PowerUpType.shield:
        return const Color(0xFF44DDFF); // cyan
      case PowerUpType.syncLock:
        return const Color(0xFFB48CFF); // accent violet
      case PowerUpType.slowMo:
        return const Color(0xFFFFD700); // gold
    }
  }

  String get label {
    switch (this) {
      case PowerUpType.shield:
        return 'SHIELD';
      case PowerUpType.syncLock:
        return 'SYNC LOCK';
      case PowerUpType.slowMo:
        return 'SLOW-MO';
    }
  }
}

class PowerUp extends PositionComponent with HasGameReference<MirrorRunGame> {
  final String side;
  final int lane;
  final double laneCenterX;
  final PowerUpType type;
  double scrollPos;
  bool collected = false;

  static const double radius = 11.0;

  // Reusable paints (no per-frame allocation).
  final Paint _glowPaint = Paint()
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
  final Paint _ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  final Paint _fillPaint = Paint();
  final Paint _iconPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;

  PowerUp({
    required this.side,
    required this.lane,
    required this.laneCenterX,
    required this.type,
    required this.scrollPos,
  }) : super(priority: 45);

  @override
  void update(double dt) {
    super.update(dt);
    // Scroll advanced by MirrorRunGame._tick (lockstep).
    if (scrollPos > MirrorRunGame.vh + 30) removeFromParent();
  }

  Rect getPickupRect() => Rect.fromCircle(
        center: Offset(laneCenterX, scrollPos),
        radius: radius + 5,
      );

  @override
  void render(Canvas canvas) {
    if (collected) return;
    final c = type.color;
    final pulse = 0.8 + 0.2 * sin(scrollPos * 0.06);
    final center = Offset(laneCenterX, scrollPos);

    _glowPaint.color = c.withValues(alpha: 0.4);
    canvas.drawCircle(center, (radius + 5) * pulse, _glowPaint);

    _fillPaint.color = const Color(0xFF0A0A12).withValues(alpha: 0.85);
    canvas.drawCircle(center, radius, _fillPaint);

    _ringPaint.color = c;
    canvas.drawCircle(center, radius, _ringPaint);

    _drawIcon(canvas, center, c);
  }

  void _drawIcon(Canvas canvas, Offset c, Color color) {
    _iconPaint.color = color;
    switch (type) {
      case PowerUpType.shield:
        // Simple shield outline
        final p = Path()
          ..moveTo(c.dx, c.dy - 5)
          ..lineTo(c.dx + 4, c.dy - 2)
          ..lineTo(c.dx + 4, c.dy + 1)
          ..quadraticBezierTo(c.dx + 4, c.dy + 5, c.dx, c.dy + 6)
          ..quadraticBezierTo(c.dx - 4, c.dy + 5, c.dx - 4, c.dy + 1)
          ..lineTo(c.dx - 4, c.dy - 2)
          ..close();
        canvas.drawPath(p, _iconPaint);
      case PowerUpType.syncLock:
        // Two parallel arrows pointing the same way (un-mirrored)
        for (final dx in [-3.0, 3.0]) {
          canvas.drawLine(Offset(c.dx + dx, c.dy - 4), Offset(c.dx + dx, c.dy + 4), _iconPaint);
          canvas.drawLine(Offset(c.dx + dx, c.dy + 4), Offset(c.dx + dx - 2, c.dy + 1), _iconPaint);
          canvas.drawLine(Offset(c.dx + dx, c.dy + 4), Offset(c.dx + dx + 2, c.dy + 1), _iconPaint);
        }
      case PowerUpType.slowMo:
        // Clock face
        canvas.drawCircle(c, 5, _iconPaint);
        canvas.drawLine(c, Offset(c.dx, c.dy - 3.5), _iconPaint);
        canvas.drawLine(c, Offset(c.dx + 2.5, c.dy), _iconPaint);
    }
  }
}
