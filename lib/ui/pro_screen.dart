import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../game/mirror_run_game.dart';
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
          const SnackBar(
            content: Text('Purchase failed. Please try again.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
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

            const Spacer(flex: 2),

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
              'MIRROR RUNNERS PRO',
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
              'ONE TIME PURCHASE — FOREVER',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.4),
                letterSpacing: 3,
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 500.ms),

            const SizedBox(height: 36),

            // Benefits
            _buildBenefit(
              icon: Icons.block_rounded,
              label: 'NO ADS',
              description: 'Remove all interstitial ads',
              delay: 600,
            ),
            const SizedBox(height: 14),
            _buildBenefit(
              icon: Icons.brush_rounded,
              label: 'CUSTOM SKINS',
              description: 'Create unlimited custom skins',
              delay: 700,
            ),
            const SizedBox(height: 14),
            _buildBenefit(
              icon: Icons.auto_awesome_rounded,
              label: 'FUTURE PERKS',
              description: 'All upcoming Pro features included',
              delay: 800,
            ),

            const Spacer(),

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
                  '${widget.game.adService.proPrice ?? '\$2.99'} · ONE TIME',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _gold.withValues(alpha: 0.8),
                    letterSpacing: 2,
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 900.ms),

              const SizedBox(height: 20),

              // GO PRO button
              TapScale(
                onTap: _isPurchasing ? null : _purchase,
                child: Container(
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
                      : const Text(
                          'GO PRO',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 4,
                          ),
                        ),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 1000.ms),

              const SizedBox(height: 20),

              // Restore
              TapScale(
                onTap: () => widget.game.adService.restorePurchases(),
                child: Text(
                  'RESTORE PURCHASES',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.25),
                    letterSpacing: 2,
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 1100.ms),
            ],

            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefit({
    required IconData icon,
    required String label,
    required String description,
    required int delay,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
            width: 0.5,
          ),
          color: Colors.white.withValues(alpha: 0.03),
        ),
        child: Row(
          children: [
            Icon(icon, color: _gold.withValues(alpha: 0.7), size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.8),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.35),
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
          'PRO ACTIVE',
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
