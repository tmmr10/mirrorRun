import 'dart:ui';
import 'package:flame/components.dart';
import '../game_state.dart';
import '../mirror_run_game.dart';

/// Darkens one side of the playfield during the BLACKOUT event, forcing the
/// player to navigate that side from memory.
class BlackoutOverlay extends PositionComponent
    with HasGameReference<MirrorRunGame> {
  static const double vw = MirrorRunGame.vw;
  static const double mid = vw / 2;

  final Paint _paint = Paint();

  BlackoutOverlay() : super(priority: 95);

  @override
  void render(Canvas canvas) {
    // Only while actually playing — otherwise a death mid-blackout would leave
    // the screen half-dark on the death screen (events don't tick when dead).
    if (game.playState != PlayState.playing) return;
    final es = game.eventSystem;
    final side = es.blackoutSide;
    if (side == null || es.blackoutFade <= 0) return;

    final alpha = (es.blackoutFade.clamp(0.0, 1.0)) * 0.98;
    final vh = MirrorRunGame.vh;
    final rect = side == 'left'
        ? Rect.fromLTWH(0, 0, mid, vh)
        : Rect.fromLTWH(mid, 0, mid, vh);

    // Soft gradient toward the mirror line so it reads as a creeping shadow.
    final from = side == 'left' ? Offset(0, 0) : Offset(vw, 0);
    final to = Offset(mid, 0);
    _paint.shader = Gradient.linear(
      from,
      to,
      [
        const Color(0xFF000000).withValues(alpha: alpha),
        const Color(0xFF000000).withValues(alpha: alpha * 0.9),
      ],
    );
    canvas.drawRect(rect, _paint);
  }
}
