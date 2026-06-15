import 'dart:ui';
import '../../game_state.dart';
import '../../components/obstacle.dart';
import 'obstacle_renderer.dart';

/// City: barriers, cones, containers, vehicles.
class CityObstacleRenderer extends ObstacleRenderer {
  const CityObstacleRenderer();

  @override
  void render(Canvas canvas, Obstacle o, Paint fill, Paint glow, Color col, double da) {
    final w = o.w;
    final h = o.h;
    switch (o.type) {
      case ObstacleType.wall:
        // Road barrier
        final cx = o.laneCenterX - o.position.x;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - w / 2, 0, w, h), const Radius.circular(3));
        canvas.drawRRect(rect, glow);
        canvas.drawRRect(rect, fill);
        // Stripes
        final stripe = pFill..color = Color.fromARGB((da * 120).toInt(), 255, 200, 0);
        for (double sy = 3; sy < h - 5; sy += 8) {
          canvas.drawRect(Rect.fromLTWH(cx - w / 2 + 2, sy, w - 4, 3), stripe);
        }

      case ObstacleType.spike:
        // Traffic cone
        final cx = o.laneCenterX - o.position.x;
        final path = Path()
          ..moveTo(cx, 0)..lineTo(cx - w * 0.15, 0)..lineTo(cx - w / 2, h)
          ..lineTo(cx + w / 2, h)..lineTo(cx + w * 0.15, 0)..close();
        canvas.drawPath(path, glow);
        canvas.drawPath(path, fill);
        // Orange stripes
        final stripe = pFill..color = Color.fromARGB((da * 150).toInt(), 255, 140, 0);
        canvas.drawRect(Rect.fromLTWH(cx - w * 0.3, h * 0.4, w * 0.6, 3), stripe);
        canvas.drawRect(Rect.fromLTWH(cx - w * 0.2, h * 0.65, w * 0.4, 2), stripe);

      case ObstacleType.doubleWall:
        // Shipping container
        final totalW = o.size.x;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, totalW, h), const Radius.circular(2));
        canvas.drawRRect(rect, glow);
        canvas.drawRRect(rect, fill);
        // Container ridges
        final ridge = pFillLine..color = Color.fromARGB((da * 50).toInt(), 0, 0, 0)..strokeWidth = 1;
        for (double rx = 6; rx < totalW - 4; rx += 8) {
          canvas.drawLine(Offset(rx, 2), Offset(rx, h - 2), ridge);
        }
        // Door line
        canvas.drawLine(
          Offset(totalW / 2, 2), Offset(totalW / 2, h - 2),
          pFillLine..color = Color.fromARGB((da * 80).toInt(), 0, 0, 0)..strokeWidth = 2);

      case ObstacleType.shifter:
        // Small car
        final cx = w / 2;
        // Body
        final bodyRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - w * 0.4, h * 0.2, w * 0.8, h * 0.6), const Radius.circular(5));
        canvas.drawRRect(bodyRect, glow);
        canvas.drawRRect(bodyRect, fill);
        // Roof
        final roofRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - w * 0.25, h * 0.05, w * 0.5, h * 0.35), const Radius.circular(4));
        canvas.drawRRect(roofRect, fill);
        // Wheels
        final wheelP = pFill..color = Color.fromARGB((da * 200).toInt(), 30, 30, 30);
        canvas.drawCircle(Offset(cx - w * 0.25, h * 0.8), 3.5, wheelP);
        canvas.drawCircle(Offset(cx + w * 0.25, h * 0.8), 3.5, wheelP);
        // Headlights
        final goingRight = o.secondLaneCenterX > o.laneCenterX;
        final lightP = pFill..color = Color.fromARGB((da * 200).toInt(), 255, 255, 180);
        final lightX = goingRight ? cx + w * 0.38 : cx - w * 0.38;
        canvas.drawCircle(Offset(lightX, h * 0.35), 2, lightP);
    }
  }
}
