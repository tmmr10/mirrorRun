import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

import '../mirror_run_game.dart';

/// A single short-lived floating text instance.
///
/// Lives ~0.9s, drifts upward and fades out. The [TextPainter] is built once on
/// spawn and only re-laid-out when its alpha changes between frames, so steady
/// frames avoid the cost of re-shaping glyph runs.
class _FloatingText {
  _FloatingText(this.text, this.pos, this.color) {
    _painter = TextPainter(textDirection: TextDirection.ltr);
    _layout(1.0);
  }

  final String text;
  final Vector2 pos;
  final Color color;

  /// Remaining life in seconds.
  double life = _lifeSpan;

  /// How far the text has drifted upward so far.
  double _rise = 0;

  late final TextPainter _painter;
  double _lastAlpha = -1;

  static const double _lifeSpan = 0.9;
  static const double _riseDistance = 36;
  static const double _fontSize = 16;

  /// Normalized progress 0 -> 1 across the lifetime.
  double get _progress => 1.0 - (life / _lifeSpan).clamp(0.0, 1.0);

  bool get isDead => life <= 0;

  void _layout(double alpha) {
    _lastAlpha = alpha;
    final c = color.withValues(alpha: alpha);
    _painter
      ..text = TextSpan(
        text: text,
        style: TextStyle(
          color: c,
          fontSize: _fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          height: 1.0,
          shadows: [
            Shadow(
              color: c.withValues(alpha: alpha * 0.9),
              blurRadius: 8,
            ),
          ],
        ),
      )
      ..layout();
  }

  void update(double dt) {
    life -= dt;
    if (life < 0) life = 0;
    _rise = _progress * _riseDistance;
  }

  void render(Canvas canvas) {
    // Ease-out fade: fully opaque for the first ~40% of life, then fades.
    final t = _progress;
    final alpha = t < 0.4 ? 1.0 : (1.0 - (t - 0.4) / 0.6).clamp(0.0, 1.0);

    // Only re-layout when the alpha actually changed enough to matter.
    if ((alpha - _lastAlpha).abs() > 0.01) {
      _layout(alpha);
    }

    final dx = pos.x - _painter.width / 2;
    final dy = pos.y - _painter.height / 2 - _rise;
    _painter.paint(canvas, Offset(dx, dy));
  }
}

/// Renders short-lived rising "floating texts" above the playfield (e.g. "+12",
/// "NEAR!") as juice feedback for near-misses and coin pickups.
class FloatingTextLayer extends PositionComponent
    with HasGameReference<MirrorRunGame> {
  FloatingTextLayer() : super(priority: 90);

  final List<_FloatingText> _texts = [];

  /// Spawn a floating text at [pos] (world coordinates) with [color].
  void spawn(String text, Vector2 pos, Color color) {
    _texts.add(_FloatingText(text, pos.clone(), color));
  }

  /// Remove all active floating texts (used on run reset).
  void clearAll() {
    _texts.clear();
  }

  @override
  void update(double dt) {
    if (_texts.isEmpty) return;
    for (final t in _texts) {
      t.update(dt);
    }
    _texts.removeWhere((t) => t.isDead);
  }

  @override
  void render(Canvas canvas) {
    if (_texts.isEmpty) return;
    for (final t in _texts) {
      t.render(canvas);
    }
  }
}
