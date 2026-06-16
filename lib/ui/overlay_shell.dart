import 'package:flutter/material.dart';

/// Centers and width-limits an overlay's content so full-screen overlays stay
/// readable on very wide displays (e.g. iPad ~1032pt) instead of being torn
/// apart edge-to-edge, while phones (~402pt < [maxWidth]) are unaffected.
///
/// Wrap the *inner content* of an overlay — keep each screen's own background
/// gradient and [SafeArea] outside this widget so they still fill the screen.
/// Place a scrolling body (ListView / SingleChildScrollView) *inside* [child]
/// so the constraint sizes the scroll viewport, not individual list items.
class OverlayShell extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const OverlayShell({
    super.key,
    required this.child,
    this.maxWidth = 520,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Body region that vertically centers its [child] when it's shorter than the
/// available height, and scrolls when it's taller. Drop this inside an
/// [Expanded] (under [OverlayShell]) in place of a plain
/// `SingleChildScrollView(child: Column(...))` so short screens stop gluing
/// their content to the top — which leaves an ugly empty void on tall tablets.
///
/// [child] should be a `Column(mainAxisSize: MainAxisSize.min, ...)` (the
/// natural-height body). Pass [padding] for the scroll viewport's inset.
class CenterableScroll extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const CenterableScroll({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxHeight - padding.vertical;
        return SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: available.isFinite && available > 0 ? available : 0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [child],
            ),
          ),
        );
      },
    );
  }
}
