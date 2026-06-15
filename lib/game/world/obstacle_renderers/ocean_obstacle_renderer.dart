import 'dart:math';
import 'dart:ui';
import '../../game_state.dart';
import '../../components/obstacle.dart';
import 'obstacle_renderer.dart';

/// Ocean: coral, jellyfish, waves, pufferfish.
class OceanObstacleRenderer extends ObstacleRenderer {
  const OceanObstacleRenderer();

  @override
  void render(Canvas canvas, Obstacle o, Paint fill, Paint glow, Color col, double da) {
    final w = o.w;
    final h = o.h;
    switch (o.type) {
      case ObstacleType.wall:
        // Coral formation
        final cx = o.laneCenterX - o.position.x;
        // Base
        canvas.drawOval(Rect.fromLTWH(cx - w / 2, h * 0.5, w, h * 0.5), glow);
        canvas.drawOval(Rect.fromLTWH(cx - w / 2, h * 0.5, w, h * 0.5), fill);
        // Branches
        final branch = pFillLineCap..color = col..strokeWidth = 3;
        canvas.drawLine(Offset(cx - 4, h * 0.5), Offset(cx - 6, h * 0.1), branch);
        canvas.drawLine(Offset(cx + 2, h * 0.45), Offset(cx + 5, 0), branch);
        canvas.drawLine(Offset(cx + 1, h * 0.5), Offset(cx - 1, h * 0.15), branch);
        // Tips
        final tip = pFill..color = Color.fromARGB((da * 180).toInt(), 150, 255, 255);
        canvas.drawCircle(Offset(cx - 6, h * 0.1), 2, tip);
        canvas.drawCircle(Offset(cx + 5, 0), 2, tip);
        canvas.drawCircle(Offset(cx - 1, h * 0.15), 1.5, tip);

      case ObstacleType.spike:
        // Jellyfish
        final cx = o.laneCenterX - o.position.x;
        // Dome
        final dome = Path()
          ..moveTo(cx - w / 2, h * 0.4)
          ..quadraticBezierTo(cx - w / 2, 0, cx, 0)
          ..quadraticBezierTo(cx + w / 2, 0, cx + w / 2, h * 0.4)
          ..close();
        canvas.drawPath(dome, glow);
        canvas.drawPath(dome, fill);
        // Tentacles
        final tent = pStroke..color = col.withValues(alpha: da * 0.7)..strokeWidth = 1.5;
        for (double tx = cx - w * 0.3; tx <= cx + w * 0.3; tx += 5) {
          final path = Path()..moveTo(tx, h * 0.4);
          path.quadraticBezierTo(tx + 2, h * 0.65, tx - 1, h);
          canvas.drawPath(path, tent);
        }

      case ObstacleType.doubleWall:
        // Wave / seaweed wall
        final totalW = o.size.x;
        final path = Path()..moveTo(0, h);
        for (double x = 0; x <= totalW; x += 8) {
          final waveY = h * 0.3 + sin(x * 0.3) * h * 0.15;
          path.lineTo(x, waveY);
        }
        path.lineTo(totalW, h);
        path.close();
        canvas.drawPath(path, glow);
        canvas.drawPath(path, fill);
        // Bubbles
        final bub = pFill..color = Color.fromARGB((da * 80).toInt(), 180, 255, 255);
        canvas.drawCircle(Offset(totalW * 0.2, h * 0.2), 2, bub);
        canvas.drawCircle(Offset(totalW * 0.5, h * 0.15), 3, bub);
        canvas.drawCircle(Offset(totalW * 0.75, h * 0.25), 1.5, bub);

      case ObstacleType.shifter:
        // Pufferfish
        final cx = w / 2;
        // Body (round)
        canvas.drawCircle(Offset(cx, h / 2), w * 0.38, glow);
        canvas.drawCircle(Offset(cx, h / 2), w * 0.35, fill);
        // Spines
        final spine = pFillLineCap..color = col..strokeWidth = 1.5;
        for (double angle = 0; angle < 3.14159 * 2; angle += 0.7) {
          final sx = cx + cos(angle) * w * 0.35;
          final sy = h / 2 + sin(angle) * w * 0.35;
          final ex = cx + cos(angle) * w * 0.48;
          final ey = h / 2 + sin(angle) * w * 0.48;
          canvas.drawLine(Offset(sx, sy), Offset(ex, ey), spine);
        }
        // Eye
        final eyeP = pFill..color = Color.fromARGB((da * 220).toInt(), 255, 255, 255);
        final goingRight = o.secondLaneCenterX > o.laneCenterX;
        canvas.drawCircle(Offset(cx + (goingRight ? 4 : -4), h / 2 - 3), 2.5, eyeP);
        canvas.drawCircle(Offset(cx + (goingRight ? 4 : -4), h / 2 - 3), 1, pFill..color = Color.fromARGB((da * 220).toInt(), 0, 0, 0));
    }
  }
}
