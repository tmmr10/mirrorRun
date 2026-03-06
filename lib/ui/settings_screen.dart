import 'dart:math';
import 'package:flutter/material.dart';
import '../game/mirror_run_game.dart';

class SettingsScreen extends StatefulWidget {
  final MirrorRunGame game;
  const SettingsScreen({super.key, required this.game});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _accent = Color(0xFFB48CFF);
  bool _helpExpanded = false;

  @override
  Widget build(BuildContext context) {
    final settings = widget.game.settingsService;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xF00a0a0f), Color(0xF0080812), Color(0xF00f0a14)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: CustomScrollView(
            slivers: [
              SliverList(
                delegate: SliverChildListDelegate([
              // Title
              Text(
                'SETTINGS',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _accent,
                  letterSpacing: 6,
                ),
              ),
              const SizedBox(height: 40),

              // Sound toggle
              _buildToggleRow(
                'SOUND',
                settings.soundEnabled,
                (v) {
                  settings.setSoundEnabled(v);
                  setState(() {});
                },
              ),
              const SizedBox(height: 20),

              // Haptic toggle
              _buildToggleRow(
                'VIBRATION',
                settings.hapticEnabled,
                (v) {
                  settings.setHapticEnabled(v);
                  setState(() {});
                },
              ),
              const SizedBox(height: 32),

              // Help section
              _buildDivider(),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => setState(() => _helpExpanded = !_helpExpanded),
                child: Row(
                  children: [
                    Text(
                      'HOW TO PLAY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _helpExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.white.withValues(alpha: 0.4),
                      size: 18,
                    ),
                  ],
                ),
              ),
              if (_helpExpanded) ...[
                const SizedBox(height: 16),
                // Mirror movement illustration
                _HelpSection(
                  illustration: const _MirrorIllustration(),
                  title: 'MIRROR MOVEMENT',
                  description: 'Drag left or right. Both runners move at the same time — mirrored. Dodge obstacles on both sides.',
                ),
                const SizedBox(height: 20),
                // Phantom illustration
                _HelpSection(
                  illustration: const _PhantomIllustration(),
                  title: 'PHANTOM',
                  description: 'Obstacles turn invisible. Memorize their positions before they fade!',
                ),
                const SizedBox(height: 20),
                // Swap illustration
                _HelpSection(
                  illustration: const _SwapIllustration(),
                  title: 'SWAP',
                  description: 'Controls are reversed. Left becomes right, right becomes left.',
                ),
              ],
              const SizedBox(height: 24),

              const SizedBox(height: 8),

              // Leaderboard
              _buildDivider(),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => widget.game.leaderboardService.showLeaderboard(),
                child: Text(
                  'LEADERBOARD',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 3,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Achievements
              _buildDivider(),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => widget.game.leaderboardService.showAchievements(),
                child: Text(
                  'ACHIEVEMENTS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 3,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Statistics
              _buildDivider(),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  widget.game.overlays.remove('SettingsScreen');
                  widget.game.overlays.add('StatsScreen');
                },
                child: Text(
                  'STATISTICS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 3,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Restore purchases
              if (!widget.game.adService.isAdFree) ...[
                _buildDivider(),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => widget.game.adService.restorePurchases(),
                  child: Text(
                    'RESTORE PURCHASES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.7),
                      letterSpacing: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              const SizedBox(height: 40),

              // Credits
              Center(
                child: Text(
                  'MIRROR RUN\nby tmmr',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.25),
                    letterSpacing: 2,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Licenses
              Center(
                child: GestureDetector(
                  onTap: () {
                    showLicensePage(
                      context: context,
                      applicationName: 'Mirror Runners',
                      applicationVersion: '1.0.0',
                    );
                  },
                  child: Text(
                    'LICENSES',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.35),
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Back button
              Center(
                child: GestureDetector(
                  onTap: () {
                    widget.game.overlays.remove('SettingsScreen');
                    widget.game.overlays.add('MenuScreen');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border.all(color: _accent.withValues(alpha: 0.3), width: 0.5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'BACK',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _accent.withValues(alpha: 0.7),
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ),
              ),
            ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 3,
            ),
          ),
          Container(
            width: 40,
            height: 22,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: value ? _accent.withValues(alpha: 0.6) : Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
              color: value ? _accent.withValues(alpha: 0.2) : Colors.transparent,
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 150),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value ? _accent : Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 0.5,
      color: Colors.white.withValues(alpha: 0.08),
    );
  }
}

class _HelpSection extends StatelessWidget {
  final Widget illustration;
  final String title;
  final String description;

  const _HelpSection({
    required this.illustration,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          height: 64,
          child: illustration,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFB48CFF).withValues(alpha: 0.7),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.45),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Mirror movement illustration ──
class _MirrorIllustration extends StatelessWidget {
  const _MirrorIllustration();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _MirrorPainter());
  }
}

class _MirrorPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final mid = w / 2;

    // Mirror line
    final mirrorPaint = Paint()
      ..color = const Color(0x40B48CFF)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(mid, 0), Offset(mid, h), mirrorPaint);

    // Ground line
    final groundY = h * 0.78;
    final groundPaint = Paint()
      ..color = const Color(0x30FFFFFF)
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(0, groundY), Offset(w, groundY), groundPaint);

    // Left player (orange)
    final lpx = mid * 0.45;
    _drawPlayer(canvas, lpx, groundY - 4, const Color(0xFFff6b35));

    // Right player (purple) — mirrored
    final rpx = mid + (mid - lpx);
    _drawPlayer(canvas, rpx, groundY - 4, const Color(0xFF9966ff));

    // Arrow showing drag direction (left)
    final arrowPaint = Paint()
      ..color = const Color(0x60FFFFFF)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final arrowY = groundY + 10;
    canvas.drawLine(Offset(lpx + 12, arrowY), Offset(lpx - 6, arrowY), arrowPaint);
    canvas.drawLine(Offset(lpx - 6, arrowY), Offset(lpx - 1, arrowY - 3), arrowPaint);
    canvas.drawLine(Offset(lpx - 6, arrowY), Offset(lpx - 1, arrowY + 3), arrowPaint);

    // Arrow on right side (mirrored — goes right)
    canvas.drawLine(Offset(rpx - 12, arrowY), Offset(rpx + 6, arrowY), arrowPaint);
    canvas.drawLine(Offset(rpx + 6, arrowY), Offset(rpx + 1, arrowY - 3), arrowPaint);
    canvas.drawLine(Offset(rpx + 6, arrowY), Offset(rpx + 1, arrowY + 3), arrowPaint);

    // Obstacles
    final obsL = Paint()..color = const Color(0x602d8c3a);
    canvas.drawRect(Rect.fromLTWH(mid * 0.7, groundY - 22, 8, 18), obsL);
    final obsR = Paint()..color = const Color(0x602d3a8c);
    canvas.drawRect(Rect.fromLTWH(mid + mid * 0.2, groundY - 22, 8, 18), obsR);
  }

  void _drawPlayer(Canvas canvas, double x, double y, Color color) {
    // Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x - 4, y - 14, 8, 14), const Radius.circular(2)),
      Paint()..color = color,
    );
    // Glow
    canvas.drawCircle(Offset(x, y - 7), 6,
      Paint()..color = color.withValues(alpha: 0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Phantom illustration ──
class _PhantomIllustration extends StatelessWidget {
  const _PhantomIllustration();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _PhantomPainter());
  }
}

class _PhantomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final mid = w / 2;

    // Mirror line
    canvas.drawLine(Offset(mid, 0), Offset(mid, h),
      Paint()..color = const Color(0x40B48CFF)..strokeWidth = 1);

    // Ground
    final groundY = h * 0.78;
    canvas.drawLine(Offset(0, groundY), Offset(w, groundY),
      Paint()..color = const Color(0x30FFFFFF)..strokeWidth = 0.5);

    // Solid obstacle (before)
    final solidPaint = Paint()..color = const Color(0xFF2d8c3a);
    canvas.drawRect(Rect.fromLTWH(8, groundY - 20, 10, 16), solidPaint);

    // Arrow showing transition
    final arrowPaint = Paint()
      ..color = const Color(0x50FFFFFF)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(24, groundY - 12), Offset(32, groundY - 12), arrowPaint);
    canvas.drawLine(Offset(32, groundY - 12), Offset(29, groundY - 15), arrowPaint);
    canvas.drawLine(Offset(32, groundY - 12), Offset(29, groundY - 9), arrowPaint);

    // Ghost obstacle (after) — dashed/faded
    final ghostPaint = Paint()
      ..color = const Color(0x202d8c3a)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(Rect.fromLTWH(36, groundY - 20, 10, 16), ghostPaint);
    // Question mark
    final textPainter = TextPainter(
      text: TextSpan(
        text: '?',
        style: TextStyle(
          fontSize: 10,
          color: Colors.white.withValues(alpha: 0.3),
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset(39, groundY - 18));

    // "PHANTOM" label glow
    final glowPaint = Paint()
      ..color = const Color(0x15B48CFF)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(mid + mid * 0.4, h * 0.4), 16, glowPaint);

    // Right side ghost obstacles
    final ghostR = Paint()
      ..color = const Color(0x202d3a8c)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(Rect.fromLTWH(mid + 10, groundY - 20, 10, 16), ghostR);
    canvas.drawRect(Rect.fromLTWH(mid + 28, groundY - 18, 8, 14), ghostR);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Swap illustration ──
class _SwapIllustration extends StatelessWidget {
  const _SwapIllustration();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SwapPainter());
  }
}

class _SwapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final mid = w / 2;

    // Mirror line
    canvas.drawLine(Offset(mid, 0), Offset(mid, h),
      Paint()..color = const Color(0x40B48CFF)..strokeWidth = 1);

    // Ground
    final groundY = h * 0.78;
    canvas.drawLine(Offset(0, groundY), Offset(w, groundY),
      Paint()..color = const Color(0x30FFFFFF)..strokeWidth = 0.5);

    // Players
    final lpx = mid * 0.5;
    final rpx = mid + mid * 0.5;

    // Left player
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(lpx - 4, groundY - 18, 8, 14), const Radius.circular(2)),
      Paint()..color = const Color(0xFFff6b35),
    );
    // Right player
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(rpx - 4, groundY - 18, 8, 14), const Radius.circular(2)),
      Paint()..color = const Color(0xFF9966ff),
    );

    // Crossed arrows showing swapped controls
    final arrowPaint = Paint()
      ..color = const Color(0xCCFF4444)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Drag left arrow under left player
    final ay = groundY + 8;
    canvas.drawLine(Offset(lpx - 8, ay), Offset(lpx + 8, ay), arrowPaint);
    // Arrow points RIGHT (inverted!)
    canvas.drawLine(Offset(lpx + 8, ay), Offset(lpx + 4, ay - 3), arrowPaint);
    canvas.drawLine(Offset(lpx + 8, ay), Offset(lpx + 4, ay + 3), arrowPaint);

    // Drag right arrow under right player
    canvas.drawLine(Offset(rpx + 8, ay), Offset(rpx - 8, ay), arrowPaint);
    // Arrow points LEFT (inverted!)
    canvas.drawLine(Offset(rpx - 8, ay), Offset(rpx - 4, ay - 3), arrowPaint);
    canvas.drawLine(Offset(rpx - 8, ay), Offset(rpx - 4, ay + 3), arrowPaint);

    // Swap icon (crossed arrows) in center
    final swapCol = const Color(0x80FF4444);
    final cx = mid;
    final cy = h * 0.3;
    // X shape
    canvas.drawLine(Offset(cx - 8, cy - 6), Offset(cx + 8, cy + 6),
      Paint()..color = swapCol..strokeWidth = 1.5);
    canvas.drawLine(Offset(cx + 8, cy - 6), Offset(cx - 8, cy + 6),
      Paint()..color = swapCol..strokeWidth = 1.5);
    // Arrow tips
    canvas.drawLine(Offset(cx + 8, cy + 6), Offset(cx + 4, cy + 4),
      Paint()..color = swapCol..strokeWidth = 1.5);
    canvas.drawLine(Offset(cx - 8, cy + 6), Offset(cx - 4, cy + 4),
      Paint()..color = swapCol..strokeWidth = 1.5);

    // Warning glow
    canvas.drawCircle(Offset(cx, cy), 14,
      Paint()..color = const Color(0x10FF4444)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
