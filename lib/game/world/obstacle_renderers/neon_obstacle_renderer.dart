import 'dart:math';
import 'dart:ui';
import '../../game_state.dart';
import '../../components/obstacle.dart';
import 'obstacle_renderer.dart';

/// Neon: light bars, lasers, glitch blocks, pulse orbs.
class NeonObstacleRenderer extends ObstacleRenderer {
  const NeonObstacleRenderer();

  @override
  void render(Canvas canvas, Obstacle o, Paint fill, Paint glow, Color col, double da) {
    final w = o.w;
    final h = o.h;
    switch (o.type) {
      case ObstacleType.wall:
        // Neon light bar
        final cx = o.laneCenterX - o.position.x;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - w / 2, 0, w, h), const Radius.circular(2));
        canvas.drawRRect(rect, glow);
        canvas.drawRRect(rect, fill);
        // Inner bright core
        final core = RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - w * 0.2, 2, w * 0.4, h - 4), const Radius.circular(1));
        canvas.drawRRect(core, pFill..color = Color.fromARGB((da * 180).toInt(), 255, 255, 255));

      case ObstacleType.spike:
        // Laser beam (X shape)
        final cx = o.laneCenterX - o.position.x;
        final lp = pFillLineCap..color = col..strokeWidth = 3;
        canvas.drawLine(Offset(cx - w / 2, 0), Offset(cx + w / 2, h), lp);
        canvas.drawLine(Offset(cx + w / 2, 0), Offset(cx - w / 2, h), lp);
        // Glow on lines (fill style + round cap + blur, matching original)
        final glp = pGlowFill
          ..color = col.withValues(alpha: da * 0.4)
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawLine(Offset(cx - w / 2, 0), Offset(cx + w / 2, h), glp);
        canvas.drawLine(Offset(cx + w / 2, 0), Offset(cx - w / 2, h), glp);
        // Center dot
        canvas.drawCircle(Offset(cx, h / 2), 3,
          pFill..color = Color.fromARGB((da * 255).toInt(), 255, 255, 255));

      case ObstacleType.doubleWall:
        // Glitch block
        final totalW = o.size.x;
        canvas.drawRect(Rect.fromLTWH(0, 0, totalW, h), glow);
        canvas.drawRect(Rect.fromLTWH(0, 0, totalW, h), fill);
        // Scanlines
        final scan = pFill..color = Color.fromARGB((da * 40).toInt(), 255, 255, 255);
        for (double sy = 2; sy < h; sy += 4) {
          canvas.drawRect(Rect.fromLTWH(0, sy, totalW, 1), scan);
        }
        // Glitch offset rectangles
        final glitch = pFill..color = Color.fromARGB((da * 100).toInt(), 255, 255, 255);
        canvas.drawRect(Rect.fromLTWH(3, h * 0.3, totalW * 0.4, 3), glitch);
        canvas.drawRect(Rect.fromLTWH(totalW * 0.5, h * 0.6, totalW * 0.4, 2), glitch);

      case ObstacleType.shifter:
        // Pulse orb
        final cx = w / 2;
        // Outer ring
        canvas.drawCircle(Offset(cx, h / 2), w * 0.42, glow);
        final ringP = pStroke
          ..color = col
          ..strokeWidth = 2;
        canvas.drawCircle(Offset(cx, h / 2), w * 0.38, ringP);
        // Inner orb
        canvas.drawCircle(Offset(cx, h / 2), w * 0.2,
          pFill..color = Color.fromARGB((da * 255).toInt(), 255, 255, 255));
        // Orbiting dots
        final goingRight = o.secondLaneCenterX > o.laneCenterX;
        final angle = goingRight ? 0.8 : -0.8;
        final dotP = pFill..color = col;
        canvas.drawCircle(
          Offset(cx + cos(angle) * w * 0.35, h / 2 + sin(angle) * w * 0.35), 2, dotP);
        canvas.drawCircle(
          Offset(cx + cos(angle + 3.14) * w * 0.35, h / 2 + sin(angle + 3.14) * w * 0.35), 2, dotP);
    }
  }
}
