import 'dart:ui';
import '../../game_state.dart';
import '../../components/obstacle.dart';
import 'obstacle_renderer.dart';

/// Forest: stumps, thorns, root tangles, critters.
class ForestObstacleRenderer extends ObstacleRenderer {
  const ForestObstacleRenderer();

  @override
  void render(Canvas canvas, Obstacle o, Paint fill, Paint glow, Color col, double da) {
    final w = o.w;
    final h = o.h;
    switch (o.type) {
      case ObstacleType.wall:
        // Tree stump
        final cx = o.laneCenterX - o.position.x;
        final trunkW = w * 0.55;
        final trunk = Rect.fromLTWH(cx - trunkW / 2, h * 0.2, trunkW, h * 0.8);
        canvas.drawRect(trunk, glow);
        canvas.drawRect(trunk, fill);
        // Crown (bushy top)
        canvas.drawOval(Rect.fromLTWH(cx - w / 2, -2, w, h * 0.55), glow);
        canvas.drawOval(Rect.fromLTWH(cx - w / 2, -2, w, h * 0.55), fill);
        // Bark lines
        final bark = pFillLine..color = const Color(0x20000000)..strokeWidth = 1;
        canvas.drawLine(Offset(cx - 2, h * 0.3), Offset(cx - 2, h * 0.9), bark);
        canvas.drawLine(Offset(cx + 2, h * 0.4), Offset(cx + 2, h * 0.85), bark);

      case ObstacleType.spike:
        // Mushroom (poisonous toadstool)
        final cx = o.laneCenterX - o.position.x;
        // Stem
        final stemW = w * 0.3;
        canvas.drawRect(Rect.fromLTWH(cx - stemW / 2, h * 0.4, stemW, h * 0.6), fill);
        // Cap (dome)
        final cap = Path()
          ..moveTo(cx - w / 2, h * 0.45)
          ..quadraticBezierTo(cx - w / 2, 0, cx, 0)
          ..quadraticBezierTo(cx + w / 2, 0, cx + w / 2, h * 0.45)
          ..close();
        canvas.drawPath(cap, glow);
        canvas.drawPath(cap, fill);
        // Spots
        final spot = pFill..color = Color.fromARGB((da * 160).toInt(), 255, 255, 200);
        canvas.drawCircle(Offset(cx - 4, h * 0.18), 2.5, spot);
        canvas.drawCircle(Offset(cx + 3, h * 0.25), 2, spot);
        canvas.drawCircle(Offset(cx, h * 0.12), 1.5, spot);

      case ObstacleType.doubleWall:
        // Fallen log across two lanes
        final totalW = o.size.x;
        final logRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(0, h * 0.2, totalW, h * 0.6), const Radius.circular(8));
        canvas.drawRRect(logRect, glow);
        canvas.drawRRect(logRect, fill);
        // Rings
        final ringPaint = pStroke..color = Color.fromARGB((da * 60).toInt(), 0, 0, 0)..strokeWidth = 1;
        canvas.drawOval(Rect.fromLTWH(2, h * 0.22, 10, h * 0.56), ringPaint);
        canvas.drawOval(Rect.fromLTWH(totalW - 12, h * 0.22, 10, h * 0.56), ringPaint);
        // Moss spots
        final moss = pFill..color = col.withValues(alpha: da * 0.4);
        canvas.drawCircle(Offset(totalW * 0.3, h * 0.35), 3, moss);
        canvas.drawCircle(Offset(totalW * 0.7, h * 0.55), 2.5, moss);

      case ObstacleType.shifter:
        // Forest critter (fox/rabbit shape)
        final cx = w / 2;
        // Body oval
        canvas.drawOval(Rect.fromLTWH(cx - w * 0.4, h * 0.3, w * 0.8, h * 0.5), glow);
        canvas.drawOval(Rect.fromLTWH(cx - w * 0.4, h * 0.3, w * 0.8, h * 0.5), fill);
        // Head
        canvas.drawCircle(Offset(cx, h * 0.25), w * 0.28, fill);
        // Ears
        final goingRight = o.secondLaneCenterX > o.laneCenterX;
        final earPath = Path()
          ..moveTo(cx - 5, h * 0.12)..lineTo(cx - 7, 0)..lineTo(cx - 1, h * 0.1)..close()
          ..moveTo(cx + 5, h * 0.12)..lineTo(cx + 7, 0)..lineTo(cx + 1, h * 0.1)..close();
        canvas.drawPath(earPath, fill);
        // Eyes
        final eyeP = pFill..color = Color.fromARGB((da * 180).toInt(), 255, 255, 255);
        canvas.drawCircle(Offset(cx - 3, h * 0.22), 1.5, eyeP);
        canvas.drawCircle(Offset(cx + 3, h * 0.22), 1.5, eyeP);
        // Direction tail
        final tailX = goingRight ? cx + w * 0.35 : cx - w * 0.35;
        canvas.drawCircle(Offset(tailX, h * 0.55), 3, fill);
    }
  }
}
