import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import '../mirror_run_game.dart';

class Collectible extends PositionComponent with HasGameReference<MirrorRunGame> {
  final String side;
  final int lane;
  final double laneCenterX;
  double scrollPos;
  bool collected = false;

  static const double radius = 7.0;

  // Reusable paints (avoid per-frame allocation in render()).
  static final Paint _glowPaint = Paint()
    ..color = const Color(0xFFFFD700).withValues(alpha: 0.35)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  static final Paint _corePaint = Paint()..color = const Color(0xFFFFC000);
  static final Paint _shinePaint = Paint()..color = const Color(0xCCFFFFFF);

  Collectible({
    required this.side,
    required this.lane,
    required this.laneCenterX,
    required this.scrollPos,
  }) : super(priority: 40);

  @override
  void update(double dt) {
    super.update(dt);
    // Scroll is advanced by MirrorRunGame._tick (lockstep with collision).
    if (scrollPos > MirrorRunGame.vh + 30) removeFromParent();
  }

  /// Generous pickup rect (slightly larger than visual radius).
  Rect getPickupRect() => Rect.fromCircle(
        center: Offset(laneCenterX, scrollPos),
        radius: radius + 4,
      );

  @override
  void render(Canvas canvas) {
    if (collected) return;

    // Pulsing factor based on scroll — gentle breathing
    final pulse = 0.85 + 0.15 * sin(scrollPos * 0.05);

    // Outer soft glow
    canvas.drawCircle(
      Offset(laneCenterX, scrollPos),
      (radius + 6) * pulse,
      _glowPaint,
    );

    // Core orb (gold)
    canvas.drawCircle(
      Offset(laneCenterX, scrollPos),
      radius,
      _corePaint,
    );

    // Shine highlight (top-left)
    canvas.drawCircle(
      Offset(laneCenterX - 2.5, scrollPos - 2.5),
      2,
      _shinePaint,
    );
  }
}
