import 'dart:ui';
import '../../game_state.dart';
import '../../components/obstacle.dart';
import 'obstacle_renderer.dart';

/// Volcano: rocks, flames, lava pools, fireballs.
class VolcanoObstacleRenderer extends ObstacleRenderer {
  const VolcanoObstacleRenderer();

  @override
  void render(Canvas canvas, Obstacle o, Paint fill, Paint glow, Color col, double da) {
    final w = o.w;
    final h = o.h;
    switch (o.type) {
      case ObstacleType.wall:
        // Jagged rock
        final cx = o.laneCenterX - o.position.x;
        final path = Path()
          ..moveTo(cx - w / 2, h)
          ..lineTo(cx - w * 0.4, h * 0.3)
          ..lineTo(cx - w * 0.1, h * 0.15)
          ..lineTo(cx + w * 0.05, 0)
          ..lineTo(cx + w * 0.25, h * 0.2)
          ..lineTo(cx + w / 2, h * 0.35)
          ..lineTo(cx + w / 2, h)
          ..close();
        canvas.drawPath(path, glow);
        canvas.drawPath(path, fill);
        // Lava cracks
        final crack = pFillLine..color = Color.fromARGB((da * 180).toInt(), 255, 100, 0)..strokeWidth = 1;
        canvas.drawLine(Offset(cx - 2, h * 0.4), Offset(cx + 1, h * 0.7), crack);
        canvas.drawLine(Offset(cx + 3, h * 0.3), Offset(cx + 1, h * 0.55), crack);

      case ObstacleType.spike:
        // Flame pillar
        final cx = o.laneCenterX - o.position.x;
        final path = Path()
          ..moveTo(cx, 0)
          ..quadraticBezierTo(cx - w * 0.6, h * 0.5, cx - w * 0.3, h)
          ..lineTo(cx + w * 0.3, h)
          ..quadraticBezierTo(cx + w * 0.6, h * 0.5, cx, 0)
          ..close();
        canvas.drawPath(path, glow);
        canvas.drawPath(path, fill);
        // Inner flame
        final inner = pFill..color = Color.fromARGB((da * 150).toInt(), 255, 200, 50);
        final ip = Path()
          ..moveTo(cx, h * 0.2)
          ..quadraticBezierTo(cx - w * 0.25, h * 0.6, cx - w * 0.1, h)
          ..lineTo(cx + w * 0.1, h)
          ..quadraticBezierTo(cx + w * 0.25, h * 0.6, cx, h * 0.2)
          ..close();
        canvas.drawPath(ip, inner);

      case ObstacleType.doubleWall:
        // Lava pool / magma bar
        final totalW = o.size.x;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(0, h * 0.15, totalW, h * 0.7), const Radius.circular(12));
        canvas.drawRRect(rect, glow);
        canvas.drawRRect(rect, fill);
        // Bubbles
        final bubble = pFill..color = Color.fromARGB((da * 140).toInt(), 255, 180, 0);
        canvas.drawCircle(Offset(totalW * 0.25, h * 0.4), 3, bubble);
        canvas.drawCircle(Offset(totalW * 0.6, h * 0.55), 2.5, bubble);
        canvas.drawCircle(Offset(totalW * 0.8, h * 0.38), 2, bubble);

      case ObstacleType.shifter:
        // Fireball
        final cx = w / 2;
        // Outer glow
        canvas.drawCircle(Offset(cx, h / 2), w * 0.45, glow);
        canvas.drawCircle(Offset(cx, h / 2), w * 0.38, fill);
        // Inner hot core
        final core = pFill..color = Color.fromARGB((da * 200).toInt(), 255, 220, 80);
        canvas.drawCircle(Offset(cx, h / 2), w * 0.2, core);
        // Trail sparks
        final goingRight = o.secondLaneCenterX > o.laneCenterX;
        final spark = pFill..color = Color.fromARGB((da * 100).toInt(), 255, 120, 0);
        final tx = goingRight ? cx - w * 0.3 : cx + w * 0.3;
        canvas.drawCircle(Offset(tx, h * 0.4), 2, spark);
        canvas.drawCircle(Offset(tx - (goingRight ? 3 : -3), h * 0.6), 1.5, spark);
    }
  }
}
