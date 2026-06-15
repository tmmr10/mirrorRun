import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../models/player_skin.dart';
import 'theme.dart';

class PlayerScenePainter extends CustomPainter {
  final Color leftColor;
  final Color rightColor;
  final double glowT;
  final HeadDecoration headDecoration;
  final FaceDecoration faceDecoration;
  /// When false, only the figures are drawn (no ground/mirror-line scene).
  final bool showScene;

  PlayerScenePainter({
    required this.leftColor,
    required this.rightColor,
    required this.glowT,
    this.headDecoration = HeadDecoration.none,
    this.faceDecoration = FaceDecoration.none,
    this.showScene = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final mid = w / 2;
    final groundY = h * 0.75;

    if (showScene) {
      // Ground line
      canvas.drawLine(
        Offset(w * 0.1, groundY),
        Offset(w * 0.9, groundY),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.06)
          ..strokeWidth = 0.5,
      );

      // Mirror line (vertical, glowing)
      final mirrorPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Color.lerp(leftColor, rightColor, 0.5)!.withValues(alpha: 0.15 + glowT * 0.1),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(mid, 0, 1, h));
      canvas.drawLine(Offset(mid, h * 0.15), Offset(mid, groundY + 10), mirrorPaint);
    }

    // Left player
    _drawPlayer(canvas, mid * 0.55, groundY, leftColor);

    // Right player (mirrored)
    _drawPlayer(canvas, mid + mid * 0.45, groundY, rightColor);
  }

  void _drawPlayer(Canvas canvas, double x, double groundY, Color color) {
    final bodyW = 20.0;
    final bodyH = 30.0;
    final bodyTop = groundY - bodyH;
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x - bodyW / 2, bodyTop, bodyW, bodyH),
      const Radius.circular(6),
    );

    // Outer glow
    canvas.drawRRect(
      bodyRect.inflate(4 + glowT * 3),
      Paint()
        ..color = color.withValues(alpha: 0.08 + glowT * 0.06)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Inner glow
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..color = color.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Body
    canvas.drawRRect(bodyRect, Paint()..color = color);

    // Head decoration (above body)
    _drawHeadDecoration(canvas, x, bodyTop, bodyW, color);

    // Eyes
    final eyeY = bodyTop + 9;
    final eyePaint = Paint()..color = const Color(0x80000000);
    canvas.drawCircle(Offset(x - 3.5, eyeY), 2.2, eyePaint);
    canvas.drawCircle(Offset(x + 3.5, eyeY), 2.2, eyePaint);

    // Face decoration (over eyes)
    _drawFaceDecoration(canvas, x, eyeY, bodyW, color);

    // Trail particles below
    final rng = Random(color.toARGB32());
    for (int i = 0; i < 3; i++) {
      final trailAlpha = (0.15 - i * 0.04).clamp(0.0, 1.0);
      final trailY = groundY + 4 + i * 6.0;
      final trailX = x + (rng.nextDouble() - 0.5) * 8;
      canvas.drawCircle(
        Offset(trailX, trailY),
        2 - i * 0.4,
        Paint()..color = color.withValues(alpha: trailAlpha),
      );
    }
  }

  void _drawHeadDecoration(Canvas canvas, double x, double bodyTop, double bodyW, Color color) {
    switch (headDecoration) {
      case HeadDecoration.none:
        break;
      case HeadDecoration.iceCrown:
        final paint = Paint()..color = const Color(0xCCAAEEFF);
        final glow = Paint()
          ..color = const Color(0x4400CCFF)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        for (final dx in [-5.0, 0.0, 5.0]) {
          final h = dx == 0 ? -8.0 : -5.5;
          final path = Path()
            ..moveTo(x + dx - 2, bodyTop)
            ..lineTo(x + dx, bodyTop + h)
            ..lineTo(x + dx + 2, bodyTop)
            ..close();
          canvas.drawPath(path, glow);
          canvas.drawPath(path, paint);
        }
      case HeadDecoration.flames:
        final t = glowT * pi * 4;
        final colors = [const Color(0xDDFF6600), const Color(0xBBFFAA00), const Color(0x99FF3300)];
        for (int i = 0; i < 3; i++) {
          final dx = (i - 1) * 5.0;
          final phase = t + i * 2.1;
          final fh = -4.0 - sin(phase) * 4 - (i == 1 ? 3 : 0);
          final fw = 3.0 + sin(phase * 0.7);
          final path = Path()
            ..moveTo(x + dx - fw, bodyTop + 1)
            ..quadraticBezierTo(x + dx - fw * 0.3, bodyTop + fh - 2, x + dx, bodyTop + fh)
            ..quadraticBezierTo(x + dx + fw * 0.3, bodyTop + fh - 2, x + dx + fw, bodyTop + 1)
            ..close();
          canvas.drawPath(path, Paint()
            ..color = colors[i].withValues(alpha: 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
          canvas.drawPath(path, Paint()..color = colors[i]);
        }
      case HeadDecoration.crown:
        final paint = Paint()..color = MR.gold;
        final glow = Paint()
          ..color = const Color(0x60FFD700)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        final path = Path()
          ..moveTo(x - 8, bodyTop + 2)
          ..lineTo(x - 8, bodyTop - 4)
          ..lineTo(x - 4, bodyTop - 1)
          ..lineTo(x, bodyTop - 7)
          ..lineTo(x + 4, bodyTop - 1)
          ..lineTo(x + 8, bodyTop - 4)
          ..lineTo(x + 8, bodyTop + 2)
          ..close();
        canvas.drawPath(path, glow);
        canvas.drawPath(path, paint);
        canvas.drawCircle(Offset(x, bodyTop - 4), 1.2, Paint()..color = MR.alert);
      case HeadDecoration.antenna:
        final bobY = sin(glowT * pi * 2) * 2;
        canvas.drawLine(
          Offset(x, bodyTop + 2),
          Offset(x, bodyTop - 8 + bobY),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.6)
            ..strokeWidth = 1.5
            ..strokeCap = ui.StrokeCap.round,
        );
        final tipY = bodyTop - 9 + bobY;
        canvas.drawCircle(Offset(x, tipY), 3, Paint()
          ..color = color.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
        canvas.drawCircle(Offset(x, tipY), 2, Paint()..color = color);
      case HeadDecoration.halo:
        final bobY = sin(glowT * pi * 2) * 1.5;
        final haloY = bodyTop - 6 + bobY;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, haloY), width: 20, height: 6),
          Paint()
            ..color = const Color(0x30FFFFFF)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, haloY), width: 18, height: 5),
          Paint()
            ..color = const Color(0xCCFFFFFF)
            ..strokeWidth = 1.5
            ..style = ui.PaintingStyle.stroke,
        );
      case HeadDecoration.horns:
        final paint = Paint()..color = const Color(0xDDCC2222);
        final glow = Paint()
          ..color = const Color(0x40FF0000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        for (final side in [-1.0, 1.0]) {
          final path = Path()
            ..moveTo(x + side * 4, bodyTop + 2)
            ..quadraticBezierTo(x + side * 9, bodyTop - 2, x + side * 8, bodyTop - 8)
            ..lineTo(x + side * 6, bodyTop - 1)
            ..close();
          canvas.drawPath(path, glow);
          canvas.drawPath(path, paint);
        }
      case HeadDecoration.wings:
        final flapY = sin(glowT * pi * 3) * 2;
        final paint = Paint()..color = color.withValues(alpha: 0.6);
        final glow = Paint()
          ..color = color.withValues(alpha: 0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        for (final side in [-1.0, 1.0]) {
          final wingX = x + side * 12;
          final path = Path()
            ..moveTo(x + side * 8, bodyTop + 8)
            ..quadraticBezierTo(wingX + side * 4, bodyTop + 2 + flapY, wingX + side * 2, bodyTop - 2 + flapY)
            ..quadraticBezierTo(wingX, bodyTop + 6 + flapY, x + side * 8, bodyTop + 18)
            ..close();
          canvas.drawPath(path, glow);
          canvas.drawPath(path, paint);
        }
      case HeadDecoration.mohawk:
        final paint = Paint()..color = color;
        final glow = Paint()
          ..color = color.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        for (int i = 0; i < 5; i++) {
          final dx = (i - 2) * 3.0;
          final h = i == 2 ? -10.0 : (i == 1 || i == 3 ? -7.0 : -4.0);
          final path = Path()
            ..moveTo(x + dx - 1.5, bodyTop + 1)
            ..lineTo(x + dx, bodyTop + h)
            ..lineTo(x + dx + 1.5, bodyTop + 1)
            ..close();
          canvas.drawPath(path, glow);
          canvas.drawPath(path, paint);
        }
      case HeadDecoration.star:
        final bobY = sin(glowT * pi * 2) * 2;
        final starY = bodyTop - 10 + bobY;
        final starPaint = Paint()..color = const Color(0xFFFFDD44);
        final starGlow = Paint()
          ..color = const Color(0x60FFDD44)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        final path = Path();
        for (int i = 0; i < 5; i++) {
          final outerAngle = -pi / 2 + i * 2 * pi / 5;
          final innerAngle = outerAngle + pi / 5;
          final ox = x + cos(outerAngle) * 5;
          final oy = starY + sin(outerAngle) * 5;
          final ix = x + cos(innerAngle) * 2;
          final iy = starY + sin(innerAngle) * 2;
          if (i == 0) {
            path.moveTo(ox, oy);
          } else {
            path.lineTo(ox, oy);
          }
          path.lineTo(ix, iy);
        }
        path.close();
        canvas.drawPath(path, starGlow);
        canvas.drawPath(path, starPaint);
    }
  }

  void _drawFaceDecoration(Canvas canvas, double x, double eyeY, double bodyW, Color color) {
    switch (faceDecoration) {
      case FaceDecoration.none:
        break;
      case FaceDecoration.goggles:
        _drawGoggles(canvas, x, eyeY, bodyW);
      case FaceDecoration.visor:
        _drawVisor(canvas, x, eyeY, bodyW, color);
      case FaceDecoration.mask:
        _drawMask(canvas, x, eyeY, bodyW);
      case FaceDecoration.monocle:
        _drawMonocle(canvas, x, eyeY);
      case FaceDecoration.scar:
        _drawScar(canvas, x, eyeY);
      case FaceDecoration.shades:
        _drawShades(canvas, x, eyeY, bodyW);
    }
  }

  void _drawGoggles(Canvas canvas, double x, double eyeY, double bodyW) {
    final strap = Paint()
      ..color = const Color(0xBB000000)
      ..strokeWidth = 1.5
      ..style = ui.PaintingStyle.stroke;
    final lens = Paint()..color = const Color(0xCC88DDFF);
    final glare = Paint()..color = const Color(0x55FFFFFF);
    final frame = Paint()
      ..color = const Color(0xCC444444)
      ..strokeWidth = 1
      ..style = ui.PaintingStyle.stroke;

    canvas.drawLine(Offset(x - bodyW / 2, eyeY), Offset(x + bodyW / 2, eyeY), strap);

    for (final dx in [-3.5, 3.5]) {
      final lr = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x + dx, eyeY), width: 7, height: 6),
        const Radius.circular(2),
      );
      canvas.drawRRect(lr, lens);
      canvas.drawRRect(lr, frame);
      canvas.drawCircle(Offset(x + dx - 1.5, eyeY - 1.5), 1, glare);
    }
  }

  void _drawVisor(Canvas canvas, double x, double eyeY, double bodyW, Color color) {
    final visorRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(x, eyeY), width: bodyW - 2, height: 5),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(visorRect, Paint()
      ..color = color.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawRRect(visorRect, Paint()..color = color.withValues(alpha: 0.7));
    canvas.drawLine(
      Offset(x - bodyW / 2 + 3, eyeY - 1),
      Offset(x + bodyW / 2 - 3, eyeY - 1),
      Paint()
        ..color = const Color(0x55FFFFFF)
        ..strokeWidth = 0.8,
    );
  }

  void _drawMask(Canvas canvas, double x, double eyeY, double bodyW) {
    final maskRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(x, eyeY), width: bodyW + 2, height: 6),
      const Radius.circular(3),
    );
    canvas.drawRRect(maskRect, Paint()..color = const Color(0xDD111111));
    // Eye holes
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x - 3.5, eyeY), width: 5, height: 4),
      Paint()..color = const Color(0xFF222222),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x + 3.5, eyeY), width: 5, height: 4),
      Paint()..color = const Color(0xFF222222),
    );
  }

  void _drawMonocle(Canvas canvas, double x, double eyeY) {
    // Chain
    canvas.drawLine(
      Offset(x + 3.5, eyeY + 3),
      Offset(x + 6, eyeY + 10),
      Paint()
        ..color = const Color(0x99FFD700)
        ..strokeWidth = 0.6,
    );
    // Rim
    canvas.drawCircle(
      Offset(x + 3.5, eyeY),
      4,
      Paint()
        ..color = const Color(0xCCFFD700)
        ..strokeWidth = 1
        ..style = ui.PaintingStyle.stroke,
    );
    // Lens glare
    canvas.drawCircle(
      Offset(x + 2.5, eyeY - 1),
      1,
      Paint()..color = const Color(0x44FFFFFF),
    );
  }

  void _drawScar(Canvas canvas, double x, double eyeY) {
    final scarPaint = Paint()
      ..color = const Color(0xCCCC4444)
      ..strokeWidth = 1.5
      ..strokeCap = ui.StrokeCap.round;
    // Diagonal scar over left eye
    canvas.drawLine(Offset(x - 6, eyeY - 5), Offset(x - 1, eyeY + 5), scarPaint);
    // Cross marks
    for (final dy in [-2.0, 1.0, 4.0]) {
      final cx = x - 3.5 + dy * 0.5;
      canvas.drawLine(
        Offset(cx - 1.2, eyeY + dy - 0.5),
        Offset(cx + 1.2, eyeY + dy + 0.5),
        Paint()
          ..color = const Color(0x88CC4444)
          ..strokeWidth = 0.8,
      );
    }
  }

  void _drawShades(Canvas canvas, double x, double eyeY, double bodyW) {
    // Bridge
    canvas.drawLine(
      Offset(x - 3, eyeY - 1), Offset(x + 3, eyeY - 1),
      Paint()
        ..color = const Color(0xCC111111)
        ..strokeWidth = 1,
    );
    // Left lens
    final ll = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(x - 4, eyeY), width: 8, height: 5.5),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(ll, Paint()..color = const Color(0xEE111111));
    canvas.drawRRect(ll, Paint()
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = 0.5
      ..style = ui.PaintingStyle.stroke);
    // Right lens
    final rl = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(x + 4, eyeY), width: 8, height: 5.5),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(rl, Paint()..color = const Color(0xEE111111));
    canvas.drawRRect(rl, Paint()
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = 0.5
      ..style = ui.PaintingStyle.stroke);
    // Glare
    canvas.drawLine(
      Offset(x - 6, eyeY - 1.5), Offset(x - 2, eyeY - 1.5),
      Paint()..color = const Color(0x33FFFFFF)..strokeWidth = 0.7,
    );
  }

  @override
  bool shouldRepaint(covariant PlayerScenePainter old) =>
      old.glowT != glowT ||
      old.leftColor != leftColor ||
      old.rightColor != rightColor ||
      old.headDecoration != headDecoration ||
      old.faceDecoration != faceDecoration ||
      old.showScene != showScene;
}
