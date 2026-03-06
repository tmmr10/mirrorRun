import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import '../game_state.dart';
import '../mirror_run_game.dart';
import '../world/biome.dart';

class Obstacle extends PositionComponent with HasGameReference<MirrorRunGame> {
  final String side; // 'left', 'right'
  final ObstacleType type;
  final int lane;
  final double laneCenterX;
  final double w;
  final double h;

  /// Y scroll position (top to bottom).
  double scrollPos;

  /// For doubleWall/shifter: second lane info.
  final double secondLaneCenterX;
  final int secondLane;

  static const double groundY = 540;
  static const double playerH = 34;

  Obstacle({
    required this.side,
    required this.type,
    required this.lane,
    required this.laneCenterX,
    required this.scrollPos,
    required this.w,
    required this.h,
    this.secondLaneCenterX = 0,
    this.secondLane = 0,
  }) : super(anchor: Anchor.topLeft);

  @override
  void update(double dt) {
    super.update(dt);
    scrollPos += game.speed * 60 * dt;
    _updatePosition();
    if (scrollPos > 700) removeFromParent();
  }

  /// For shifter: interpolation factor 0..1 based on scroll progress.
  double get _shifterT {
    final progress = ((scrollPos + 60) / (groundY + 60)).clamp(0.0, 1.0);
    return ((progress - 0.3) / 0.4).clamp(0.0, 1.0);
  }

  double get _shifterCurrentX {
    return laneCenterX + (secondLaneCenterX - laneCenterX) * _shifterT;
  }

  void _updatePosition() {
    switch (type) {
      case ObstacleType.wall:
      case ObstacleType.spike:
        position = Vector2(laneCenterX - w / 2, scrollPos);
        size = Vector2(w, h);
      case ObstacleType.doubleWall:
        final leftX = min(laneCenterX, secondLaneCenterX);
        final rightX = max(laneCenterX, secondLaneCenterX);
        final totalW = (rightX - leftX) + w;
        position = Vector2(leftX - w / 2, scrollPos);
        size = Vector2(totalW, h);
      case ObstacleType.shifter:
        final cx = _shifterCurrentX;
        position = Vector2(cx - w / 2, scrollPos);
        size = Vector2(w, h);
    }
  }

  Rect getHitRect() {
    const sh = 7.0;
    switch (type) {
      case ObstacleType.wall:
        return Rect.fromLTWH(laneCenterX - w / 2 + sh, scrollPos, w - sh * 2, h - 4);
      case ObstacleType.spike:
        return Rect.fromLTWH(laneCenterX - w / 2 + sh, scrollPos + 5, w - sh * 2, h - 5);
      case ObstacleType.doubleWall:
        final leftX = min(laneCenterX, secondLaneCenterX);
        final rightX = max(laneCenterX, secondLaneCenterX);
        final totalW = (rightX - leftX) + w;
        return Rect.fromLTWH(leftX - w / 2 + sh, scrollPos, totalW - sh * 2, h - 4);
      case ObstacleType.shifter:
        final cx = _shifterCurrentX;
        return Rect.fromLTWH(cx - w / 2 + sh, scrollPos, w - sh * 2, h - 4);
    }
  }

  List<int> get blockedLanes {
    switch (type) {
      case ObstacleType.doubleWall:
      case ObstacleType.shifter:
        return [lane, secondLane];
      default:
        return [lane];
    }
  }

  bool isInDangerZone() {
    return scrollPos > groundY - playerH - 40 && scrollPos < groundY + 10;
  }

  @override
  void render(Canvas canvas) {
    final phantomFade = game.eventSystem.phantomFade;
    if (phantomFade >= 1.0) return;

    final biome = BiomeManager.getBiome(game.score);
    final Color col = side == 'left' ? biome.obsL : biome.obsR;
    final Color glow = side == 'left' ? biome.obsGlowL : biome.obsGlowR;

    final a = phantomFade > 0 ? (1 - phantomFade) : 1.0;
    final glowPaint = Paint()
      ..color = glow.withValues(alpha: glow.a * a)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    final fillPaint = Paint()..color = col.withValues(alpha: col.a * a);
    final detailAlpha = (0.6 * a).clamp(0.0, 1.0);

    switch (biome.type) {
      case BiomeType.forest:
        _renderForest(canvas, fillPaint, glowPaint, col, detailAlpha);
      case BiomeType.city:
        _renderCity(canvas, fillPaint, glowPaint, col, detailAlpha);
      case BiomeType.crystal:
        _renderCrystal(canvas, fillPaint, glowPaint, col, detailAlpha);
      case BiomeType.volcano:
        _renderVolcano(canvas, fillPaint, glowPaint, col, detailAlpha);
      case BiomeType.desert:
        _renderDesert(canvas, fillPaint, glowPaint, col, detailAlpha);
      case BiomeType.ocean:
        _renderOcean(canvas, fillPaint, glowPaint, col, detailAlpha);
      case BiomeType.ruins:
        _renderRuins(canvas, fillPaint, glowPaint, col, detailAlpha);
      case BiomeType.space:
        _renderSpace(canvas, fillPaint, glowPaint, col, detailAlpha);
      case BiomeType.storm:
        _renderStorm(canvas, fillPaint, glowPaint, col, detailAlpha);
      case BiomeType.neon:
        _renderNeon(canvas, fillPaint, glowPaint, col, detailAlpha);
      case BiomeType.void_:
        _renderVoid(canvas, fillPaint, glowPaint, col, detailAlpha);
    }
  }

  // ── Forest: stumps, thorns, root tangles, critters ──

  void _renderForest(Canvas canvas, Paint fill, Paint glow, Color col, double da) {
    switch (type) {
      case ObstacleType.wall:
        // Tree stump
        final cx = laneCenterX - position.x;
        final trunkW = w * 0.55;
        final trunk = Rect.fromLTWH(cx - trunkW / 2, h * 0.2, trunkW, h * 0.8);
        canvas.drawRect(trunk, glow);
        canvas.drawRect(trunk, fill);
        // Crown (bushy top)
        canvas.drawOval(Rect.fromLTWH(cx - w / 2, -2, w, h * 0.55), glow);
        canvas.drawOval(Rect.fromLTWH(cx - w / 2, -2, w, h * 0.55), fill);
        // Bark lines
        final bark = Paint()..color = const Color(0x20000000)..strokeWidth = 1;
        canvas.drawLine(Offset(cx - 2, h * 0.3), Offset(cx - 2, h * 0.9), bark);
        canvas.drawLine(Offset(cx + 2, h * 0.4), Offset(cx + 2, h * 0.85), bark);

      case ObstacleType.spike:
        // Mushroom (poisonous toadstool)
        final cx = laneCenterX - position.x;
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
        final spot = Paint()..color = Color.fromARGB((da * 160).toInt(), 255, 255, 200);
        canvas.drawCircle(Offset(cx - 4, h * 0.18), 2.5, spot);
        canvas.drawCircle(Offset(cx + 3, h * 0.25), 2, spot);
        canvas.drawCircle(Offset(cx, h * 0.12), 1.5, spot);

      case ObstacleType.doubleWall:
        // Fallen log across two lanes
        final totalW = size.x;
        final logRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(0, h * 0.2, totalW, h * 0.6), const Radius.circular(8));
        canvas.drawRRect(logRect, glow);
        canvas.drawRRect(logRect, fill);
        // Rings
        final ringPaint = Paint()..color = Color.fromARGB((da * 60).toInt(), 0, 0, 0)..strokeWidth = 1..style = PaintingStyle.stroke;
        canvas.drawOval(Rect.fromLTWH(2, h * 0.22, 10, h * 0.56), ringPaint);
        canvas.drawOval(Rect.fromLTWH(totalW - 12, h * 0.22, 10, h * 0.56), ringPaint);
        // Moss spots
        final moss = Paint()..color = col.withValues(alpha: da * 0.4);
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
        final goingRight = secondLaneCenterX > laneCenterX;
        final earPath = Path()
          ..moveTo(cx - 5, h * 0.12)..lineTo(cx - 7, 0)..lineTo(cx - 1, h * 0.1)..close()
          ..moveTo(cx + 5, h * 0.12)..lineTo(cx + 7, 0)..lineTo(cx + 1, h * 0.1)..close();
        canvas.drawPath(earPath, fill);
        // Eyes
        final eyeP = Paint()..color = Color.fromARGB((da * 180).toInt(), 255, 255, 255);
        canvas.drawCircle(Offset(cx - 3, h * 0.22), 1.5, eyeP);
        canvas.drawCircle(Offset(cx + 3, h * 0.22), 1.5, eyeP);
        // Direction tail
        final tailX = goingRight ? cx + w * 0.35 : cx - w * 0.35;
        canvas.drawCircle(Offset(tailX, h * 0.55), 3, fill);
    }
  }

  // ── City: barriers, cones, containers, vehicles ──

  void _renderCity(Canvas canvas, Paint fill, Paint glow, Color col, double da) {
    switch (type) {
      case ObstacleType.wall:
        // Road barrier
        final cx = laneCenterX - position.x;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - w / 2, 0, w, h), const Radius.circular(3));
        canvas.drawRRect(rect, glow);
        canvas.drawRRect(rect, fill);
        // Stripes
        final stripe = Paint()..color = Color.fromARGB((da * 120).toInt(), 255, 200, 0);
        for (double sy = 3; sy < h - 5; sy += 8) {
          canvas.drawRect(Rect.fromLTWH(cx - w / 2 + 2, sy, w - 4, 3), stripe);
        }

      case ObstacleType.spike:
        // Traffic cone
        final cx = laneCenterX - position.x;
        final path = Path()
          ..moveTo(cx, 0)..lineTo(cx - w * 0.15, 0)..lineTo(cx - w / 2, h)
          ..lineTo(cx + w / 2, h)..lineTo(cx + w * 0.15, 0)..close();
        canvas.drawPath(path, glow);
        canvas.drawPath(path, fill);
        // Orange stripes
        final stripe = Paint()..color = Color.fromARGB((da * 150).toInt(), 255, 140, 0);
        canvas.drawRect(Rect.fromLTWH(cx - w * 0.3, h * 0.4, w * 0.6, 3), stripe);
        canvas.drawRect(Rect.fromLTWH(cx - w * 0.2, h * 0.65, w * 0.4, 2), stripe);

      case ObstacleType.doubleWall:
        // Shipping container
        final totalW = size.x;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, totalW, h), const Radius.circular(2));
        canvas.drawRRect(rect, glow);
        canvas.drawRRect(rect, fill);
        // Container ridges
        final ridge = Paint()..color = Color.fromARGB((da * 50).toInt(), 0, 0, 0)..strokeWidth = 1;
        for (double rx = 6; rx < totalW - 4; rx += 8) {
          canvas.drawLine(Offset(rx, 2), Offset(rx, h - 2), ridge);
        }
        // Door line
        canvas.drawLine(
          Offset(totalW / 2, 2), Offset(totalW / 2, h - 2),
          Paint()..color = Color.fromARGB((da * 80).toInt(), 0, 0, 0)..strokeWidth = 2);

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
        final wheelP = Paint()..color = Color.fromARGB((da * 200).toInt(), 30, 30, 30);
        canvas.drawCircle(Offset(cx - w * 0.25, h * 0.8), 3.5, wheelP);
        canvas.drawCircle(Offset(cx + w * 0.25, h * 0.8), 3.5, wheelP);
        // Headlights
        final goingRight = secondLaneCenterX > laneCenterX;
        final lightP = Paint()..color = Color.fromARGB((da * 200).toInt(), 255, 255, 180);
        final lightX = goingRight ? cx + w * 0.38 : cx - w * 0.38;
        canvas.drawCircle(Offset(lightX, h * 0.35), 2, lightP);
    }
  }

  // ── Crystal: ice columns, icicle clusters, glacier bridges, sliding ice blocks ──

  void _renderCrystal(Canvas canvas, Paint fill, Paint glow, Color col, double da) {
    switch (type) {
      case ObstacleType.wall:
        // Ice column
        final cx = laneCenterX - position.x;
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
        final shine = Paint()..color = Color.fromARGB((da * 120).toInt(), 200, 240, 255);
        canvas.drawLine(Offset(cx - w * 0.1, h * 0.1), Offset(cx - w * 0.15, h * 0.6), shine);
        canvas.drawLine(Offset(cx + w * 0.2, h * 0.2), Offset(cx + w * 0.1, h * 0.7), shine);

      case ObstacleType.spike:
        // Icicle cluster (hanging stalactites)
        final cx = laneCenterX - position.x;
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
          Paint()..color = Color.fromARGB((da * 180).toInt(), 220, 255, 255));

      case ObstacleType.doubleWall:
        // Glacier bridge
        final totalW = size.x;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(0, h * 0.2, totalW, h * 0.6), const Radius.circular(4));
        canvas.drawRRect(rect, glow);
        canvas.drawRRect(rect, fill);
        // Ice cracks
        final crack = Paint()..color = Color.fromARGB((da * 80).toInt(), 180, 230, 255)..strokeWidth = 1;
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
        final frost = Paint()..color = Color.fromARGB((da * 100).toInt(), 200, 240, 255);
        canvas.drawLine(Offset(cx - w * 0.2, h * 0.35), Offset(cx + w * 0.15, h * 0.5), frost);
        // Direction indicator
        final goingRight = secondLaneCenterX > laneCenterX;
        final trail = Paint()..color = Color.fromARGB((da * 60).toInt(), 180, 230, 255);
        final tx = goingRight ? cx - w * 0.3 : cx + w * 0.3;
        canvas.drawCircle(Offset(tx, h * 0.5), 3, trail);
    }
  }

  // ── Volcano: rocks, flames, lava pools, fireballs ──

  void _renderVolcano(Canvas canvas, Paint fill, Paint glow, Color col, double da) {
    switch (type) {
      case ObstacleType.wall:
        // Jagged rock
        final cx = laneCenterX - position.x;
        final path = Path()
          ..moveTo(cx - w / 2, h)
          ..lineTo(cx - w * 0.4, h * 0.3)
          ..lineTo(cx - w * 0.1, h * 0.15)
          ..lineTo(cx + w * 0.05, 0)
          ..lineTo(cx + w * 0.25, h * 0.2)
          ..lineTo(cx + w / 2, h * 0.35)
          ..lineTo(cx + w / 2, h)
          ..close();
        canvas.drawPath(path, glow);
        canvas.drawPath(path, fill);
        // Lava cracks
        final crack = Paint()..color = Color.fromARGB((da * 180).toInt(), 255, 100, 0)..strokeWidth = 1;
        canvas.drawLine(Offset(cx - 2, h * 0.4), Offset(cx + 1, h * 0.7), crack);
        canvas.drawLine(Offset(cx + 3, h * 0.3), Offset(cx + 1, h * 0.55), crack);

      case ObstacleType.spike:
        // Flame pillar
        final cx = laneCenterX - position.x;
        final path = Path()
          ..moveTo(cx, 0)
          ..quadraticBezierTo(cx - w * 0.6, h * 0.5, cx - w * 0.3, h)
          ..lineTo(cx + w * 0.3, h)
          ..quadraticBezierTo(cx + w * 0.6, h * 0.5, cx, 0)
          ..close();
        canvas.drawPath(path, glow);
        canvas.drawPath(path, fill);
        // Inner flame
        final inner = Paint()..color = Color.fromARGB((da * 150).toInt(), 255, 200, 50);
        final ip = Path()
          ..moveTo(cx, h * 0.2)
          ..quadraticBezierTo(cx - w * 0.25, h * 0.6, cx - w * 0.1, h)
          ..lineTo(cx + w * 0.1, h)
          ..quadraticBezierTo(cx + w * 0.25, h * 0.6, cx, h * 0.2)
          ..close();
        canvas.drawPath(ip, inner);

      case ObstacleType.doubleWall:
        // Lava pool / magma bar
        final totalW = size.x;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(0, h * 0.15, totalW, h * 0.7), const Radius.circular(12));
        canvas.drawRRect(rect, glow);
        canvas.drawRRect(rect, fill);
        // Bubbles
        final bubble = Paint()..color = Color.fromARGB((da * 140).toInt(), 255, 180, 0);
        canvas.drawCircle(Offset(totalW * 0.25, h * 0.4), 3, bubble);
        canvas.drawCircle(Offset(totalW * 0.6, h * 0.55), 2.5, bubble);
        canvas.drawCircle(Offset(totalW * 0.8, h * 0.38), 2, bubble);

      case ObstacleType.shifter:
        // Fireball
        final cx = w / 2;
        // Outer glow
        canvas.drawCircle(Offset(cx, h / 2), w * 0.45, glow);
        canvas.drawCircle(Offset(cx, h / 2), w * 0.38, fill);
        // Inner hot core
        final core = Paint()..color = Color.fromARGB((da * 200).toInt(), 255, 220, 80);
        canvas.drawCircle(Offset(cx, h / 2), w * 0.2, core);
        // Trail sparks
        final goingRight = secondLaneCenterX > laneCenterX;
        final spark = Paint()..color = Color.fromARGB((da * 100).toInt(), 255, 120, 0);
        final tx = goingRight ? cx - w * 0.3 : cx + w * 0.3;
        canvas.drawCircle(Offset(tx, h * 0.4), 2, spark);
        canvas.drawCircle(Offset(tx - (goingRight ? 3 : -3), h * 0.6), 1.5, spark);
    }
  }

  // ── Desert: obelisks, cacti, double pillars, sandstorm whirls ──

  void _renderDesert(Canvas canvas, Paint fill, Paint glow, Color col, double da) {
    switch (type) {
      case ObstacleType.wall:
        // Sandstone obelisk
        final cx = laneCenterX - position.x;
        final path = Path()
          ..moveTo(cx - w * 0.35, h)
          ..lineTo(cx - w * 0.25, h * 0.1)
          ..lineTo(cx, 0)
          ..lineTo(cx + w * 0.25, h * 0.1)
          ..lineTo(cx + w * 0.35, h)
          ..close();
        canvas.drawPath(path, glow);
        canvas.drawPath(path, fill);
        // Hieroglyph-like marks
        final mark = Paint()..color = Color.fromARGB((da * 80).toInt(), 0, 0, 0)..strokeWidth = 1;
        canvas.drawLine(Offset(cx - 3, h * 0.4), Offset(cx + 3, h * 0.4), mark);
        canvas.drawLine(Offset(cx - 2, h * 0.55), Offset(cx + 2, h * 0.55), mark);
        canvas.drawRect(Rect.fromLTWH(cx - 2, h * 0.65, 4, 4), mark);

      case ObstacleType.spike:
        // Cactus
        final cx = laneCenterX - position.x;
        final stemW = w * 0.25;
        // Main stem
        canvas.drawRect(Rect.fromLTWH(cx - stemW / 2, h * 0.1, stemW, h * 0.9), glow);
        canvas.drawRect(Rect.fromLTWH(cx - stemW / 2, h * 0.1, stemW, h * 0.9), fill);
        // Arms
        final armW = stemW * 0.7;
        // Left arm
        canvas.drawRect(Rect.fromLTWH(cx - stemW / 2 - armW, h * 0.3, armW, armW), fill);
        canvas.drawRect(Rect.fromLTWH(cx - stemW / 2 - armW, h * 0.15, armW, h * 0.15 + armW), fill);
        // Right arm
        canvas.drawRect(Rect.fromLTWH(cx + stemW / 2, h * 0.45, armW, armW), fill);
        canvas.drawRect(Rect.fromLTWH(cx + stemW / 2, h * 0.3, armW, h * 0.15 + armW), fill);
        // Spines
        final spine = Paint()..color = Color.fromARGB((da * 100).toInt(), 255, 255, 200)..strokeWidth = 0.5;
        for (double sy = h * 0.15; sy < h * 0.9; sy += 8) {
          canvas.drawLine(Offset(cx - stemW / 2 - 2, sy), Offset(cx - stemW / 2, sy), spine);
          canvas.drawLine(Offset(cx + stemW / 2 + 2, sy), Offset(cx + stemW / 2, sy), spine);
        }

      case ObstacleType.doubleWall:
        // Double sandstone pillars
        final totalW = size.x;
        final pillarW = totalW * 0.35;
        // Left pillar
        canvas.drawRect(Rect.fromLTWH(0, h * 0.1, pillarW, h * 0.9), glow);
        canvas.drawRect(Rect.fromLTWH(0, h * 0.1, pillarW, h * 0.9), fill);
        // Right pillar
        canvas.drawRect(Rect.fromLTWH(totalW - pillarW, h * 0.1, pillarW, h * 0.9), glow);
        canvas.drawRect(Rect.fromLTWH(totalW - pillarW, h * 0.1, pillarW, h * 0.9), fill);
        // Connecting lintel
        canvas.drawRect(Rect.fromLTWH(0, h * 0.05, totalW, h * 0.12), fill);
        // Sand texture
        final sand = Paint()..color = Color.fromARGB((da * 40).toInt(), 0, 0, 0);
        canvas.drawCircle(Offset(pillarW * 0.5, h * 0.5), 2, sand);
        canvas.drawCircle(Offset(totalW - pillarW * 0.5, h * 0.6), 1.5, sand);

      case ObstacleType.shifter:
        // Sandstorm whirl
        final cx = w / 2;
        // Swirling sand
        canvas.drawCircle(Offset(cx, h / 2), w * 0.4,
          Paint()..color = col.withValues(alpha: da * 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
        canvas.drawCircle(Offset(cx, h / 2), w * 0.28, glow);
        canvas.drawCircle(Offset(cx, h / 2), w * 0.22, fill);
        // Swirl lines
        final swirl = Paint()..color = Color.fromARGB((da * 100).toInt(), 255, 220, 150)..strokeWidth = 1.5..style = PaintingStyle.stroke;
        final sPath = Path()
          ..moveTo(cx - w * 0.15, h * 0.3)
          ..quadraticBezierTo(cx + w * 0.2, h * 0.4, cx - w * 0.1, h * 0.6)
          ..quadraticBezierTo(cx + w * 0.15, h * 0.7, cx, h * 0.75);
        canvas.drawPath(sPath, swirl);
    }
  }

  // ── Ocean: coral, jellyfish, waves, pufferfish ──

  void _renderOcean(Canvas canvas, Paint fill, Paint glow, Color col, double da) {
    switch (type) {
      case ObstacleType.wall:
        // Coral formation
        final cx = laneCenterX - position.x;
        // Base
        canvas.drawOval(Rect.fromLTWH(cx - w / 2, h * 0.5, w, h * 0.5), glow);
        canvas.drawOval(Rect.fromLTWH(cx - w / 2, h * 0.5, w, h * 0.5), fill);
        // Branches
        final branch = Paint()..color = col..strokeWidth = 3..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(cx - 4, h * 0.5), Offset(cx - 6, h * 0.1), branch);
        canvas.drawLine(Offset(cx + 2, h * 0.45), Offset(cx + 5, 0), branch);
        canvas.drawLine(Offset(cx + 1, h * 0.5), Offset(cx - 1, h * 0.15), branch);
        // Tips
        final tip = Paint()..color = Color.fromARGB((da * 180).toInt(), 150, 255, 255);
        canvas.drawCircle(Offset(cx - 6, h * 0.1), 2, tip);
        canvas.drawCircle(Offset(cx + 5, 0), 2, tip);
        canvas.drawCircle(Offset(cx - 1, h * 0.15), 1.5, tip);

      case ObstacleType.spike:
        // Jellyfish
        final cx = laneCenterX - position.x;
        // Dome
        final dome = Path()
          ..moveTo(cx - w / 2, h * 0.4)
          ..quadraticBezierTo(cx - w / 2, 0, cx, 0)
          ..quadraticBezierTo(cx + w / 2, 0, cx + w / 2, h * 0.4)
          ..close();
        canvas.drawPath(dome, glow);
        canvas.drawPath(dome, fill);
        // Tentacles
        final tent = Paint()..color = col.withValues(alpha: da * 0.7)..strokeWidth = 1.5..style = PaintingStyle.stroke;
        for (double tx = cx - w * 0.3; tx <= cx + w * 0.3; tx += 5) {
          final path = Path()..moveTo(tx, h * 0.4);
          path.quadraticBezierTo(tx + 2, h * 0.65, tx - 1, h);
          canvas.drawPath(path, tent);
        }

      case ObstacleType.doubleWall:
        // Wave / seaweed wall
        final totalW = size.x;
        final path = Path()..moveTo(0, h);
        for (double x = 0; x <= totalW; x += 8) {
          final waveY = h * 0.3 + sin(x * 0.3) * h * 0.15;
          path.lineTo(x, waveY);
        }
        path.lineTo(totalW, h);
        path.close();
        canvas.drawPath(path, glow);
        canvas.drawPath(path, fill);
        // Bubbles
        final bub = Paint()..color = Color.fromARGB((da * 80).toInt(), 180, 255, 255);
        canvas.drawCircle(Offset(totalW * 0.2, h * 0.2), 2, bub);
        canvas.drawCircle(Offset(totalW * 0.5, h * 0.15), 3, bub);
        canvas.drawCircle(Offset(totalW * 0.75, h * 0.25), 1.5, bub);

      case ObstacleType.shifter:
        // Pufferfish
        final cx = w / 2;
        // Body (round)
        canvas.drawCircle(Offset(cx, h / 2), w * 0.38, glow);
        canvas.drawCircle(Offset(cx, h / 2), w * 0.35, fill);
        // Spines
        final spine = Paint()..color = col..strokeWidth = 1.5..strokeCap = StrokeCap.round;
        for (double angle = 0; angle < 3.14159 * 2; angle += 0.7) {
          final sx = cx + cos(angle) * w * 0.35;
          final sy = h / 2 + sin(angle) * w * 0.35;
          final ex = cx + cos(angle) * w * 0.48;
          final ey = h / 2 + sin(angle) * w * 0.48;
          canvas.drawLine(Offset(sx, sy), Offset(ex, ey), spine);
        }
        // Eye
        final eyeP = Paint()..color = Color.fromARGB((da * 220).toInt(), 255, 255, 255);
        final goingRight = secondLaneCenterX > laneCenterX;
        canvas.drawCircle(Offset(cx + (goingRight ? 4 : -4), h / 2 - 3), 2.5, eyeP);
        canvas.drawCircle(Offset(cx + (goingRight ? 4 : -4), h / 2 - 3), 1, Paint()..color = Color.fromARGB((da * 220).toInt(), 0, 0, 0));
    }
  }

  // ── Ruins: cracked stone, splinters, pillar pairs, rolling boulders ──

  void _renderRuins(Canvas canvas, Paint fill, Paint glow, Color col, double da) {
    switch (type) {
      case ObstacleType.wall:
        // Cracked stone block with vines
        final cx = laneCenterX - position.x;
        final rect = Rect.fromLTWH(cx - w / 2, 0, w, h);
        canvas.drawRect(rect, glow);
        canvas.drawRect(rect, fill);
        // Cracks
        final crack = Paint()..color = Color.fromARGB((da * 80).toInt(), 0, 0, 0)..strokeWidth = 1;
        canvas.drawLine(Offset(cx - w * 0.2, 0), Offset(cx + w * 0.1, h * 0.4), crack);
        canvas.drawLine(Offset(cx + w * 0.1, h * 0.4), Offset(cx - w * 0.05, h), crack);
        // Vine / moss
        final vine = Paint()..color = Color.fromARGB((da * 120).toInt(), 60, 140, 60)..strokeWidth = 2;
        final vinePath = Path()
          ..moveTo(cx + w * 0.3, 0)
          ..quadraticBezierTo(cx + w * 0.4, h * 0.3, cx + w * 0.2, h * 0.6);
        canvas.drawPath(vinePath, vine);
        // Moss patch
        canvas.drawCircle(Offset(cx - w * 0.2, h * 0.7), 3,
          Paint()..color = Color.fromARGB((da * 80).toInt(), 80, 160, 80));

      case ObstacleType.spike:
        // Stone splinters (broken column top)
        final cx = laneCenterX - position.x;
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
          Paint()..color = Color.fromARGB((da * 100).toInt(), 60, 140, 60));

      case ObstacleType.doubleWall:
        // Pillar pair with fallen lintel
        final totalW = size.x;
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
        final vine = Paint()..color = Color.fromARGB((da * 80).toInt(), 60, 140, 60)..strokeWidth = 1.5..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(pw, h * 0.1), Offset(pw + 5, h * 0.5), vine);

      case ObstacleType.shifter:
        // Rolling boulder
        final cx = w / 2;
        canvas.drawCircle(Offset(cx, h / 2), w * 0.4, glow);
        canvas.drawCircle(Offset(cx, h / 2), w * 0.36, fill);
        // Rock texture
        final tex = Paint()..color = Color.fromARGB((da * 50).toInt(), 0, 0, 0);
        canvas.drawCircle(Offset(cx - 4, h / 2 - 3), 3, tex);
        canvas.drawCircle(Offset(cx + 3, h / 2 + 2), 2.5, tex);
        // Moss spot
        canvas.drawCircle(Offset(cx + 5, h / 2 - 5), 2,
          Paint()..color = Color.fromARGB((da * 80).toInt(), 60, 140, 60));
        // Motion trail
        final goingRight = secondLaneCenterX > laneCenterX;
        final trail = Paint()..color = Color.fromARGB((da * 40).toInt(), 100, 80, 60);
        final trailX = goingRight ? cx - w * 0.35 : cx + w * 0.35;
        canvas.drawCircle(Offset(trailX, h * 0.6), 2, trail);
    }
  }

  // ── Space: asteroids, satellites, debris, UFOs ──

  void _renderSpace(Canvas canvas, Paint fill, Paint glow, Color col, double da) {
    switch (type) {
      case ObstacleType.wall:
        // Asteroid
        final cx = laneCenterX - position.x;
        final path = Path()
          ..moveTo(cx - w * 0.1, 0)
          ..lineTo(cx - w / 2, h * 0.25)
          ..lineTo(cx - w * 0.45, h * 0.7)
          ..lineTo(cx - w * 0.1, h)
          ..lineTo(cx + w * 0.3, h * 0.85)
          ..lineTo(cx + w / 2, h * 0.4)
          ..lineTo(cx + w * 0.2, h * 0.05)
          ..close();
        canvas.drawPath(path, glow);
        canvas.drawPath(path, fill);
        // Craters
        final crater = Paint()..color = Color.fromARGB((da * 60).toInt(), 0, 0, 0);
        canvas.drawCircle(Offset(cx - 2, h * 0.35), 3, crater);
        canvas.drawCircle(Offset(cx + 4, h * 0.6), 2, crater);

      case ObstacleType.spike:
        // Satellite dish / antenna
        final cx = laneCenterX - position.x;
        // Mast
        canvas.drawRect(
          Rect.fromLTWH(cx - 1.5, h * 0.3, 3, h * 0.7),
          fill);
        // Dish
        final dish = Path()
          ..moveTo(cx - w / 2, h * 0.35)
          ..quadraticBezierTo(cx, 0, cx + w / 2, h * 0.35)
          ..close();
        canvas.drawPath(dish, glow);
        canvas.drawPath(dish, fill);
        // Signal dot
        canvas.drawCircle(Offset(cx, h * 0.15), 2,
          Paint()..color = Color.fromARGB((da * 200).toInt(), 255, 100, 100));

      case ObstacleType.doubleWall:
        // Space debris / hull fragment
        final totalW = size.x;
        final path = Path()
          ..moveTo(4, h * 0.15)
          ..lineTo(0, h * 0.5)
          ..lineTo(3, h * 0.9)
          ..lineTo(totalW - 3, h)
          ..lineTo(totalW, h * 0.45)
          ..lineTo(totalW - 5, h * 0.05)
          ..close();
        canvas.drawPath(path, glow);
        canvas.drawPath(path, fill);
        // Rivets
        final rivet = Paint()..color = Color.fromARGB((da * 100).toInt(), 200, 200, 255);
        for (double rx = 8; rx < totalW - 4; rx += 12) {
          canvas.drawCircle(Offset(rx, h * 0.5), 1.5, rivet);
        }

      case ObstacleType.shifter:
        // UFO
        final cx = w / 2;
        // Dome
        canvas.drawOval(
          Rect.fromLTWH(cx - w * 0.2, h * 0.1, w * 0.4, h * 0.35), fill);
        // Saucer body
        canvas.drawOval(
          Rect.fromLTWH(cx - w / 2, h * 0.3, w, h * 0.35), glow);
        canvas.drawOval(
          Rect.fromLTWH(cx - w / 2, h * 0.3, w, h * 0.35), fill);
        // Lights
        final light = Paint()..color = Color.fromARGB((da * 200).toInt(), 255, 255, 150);
        canvas.drawCircle(Offset(cx - w * 0.3, h * 0.5), 2, light);
        canvas.drawCircle(Offset(cx, h * 0.52), 2, light);
        canvas.drawCircle(Offset(cx + w * 0.3, h * 0.5), 2, light);
        // Beam
        final beam = Paint()..color = Color.fromARGB((da * 40).toInt(), 200, 255, 200);
        final beamPath = Path()
          ..moveTo(cx - w * 0.15, h * 0.6)
          ..lineTo(cx - w * 0.3, h)
          ..lineTo(cx + w * 0.3, h)
          ..lineTo(cx + w * 0.15, h * 0.6)
          ..close();
        canvas.drawPath(beamPath, beam);
    }
  }

  // ── Storm: lightning rods, ball lightning, storm towers, sideways bolts ──

  void _renderStorm(Canvas canvas, Paint fill, Paint glow, Color col, double da) {
    switch (type) {
      case ObstacleType.wall:
        // Lightning rod
        final cx = laneCenterX - position.x;
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
        final arc = Paint()..color = Color.fromARGB((da * 200).toInt(), 238, 221, 68)..strokeWidth = 1.5;
        canvas.drawLine(Offset(cx, h * 0.05), Offset(cx - 5, h * -0.05), arc);
        canvas.drawLine(Offset(cx, h * 0.05), Offset(cx + 4, h * -0.03), arc);

      case ObstacleType.spike:
        // Ball lightning
        final cx = laneCenterX - position.x;
        // Outer glow
        canvas.drawCircle(Offset(cx, h / 2), w * 0.45,
          Paint()..color = Color.fromARGB((da * 60).toInt(), 238, 221, 68)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
        canvas.drawCircle(Offset(cx, h / 2), w * 0.3, glow);
        canvas.drawCircle(Offset(cx, h / 2), w * 0.25, fill);
        // Inner bright core
        canvas.drawCircle(Offset(cx, h / 2), w * 0.12,
          Paint()..color = Color.fromARGB((da * 220).toInt(), 255, 255, 200));
        // Sparks
        final spark = Paint()..color = Color.fromARGB((da * 150).toInt(), 238, 221, 68)..strokeWidth = 1;
        canvas.drawLine(Offset(cx - w * 0.3, h * 0.3), Offset(cx - w * 0.45, h * 0.2), spark);
        canvas.drawLine(Offset(cx + w * 0.25, h * 0.65), Offset(cx + w * 0.4, h * 0.75), spark);

      case ObstacleType.doubleWall:
        // Storm towers (two pillars with arc between)
        final totalW = size.x;
        final tw = totalW * 0.2;
        // Left tower
        canvas.drawRect(Rect.fromLTWH(0, 0, tw, h), glow);
        canvas.drawRect(Rect.fromLTWH(0, 0, tw, h), fill);
        // Right tower
        canvas.drawRect(Rect.fromLTWH(totalW - tw, 0, tw, h), glow);
        canvas.drawRect(Rect.fromLTWH(totalW - tw, 0, tw, h), fill);
        // Electric arc between towers
        final arcPaint = Paint()
          ..color = Color.fromARGB((da * 180).toInt(), 238, 221, 68)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        final arcPath = Path()..moveTo(tw, h * 0.4);
        for (double ax = tw; ax < totalW - tw; ax += 6) {
          final ay = h * 0.4 + ((ax / 6).toInt() % 2 == 0 ? -4 : 4);
          arcPath.lineTo(ax, ay);
        }
        arcPath.lineTo(totalW - tw, h * 0.4);
        canvas.drawPath(arcPath, arcPaint);
        // Glow on arc
        canvas.drawPath(arcPath, Paint()
          ..color = Color.fromARGB((da * 40).toInt(), 238, 221, 68)
          ..strokeWidth = 8
          ..style = PaintingStyle.stroke
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
        canvas.drawPath(boltPath, Paint()
          ..color = Color.fromARGB((da * 60).toInt(), 238, 221, 68)
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
        // Bolt
        canvas.drawPath(boltPath, Paint()
          ..color = col
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke);
        // Bright core
        canvas.drawPath(boltPath, Paint()
          ..color = Color.fromARGB((da * 200).toInt(), 255, 255, 200)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke);
    }
  }

  // ── Neon: light bars, lasers, glitch blocks, pulse orbs ──

  void _renderNeon(Canvas canvas, Paint fill, Paint glow, Color col, double da) {
    switch (type) {
      case ObstacleType.wall:
        // Neon light bar
        final cx = laneCenterX - position.x;
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - w / 2, 0, w, h), const Radius.circular(2));
        canvas.drawRRect(rect, glow);
        canvas.drawRRect(rect, fill);
        // Inner bright core
        final core = RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - w * 0.2, 2, w * 0.4, h - 4), const Radius.circular(1));
        canvas.drawRRect(core, Paint()..color = Color.fromARGB((da * 180).toInt(), 255, 255, 255));

      case ObstacleType.spike:
        // Laser beam (X shape)
        final cx = laneCenterX - position.x;
        final lp = Paint()..color = col..strokeWidth = 3..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(cx - w / 2, 0), Offset(cx + w / 2, h), lp);
        canvas.drawLine(Offset(cx + w / 2, 0), Offset(cx - w / 2, h), lp);
        // Glow on lines
        final glp = Paint()
          ..color = col.withValues(alpha: da * 0.4)
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
        canvas.drawLine(Offset(cx - w / 2, 0), Offset(cx + w / 2, h), glp);
        canvas.drawLine(Offset(cx + w / 2, 0), Offset(cx - w / 2, h), glp);
        // Center dot
        canvas.drawCircle(Offset(cx, h / 2), 3,
          Paint()..color = Color.fromARGB((da * 255).toInt(), 255, 255, 255));

      case ObstacleType.doubleWall:
        // Glitch block
        final totalW = size.x;
        canvas.drawRect(Rect.fromLTWH(0, 0, totalW, h), glow);
        canvas.drawRect(Rect.fromLTWH(0, 0, totalW, h), fill);
        // Scanlines
        final scan = Paint()..color = Color.fromARGB((da * 40).toInt(), 255, 255, 255);
        for (double sy = 2; sy < h; sy += 4) {
          canvas.drawRect(Rect.fromLTWH(0, sy, totalW, 1), scan);
        }
        // Glitch offset rectangles
        final glitch = Paint()..color = Color.fromARGB((da * 100).toInt(), 255, 255, 255);
        canvas.drawRect(Rect.fromLTWH(3, h * 0.3, totalW * 0.4, 3), glitch);
        canvas.drawRect(Rect.fromLTWH(totalW * 0.5, h * 0.6, totalW * 0.4, 2), glitch);

      case ObstacleType.shifter:
        // Pulse orb
        final cx = w / 2;
        // Outer ring
        canvas.drawCircle(Offset(cx, h / 2), w * 0.42, glow);
        final ringP = Paint()
          ..color = col
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(Offset(cx, h / 2), w * 0.38, ringP);
        // Inner orb
        canvas.drawCircle(Offset(cx, h / 2), w * 0.2,
          Paint()..color = Color.fromARGB((da * 255).toInt(), 255, 255, 255));
        // Orbiting dots
        final goingRight = secondLaneCenterX > laneCenterX;
        final angle = goingRight ? 0.8 : -0.8;
        final dotP = Paint()..color = col;
        canvas.drawCircle(
          Offset(cx + cos(angle) * w * 0.35, h / 2 + sin(angle) * w * 0.35), 2, dotP);
        canvas.drawCircle(
          Offset(cx + cos(angle + 3.14) * w * 0.35, h / 2 + sin(angle + 3.14) * w * 0.35), 2, dotP);
    }
  }

  // ── Void: static, fragments, cracks, shadows ──

  void _renderVoid(Canvas canvas, Paint fill, Paint glow, Color col, double da) {
    switch (type) {
      case ObstacleType.wall:
        // Static noise block
        final cx = laneCenterX - position.x;
        final rect = Rect.fromLTWH(cx - w / 2, 0, w, h);
        canvas.drawRect(rect, glow);
        canvas.drawRect(rect, fill);
        // Noise lines
        final noise = Paint()..color = Color.fromARGB((da * 60).toInt(), 255, 255, 255)..strokeWidth = 1;
        for (double ny = 2; ny < h - 2; ny += 3) {
          final offset = ((ny * 7).toInt() % 5) - 2;
          canvas.drawLine(
            Offset(cx - w / 2 + 2 + offset, ny),
            Offset(cx + w / 2 - 2 + offset, ny),
            noise);
        }

      case ObstacleType.spike:
        // Crack / rift
        final cx = laneCenterX - position.x;
        final path = Path()
          ..moveTo(cx, 0)
          ..lineTo(cx - 3, h * 0.2)
          ..lineTo(cx + 4, h * 0.4)
          ..lineTo(cx - 2, h * 0.6)
          ..lineTo(cx + 3, h * 0.8)
          ..lineTo(cx, h);
        final riftP = Paint()
          ..color = col
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
        canvas.drawPath(path, Paint()
          ..color = col.withValues(alpha: da * 0.5)
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
        canvas.drawPath(path, riftP);
        // White core
        canvas.drawPath(path, Paint()
          ..color = Color.fromARGB((da * 200).toInt(), 255, 255, 255)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke);

      case ObstacleType.doubleWall:
        // Fragmented bar
        final totalW = size.x;
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
          Paint()
            ..color = col.withValues(alpha: da * 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
        canvas.drawCircle(Offset(cx, h / 2), w * 0.3, fill);
        // Void eyes
        final eyeP = Paint()..color = Color.fromARGB((da * 255).toInt(), 255, 255, 255);
        canvas.drawCircle(Offset(cx - 4, h / 2 - 2), 2, eyeP);
        canvas.drawCircle(Offset(cx + 4, h / 2 - 2), 2, eyeP);
    }
  }
}
