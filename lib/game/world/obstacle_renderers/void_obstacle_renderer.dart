import 'dart:ui';
import '../../game_state.dart';
import '../../components/obstacle.dart';
import 'obstacle_renderer.dart';

/// Void: static, fragments, cracks, shadows.
class VoidObstacleRenderer extends ObstacleRenderer {
  const VoidObstacleRenderer();

  @override
  void render(Canvas canvas, Obstacle o, Paint fill, Paint glow, Color col, double da) {
    final w = o.w;
    final h = o.h;
    switch (o.type) {
      case ObstacleType.wall:
        // Static noise block
        final cx = o.laneCenterX - o.position.x;
        final rect = Rect.fromLTWH(cx - w / 2, 0, w, h);
        canvas.drawRect(rect, glow);
        canvas.drawRect(rect, fill);
        // Noise lines
        final noise = pFillLine..color = Color.fromARGB((da * 60).toInt(), 255, 255, 255)..strokeWidth = 1;
        for (double ny = 2; ny < h - 2; ny += 3) {
          final offset = ((ny * 7).toInt() % 5) - 2;
          canvas.drawLine(
            Offset(cx - w / 2 + 2 + offset, ny),
            Offset(cx + w / 2 - 2 + offset, ny),
            noise);
        }

      case ObstacleType.spike:
        // Crack / rift
        final cx = o.laneCenterX - o.position.x;
        final path = Path()
          ..moveTo(cx, 0)
          ..lineTo(cx - 3, h * 0.2)
          ..lineTo(cx + 4, h * 0.4)
          ..lineTo(cx - 2, h * 0.6)
          ..lineTo(cx + 3, h * 0.8)
          ..lineTo(cx, h);
        final riftP = pStrokeCap
          ..color = col
          ..strokeWidth = 4;
        canvas.drawPath(path, pStrokeGlow
          ..color = col.withValues(alpha: da * 0.5)
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
        canvas.drawPath(path, riftP);
        // White core
        canvas.drawPath(path, pStroke
          ..color = Color.fromARGB((da * 200).toInt(), 255, 255, 255)
          ..strokeWidth = 1.5);

      case ObstacleType.doubleWall:
        // Fragmented bar
        final totalW = o.size.x;
        // Draw as broken segments
        double sx = 0;
        int seg = 0;
        while (sx < totalW) {
          final segW = 6.0 + (seg * 7 % 5);
          final offset = (seg % 2 == 0 ? -2.0 : 2.0);
          canvas.drawRect(
            Rect.fromLTWH(sx, offset + 1, segW.clamp(0, totalW - sx), h - 2),
            glow);
          canvas.drawRect(
            Rect.fromLTWH(sx, offset + 1, segW.clamp(0, totalW - sx), h - 2),
            fill);
          sx += segW + 2;
          seg++;
        }

      case ObstacleType.shifter:
        // Shadow entity
        final cx = w / 2;
        // Amorphous shape
        canvas.drawCircle(Offset(cx, h / 2), w * 0.4,
          pGlowFill
            ..color = col.withValues(alpha: da * 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
        canvas.drawCircle(Offset(cx, h / 2), w * 0.3, fill);
        // Void eyes
        final eyeP = pFill..color = Color.fromARGB((da * 255).toInt(), 255, 255, 255);
        canvas.drawCircle(Offset(cx - 4, h / 2 - 2), 2, eyeP);
        canvas.drawCircle(Offset(cx + 4, h / 2 - 2), 2, eyeP);
    }
  }
}
