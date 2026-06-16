import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../game/mirror_run_game.dart';
import '../l10n/l10n_ext.dart';
import 'overlay_shell.dart';
import 'tap_scale.dart';
import 'theme.dart';

class ProScreen extends StatefulWidget {
  final MirrorRunGame game;
  const ProScreen({super.key, required this.game});

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  static const _gold = MR.gold;
  static const _accent = MR.accent;
  bool _isPurchasing = false;
  bool _isRestoring = false;

  @override
  void initState() {
    super.initState();
    widget.game.adService.proStatusNotifier.addListener(_onProStatus);
  }

  void _onProStatus() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.game.adService.proStatusNotifier.removeListener(_onProStatus);
    super.dispose();
  }

  void _close() {
    widget.game.overlays.remove('ProScreen');
  }

  Future<void> _purchase() async {
    setState(() => _isPurchasing = true);
    final success = await widget.game.adService.purchasePro();
    if (mounted) {
      setState(() => _isPurchasing = false);
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.proPurchaseFailed),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
                ? context.l10n.proPurchasesRestored
                : context.l10n.proRestoreComplete,
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPro = widget.game.adService.isPro;

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.9,
          colors: [Color(0xF5100a08), Color(0xF5000000)],
        ),
      ),
      child: SafeArea(
        child: OverlayShell(
          child: Column(
          children: [
            // Back button
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 16, right: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TapScale(
                  onTap: _close,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Icon(
                      Icons.arrow_back_ios_rounded,
                      color: _accent.withValues(alpha: 0.5),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 300.ms),

            // Scrollable body — vertically centered when it fits, scrolls when taller.
            Expanded(
              child: CenterableScroll(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
            // Crown icon with glow
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _gold.withValues(alpha: 0.2),
                    blurRadius: 40,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Icon(
                Icons.workspace_premium_rounded,
                color: _gold,
                size: 48,
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms, delay: 200.ms)
                .scale(
                  begin: const Offset(0.6, 0.6),
                  end: const Offset(1, 1),
                  duration: 500.ms,
                  delay: 200.ms,
                  curve: Curves.easeOutCubic,
                ),

            const SizedBox(height: 24),

            // Title
            Text(
              context.l10n.proTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _gold,
                letterSpacing: 4,
                shadows: [
                  Shadow(color: _gold.withValues(alpha: 0.4), blurRadius: 20),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 400.ms),

            const SizedBox(height: 8),

            Text(
              context.l10n.proSubtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.4),
                letterSpacing: 3,
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 500.ms),

            const SizedBox(height: 36),

            // Benefits — Skin Creator is the hero (highlighted).
            _buildBenefit(
              icon: Icons.brush_rounded,
              label: context.l10n.proBenefitSkinCreatorLabel,
              description: context.l10n.proBenefitSkinCreatorDesc,
              delay: 600,
              highlight: true,
            ),
            const SizedBox(height: 14),
            _buildBenefit(
              icon: Icons.block_rounded,
              label: context.l10n.proBenefitNoAdsLabel,
              description: context.l10n.proBenefitNoAdsDesc,
              delay: 700,
            ),
            const SizedBox(height: 14),
            _buildBenefit(
              icon: Icons.favorite_rounded,
              label: context.l10n.proBenefitFreeRevivesLabel,
              description: context.l10n.proBenefitFreeRevivesDesc,
              delay: 800,
            ),

            const SizedBox(height: 36),

            // Price badge + button OR active state
            if (isPro)
              _buildProActive()
            else ...[
              // Price
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _gold.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                  color: _gold.withValues(alpha: 0.06),
                ),
                child: Text(
                  context.l10n.proPriceLine(
                      widget.game.adService.proPrice ?? '\$2.99'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _gold.withValues(alpha: 0.8),
                    letterSpacing: 2,
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 900.ms),

              const SizedBox(height: 20),

              // GO PRO button — full width, matching the benefit cards above.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: TapScale(
                onTap: _isPurchasing ? null : _purchase,
                child: Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      colors: [
                        _gold.withValues(alpha: 0.5),
                        _gold.withValues(alpha: 0.3),
                      ],
                    ),
                    border: Border.all(
                      color: _gold.withValues(alpha: 0.6),
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _gold.withValues(alpha: 0.15),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: _isPurchasing
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        )
                      : Text(
                          context.l10n.proGoPro,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 4,
                          ),
                        ),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 1000.ms),
              ),

              const SizedBox(height: 20),

              // Restore
              TapScale(
                minSize: MR.minTouchTarget,
                onTap: _isRestoring ? null : _restore,
                child: _isRestoring
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      )
                    : Text(
                        context.l10n.proRestorePurchases,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withValues(alpha: 0.55),
                          letterSpacing: 2,
                        ),
                      ),
              ).animate().fadeIn(duration: 400.ms, delay: 1100.ms),
            ],
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

  Widget _buildBenefit({
    required IconData icon,
    required String label,
    required String description,
    required int delay,
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: highlight ? 16 : 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: highlight
                ? _gold.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.06),
            width: highlight ? 1 : 0.5,
          ),
          color: highlight
              ? _gold.withValues(alpha: 0.06)
              : Colors.white.withValues(alpha: 0.03),
          boxShadow: highlight
              ? [
                  BoxShadow(
                    color: _gold.withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(icon,
                color: highlight ? _gold : _gold.withValues(alpha: 0.7),
                size: highlight ? 26 : 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: highlight ? 12 : 11,
                          fontWeight: FontWeight.w700,
                          color: highlight
                              ? _gold
                              : Colors.white.withValues(alpha: 0.8),
                          letterSpacing: 2,
                        ),
                      ),
                      if (highlight) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _gold.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '★ ${context.l10n.proBest}',
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              color: _gold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: highlight ? 11 : 10,
                      color: Colors.white.withValues(alpha: highlight ? 0.6 : 0.35),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms, delay: Duration(milliseconds: delay))
        .slideX(begin: 0.1, end: 0, duration: 300.ms, delay: Duration(milliseconds: delay));
  }

  Widget _buildProActive() {
    return Column(
      children: [
        Icon(
          Icons.check_circle_rounded,
          color: _gold,
          size: 40,
        ),
        const SizedBox(height: 12),
        Text(
          context.l10n.proActive,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _gold,
            letterSpacing: 4,
            shadows: [
              Shadow(color: _gold.withValues(alpha: 0.4), blurRadius: 16),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms, delay: 600.ms);
  }
}
