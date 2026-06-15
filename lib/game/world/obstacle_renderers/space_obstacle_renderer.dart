import 'dart:ui';
import '../../game_state.dart';
import '../../components/obstacle.dart';
import 'obstacle_renderer.dart';

/// Space: asteroids, satellites, debris, UFOs.
class SpaceObstacleRenderer extends ObstacleRenderer {
  const SpaceObstacleRenderer();

  @override
  void render(Canvas canvas, Obstacle o, Paint fill, Paint glow, Color col, double da) {
    final w = o.w;
    final h = o.h;
    switch (o.type) {
      case ObstacleType.wall:
        // Asteroid
        final cx = o.laneCenterX - o.position.x;
        final path = Path()
          ..moveTo(cx - w * 0.1, 0)
          ..lineTo(cx - w / 2, h * 0.25)
          ..lineTo(cx - w * 0.45, h * 0.7)
          ..lineTo(cx - w * 0.1, h)
          ..lineTo(cx + w * 0.3, h * 0.85)
          ..lineTo(cx + w / 2, h * 0.4)
          ..lineTo(cx + w * 0.2, h * 0.05)
          ..close();
        canvas.drawPath(path, glow);
        canvas.drawPath(path, fill);
        // Craters
        final crater = pFill..color = Color.fromARGB((da * 60).toInt(), 0, 0, 0);
        canvas.drawCircle(Offset(cx - 2, h * 0.35), 3, crater);
        canvas.drawCircle(Offset(cx + 4, h * 0.6), 2, crater);

      case ObstacleType.spike:
        // Satellite dish / antenna
        final cx = o.laneCenterX - o.position.x;
        // Mast
        canvas.drawRect(
          Rect.fromLTWH(cx - 1.5, h * 0.3, 3, h * 0.7),
          fill);
        // Dish
        final dish = Path()
          ..moveTo(cx - w / 2, h * 0.35)
          ..quadraticBezierTo(cx, 0, cx + w / 2, h * 0.35)
          ..close();
        canvas.drawPath(dish, glow);
        canvas.drawPath(dish, fill);
        // Signal dot
        canvas.drawCircle(Offset(cx, h * 0.15), 2,
          pFill..color = Color.fromARGB((da * 200).toInt(), 255, 100, 100));

      case ObstacleType.doubleWall:
        // Space debris / hull fragment
        final totalW = o.size.x;
        final path = Path()
          ..moveTo(4, h * 0.15)
          ..lineTo(0, h * 0.5)
          ..lineTo(3, h * 0.9)
          ..lineTo(totalW - 3, h)
          ..lineTo(totalW, h * 0.45)
          ..lineTo(totalW - 5, h * 0.05)
          ..close();
        canvas.drawPath(path, glow);
        canvas.drawPath(path, fill);
        // Rivets
        final rivet = pFill..color = Color.fromARGB((da * 100).toInt(), 200, 200, 255);
        for (double rx = 8; rx < totalW - 4; rx += 12) {
          canvas.drawCircle(Offset(rx, h * 0.5), 1.5, rivet);
        }

      case ObstacleType.shifter:
        // UFO
        final cx = w / 2;
        // Dome
        canvas.drawOval(
          Rect.fromLTWH(cx - w * 0.2, h * 0.1, w * 0.4, h * 0.35), fill);
        // Saucer body
        canvas.drawOval(
          Rect.fromLTWH(cx - w / 2, h * 0.3, w, h * 0.35), glow);
        canvas.drawOval(
          Rect.fromLTWH(cx - w / 2, h * 0.3, w, h * 0.35), fill);
        // Lights
        final light = pFill..color = Color.fromARGB((da * 200).toInt(), 255, 255, 150);
        canvas.drawCircle(Offset(cx - w * 0.3, h * 0.5), 2, light);
        canvas.drawCircle(Offset(cx, h * 0.52), 2, light);
        canvas.drawCircle(Offset(cx + w * 0.3, h * 0.5), 2, light);
        // Beam
        final beam = pFill..color = Color.fromARGB((da * 40).toInt(), 200, 255, 200);
        final beamPath = Path()
          ..moveTo(cx - w * 0.15, h * 0.6)
          ..lineTo(cx - w * 0.3, h)
          ..lineTo(cx + w * 0.3, h)
          ..lineTo(cx + w * 0.15, h * 0.6)
          ..close();
        canvas.drawPath(beamPath, beam);
    }
  }
}
