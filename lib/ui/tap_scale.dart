import 'package:flutter/material.dart';

class TapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final HitTestBehavior behavior;

  /// When set, guarantees a minimum hit-/touch-area of [minSize]×[minSize]
  /// logical pixels by wrapping the (centered) child in a [ConstrainedBox].
  /// The child's own visual size is left untouched — only the tappable area
  /// is grown if it would otherwise be smaller. Leave null for the original
  /// behaviour (no extra constraints).
  final double? minSize;

  /// When true, the button fires [onTap] on pointer-up anywhere within its
  /// bounds — even if the finger drifted past the tap slop in between (a
  /// "swipe-ish" press). Uses a raw [Listener] instead of a tap recognizer so
  /// it can't be cancelled by movement or lose a gesture-arena race. Use this
  /// for critical modal buttons (e.g. the pause overlay's RESUME / QUIT) where
  /// a stationary tap can't be relied upon.
  final bool movementTolerant;

  const TapScale({
    super.key,
    required this.child,
    this.onTap,
    this.behavior = HitTestBehavior.opaque,
    this.minSize,
    this.movementTolerant = false,
  });

  @override
  State<TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<TapScale> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    // Press feedback dims (tints) the button content — no scale/zoom.
    _opacity = Tween<double>(begin: 1.0, end: 0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    if (widget.onTap != null) _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() => _controller.reverse();

  // ── Movement-tolerant (Listener) handlers ──
  void _onPointerDown(PointerDownEvent _) {
    if (widget.onTap != null) _controller.forward();
  }

  void _onPointerUp(PointerUpEvent event) {
    _controller.reverse();
    if (widget.onTap == null) return;
    // Only fire if the release lands within this button's bounds — pressing
    // then dragging far away and releasing should NOT trigger it.
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) {
      widget.onTap!.call();
      return;
    }
    final local = box.globalToLocal(event.position);
    if (local.dx >= 0 &&
        local.dy >= 0 &&
        local.dx <= box.size.width &&
        local.dy <= box.size.height) {
      widget.onTap!.call();
    }
  }

  void _onPointerCancel(PointerCancelEvent _) => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    Widget content = widget.child;
    if (widget.minSize != null) {
      // Grow only the hit-/touch-area; keep the child visually centered and
      // at its intrinsic size.
      content = ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: widget.minSize!,
          minHeight: widget.minSize!,
        ),
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: widget.child,
        ),
      );
    }

    final visual = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: _opacity.value,
        child: child,
      ),
      child: content,
    );

    if (widget.movementTolerant) {
      return Listener(
        behavior: widget.behavior,
        onPointerDown: _onPointerDown,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: visual,
      );
    }

    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: visual,
    );
  }
}
