import 'dart:ui';
import '../../game_state.dart';
import '../../components/obstacle.dart';
import 'obstacle_renderer.dart';

/// Desert: obelisks, cacti, double pillars, sandstorm whirls.
class DesertObstacleRenderer extends ObstacleRenderer {
  const DesertObstacleRenderer();

  @override
  void render(Canvas canvas, Obstacle o, Paint fill, Paint glow, Color col, double da) {
    final w = o.w;
    final h = o.h;
    switch (o.type) {
      case ObstacleType.wall:
        // Sandstone obelisk
        final cx = o.laneCenterX - o.position.x;
        final path = Path()
          ..moveTo(cx - w * 0.35, h)
          ..lineTo(cx - w * 0.25, h * 0.1)
          ..lineTo(cx, 0)
          ..lineTo(cx + w * 0.25, h * 0.1)
          ..lineTo(cx + w * 0.35, h)
          ..close();
        canvas.drawPath(path, glow);
        canvas.drawPath(path, fill);
        // Hieroglyph-like marks
        final mark = pFillLine..color = Color.fromARGB((da * 80).toInt(), 0, 0, 0)..strokeWidth = 1;
        canvas.drawLine(Offset(cx - 3, h * 0.4), Offset(cx + 3, h * 0.4), mark);
        canvas.drawLine(Offset(cx - 2, h * 0.55), Offset(cx + 2, h * 0.55), mark);
        canvas.drawRect(Rect.fromLTWH(cx - 2, h * 0.65, 4, 4), mark);

      case ObstacleType.spike:
        // Cactus
        final cx = o.laneCenterX - o.position.x;
        final stemW = w * 0.25;
        // Main stem
        canvas.drawRect(Rect.fromLTWH(cx - stemW / 2, h * 0.1, stemW, h * 0.9), glow);
        canvas.drawRect(Rect.fromLTWH(cx - stemW / 2, h * 0.1, stemW, h * 0.9), fill);
        // Arms
        final armW = stemW * 0.7;
        // Left arm
        canvas.drawRect(Rect.fromLTWH(cx - stemW / 2 - armW, h * 0.3, armW, armW), fill);
        canvas.drawRect(Rect.fromLTWH(cx - stemW / 2 - armW, h * 0.15, armW, h * 0.15 + armW), fill);
        // Right arm
        canvas.drawRect(Rect.fromLTWH(cx + stemW / 2, h * 0.45, armW, armW), fill);
        canvas.drawRect(Rect.fromLTWH(cx + stemW / 2, h * 0.3, armW, h * 0.15 + armW), fill);
        // Spines
        final spine = pFillLine..color = Color.fromARGB((da * 100).toInt(), 255, 255, 200)..strokeWidth = 0.5;
        for (double sy = h * 0.15; sy < h * 0.9; sy += 8) {
          canvas.drawLine(Offset(cx - stemW / 2 - 2, sy), Offset(cx - stemW / 2, sy), spine);
          canvas.drawLine(Offset(cx + stemW / 2 + 2, sy), Offset(cx + stemW / 2, sy), spine);
        }

      case ObstacleType.doubleWall:
        // Double sandstone pillars
        final totalW = o.size.x;
        final pillarW = totalW * 0.35;
        // Left pillar
        canvas.drawRect(Rect.fromLTWH(0, h * 0.1, pillarW, h * 0.9), glow);
        canvas.drawRect(Rect.fromLTWH(0, h * 0.1, pillarW, h * 0.9), fill);
        // Right pillar
        canvas.drawRect(Rect.fromLTWH(totalW - pillarW, h * 0.1, pillarW, h * 0.9), glow);
        canvas.drawRect(Rect.fromLTWH(totalW - pillarW, h * 0.1, pillarW, h * 0.9), fill);
        // Connecting lintel
        canvas.drawRect(Rect.fromLTWH(0, h * 0.05, totalW, h * 0.12), fill);
        // Sand texture
        final sand = pFill..color = Color.fromARGB((da * 40).toInt(), 0, 0, 0);
        canvas.drawCircle(Offset(pillarW * 0.5, h * 0.5), 2, sand);
        canvas.drawCircle(Offset(totalW - pillarW * 0.5, h * 0.6), 1.5, sand);

      case ObstacleType.shifter:
        // Sandstorm whirl
        final cx = w / 2;
        // Swirling sand
        canvas.drawCircle(Offset(cx, h / 2), w * 0.4,
          pGlowFill..color = col.withValues(alpha: da * 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
        canvas.drawCircle(Offset(cx, h / 2), w * 0.28, glow);
        canvas.drawCircle(Offset(cx, h / 2), w * 0.22, fill);
        // Swirl lines
        final swirl = pStroke..color = Color.fromARGB((da * 100).toInt(), 255, 220, 150)..strokeWidth = 1.5;
        final sPath = Path()
          ..moveTo(cx - w * 0.15, h * 0.3)
          ..quadraticBezierTo(cx + w * 0.2, h * 0.4, cx - w * 0.1, h * 0.6)
          ..quadraticBezierTo(cx + w * 0.15, h * 0.7, cx, h * 0.75);
        canvas.drawPath(sPath, swirl);
    }
  }
}
