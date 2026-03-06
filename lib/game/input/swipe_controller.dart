import 'package:flutter/material.dart';
import '../mirror_run_game.dart';

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
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            game.onDrag(details.delta.dx, constraints.maxWidth);
          },
          child: child,
        );
      },
    );
  }
}
