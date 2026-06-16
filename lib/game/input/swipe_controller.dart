import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import '../game_state.dart';
import '../mirror_run_game.dart';

/// Wraps the [GameWidget] with horizontal-drag steering.
///
/// The drag recognizer must NOT compete in the gesture arena while the game is
/// paused — otherwise a stationary tap on the pause overlay (RESUME / dim
/// background) gets cancelled the moment the finger drifts past the horizontal
/// slop, and the overlay's `onTap` never fires (the game appears to "swallow"
/// the tap). We gate the recognizer at `isPointerAllowed`, which is evaluated
/// synchronously on pointer-down — before the arena resolves — so when paused
/// the recognizer never even enters the arena and the overlay tap wins cleanly.
class SwipeController extends StatelessWidget {
  final MirrorRunGame game;
  final Widget child;

  const SwipeController({
    super.key,
    required this.game,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // The game maps the screen-space drag delta into game coordinates using its
    // own render zoom (uniform-fit + letterboxing), so the widget no longer
    // needs to pass the layout width — a raw RawGestureDetector is enough.
    return RawGestureDetector(
      gestures: {
        _GatedHorizontalDragRecognizer:
            GestureRecognizerFactoryWithHandlers<
                _GatedHorizontalDragRecognizer>(
          () => _GatedHorizontalDragRecognizer(game),
          (recognizer) {
            recognizer.onUpdate = (details) => game.onDrag(details.delta.dx);
          },
        ),
      },
      child: child,
    );
  }
}

/// A horizontal-drag recognizer that only accepts pointers while the game is
/// actively running. While paused/countdown/menu/dead it rejects the pointer at
/// `isPointerAllowed`, keeping it out of the gesture arena so overlay taps
/// (e.g. the pause screen) are never cancelled by it.
class _GatedHorizontalDragRecognizer extends HorizontalDragGestureRecognizer {
  final MirrorRunGame game;

  _GatedHorizontalDragRecognizer(this.game);

  bool get _steeringActive =>
      game.playState == PlayState.playing && !game.paused;

  @override
  bool isPointerAllowed(PointerEvent event) {
    if (!_steeringActive) return false;
    return super.isPointerAllowed(event);
  }
}
