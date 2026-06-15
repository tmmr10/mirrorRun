import 'dart:ui';
import '../../game_state.dart';
import '../../components/obstacle.dart';
import 'obstacle_renderer.dart';

/// Ruins: cracked stone, splinters, pillar pairs, rolling boulders.
class RuinsObstacleRenderer extends ObstacleRenderer {
  const RuinsObstacleRenderer();

  @override
  void render(Canvas canvas, Obstacle o, Paint fill, Paint glow, Color col, double da) {
    final w = o.w;
    final h = o.h;
    switch (o.type) {
      case ObstacleType.wall:
        // Cracked stone block with vines
        final cx = o.laneCenterX - o.position.x;
        final rect = Rect.fromLTWH(cx - w / 2, 0, w, h);
        canvas.drawRect(rect, glow);
        canvas.drawRect(rect, fill);
        // Cracks
        final crack = pFillLine..color = Color.fromARGB((da * 80).toInt(), 0, 0, 0)..strokeWidth = 1;
        canvas.drawLine(Offset(cx - w * 0.2, 0), Offset(cx + w * 0.1, h * 0.4), crack);
        canvas.drawLine(Offset(cx + w * 0.1, h * 0.4), Offset(cx - w * 0.05, h), crack);
        // Vine / moss
        final vine = pFillLine..color = Color.fromARGB((da * 120).toInt(), 60, 140, 60)..strokeWidth = 2;
        final vinePath = Path()
          ..moveTo(cx + w * 0.3, 0)
          ..quadraticBezierTo(cx + w * 0.4, h * 0.3, cx + w * 0.2, h * 0.6);
        canvas.drawPath(vinePath, vine);
        // Moss patch
        canvas.drawCircle(Offset(cx - w * 0.2, h * 0.7), 3,
          pFill..color = Color.fromARGB((da * 80).toInt(), 80, 160, 80));

      case ObstacleType.spike:
        // Stone splinters (broken column top)
        final cx = o.laneCenterX - o.position.x;
        final path = Path()
          ..moveTo(cx - w * 0.4, h)
          ..lineTo(cx - w * 0.35, h * 0.3)
          ..lineTo(cx - w * 0.1, 0)
          ..lineTo(cx + w * 0.1, h * 0.15)
          ..lineTo(cx + w * 0.35, h * 0.05)
          ..lineTo(cx + w * 0.4, h * 0.35)
          ..lineTo(cx + w * 0.3, h)
          ..close();
        canvas.drawPath(path, glow);
        canvas.drawPath(path, fill);
        // Moss accent
        canvas.drawCircle(Offset(cx, h * 0.5), 2.5,
          pFill..color = Color.fromARGB((da * 100).toInt(), 60, 140, 60));

      case ObstacleType.doubleWall:
        // Pillar pair with fallen lintel
        final totalW = o.size.x;
        final pw = totalW * 0.2;
        // Left pillar
        canvas.drawRect(Rect.fromLTWH(0, 0, pw, h), glow);
        canvas.drawRect(Rect.fromLTWH(0, 0, pw, h), fill);
        // Right pillar
        canvas.drawRect(Rect.fromLTWH(totalW - pw, 0, pw, h), glow);
        canvas.drawRect(Rect.fromLTWH(totalW - pw, 0, pw, h), fill);
        // Fallen stone across
        final lintel = RRect.fromRectAndRadius(
          Rect.fromLTWH(pw * 0.5, h * 0.3, totalW - pw, h * 0.25), const Radius.circular(2));
        canvas.drawRRect(lintel, fill);
        // Vine detail
        final vine = pStroke..color = Color.fromARGB((da * 80).toInt(), 60, 140, 60)..strokeWidth = 1.5;
        canvas.drawLine(Offset(pw, h * 0.1), Offset(pw + 5, h * 0.5), vine);

      case ObstacleType.shifter:
        // Rolling boulder
        final cx = w / 2;
        canvas.drawCircle(Offset(cx, h / 2), w * 0.4, glow);
        canvas.drawCircle(Offset(cx, h / 2), w * 0.36, fill);
        // Rock texture
        final tex = pFill..color = Color.fromARGB((da * 50).toInt(), 0, 0, 0);
        canvas.drawCircle(Offset(cx - 4, h / 2 - 3), 3, tex);
        canvas.drawCircle(Offset(cx + 3, h / 2 + 2), 2.5, tex);
        // Moss spot
        canvas.drawCircle(Offset(cx + 5, h / 2 - 5), 2,
          pFill..color = Color.fromARGB((da * 80).toInt(), 60, 140, 60));
        // Motion trail
        final goingRight = o.secondLaneCenterX > o.laneCenterX;
        final trail = pFill..color = Color.fromARGB((da * 40).toInt(), 100, 80, 60);
        final trailX = goingRight ? cx - w * 0.35 : cx + w * 0.35;
        canvas.drawCircle(Offset(trailX, h * 0.6), 2, trail);
    }
  }
}
