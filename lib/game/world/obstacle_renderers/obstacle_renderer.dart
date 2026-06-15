import 'dart:ui';
import '../../components/obstacle.dart';

// ── Reusable Paint instances (avoid per-frame allocations in render hot-path) ──
//
// These are shared across all ObstacleRenderer instances. Each draw call MUST set
// every property it relies on (color, and where applicable style/strokeWidth/
// strokeCap/maskFilter), because a previous draw may have left a different value
// behind. To keep that safe and cheap, paints are split by purpose:
//   pFill         — plain fill (style/strokeWidth/maskFilter must be reset by user)
//   pGlowFill     — blurred glow/aura fills (sets maskFilter, must be reset)
//   pStroke       — generic stroke (sets style=stroke + strokeWidth)
//   pStrokeCap    — stroke with round cap
//   pStrokeGlow   — blurred stroke glow (style=stroke + strokeWidth + maskFilter)
//
// The render() method's own `fill`/`glow` paints are created per-render in
// Obstacle.render() and passed down; those are intentionally left as-is.

/// Plain fill paint (style = fill, no strokeWidth/maskFilter). Used for
/// drawRect/drawCircle/drawOval/drawPath/drawRRect solid fills. Set color per use.
final Paint pFill = Paint();

/// Fill-style paint that ALSO carries a strokeWidth, matching the original code
/// where lines were drawn with a default-style (fill) Paint plus `..strokeWidth`.
/// Behaviour stays bit-identical to those `Paint()..color=..()..strokeWidth=N`
/// uses. Set color + strokeWidth per use. style stays fill, cap stays butt.
final Paint pFillLine = Paint();

/// Like pFillLine but with a round stroke cap (still fill style), matching the
/// original `Paint()..color..strokeWidth..strokeCap = StrokeCap.round` lines.
/// Kept separate so the round cap never leaks into plain pFillLine draws.
final Paint pFillLineCap = Paint()..strokeCap = StrokeCap.round;

/// Blurred glow/aura FILL paint (style = fill). Always set color + maskFilter
/// per use; nothing else relies on it.
final Paint pGlowFill = Paint();

/// Explicit-stroke paint (style = stroke), no special cap. Set color +
/// strokeWidth per use; cap is reset to butt each use.
final Paint pStroke = Paint()..style = PaintingStyle.stroke;

/// Explicit-stroke paint with round cap (style = stroke, cap = round).
/// Set color + strokeWidth per use.
final Paint pStrokeCap = Paint()
  ..style = PaintingStyle.stroke
  ..strokeCap = StrokeCap.round;

/// Blurred stroke-glow paint (style = stroke). Set color/strokeWidth/strokeCap/
/// maskFilter per use.
final Paint pStrokeGlow = Paint()..style = PaintingStyle.stroke;

/// Strategy for drawing an [Obstacle] in a given biome's visual style.
///
/// Renderers are stateless — one shared instance per biome suffices. The
/// per-frame `fill`/`glow` paints and `col`/`da` (detail alpha) are computed in
/// [Obstacle.render] and passed in. Implementations switch over `o.type`
/// (wall/spike/doubleWall/shifter) to draw the biome-specific shape.
abstract class ObstacleRenderer {
  const ObstacleRenderer();

  void render(Canvas canvas, Obstacle o, Paint fill, Paint glow, Color col, double da);
}
