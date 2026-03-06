import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'event_system.dart';
import '../mirror_run_game.dart';

class MirrorLine extends PositionComponent with HasGameReference<MirrorRunGame> {
  static const double mid = 220;
  static const double vh = 640;
  int _frame = 0;

  MirrorLine() : super(
    position: Vector2(mid - 3, 0),
    size: Vector2(6, vh),
    priority: 50,
  );

  @override
  void update(double dt) {
    super.update(dt);
    _frame++;
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

  void _drawNormal(Canvas canvas) {
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
    canvas.drawRect(Rect.fromLTWH(0, 0, 6, vh), Paint()..shader = gradient);

    final alpha = (0.07 + 0.05 * sin(_frame * 0.06)) * 255;
    canvas.drawRect(
      Rect.fromLTWH(2, 0, 2, vh),
      Paint()..color = Color.fromARGB(alpha.toInt().clamp(0, 255), 255, 255, 255),
    );
  }

  void _drawWarning(Canvas canvas, EventSystem es) {
    final isPhantom = es.warningLabel == 'PHANTOM';
    final Color baseColor = isPhantom
        ? const Color(0xFF44DDFF)
        : const Color(0xFFFF5028);

    // Fast pulsing line
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
    canvas.drawRect(Rect.fromLTWH(0, 0, 6, vh), Paint()..shader = gradient);

    // Wide pulsing glow
    canvas.drawRect(
      Rect.fromLTWH(-12, 0, 30, vh),
      Paint()
        ..color = baseColor.withValues(alpha: pulse * 0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
  }

  void _drawPhantom(Canvas canvas, double fade) {
    const color = Color(0xFF44DDFF);
    final intensity = 0.3 + 0.3 * fade;

    // Ghostly flickering line
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
    canvas.drawRect(Rect.fromLTWH(0, 0, 6, vh), Paint()..shader = gradient);

    // Cyan glow
    canvas.drawRect(
      Rect.fromLTWH(-8, 0, 22, vh),
      Paint()
        ..color = color.withValues(alpha: (intensity * 0.12).clamp(0.0, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
  }

  void _drawSwap(Canvas canvas, EventSystem es) {
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
    canvas.drawRect(Rect.fromLTWH(0, 0, 6, vh), Paint()..shader = gradient);

    // Wide glow during swap
    if (es.mirrorSwapped) {
      final glowAlpha = (0.08 + 0.04 * sin(_frame * 0.1)).clamp(0.0, 1.0);
      canvas.drawRect(
        Rect.fromLTWH(-8, 0, 22, vh),
        Paint()
          ..color = color.withValues(alpha: glowAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }
  }

  void _drawRecovery(Canvas canvas, double flash) {
    // Bright white/purple burst that fades back to normal
    const normalColor = Color(0xFFD2BEFF);
    const flashColor = Color(0xFFFFFFFF);

    // Lerp from flash white to normal purple
    final t = 1 - flash; // 0=full flash, 1=normal
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
    canvas.drawRect(Rect.fromLTWH(0, 0, 6, vh), Paint()..shader = gradient);

    // Wide bright glow that shrinks
    final glowWidth = 30.0 * flash;
    final glowAlpha = (flash * 0.25).clamp(0.0, 1.0);
    canvas.drawRect(
      Rect.fromLTWH(-glowWidth / 2, 0, 6 + glowWidth, vh),
      Paint()
        ..color = flashColor.withValues(alpha: glowAlpha)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 + flash * 10),
    );
  }
}
