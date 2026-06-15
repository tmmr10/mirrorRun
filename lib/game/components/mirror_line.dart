import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'event_system.dart';
import '../mirror_run_game.dart';

class MirrorLine extends PositionComponent with HasGameReference<MirrorRunGame> {
  static const double mid = 220;
  double get vh => MirrorRunGame.vh;
  int _frame = 0;

  // Reusable paints (avoid per-frame allocation in render()).
  // Shaders are dynamic per frame and reassigned each draw.
  final Paint _shaderPaint = Paint();
  final Paint _colorPaint = Paint();
  final Paint _glowPaint = Paint();
  final Paint _fadePaint = Paint();
  static final Paint _layerPaint = Paint();

  MirrorLine() : super(
    position: Vector2(mid - 3, 0),
    size: Vector2(6, 960),
    priority: 50,
  );

  @override
  void update(double dt) {
    super.update(dt);
    _frame = (_frame + 1) % 100000;
  }

  @override
  void render(Canvas canvas) {
    final es = game.eventSystem;

    // 1. Recovery flash: bright white/purple burst fading back to normal
    if (es.recoveryFlash > 0) {
      _drawRecovery(canvas, es.recoveryFlash);
      return;
    }

    // 2. Warning: line pulses in event color
    if (es.isWarning) {
      _drawWarning(canvas, es);
      return;
    }

    // 3. Active phantom: line turns cyan with ghostly flicker
    if (es.activeEvent == GameEvent.phantom) {
      _drawPhantom(canvas, es.phantomFade);
      return;
    }

    // 4. Active mirror swap: line turns red/orange
    if (es.mirrorSwapped || es.swapFlash > 0) {
      _drawSwap(canvas, es);
      return;
    }

    // 5. Normal state
    _drawNormal(canvas);
  }

  /// Fade-out mask: top 15% fades from transparent to opaque.
  void _applyTopFade(Canvas canvas) {
    canvas.saveLayer(Rect.fromLTWH(-20, 0, 46, vh), _layerPaint);
  }

  void _finishTopFade(Canvas canvas) {
    final fadeHeight = vh * 0.50;
    _fadePaint
      ..blendMode = BlendMode.dstIn
      ..shader = Gradient.linear(
        const Offset(0, 0),
        Offset(0, fadeHeight),
        const [Color(0x00FFFFFF), Color(0xFFFFFFFF)],
      );
    canvas.drawRect(Rect.fromLTWH(-20, 0, 46, fadeHeight), _fadePaint);
    canvas.restore();
  }

  void _drawNormal(Canvas canvas) {
    _applyTopFade(canvas);

    final gradient = Gradient.linear(
      const Offset(0, 0),
      const Offset(6, 0),
      const [
        Color(0x00A082FF),
        Color(0xF2D2BEFF),
        Color(0x00A082FF),
      ],
      const [0.0, 0.5, 1.0],
    );
    _shaderPaint.shader = gradient;
    canvas.drawRect(Rect.fromLTWH(0, 0, 6, vh), _shaderPaint);

    final alpha = (0.07 + 0.05 * sin(_frame * 0.06)) * 255;
    _colorPaint.color = Color.fromARGB(alpha.toInt().clamp(0, 255), 255, 255, 255);
    canvas.drawRect(Rect.fromLTWH(2, 0, 2, vh), _colorPaint);

    _finishTopFade(canvas);
  }

  void _drawWarning(Canvas canvas, EventSystem es) {
    _applyTopFade(canvas);

    final isPhantom = es.warningLabel == 'PHANTOM';
    final Color baseColor = isPhantom
        ? const Color(0xFF44DDFF)
        : const Color(0xFFFF5028);

    final pulse = (0.4 + 0.6 * ((sin(_frame * 0.3) + 1) / 2)).clamp(0.0, 1.0);

    final gradient = Gradient.linear(
      const Offset(0, 0),
      const Offset(6, 0),
      [
        baseColor.withValues(alpha: 0),
        baseColor.withValues(alpha: pulse),
        baseColor.withValues(alpha: 0),
      ],
      const [0.0, 0.5, 1.0],
    );
    _shaderPaint.shader = gradient;
    canvas.drawRect(Rect.fromLTWH(0, 0, 6, vh), _shaderPaint);

    _glowPaint
      ..color = baseColor.withValues(alpha: pulse * 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawRect(Rect.fromLTWH(-12, 0, 30, vh), _glowPaint);

    _finishTopFade(canvas);
  }

  void _drawPhantom(Canvas canvas, double fade) {
    _applyTopFade(canvas);

    const color = Color(0xFF44DDFF);
    final intensity = 0.3 + 0.3 * fade;

    final flicker = (sin(_frame * 0.2) * 0.15 + sin(_frame * 0.47) * 0.1).clamp(-0.2, 0.2);

    final gradient = Gradient.linear(
      const Offset(0, 0),
      const Offset(6, 0),
      [
        color.withValues(alpha: 0),
        color.withValues(alpha: (intensity + flicker).clamp(0.1, 1.0)),
        color.withValues(alpha: 0),
      ],
      const [0.0, 0.5, 1.0],
    );
    _shaderPaint.shader = gradient;
    canvas.drawRect(Rect.fromLTWH(0, 0, 6, vh), _shaderPaint);

    _glowPaint
      ..color = color.withValues(alpha: (intensity * 0.12).clamp(0.0, 1.0))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawRect(Rect.fromLTWH(-8, 0, 22, vh), _glowPaint);

    _finishTopFade(canvas);
  }

  void _drawSwap(Canvas canvas, EventSystem es) {
    _applyTopFade(canvas);

    const color = Color(0xFFFF5028);
    final flashAlpha = es.swapFlash > 0
        ? es.swapFlash
        : 0.3 + 0.15 * sin(_frame * 0.12);

    final gradient = Gradient.linear(
      const Offset(0, 0),
      const Offset(6, 0),
      [
        color.withValues(alpha: 0),
        color.withValues(alpha: flashAlpha.clamp(0.0, 1.0)),
        color.withValues(alpha: 0),
      ],
      const [0.0, 0.5, 1.0],
    );
    _shaderPaint.shader = gradient;
    canvas.drawRect(Rect.fromLTWH(0, 0, 6, vh), _shaderPaint);

    if (es.mirrorSwapped) {
      final glowAlpha = (0.08 + 0.04 * sin(_frame * 0.1)).clamp(0.0, 1.0);
      _glowPaint
        ..color = color.withValues(alpha: glowAlpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawRect(Rect.fromLTWH(-8, 0, 22, vh), _glowPaint);
    }

    _finishTopFade(canvas);
  }

  void _drawRecovery(Canvas canvas, double flash) {
    _applyTopFade(canvas);

    const normalColor = Color(0xFFD2BEFF);
    const flashColor = Color(0xFFFFFFFF);

    final t = 1 - flash;
    final centerAlpha = (1.0 - t * 0.05).clamp(0.0, 1.0);

    final gradient = Gradient.linear(
      const Offset(0, 0),
      const Offset(6, 0),
      [
        const Color(0x00000000),
        Color.lerp(flashColor, normalColor, t)!.withValues(alpha: centerAlpha),
        const Color(0x00000000),
      ],
      const [0.0, 0.5, 1.0],
    );
    _shaderPaint.shader = gradient;
    canvas.drawRect(Rect.fromLTWH(0, 0, 6, vh), _shaderPaint);

    final glowWidth = 30.0 * flash;
    final glowAlpha = (flash * 0.25).clamp(0.0, 1.0);
    _glowPaint
      ..color = flashColor.withValues(alpha: glowAlpha)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 + flash * 10);
    canvas.drawRect(
      Rect.fromLTWH(-glowWidth / 2, 0, 6 + glowWidth, vh),
      _glowPaint,
    );

    _finishTopFade(canvas);
  }
}
