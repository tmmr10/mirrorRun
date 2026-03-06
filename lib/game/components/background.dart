import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import '../game_state.dart';
import '../mirror_run_game.dart';
import '../world/biome.dart';

class Background extends PositionComponent with HasGameReference<MirrorRunGame> {
  static const double vw = 440;
  static const double vh = 640;
  static const double mid = 220;
  static const double groundY = 540;

  static const List<double> mirrorLanesL = [55, 120, 185];
  static const List<double> mirrorLanesR = [255, 320, 385];

  final List<_Deco> _decos = [];
  final _rng = Random();
  double _decoTimer = 0;
  int _frame = 0;

  Background() : super(size: Vector2(vw, vh), priority: -100);

  @override
  void update(double dt) {
    super.update(dt);
    if (game.playState == PlayState.menu) return;

    _frame++;

    for (final d in _decos) {
      d.x -= game.speed * 0.18 * 60 * dt;
    }
    _decos.removeWhere((d) => d.x < -50);

    _decoTimer -= dt;
    if (_decoTimer <= 0) {
      _spawnDeco();
      _decoTimer = 70 / 60;
    }
  }

  void spawnInitialDecos() {
    for (int i = 0; i < 6; i++) {
      _spawnDeco(atX: vw + i * 120 - vw);
    }
  }

  void _spawnDeco({double? atX}) {
    final biome = BiomeManager.getBiome(game.score);
    for (int s = 0; s < 2; s++) {
      final side = s == 0 ? 'left' : 'right';
      // For periodic spawns: appear at right edge of each half and scroll in.
      // For initial spawns (atX given): use atX directly.
      final double x;
      if (atX != null) {
        x = atX;
      } else {
        x = side == 'left'
            ? mid + _rng.nextDouble() * 20
            : vw + _rng.nextDouble() * 20;
      }
      _decos.add(_Deco(
        x: x,
        h: 35 + _rng.nextDouble() * 55,
        w: 7 + _rng.nextDouble() * 9,
        side: side,
        biomeType: biome.type,
      ));
    }
  }

  @override
  void render(Canvas canvas) {
    final biome = BiomeManager.getBiome(game.score);
    _drawSky(canvas, biome);
    _drawDecos(canvas, biome);
    _drawGround(canvas, biome);
    _drawLaneGuides(canvas);
  }

  void _drawSky(Canvas canvas, BiomeData biome) {
    final gl = _gradient(0, 0, 0, vh, biome.skyL);
    canvas.drawRect(Rect.fromLTWH(0, 0, mid, vh), Paint()..shader = gl);
    final gr = _gradient(0, 0, 0, vh, biome.skyR);
    canvas.drawRect(Rect.fromLTWH(mid, 0, mid, vh), Paint()..shader = gr);

    if (biome.type == BiomeType.space || biome.type == BiomeType.neon || biome.type == BiomeType.void_ || biome.type == BiomeType.storm) {
      final starPaint = Paint()..color = const Color(0xCCFFFFFF);
      for (int i = 0; i < 8; i++) {
        final sx = (_frame * 0.15 + i * 137) % vw;
        final sy = (i * 97 + 31) % (groundY - 40);
        canvas.drawCircle(Offset(sx, sy), 0.9, starPaint);
      }
    }
  }

  void _drawDecos(Canvas canvas, BiomeData biome) {
    for (final d in _decos) {
      switch (d.biomeType) {
        case BiomeType.forest:
          final trunkCol = d.side == 'left' ? const Color(0xFF1d501d) : const Color(0xFF1d1d50);
          final crownCol = d.side == 'left' ? const Color(0xFF226022) : const Color(0xFF222260);
          canvas.drawRect(Rect.fromLTWH(d.x - d.w / 2, groundY - d.h, d.w, d.h), Paint()..color = trunkCol);
          canvas.drawCircle(Offset(d.x, groundY - d.h), d.w * 1.5, Paint()..color = crownCol);
        case BiomeType.city:
          final bldgCol = d.side == 'left' ? const Color(0xFF222244) : const Color(0xFF442222);
          canvas.drawRect(Rect.fromLTWH(d.x - d.w, groundY - d.h, d.w * 2, d.h), Paint()..color = bldgCol);
          final winPaint = Paint()..color = (d.side == 'left' ? const Color(0x40B4C8FF) : const Color(0x40FFC8B4));
          int winCol = 0;
          for (double wy = groundY - d.h + 6; wy < groundY - 8; wy += 13) {
            int winRow = 0;
            for (double wx = d.x - d.w + 4; wx < d.x + d.w - 4; wx += 9) {
              if ((winRow + winCol) % 3 != 0) canvas.drawRect(Rect.fromLTWH(wx, wy, 5, 7), winPaint);
              winRow++;
            }
            winCol++;
          }
          canvas.drawLine(Offset(d.x, groundY - d.h), Offset(d.x, groundY - d.h - 18), Paint()..color = bldgCol..strokeWidth = 2);
        case BiomeType.crystal:
          // Crystal shards / icicle shapes
          final crystalCol = d.side == 'left' ? const Color(0xFF205880) : const Color(0xFF1A6888);
          final shineCol = d.side == 'left' ? const Color(0x4040CCEE) : const Color(0x4030BBDD);
          // Main shard
          final path = Path()
            ..moveTo(d.x, groundY - d.h)
            ..lineTo(d.x - d.w * 0.6, groundY)
            ..lineTo(d.x + d.w * 0.6, groundY)
            ..close();
          canvas.drawPath(path, Paint()..color = crystalCol);
          // Smaller shard offset
          final path2 = Path()
            ..moveTo(d.x + d.w * 0.4, groundY - d.h * 0.6)
            ..lineTo(d.x + d.w * 0.1, groundY)
            ..lineTo(d.x + d.w * 0.8, groundY)
            ..close();
          canvas.drawPath(path2, Paint()..color = crystalCol);
          // Shine highlight
          canvas.drawCircle(Offset(d.x, groundY - d.h * 0.7), 2, Paint()..color = shineCol..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
        case BiomeType.volcano:
          final rockCol = d.side == 'left' ? const Color(0xFF3a1808) : const Color(0xFF381010);
          final path = Path()
            ..moveTo(d.x - d.w, groundY)..lineTo(d.x - d.w * 0.3, groundY - d.h)
            ..lineTo(d.x + d.w * 0.3, groundY - d.h * 0.7)..lineTo(d.x + d.w, groundY)..close();
          canvas.drawPath(path, Paint()..color = rockCol);
          canvas.drawCircle(Offset(d.x, groundY - 4), d.w * 0.8, Paint()..color = const Color(0x30ff4400));
        case BiomeType.desert:
          // Sand dunes / small pyramids
          final sandCol = d.side == 'left' ? const Color(0xFF3a2a10) : const Color(0xFF382810);
          final highlightCol = d.side == 'left' ? const Color(0x30CC9933) : const Color(0x30BB8822);
          // Dune shape
          final path = Path()
            ..moveTo(d.x - d.w * 1.2, groundY)
            ..quadraticBezierTo(d.x, groundY - d.h * 0.7, d.x + d.w * 1.2, groundY)
            ..close();
          canvas.drawPath(path, Paint()..color = sandCol);
          // Small pyramid accent
          final pyPath = Path()
            ..moveTo(d.x + d.w * 0.3, groundY - d.h * 0.4)
            ..lineTo(d.x, groundY)
            ..lineTo(d.x + d.w * 0.6, groundY)
            ..close();
          canvas.drawPath(pyPath, Paint()..color = highlightCol);
        case BiomeType.ocean:
          final seaCol = d.side == 'left' ? const Color(0xFF0a4060) : const Color(0xFF083050);
          canvas.drawRect(Rect.fromLTWH(d.x - d.w / 4, groundY - d.h, d.w / 2, d.h), Paint()..color = seaCol);
          canvas.drawCircle(Offset(d.x + d.w * 0.4, groundY - d.h - 8), 3, Paint()..color = const Color(0x3020a0dd));
          canvas.drawCircle(Offset(d.x - d.w * 0.2, groundY - d.h - 16), 2, Paint()..color = const Color(0x2020a0dd));
        case BiomeType.ruins:
          // Broken arches / vine fragments
          final stoneCol = d.side == 'left' ? const Color(0xFF2a3a2a) : const Color(0xFF2a2a20);
          final mossCol = d.side == 'left' ? const Color(0x405A8A5A) : const Color(0x406A7A5A);
          // Stone pillar fragment
          canvas.drawRect(Rect.fromLTWH(d.x - d.w * 0.4, groundY - d.h, d.w * 0.8, d.h), Paint()..color = stoneCol);
          // Broken top (jagged)
          final topPath = Path()
            ..moveTo(d.x - d.w * 0.4, groundY - d.h)
            ..lineTo(d.x - d.w * 0.2, groundY - d.h - 6)
            ..lineTo(d.x + d.w * 0.1, groundY - d.h - 2)
            ..lineTo(d.x + d.w * 0.4, groundY - d.h - 8)
            ..lineTo(d.x + d.w * 0.4, groundY - d.h)
            ..close();
          canvas.drawPath(topPath, Paint()..color = stoneCol);
          // Moss patches
          canvas.drawCircle(Offset(d.x - d.w * 0.1, groundY - d.h * 0.4), 3, Paint()..color = mossCol);
          canvas.drawCircle(Offset(d.x + d.w * 0.2, groundY - d.h * 0.7), 2.5, Paint()..color = mossCol);
        case BiomeType.space:
          final planetCol = d.side == 'left' ? const Color(0x805078FF) : const Color(0x80FF5078);
          canvas.drawCircle(Offset(d.x, groundY - d.h), d.w * 0.9, Paint()..color = planetCol);
          final ringCol = d.side == 'left' ? const Color(0x405078FF) : const Color(0x40FF5078);
          canvas.drawOval(
            Rect.fromCenter(center: Offset(d.x, groundY - d.h), width: d.w * 3.8, height: d.w),
            Paint()..color = ringCol..style = PaintingStyle.stroke..strokeWidth = 3,
          );
        case BiomeType.storm:
          // Cloud streaks / distant lightning
          final cloudCol = d.side == 'left' ? const Color(0x307744BB) : const Color(0x309944AA);
          final boltCol = d.side == 'left' ? const Color(0x40EEDD44) : const Color(0x40FFEE66);
          // Cloud streak
          canvas.drawOval(
            Rect.fromLTWH(d.x - d.w * 1.5, groundY - d.h, d.w * 3, d.h * 0.3),
            Paint()..color = cloudCol..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
          );
          // Distant lightning bolt
          final lPath = Path()
            ..moveTo(d.x + d.w * 0.2, groundY - d.h * 0.8)
            ..lineTo(d.x - d.w * 0.1, groundY - d.h * 0.5)
            ..lineTo(d.x + d.w * 0.3, groundY - d.h * 0.5)
            ..lineTo(d.x, groundY - d.h * 0.2);
          canvas.drawPath(lPath, Paint()..color = boltCol..strokeWidth = 1.5..style = PaintingStyle.stroke);
        case BiomeType.neon:
          final neonCol = d.side == 'left' ? const Color(0x608800ff) : const Color(0x60ff0088);
          canvas.drawRect(Rect.fromLTWH(d.x - 1.5, groundY - d.h, 3, d.h), Paint()..color = neonCol);
          canvas.drawCircle(Offset(d.x, groundY - d.h), 4, Paint()..color = neonCol..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
        case BiomeType.void_:
          canvas.drawRect(Rect.fromLTWH(d.x - 0.5, groundY - d.h, 1, d.h), Paint()..color = const Color(0x15ffffff));
      }
    }
  }

  void _drawGround(Canvas canvas, BiomeData biome) {
    if (game.playState == PlayState.dead) {
      final grad = _gradient(0, 0, vw, 0, [biome.groundL, biome.groundR]);
      canvas.drawRect(Rect.fromLTWH(0, groundY, vw, vh - groundY), Paint()..shader = grad);
      canvas.drawLine(Offset(0, groundY), Offset(vw, groundY), Paint()..color = biome.lineL..strokeWidth = 2);
    } else {
      canvas.drawRect(Rect.fromLTWH(0, groundY, mid, vh - groundY), Paint()..color = biome.groundL);
      canvas.drawRect(Rect.fromLTWH(mid, groundY, mid, vh - groundY), Paint()..color = biome.groundR);
      canvas.drawLine(Offset(0, groundY), Offset(mid, groundY), Paint()..color = biome.lineL..strokeWidth = 2);
      canvas.drawLine(Offset(mid, groundY), Offset(vw, groundY), Paint()..color = biome.lineR..strokeWidth = 2);
    }
  }

  void _drawLaneGuides(Canvas canvas) {
    final guidePaint = Paint()..color = const Color(0x0AFFFFFF)..strokeWidth = 1;
    for (final lx in [...mirrorLanesL, ...mirrorLanesR]) {
      canvas.drawLine(Offset(lx, 0), Offset(lx, vh), guidePaint);
    }
  }

  Shader _gradient(double x0, double y0, double x1, double y1, List<Color> colors) {
    return Gradient.linear(
      Offset(x0, y0),
      Offset(x1 == 0 ? 1 : x1, y1 == 0 ? 1 : y1),
      colors,
    );
  }
}

class _Deco {
  double x;
  final double h;
  final double w;
  final String side;
  final BiomeType biomeType;

  _Deco({
    required this.x,
    required this.h,
    required this.w,
    required this.side,
    required this.biomeType,
  });
}
