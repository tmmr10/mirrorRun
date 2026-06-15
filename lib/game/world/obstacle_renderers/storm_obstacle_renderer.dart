import 'dart:ui';
import '../../game_state.dart';
import '../../components/obstacle.dart';
import 'obstacle_renderer.dart';

/// Storm: lightning rods, ball lightning, storm towers, sideways bolts.
class StormObstacleRenderer extends ObstacleRenderer {
  const StormObstacleRenderer();

  @override
  void render(Canvas canvas, Obstacle o, Paint fill, Paint glow, Color col, double da) {
    final w = o.w;
    final h = o.h;
    switch (o.type) {
      case ObstacleType.wall:
        // Lightning rod
        final cx = o.laneCenterX - o.position.x;
        // Rod
        canvas.drawRect(Rect.fromLTWH(cx - 2, h * 0.15, 4, h * 0.85), fill);
        // Top conductor
        final topPath = Path()
          ..moveTo(cx - w * 0.3, h * 0.2)
          ..lineTo(cx, 0)
          ..lineTo(cx + w * 0.3, h * 0.2)
          ..close();
        canvas.drawPath(topPath, glow);
        canvas.drawPath(topPath, fill);
        // Electric arc at top
        final arc = pFillLine..color = Color.fromARGB((da * 200).toInt(), 238, 221, 68)..strokeWidth = 1.5;
        canvas.drawLine(Offset(cx, h * 0.05), Offset(cx - 5, h * -0.05), arc);
        canvas.drawLine(Offset(cx, h * 0.05), Offset(cx + 4, h * -0.03), arc);

      case ObstacleType.spike:
        // Ball lightning
        final cx = o.laneCenterX - o.position.x;
        // Outer glow
        canvas.drawCircle(Offset(cx, h / 2), w * 0.45,
          pGlowFill..color = Color.fromARGB((da * 60).toInt(), 238, 221, 68)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
        canvas.drawCircle(Offset(cx, h / 2), w * 0.3, glow);
        canvas.drawCircle(Offset(cx, h / 2), w * 0.25, fill);
        // Inner bright core
        canvas.drawCircle(Offset(cx, h / 2), w * 0.12,
          pFill..color = Color.fromARGB((da * 220).toInt(), 255, 255, 200));
        // Sparks
        final spark = pFillLine..color = Color.fromARGB((da * 150).toInt(), 238, 221, 68)..strokeWidth = 1;
        canvas.drawLine(Offset(cx - w * 0.3, h * 0.3), Offset(cx - w * 0.45, h * 0.2), spark);
        canvas.drawLine(Offset(cx + w * 0.25, h * 0.65), Offset(cx + w * 0.4, h * 0.75), spark);

      case ObstacleType.doubleWall:
        // Storm towers (two pillars with arc between)
        final totalW = o.size.x;
        final tw = totalW * 0.2;
        // Left tower
        canvas.drawRect(Rect.fromLTWH(0, 0, tw, h), glow);
        canvas.drawRect(Rect.fromLTWH(0, 0, tw, h), fill);
        // Right tower
        canvas.drawRect(Rect.fromLTWH(totalW - tw, 0, tw, h), glow);
        canvas.drawRect(Rect.fromLTWH(totalW - tw, 0, tw, h), fill);
        // Electric arc between towers
        final arcPaint = pStroke
          ..color = Color.fromARGB((da * 180).toInt(), 238, 221, 68)
          ..strokeWidth = 2;
        final arcPath = Path()..moveTo(tw, h * 0.4);
        for (double ax = tw; ax < totalW - tw; ax += 6) {
          final ay = h * 0.4 + ((ax / 6).toInt() % 2 == 0 ? -4 : 4);
          arcPath.lineTo(ax, ay);
        }
        arcPath.lineTo(totalW - tw, h * 0.4);
        canvas.drawPath(arcPath, arcPaint);
        // Glow on arc
        canvas.drawPath(arcPath, pStrokeGlow
          ..color = Color.fromARGB((da * 40).toInt(), 238, 221, 68)
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.butt
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

      case ObstacleType.shifter:
        // Sideways lightning bolt
        final cx = w / 2;
        final boltPath = Path()
          ..moveTo(cx - w * 0.35, h * 0.2)
          ..lineTo(cx + w * 0.05, h * 0.35)
          ..lineTo(cx - w * 0.1, h * 0.45)
          ..lineTo(cx + w * 0.35, h * 0.6)
          ..lineTo(cx + w * 0.05, h * 0.65)
          ..lineTo(cx + w * 0.15, h * 0.8);
        // Glow
        canvas.drawPath(boltPath, pStrokeGlow
          ..color = Color.fromARGB((da * 60).toInt(), 238, 221, 68)
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
        // Bolt
        canvas.drawPath(boltPath, pStrokeCap
          ..color = col
          ..strokeWidth = 3);
        // Bright core
        canvas.drawPath(boltPath, pStroke
          ..color = Color.fromARGB((da * 200).toInt(), 255, 255, 200)
          ..strokeWidth = 1.5);
    }
  }
}
