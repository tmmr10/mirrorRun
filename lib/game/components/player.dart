import 'dart:ui';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
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
    final bodyColor = swapped
        ? (side == 'left' ? const Color(0xFF9966ff) : const Color(0xFFff6b35))
        : color;
    canvas.drawRRect(bodyRect, Paint()..color = bodyColor);

    // Eyes
    final eyePaint = Paint()..color = const Color(0x80000000);
    canvas.drawCircle(Offset(pw / 2 - 4, 10), 2.5, eyePaint);
    canvas.drawCircle(Offset(pw / 2 + 4, 10), 2.5, eyePaint);
  }
}

class _TrailPoint {
  final double x, y;
  _TrailPoint(this.x, this.y);
}
