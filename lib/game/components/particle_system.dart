import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import '../mirror_run_game.dart';

class ParticleSystem extends PositionComponent with HasGameReference<MirrorRunGame> {
  final List<_Particle> _particles = [];
  final List<_Shard> _shards = [];
  final _rng = Random();

  // Reusable paints (avoid per-element allocation in render()).
  static final Paint _fillPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _shardStrokePaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  ParticleSystem() : super(priority: 80);

  int get shardCount => _shards.length;

  void burst(Vector2 pos, Color col) {
    for (int i = 0; i < 20; i++) {
      final a = _rng.nextDouble() * pi * 2;
      final spd = 2 + _rng.nextDouble() * 6;
      _particles.add(_Particle(
        x: pos.x,
        y: pos.y,
        vx: cos(a) * spd * 60,
        vy: (sin(a) * spd - 3) * 60,
        r: 2 + _rng.nextDouble() * 4,
        color: col,
      ));
    }
  }

  /// Smaller, gold-colored burst for coin pickups.
  void burstCoin(Vector2 pos) {
    for (int i = 0; i < 10; i++) {
      final a = _rng.nextDouble() * pi * 2;
      final spd = 1.5 + _rng.nextDouble() * 3;
      _particles.add(_Particle(
        x: pos.x,
        y: pos.y,
        vx: cos(a) * spd * 60,
        vy: (sin(a) * spd - 1.5) * 60,
        r: 1.5 + _rng.nextDouble() * 2,
        color: const Color(0xFFFFD700),
      ));
    }
  }

  void spawnShards(Vector2 center) {
    for (int i = 0; i < 25; i++) {
      _shards.add(_Shard(
        x: center.x + (_rng.nextDouble() - 0.5) * 40,
        y: _rng.nextDouble() * MirrorRunGame.vh,
        vx: (_rng.nextDouble() - 0.5) * 9 * 60,
        vy: (-2 - _rng.nextDouble() * 5) * 60,
        rot: _rng.nextDouble() * pi,
        rotV: (_rng.nextDouble() - 0.5) * 0.25 * 60,
        w: 12 + _rng.nextDouble() * 30,
        h: 4 + _rng.nextDouble() * 10,
      ));
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    for (final p in _particles) {
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vy += 0.3 * 60 * dt;
      p.life -= 0.03 * 60 * dt;
    }
    _particles.removeWhere((p) => p.life <= 0);

    for (final s in _shards) {
      s.x += s.vx * dt;
      s.y += s.vy * dt;
      s.vy += 0.2 * 60 * dt;
      s.rot += s.rotV * dt;
      s.life -= 0.016 * 60 * dt;
    }
    _shards.removeWhere((s) => s.life <= 0);
  }

  @override
  void render(Canvas canvas) {
    // Particles
    for (final p in _particles) {
      _fillPaint.color = p.color.withValues(alpha: p.life.clamp(0, 1));
      canvas.drawCircle(
        Offset(p.x, p.y),
        p.r * p.life.clamp(0, 1),
        _fillPaint,
      );
    }

    // Shards
    for (final s in _shards) {
      canvas.save();
      canvas.translate(s.x, s.y);
      canvas.rotate(s.rot);

      final life = s.life.clamp(0.0, 1.0);
      final rect = Rect.fromCenter(center: Offset.zero, width: s.w, height: s.h);

      _fillPaint.color = Color.fromARGB((life * 0.4 * 255).toInt(), 200, 180, 255);
      canvas.drawRect(rect, _fillPaint);

      _shardStrokePaint.color = Color.fromARGB((life * 255).toInt(), 255, 255, 255);
      canvas.drawRect(rect, _shardStrokePaint);

      canvas.restore();
    }
  }
}

class _Particle {
  double x, y, vx, vy, r;
  double life = 1.0;
  final Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.r,
    required this.color,
  });
}

class _Shard {
  double x, y, vx, vy, rot, rotV, w, h;
  double life = 1.0;

  _Shard({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rot,
    required this.rotV,
    required this.w,
    required this.h,
  });
}
