import 'dart:ui';
import '../../game_state.dart';
import '../../components/obstacle.dart';
import 'obstacle_renderer.dart';

/// Crystal: ice columns, icicle clusters, glacier bridges, sliding ice blocks.
class CrystalObstacleRenderer extends ObstacleRenderer {
  const CrystalObstacleRenderer();

  @override
  void render(Canvas canvas, Obstacle o, Paint fill, Paint glow, Color col, double da) {
    final w = o.w;
    final h = o.h;
    switch (o.type) {
      case ObstacleType.wall:
        // Ice column
        final cx = o.laneCenterX - o.position.x;
        final path = Path()
          ..moveTo(cx - w * 0.3, h)
          ..lineTo(cx - w * 0.4, h * 0.3)
          ..lineTo(cx - w * 0.1, 0)
          ..lineTo(cx + w * 0.15, h * 0.1)
          ..lineTo(cx + w * 0.4, h * 0.25)
          ..lineTo(cx + w * 0.35, h)
          ..close();
        canvas.drawPath(path, glow);
        canvas.drawPath(path, fill);
        // Frost shine
        final shine = pFillLine..color = Color.fromARGB((da * 120).toInt(), 200, 240, 255)..strokeWidth = 0;
        canvas.drawLine(Offset(cx - w * 0.1, h * 0.1), Offset(cx - w * 0.15, h * 0.6), shine);
        canvas.drawLine(Offset(cx + w * 0.2, h * 0.2), Offset(cx + w * 0.1, h * 0.7), shine);

      case ObstacleType.spike:
        // Icicle cluster (hanging stalactites)
        final cx = o.laneCenterX - o.position.x;
        for (int i = -1; i <= 1; i++) {
          final ox = cx + i * w * 0.25;
          final ih = h * (0.7 + i.abs() * -0.15);
          final iw = w * 0.15;
          final ip = Path()
            ..moveTo(ox - iw, 0)
            ..lineTo(ox, ih)
            ..lineTo(ox + iw, 0)
            ..close();
          canvas.drawPath(ip, glow);
          canvas.drawPath(ip, fill);
        }
        // Frost sparkle
        canvas.drawCircle(Offset(cx, h * 0.3), 2,
          pFill..color = Color.fromARGB((da * 180).toInt(), 220, 255, 255));

      case ObstacleType.doubleWall:
        // Glacier bridge
        final totalW = o.size.x;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(0, h * 0.2, totalW, h * 0.6), const Radius.circular(4));
        canvas.drawRRect(rect, glow);
        canvas.drawRRect(rect, fill);
        // Ice cracks
        final crack = pFillLine..color = Color.fromARGB((da * 80).toInt(), 180, 230, 255)..strokeWidth = 1;
        canvas.drawLine(Offset(totalW * 0.2, h * 0.3), Offset(totalW * 0.35, h * 0.6), crack);
        canvas.drawLine(Offset(totalW * 0.6, h * 0.25), Offset(totalW * 0.5, h * 0.7), crack);
        canvas.drawLine(Offset(totalW * 0.8, h * 0.4), Offset(totalW * 0.75, h * 0.65), crack);

      case ObstacleType.shifter:
        // Sliding ice block
        final cx = w / 2;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - w * 0.35, h * 0.15, w * 0.7, h * 0.7), const Radius.circular(3));
        canvas.drawRRect(rect, glow);
        canvas.drawRRect(rect, fill);
        // Frost surface detail
        final frost = pFillLine..color = Color.fromARGB((da * 100).toInt(), 200, 240, 255)..strokeWidth = 0;
        canvas.drawLine(Offset(cx - w * 0.2, h * 0.35), Offset(cx + w * 0.15, h * 0.5), frost);
        // Direction indicator
        final goingRight = o.secondLaneCenterX > o.laneCenterX;
        final trail = pFill..color = Color.fromARGB((da * 60).toInt(), 180, 230, 255);
        final tx = goingRight ? cx - w * 0.3 : cx + w * 0.3;
        canvas.drawCircle(Offset(tx, h * 0.5), 3, trail);
    }
  }
}
