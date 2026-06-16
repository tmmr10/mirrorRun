import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../game/mirror_run_game.dart';
import '../game/world/biome.dart';
import '../l10n/game_l10n.dart';
import '../l10n/l10n_ext.dart';
import 'overlay_shell.dart';
import 'tap_scale.dart';
import 'theme.dart';

class SettingsScreen extends StatefulWidget {
  final MirrorRunGame game;
  const SettingsScreen({super.key, required this.game});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _helpExpanded = false;
  bool _biomesExpanded = false;
  bool _isRestoring = false;

  static const _accent = MR.accent;

  @override
  Widget build(BuildContext context) {
    final settings = widget.game.settingsService;

    return Container(
      decoration: const BoxDecoration(gradient: MR.bgGradient),
      child: SafeArea(
        child: OverlayShell(
          child: Column(
            children: [
              // Top bar with back button and title — pinned at the top
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Row(
                  children: [
                    TapScale(
                      onTap: () {
                        widget.game.overlays.remove('SettingsScreen');
                        widget.game.overlays.add('MenuScreen');
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Icon(
                          Icons.arrow_back_ios_rounded,
                          color: _accent.withValues(alpha: 0.5),
                          size: 20,
                        ),
                      ),
                    ),
                    Text(
                      context.l10n.settingsTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _accent,
                        letterSpacing: 6,
                      ),
                    ),
                  ],
                ),
              ),

              // Settings body — vertically centered when it fits, scrolls when taller
              Expanded(
                child: CenterableScroll(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
              // Sound toggle
              _buildToggleRow(
                context.l10n.settingsSound,
                settings.soundEnabled,
                (v) {
                  settings.setSoundEnabled(v);
                  setState(() {});
                },
              ),
              const SizedBox(height: 20),

              // Haptic toggle
              _buildToggleRow(
                context.l10n.settingsVibration,
                settings.hapticEnabled,
                (v) {
                  settings.setHapticEnabled(v);
                  setState(() {});
                },
              ),
              const SizedBox(height: 20),

              // Language selector
              _buildLanguageRow(context, settings),
              const SizedBox(height: 32),

              // Help section
              _buildDivider(),
              const SizedBox(height: 16),
              TapScale(
                minSize: MR.minTouchTarget,
                onTap: () => setState(() => _helpExpanded = !_helpExpanded),
                child: Row(
                  children: [
                    Text(
                      context.l10n.howtoTitle,
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
                  title: context.l10n.howtoMirrorTitle,
                  description: context.l10n.howtoMirrorDesc,
                ),
                const SizedBox(height: 20),
                // Phantom illustration
                _HelpSection(
                  illustration: const _PhantomIllustration(),
                  title: context.l10n.howtoPhantomTitle,
                  description: context.l10n.howtoPhantomDesc,
                ),
                const SizedBox(height: 20),
                // Swap illustration
                _HelpSection(
                  illustration: const _SwapIllustration(),
                  title: context.l10n.howtoSwapTitle,
                  description: context.l10n.howtoSwapDesc,
                ),
                const SizedBox(height: 20),
                // Desync event
                _HelpSection(
                  illustration: const _DesyncIllustration(),
                  title: context.l10n.howtoDesyncTitle,
                  description: context.l10n.howtoDesyncDesc,
                ),
                const SizedBox(height: 20),
                // Blackout event
                _HelpSection(
                  illustration: const _BlackoutIllustration(),
                  title: context.l10n.howtoBlackoutTitle,
                  description: context.l10n.howtoBlackoutDesc,
                ),
                const SizedBox(height: 24),
                // Power-ups sub-header
                Text(
                  context.l10n.howtoPowerUps,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.7),
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 16),
                // Shield
                _HelpSection(
                  illustration: const _PowerUpOrb(kind: _OrbKind.shield),
                  title: context.l10n.howtoShieldTitle,
                  description: context.l10n.howtoShieldDesc,
                ),
                const SizedBox(height: 20),
                // Sync-lock
                _HelpSection(
                  illustration: const _PowerUpOrb(kind: _OrbKind.syncLock),
                  title: context.l10n.howtoSyncLockTitle,
                  description: context.l10n.howtoSyncLockDesc,
                ),
                const SizedBox(height: 20),
                // Slow-mo
                _HelpSection(
                  illustration: const _PowerUpOrb(kind: _OrbKind.slowMo),
                  title: context.l10n.howtoSlowMoTitle,
                  description: context.l10n.howtoSlowMoDesc,
                ),
                const SizedBox(height: 20),
                // Foresight
                _HelpSection(
                  illustration: const _PowerUpOrb(kind: _OrbKind.foresight),
                  title: context.l10n.howtoForesightTitle,
                  description: context.l10n.howtoForesightDesc,
                ),
              ],
              const SizedBox(height: 24),

              // Biomes overview
              _buildDivider(),
              const SizedBox(height: 16),
              TapScale(
                minSize: MR.minTouchTarget,
                onTap: () => setState(() => _biomesExpanded = !_biomesExpanded),
                child: Row(
                  children: [
                    Text(
                      context.l10n.settingsBiomes,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _biomesExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.white.withValues(alpha: 0.4),
                      size: 18,
                    ),
                  ],
                ),
              ),
              if (_biomesExpanded) ...[
                const SizedBox(height: 16),
                ...BiomeManager.biomes.map((b) {
                  final isLast = b == BiomeManager.biomes.last;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: b.lineL,
                            boxShadow: [
                              BoxShadow(
                                color: b.lineL.withValues(alpha: 0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          biomeNameLocalized(context, b.name),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: b.lineL.withValues(alpha: 0.9),
                            letterSpacing: 2,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          isLast ? '${b.startM}m +' : '${b.startM}m',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.35),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              const SizedBox(height: 24),

              // Leaderboard (iOS only — Google Play Games not yet configured)
              if (defaultTargetPlatform != TargetPlatform.android) ...[
                _buildDivider(),
                const SizedBox(height: 16),
                TapScale(
                  minSize: MR.minTouchTarget,
                  onTap: () => widget.game.leaderboardService.showLeaderboard(),
                  child: Text(
                    context.l10n.settingsLeaderboard,
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

              const SizedBox(height: 24),

              // Statistics
              _buildDivider(),
              const SizedBox(height: 16),
              TapScale(
                minSize: MR.minTouchTarget,
                onTap: () {
                  widget.game.overlays.remove('SettingsScreen');
                  widget.game.overlays.add('StatsScreen');
                },
                child: Text(
                  context.l10n.settingsStatistics,
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
              if (!widget.game.adService.isPro) ...[
                _buildDivider(),
                const SizedBox(height: 16),
                TapScale(
                  minSize: MR.minTouchTarget,
                  onTap: _isRestoring ? null : _restore,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _isRestoring
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          )
                        : Text(
                            context.l10n.settingsRestorePurchases,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.7),
                              letterSpacing: 3,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              const SizedBox(height: 40),

              // Credits
              Center(
                child: Text(
                  'MIRROR RUNNERS\nby tmmr',
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
                child: TapScale(
                  minSize: MR.minTouchTarget,
                  onTap: () => _showLicenses(context),
                  child: Text(
                    context.l10n.settingsLicenses,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.55),
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _restore() async {
    setState(() => _isRestoring = true);
    await widget.game.adService.restorePurchases();
    if (mounted) {
      setState(() => _isRestoring = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.game.adService.isPro
                ? context.l10n.settingsPurchasesRestored
                : context.l10n.settingsRestoreComplete,
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Opens the licenses page inside a dark theme so it matches the app's
  /// look instead of breaking out into Material's bright default theme.
  void _showLicenses(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (ctx) => Theme(
          data: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: MR.accent,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: MR.bgMid,
          ),
          child: const LicensePage(
            applicationName: 'Mirror Runners',
            applicationVersion: '1.0.0',
          ),
        ),
      ),
    );
  }

  Widget _buildToggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return TapScale(
      minSize: MR.minTouchTarget,
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

  /// Tappable row showing the current language choice; opens a small sheet
  /// to pick System / English / Deutsch. Styled like the navigation rows.
  Widget _buildLanguageRow(BuildContext context, dynamic settings) {
    final override = settings.localeOverride as String?;
    final valueLabel = override == 'en'
        ? context.l10n.languageEnglish
        : override == 'de'
            ? context.l10n.languageGerman
            : context.l10n.languageSystem;
    return TapScale(
      minSize: MR.minTouchTarget,
      onTap: () => _showLanguageSheet(context, settings),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            context.l10n.languageTitle,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 3,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                valueLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _accent.withValues(alpha: 0.8),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withValues(alpha: 0.4),
                size: 18,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLanguageSheet(BuildContext context, dynamic settings) {
    final current = settings.localeOverride as String?;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: MR.bgMid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        Widget option(String label, String? code) {
          final selected = current == code;
          return TapScale(
            minSize: MR.minTouchTarget,
            onTap: () {
              settings.setLocaleOverride(code);
              Navigator.of(ctx).pop();
              setState(() {});
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: selected ? 0.95 : 0.7),
                      letterSpacing: 1,
                    ),
                  ),
                  if (selected)
                    Icon(Icons.check_rounded, color: _accent, size: 18),
                ],
              ),
            ),
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    ctx.l10n.languageTitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _accent,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              option(ctx.l10n.languageSystem, null),
              option(ctx.l10n.languageEnglish, 'en'),
              option(ctx.l10n.languageGerman, 'de'),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
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
                  color: MR.accent.withValues(alpha: 0.7),
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

// ── Desync illustration ──
class _DesyncIllustration extends StatelessWidget {
  const _DesyncIllustration();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _DesyncPainter());
  }
}

class _DesyncPainter extends CustomPainter {
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

    // Left player — sits higher (faster scroll)
    final lpx = mid * 0.5;
    _drawPlayer(canvas, lpx, groundY - 16, MR.danger);
    // Right player — sits lower (slower scroll)
    final rpx = mid + mid * 0.5;
    _drawPlayer(canvas, rpx, groundY, const Color(0xFF9966ff));

    // Arrows of different length showing different speeds
    final arrowPaint = Paint()
      ..color = const Color(0x80B48CFF)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    // Left: long arrow (fast)
    _arrowDown(canvas, lpx, groundY + 6, 14, arrowPaint);
    // Right: short arrow (slow)
    _arrowDown(canvas, rpx, groundY + 6, 7, arrowPaint);
  }

  void _arrowDown(Canvas canvas, double x, double y, double len, Paint p) {
    canvas.drawLine(Offset(x, y), Offset(x, y + len), p);
    canvas.drawLine(Offset(x, y + len), Offset(x - 3, y + len - 3), p);
    canvas.drawLine(Offset(x, y + len), Offset(x + 3, y + len - 3), p);
  }

  void _drawPlayer(Canvas canvas, double x, double y, Color color) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x - 4, y - 14, 8, 14), const Radius.circular(2)),
      Paint()..color = color,
    );
    canvas.drawCircle(Offset(x, y - 7), 6,
      Paint()..color = color.withValues(alpha: 0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Blackout illustration ──
class _BlackoutIllustration extends StatelessWidget {
  const _BlackoutIllustration();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _BlackoutPainter());
  }
}

class _BlackoutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final mid = w / 2;

    // Ground
    final groundY = h * 0.78;
    canvas.drawLine(Offset(0, groundY), Offset(w, groundY),
      Paint()..color = const Color(0x30FFFFFF)..strokeWidth = 0.5);

    // Left player (lit, orange)
    final lpx = mid * 0.5;
    _drawPlayer(canvas, lpx, groundY, MR.danger, 1.0);

    // Right player (barely visible in the dark)
    final rpx = mid + mid * 0.5;
    _drawPlayer(canvas, rpx, groundY, const Color(0xFF9966ff), 0.18);

    // Dark overlay over the right half
    final darkPaint = Paint()..color = const Color(0xE6000000);
    canvas.drawRect(Rect.fromLTWH(mid, 0, mid, h), darkPaint);

    // Mirror line (drawn over the overlay so it stays visible)
    canvas.drawLine(Offset(mid, 0), Offset(mid, h),
      Paint()..color = const Color(0x40B48CFF)..strokeWidth = 1);
  }

  void _drawPlayer(Canvas canvas, double x, double y, Color color, double alpha) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x - 4, y - 14, 8, 14), const Radius.circular(2)),
      Paint()..color = color.withValues(alpha: alpha),
    );
    canvas.drawCircle(Offset(x, y - 7), 6,
      Paint()..color = color.withValues(alpha: 0.2 * alpha)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Power-up orb illustration (mirrors the in-game PowerUp look) ──
enum _OrbKind { shield, syncLock, slowMo, foresight }

class _PowerUpOrb extends StatelessWidget {
  final _OrbKind kind;
  const _PowerUpOrb({required this.kind});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _PowerUpOrbPainter(kind));
  }
}

class _PowerUpOrbPainter extends CustomPainter {
  final _OrbKind kind;
  _PowerUpOrbPainter(this.kind);

  Color get _color {
    switch (kind) {
      case _OrbKind.shield:
        return MR.cyan;
      case _OrbKind.syncLock:
        return MR.accent;
      case _OrbKind.slowMo:
        return MR.gold;
      case _OrbKind.foresight:
        return const Color(0xFF66FFC2);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c = _color;
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 13.0;

    // Soft glow
    canvas.drawCircle(center, radius + 5,
      Paint()
        ..color = c.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

    // Dark fill
    canvas.drawCircle(center, radius,
      Paint()..color = const Color(0xFF0A0A12).withValues(alpha: 0.85));

    // Colored ring
    canvas.drawCircle(center, radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = c);

    _drawIcon(canvas, center, c);
  }

  void _drawIcon(Canvas canvas, Offset c, Color color) {
    final iconPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = color;
    switch (kind) {
      case _OrbKind.shield:
        final p = Path()
          ..moveTo(c.dx, c.dy - 5)
          ..lineTo(c.dx + 4, c.dy - 2)
          ..lineTo(c.dx + 4, c.dy + 1)
          ..quadraticBezierTo(c.dx + 4, c.dy + 5, c.dx, c.dy + 6)
          ..quadraticBezierTo(c.dx - 4, c.dy + 5, c.dx - 4, c.dy + 1)
          ..lineTo(c.dx - 4, c.dy - 2)
          ..close();
        canvas.drawPath(p, iconPaint);
      case _OrbKind.syncLock:
        for (final dx in [-3.0, 3.0]) {
          canvas.drawLine(Offset(c.dx + dx, c.dy - 4), Offset(c.dx + dx, c.dy + 4), iconPaint);
          canvas.drawLine(Offset(c.dx + dx, c.dy + 4), Offset(c.dx + dx - 2, c.dy + 1), iconPaint);
          canvas.drawLine(Offset(c.dx + dx, c.dy + 4), Offset(c.dx + dx + 2, c.dy + 1), iconPaint);
        }
      case _OrbKind.slowMo:
        canvas.drawCircle(c, 5, iconPaint);
        canvas.drawLine(c, Offset(c.dx, c.dy - 3.5), iconPaint);
        canvas.drawLine(c, Offset(c.dx + 2.5, c.dy), iconPaint);
      case _OrbKind.foresight:
        final eye = Path()
          ..moveTo(c.dx - 6, c.dy)
          ..quadraticBezierTo(c.dx, c.dy - 5, c.dx + 6, c.dy)
          ..quadraticBezierTo(c.dx, c.dy + 5, c.dx - 6, c.dy)
          ..close();
        canvas.drawPath(eye, iconPaint);
        canvas.drawCircle(c, 1.6, iconPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PowerUpOrbPainter oldDelegate) => oldDelegate.kind != kind;
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
    _drawPlayer(canvas, lpx, groundY - 4, MR.danger);

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
      Paint()..color = MR.danger,
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
