import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import '../game_state.dart';
import '../mirror_run_game.dart';

class Obstacle extends PositionComponent with HasGameReference<MirrorRunGame> {
  final String side; // 'left', 'right'
  final ObstacleType type;
  final int lane;
  final double laneCenterX;
  final double w;
  final double h;

  /// Y scroll position (top to bottom).
  double scrollPos;

  /// True if this obstacle has already triggered a near-miss (prevents retrigger).
  bool nearMissed = false;

  /// For doubleWall/shifter: second lane info.
  final double secondLaneCenterX;
  final int secondLane;

  static double get groundY => MirrorRunGame.groundY;
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
    // Scroll is advanced by the game's fixed-step loop (see MirrorRunGame._tick)
    // so movement and collision stay in lockstep. Here we only sync the visual
    // position and cull off-screen obstacles.
    _updatePosition();
    if (scrollPos > MirrorRunGame.vh + 60) removeFromParent();
  }

  /// For shifter: interpolation factor 0..1 based on scroll progress.
  double get _shifterT {
    final progress = ((scrollPos + 60) / (groundY + 60)).clamp(0.0, 1.0);
    return ((progress - 0.3) / 0.4).clamp(0.0, 1.0);
  }

  /// Current interpolated X center for shifter obstacles (public for renderers).
  double get shifterCurrentX {
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
        final cx = shifterCurrentX;
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
        final cx = shifterCurrentX;
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
    final foresight = game.foresightActive;
    if (!foresight && phantomFade >= 1.0) return;

    final biome = game.currentBiome;
    final Color col = side == 'left' ? biome.obsL : biome.obsR;
    final Color glow = side == 'left' ? biome.obsGlowL : biome.obsGlowR;

    final double a = foresight
        ? (phantomFade > 0 ? max(1 - phantomFade, 0.4) : 1.0)
        : (phantomFade > 0 ? (1 - phantomFade) : 1.0);
    final glowPaint = Paint()
      ..color = glow.withValues(alpha: glow.a * a)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    final fillPaint = Paint()..color = col.withValues(alpha: col.a * a);
    final detailAlpha = (0.6 * a).clamp(0.0, 1.0);

    biome.obstacleRenderer.render(canvas, this, fillPaint, glowPaint, col, detailAlpha);
  }
}
