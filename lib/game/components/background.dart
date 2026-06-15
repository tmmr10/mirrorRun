import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import '../game_state.dart';
import '../mirror_run_game.dart';
import '../world/biome.dart';

class Background extends PositionComponent with HasGameReference<MirrorRunGame> {
  static const double vw = 440;
  double get vh => MirrorRunGame.vh;
  static const double mid = 220;
  double get groundY => MirrorRunGame.groundY;

  final List<_Deco> _decos = [];
  final _rng = Random();
  double _decoTimer = 0;
  int _frame = 0;

  // Reusable paints (avoid per-frame allocation in render()).
  final Paint _fillPaint = Paint();
  final Paint _blurPaint = Paint();
  final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;
  final Paint _shaderPaint = Paint();

  // Biome transition wipe effect
  double _transitionTimer = 0;
  Color _transitionColorL = const Color(0x00000000);
  Color _transitionColorR = const Color(0x00000000);
  static const double _transitionDuration = 0.5;

  // Ambient biome particles
  final List<_AmbientParticle> _ambientParticles = [];
  double _ambientSpawnTimer = 0;
  static const int _maxAmbientParticles = 15;

  Background() : super(priority: -100);

  void startTransition(Color leftColor, Color rightColor) {
    _transitionTimer = _transitionDuration;
    _transitionColorL = leftColor;
    _transitionColorR = rightColor;
  }

  void clearAmbientParticles() {
    _ambientParticles.clear();
    _ambientSpawnTimer = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.playState == PlayState.menu) return;

    _frame = (_frame + 1) % 100000;

    // Transition wipe decay
    if (_transitionTimer > 0) {
      _transitionTimer = (_transitionTimer - dt).clamp(0.0, double.infinity);
    }

    for (final d in _decos) {
      d.x -= game.speed * 0.18 * 60 * dt;
    }
    _decos.removeWhere((d) => d.x < -50);

    _decoTimer -= dt;
    if (_decoTimer <= 0) {
      _spawnDeco();
      _decoTimer = 70 / 60;
    }

    // Update ambient particles
    _updateAmbientParticles(dt);
  }

  void spawnInitialDecos() {
    _decos.clear();
    for (int i = 0; i < 6; i++) {
      _spawnDeco(atX: i * 120.0);
    }
  }

  void _spawnDeco({double? atX}) {
    final biome = game.currentBiome;
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
    final biome = game.currentBiome;
    _drawSky(canvas, biome);
    _drawAmbientParticles(canvas);
    _drawDecos(canvas, biome);
    _drawGround(canvas, biome);
    if (_transitionTimer > 0) _drawTransitionWipe(canvas);
  }

  void _drawSky(Canvas canvas, BiomeData biome) {
    final gl = _gradient(0, 0, 0, vh, biome.skyL);
    _shaderPaint.shader = gl;
    canvas.drawRect(Rect.fromLTWH(0, 0, mid, vh), _shaderPaint);
    final gr = _gradient(0, 0, 0, vh, biome.skyR);
    _shaderPaint.shader = gr;
    canvas.drawRect(Rect.fromLTWH(mid, 0, mid, vh), _shaderPaint);

    if (biome.type == BiomeType.space || biome.type == BiomeType.neon || biome.type == BiomeType.void_ || biome.type == BiomeType.storm) {
      _fillPaint.color = const Color(0xCCFFFFFF);
      for (int i = 0; i < 8; i++) {
        final sx = (_frame * 0.15 + i * 137) % vw;
        final sy = (i * 97 + 31) % (groundY - 40);
        canvas.drawCircle(Offset(sx, sy), 0.9, _fillPaint);
      }
    }
  }

  void _drawDecos(Canvas canvas, BiomeData biome) {
    for (final d in _decos) {
      switch (d.biomeType) {
        case BiomeType.forest:
          final trunkCol = d.side == 'left' ? const Color(0xFF1d501d) : const Color(0xFF1d1d50);
          final crownCol = d.side == 'left' ? const Color(0xFF226022) : const Color(0xFF222260);
          _fillPaint.color = trunkCol;
          canvas.drawRect(Rect.fromLTWH(d.x - d.w / 2, groundY - d.h, d.w, d.h), _fillPaint);
          _fillPaint.color = crownCol;
          canvas.drawCircle(Offset(d.x, groundY - d.h), d.w * 1.5, _fillPaint);
        case BiomeType.city:
          final bldgCol = d.side == 'left' ? const Color(0xFF222244) : const Color(0xFF442222);
          _fillPaint.color = bldgCol;
          canvas.drawRect(Rect.fromLTWH(d.x - d.w, groundY - d.h, d.w * 2, d.h), _fillPaint);
          _fillPaint.color = (d.side == 'left' ? const Color(0x40B4C8FF) : const Color(0x40FFC8B4));
          int winCol = 0;
          for (double wy = groundY - d.h + 6; wy < groundY - 8; wy += 13) {
            int winRow = 0;
            for (double wx = d.x - d.w + 4; wx < d.x + d.w - 4; wx += 9) {
              if ((winRow + winCol) % 3 != 0) canvas.drawRect(Rect.fromLTWH(wx, wy, 5, 7), _fillPaint);
              winRow++;
            }
            winCol++;
          }
          _strokePaint
            ..color = bldgCol
            ..strokeWidth = 2;
          canvas.drawLine(Offset(d.x, groundY - d.h), Offset(d.x, groundY - d.h - 18), _strokePaint);
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
          _fillPaint.color = crystalCol;
          canvas.drawPath(path, _fillPaint);
          // Smaller shard offset
          final path2 = Path()
            ..moveTo(d.x + d.w * 0.4, groundY - d.h * 0.6)
            ..lineTo(d.x + d.w * 0.1, groundY)
            ..lineTo(d.x + d.w * 0.8, groundY)
            ..close();
          canvas.drawPath(path2, _fillPaint);
          // Shine highlight
          _blurPaint
            ..color = shineCol
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
          canvas.drawCircle(Offset(d.x, groundY - d.h * 0.7), 2, _blurPaint);
        case BiomeType.volcano:
          final rockCol = d.side == 'left' ? const Color(0xFF3a1808) : const Color(0xFF381010);
          final path = Path()
            ..moveTo(d.x - d.w, groundY)..lineTo(d.x - d.w * 0.3, groundY - d.h)
            ..lineTo(d.x + d.w * 0.3, groundY - d.h * 0.7)..lineTo(d.x + d.w, groundY)..close();
          _fillPaint.color = rockCol;
          canvas.drawPath(path, _fillPaint);
          _fillPaint.color = const Color(0x30ff4400);
          canvas.drawCircle(Offset(d.x, groundY - 4), d.w * 0.8, _fillPaint);
        case BiomeType.desert:
          // Sand dunes / small pyramids
          final sandCol = d.side == 'left' ? const Color(0xFF3a2a10) : const Color(0xFF382810);
          final highlightCol = d.side == 'left' ? const Color(0x30CC9933) : const Color(0x30BB8822);
          // Dune shape
          final path = Path()
            ..moveTo(d.x - d.w * 1.2, groundY)
            ..quadraticBezierTo(d.x, groundY - d.h * 0.7, d.x + d.w * 1.2, groundY)
            ..close();
          _fillPaint.color = sandCol;
          canvas.drawPath(path, _fillPaint);
          // Small pyramid accent
          final pyPath = Path()
            ..moveTo(d.x + d.w * 0.3, groundY - d.h * 0.4)
            ..lineTo(d.x, groundY)
            ..lineTo(d.x + d.w * 0.6, groundY)
            ..close();
          _fillPaint.color = highlightCol;
          canvas.drawPath(pyPath, _fillPaint);
        case BiomeType.ocean:
          final seaCol = d.side == 'left' ? const Color(0xFF0a4060) : const Color(0xFF083050);
          _fillPaint.color = seaCol;
          canvas.drawRect(Rect.fromLTWH(d.x - d.w / 4, groundY - d.h, d.w / 2, d.h), _fillPaint);
          _fillPaint.color = const Color(0x3020a0dd);
          canvas.drawCircle(Offset(d.x + d.w * 0.4, groundY - d.h - 8), 3, _fillPaint);
          _fillPaint.color = const Color(0x2020a0dd);
          canvas.drawCircle(Offset(d.x - d.w * 0.2, groundY - d.h - 16), 2, _fillPaint);
        case BiomeType.ruins:
          // Broken arches / vine fragments
          final stoneCol = d.side == 'left' ? const Color(0xFF2a3a2a) : const Color(0xFF2a2a20);
          final mossCol = d.side == 'left' ? const Color(0x405A8A5A) : const Color(0x406A7A5A);
          // Stone pillar fragment
          _fillPaint.color = stoneCol;
          canvas.drawRect(Rect.fromLTWH(d.x - d.w * 0.4, groundY - d.h, d.w * 0.8, d.h), _fillPaint);
          // Broken top (jagged)
          final topPath = Path()
            ..moveTo(d.x - d.w * 0.4, groundY - d.h)
            ..lineTo(d.x - d.w * 0.2, groundY - d.h - 6)
            ..lineTo(d.x + d.w * 0.1, groundY - d.h - 2)
            ..lineTo(d.x + d.w * 0.4, groundY - d.h - 8)
            ..lineTo(d.x + d.w * 0.4, groundY - d.h)
            ..close();
          canvas.drawPath(topPath, _fillPaint);
          // Moss patches
          _fillPaint.color = mossCol;
          canvas.drawCircle(Offset(d.x - d.w * 0.1, groundY - d.h * 0.4), 3, _fillPaint);
          canvas.drawCircle(Offset(d.x + d.w * 0.2, groundY - d.h * 0.7), 2.5, _fillPaint);
        case BiomeType.space:
          final planetCol = d.side == 'left' ? const Color(0x805078FF) : const Color(0x80FF5078);
          _fillPaint.color = planetCol;
          canvas.drawCircle(Offset(d.x, groundY - d.h), d.w * 0.9, _fillPaint);
          final ringCol = d.side == 'left' ? const Color(0x405078FF) : const Color(0x40FF5078);
          _strokePaint
            ..color = ringCol
            ..strokeWidth = 3;
          canvas.drawOval(
            Rect.fromCenter(center: Offset(d.x, groundY - d.h), width: d.w * 3.8, height: d.w),
            _strokePaint,
          );
        case BiomeType.storm:
          // Cloud streaks / distant lightning
          final cloudCol = d.side == 'left' ? const Color(0x307744BB) : const Color(0x309944AA);
          final boltCol = d.side == 'left' ? const Color(0x40EEDD44) : const Color(0x40FFEE66);
          // Cloud streak
          _blurPaint
            ..color = cloudCol
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
          canvas.drawOval(
            Rect.fromLTWH(d.x - d.w * 1.5, groundY - d.h, d.w * 3, d.h * 0.3),
            _blurPaint,
          );
          // Distant lightning bolt
          final lPath = Path()
            ..moveTo(d.x + d.w * 0.2, groundY - d.h * 0.8)
            ..lineTo(d.x - d.w * 0.1, groundY - d.h * 0.5)
            ..lineTo(d.x + d.w * 0.3, groundY - d.h * 0.5)
            ..lineTo(d.x, groundY - d.h * 0.2);
          _strokePaint
            ..color = boltCol
            ..strokeWidth = 1.5;
          canvas.drawPath(lPath, _strokePaint);
        case BiomeType.neon:
          final neonCol = d.side == 'left' ? const Color(0x608800ff) : const Color(0x60ff0088);
          _fillPaint.color = neonCol;
          canvas.drawRect(Rect.fromLTWH(d.x - 1.5, groundY - d.h, 3, d.h), _fillPaint);
          _blurPaint
            ..color = neonCol
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
          canvas.drawCircle(Offset(d.x, groundY - d.h), 4, _blurPaint);
        case BiomeType.void_:
          _fillPaint.color = const Color(0x15ffffff);
          canvas.drawRect(Rect.fromLTWH(d.x - 0.5, groundY - d.h, 1, d.h), _fillPaint);
      }
    }
  }

  void _drawGround(Canvas canvas, BiomeData biome) {
    if (game.playState == PlayState.dead) {
      final grad = _gradient(0, 0, vw, 0, [biome.groundL, biome.groundR]);
      _shaderPaint.shader = grad;
      canvas.drawRect(Rect.fromLTWH(0, groundY, vw, vh - groundY), _shaderPaint);
      _strokePaint
        ..color = biome.lineL
        ..strokeWidth = 2;
      canvas.drawLine(Offset(0, groundY), Offset(vw, groundY), _strokePaint);
    } else {
      _fillPaint.color = biome.groundL;
      canvas.drawRect(Rect.fromLTWH(0, groundY, mid, vh - groundY), _fillPaint);
      _fillPaint.color = biome.groundR;
      canvas.drawRect(Rect.fromLTWH(mid, groundY, mid, vh - groundY), _fillPaint);
      _strokePaint
        ..color = biome.lineL
        ..strokeWidth = 2;
      canvas.drawLine(Offset(0, groundY), Offset(mid, groundY), _strokePaint);
      _strokePaint.color = biome.lineR;
      canvas.drawLine(Offset(mid, groundY), Offset(vw, groundY), _strokePaint);
    }
  }

  void _drawTransitionWipe(Canvas canvas) {
    final t = _transitionTimer / _transitionDuration; // 1→0
    final wipeProgress = 1.0 - t; // 0→1
    final alpha = (t * 0.6).clamp(0.0, 0.6);

    // Left side: wipe from left edge toward mirror center
    final leftWidth = mid * wipeProgress;
    _shaderPaint.shader = Gradient.linear(
      Offset(mid - leftWidth, 0),
      Offset(mid, 0),
      [_transitionColorL.withValues(alpha: 0), _transitionColorL.withValues(alpha: alpha)],
    );
    canvas.drawRect(Rect.fromLTWH(mid - leftWidth, 0, leftWidth, vh), _shaderPaint);

    // Right side: wipe from right edge toward mirror center
    final rightWidth = mid * wipeProgress;
    _shaderPaint.shader = Gradient.linear(
      Offset(mid, 0),
      Offset(mid + rightWidth, 0),
      [_transitionColorR.withValues(alpha: alpha), _transitionColorR.withValues(alpha: 0)],
    );
    canvas.drawRect(Rect.fromLTWH(mid, 0, rightWidth, vh), _shaderPaint);

    // Bright flash line at center
    if (t > 0.3) {
      final flashAlpha = ((t - 0.3) / 0.7 * 0.5).clamp(0.0, 0.5);
      _fillPaint.color = Color.fromARGB((flashAlpha * 255).toInt(), 255, 255, 255);
      canvas.drawRect(Rect.fromLTWH(mid - 3, 0, 6, vh), _fillPaint);
    }
  }

  // --- Ambient Biome Particles ---

  void _updateAmbientParticles(double dt) {
    // Update existing
    for (final p in _ambientParticles) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.life -= dt;
    }
    _ambientParticles.removeWhere((p) => p.life <= 0 || p.y > vh + 10 || p.y < -10 || p.x < -10 || p.x > vw + 10);

    // Spawn new
    _ambientSpawnTimer -= dt;
    if (_ambientSpawnTimer <= 0 && _ambientParticles.length < _maxAmbientParticles) {
      final biome = game.currentBiome;
      _spawnAmbientParticle(biome.type);
      _ambientSpawnTimer = 0.3 + _rng.nextDouble() * 0.4;
    }
  }

  void _spawnAmbientParticle(BiomeType type) {
    switch (type) {
      case BiomeType.forest:
        _ambientParticles.add(_AmbientParticle(
          x: _rng.nextDouble() * vw, y: -5,
          vx: -10 + _rng.nextDouble() * 20, vy: 20 + _rng.nextDouble() * 30,
          life: 3 + _rng.nextDouble() * 2, maxLife: 5,
          size: 2 + _rng.nextDouble() * 2,
          color: Color.fromARGB(40 + _rng.nextInt(30), 30, 120, 30),
        ));
      case BiomeType.city:
        _ambientParticles.add(_AmbientParticle(
          x: _rng.nextDouble() * vw, y: _rng.nextDouble() * groundY,
          vx: 0, vy: 0,
          life: 0.5 + _rng.nextDouble() * 1.5, maxLife: 2,
          size: 1 + _rng.nextDouble(),
          color: Color.fromARGB(30 + _rng.nextInt(30), 255, 230, 180),
        ));
      case BiomeType.crystal:
        _ambientParticles.add(_AmbientParticle(
          x: _rng.nextDouble() * vw, y: -5,
          vx: -15 + _rng.nextDouble() * 10, vy: 15 + _rng.nextDouble() * 25,
          life: 3 + _rng.nextDouble() * 2, maxLife: 5,
          size: 1.5 + _rng.nextDouble() * 1.5,
          color: Color.fromARGB(40 + _rng.nextInt(50), 100, 220, 255),
        ));
      case BiomeType.volcano:
        _ambientParticles.add(_AmbientParticle(
          x: _rng.nextDouble() * vw, y: groundY,
          vx: -5 + _rng.nextDouble() * 10, vy: -(30 + _rng.nextDouble() * 50),
          life: 2 + _rng.nextDouble() * 2, maxLife: 4,
          size: 1.5 + _rng.nextDouble() * 1.5,
          color: Color.fromARGB(50 + _rng.nextInt(50), 255, 100 + _rng.nextInt(60), 0),
        ));
      case BiomeType.desert:
        _ambientParticles.add(_AmbientParticle(
          x: -5, y: _rng.nextDouble() * groundY,
          vx: 40 + _rng.nextDouble() * 40, vy: 5 + _rng.nextDouble() * 10,
          life: 2 + _rng.nextDouble() * 2, maxLife: 4,
          size: 1 + _rng.nextDouble(),
          color: Color.fromARGB(30 + _rng.nextInt(30), 200, 170, 80),
        ));
      case BiomeType.ocean:
        _ambientParticles.add(_AmbientParticle(
          x: _rng.nextDouble() * vw, y: groundY,
          vx: -3 + _rng.nextDouble() * 6, vy: -(15 + _rng.nextDouble() * 20),
          life: 3 + _rng.nextDouble() * 2, maxLife: 5,
          size: 1.5 + _rng.nextDouble() * 2,
          color: Color.fromARGB(30 + _rng.nextInt(30), 80, 180, 255),
        ));
      case BiomeType.ruins:
        _ambientParticles.add(_AmbientParticle(
          x: _rng.nextDouble() * vw, y: _rng.nextDouble() * groundY,
          vx: -5 + _rng.nextDouble() * 10, vy: -5 + _rng.nextDouble() * 10,
          life: 3 + _rng.nextDouble() * 2, maxLife: 5,
          size: 1 + _rng.nextDouble(),
          color: Color.fromARGB(25 + _rng.nextInt(20), 100, 140, 100),
        ));
      case BiomeType.space:
        // Shooting stars — rarer, faster
        if (_rng.nextDouble() > 0.6) return;
        _ambientParticles.add(_AmbientParticle(
          x: _rng.nextDouble() * vw, y: -5,
          vx: 60 + _rng.nextDouble() * 80, vy: 80 + _rng.nextDouble() * 60,
          life: 0.4 + _rng.nextDouble() * 0.4, maxLife: 0.8,
          size: 1 + _rng.nextDouble(),
          color: Color.fromARGB(60 + _rng.nextInt(70), 255, 255, 255),
        ));
      case BiomeType.storm:
        _ambientParticles.add(_AmbientParticle(
          x: _rng.nextDouble() * vw, y: -5,
          vx: 20 + _rng.nextDouble() * 15, vy: 80 + _rng.nextDouble() * 60,
          life: 0.8 + _rng.nextDouble() * 0.6, maxLife: 1.4,
          size: 1 + _rng.nextDouble() * 0.5,
          color: Color.fromARGB(40 + _rng.nextInt(40), 180, 140, 220),
        ));
      case BiomeType.neon:
        _ambientParticles.add(_AmbientParticle(
          x: _rng.nextDouble() * vw, y: -5,
          vx: 0, vy: 60 + _rng.nextDouble() * 80,
          life: 0.8 + _rng.nextDouble() * 0.8, maxLife: 1.6,
          size: 1 + _rng.nextDouble(),
          color: _rng.nextBool()
              ? Color.fromARGB(50 + _rng.nextInt(50), 255, 0, 170)
              : Color.fromARGB(50 + _rng.nextInt(50), 0, 255, 170),
        ));
      case BiomeType.void_:
        // Static flickers — brief, scattered
        _ambientParticles.add(_AmbientParticle(
          x: _rng.nextDouble() * vw, y: _rng.nextDouble() * vh,
          vx: 0, vy: 0,
          life: 0.1 + _rng.nextDouble() * 0.3, maxLife: 0.4,
          size: 1 + _rng.nextDouble() * 2,
          color: Color.fromARGB(10 + _rng.nextInt(25), 255, 255, 255),
        ));
    }
  }

  void _drawAmbientParticles(Canvas canvas) {
    for (final p in _ambientParticles) {
      final lifeAlpha = (p.life / p.maxLife).clamp(0.0, 1.0);
      _fillPaint.color = p.color.withValues(alpha: p.color.a * lifeAlpha);
      canvas.drawCircle(Offset(p.x, p.y), p.size, _fillPaint);
    }
  }

  Shader _gradient(double x0, double y0, double x1, double y1, List<Color> colors) {
    // Guard against zero-length gradient vector
    if (x0 == x1 && y0 == y1) {
      return Gradient.linear(Offset(x0, y0), Offset(x0, y0 + 1), colors);
    }
    return Gradient.linear(Offset(x0, y0), Offset(x1, y1), colors);
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

class _AmbientParticle {
  double x, y, vx, vy, life;
  final double maxLife, size;
  final Color color;

  _AmbientParticle({
    required this.x, required this.y,
    required this.vx, required this.vy,
    required this.life, required this.maxLife,
    required this.size, required this.color,
  });
}
