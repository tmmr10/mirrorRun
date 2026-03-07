import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../game/mirror_run_game.dart';
import '../game/world/biome.dart';
import 'tap_scale.dart';

class DeathScreen extends StatefulWidget {
  final MirrorRunGame game;
  const DeathScreen({super.key, required this.game});

  @override
  State<DeathScreen> createState() => _DeathScreenState();
}

class _DeathScreenState extends State<DeathScreen> {
  bool _canInteract = false;
  bool _adWasShown = false;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _canInteract = true);
    });
    widget.game.adService.onAdFreeChanged = () {
      if (mounted) setState(() {});
    };
    final adService = widget.game.adService;
    if (adService.shouldShowAd(widget.game.lastRunDuration)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        adService.showAd(() {
          if (mounted) setState(() => _adWasShown = true);
        });
      });
    }
  }

  @override
  void dispose() {
    widget.game.adService.onAdFreeChanged = null;
    super.dispose();
  }

  void _retry() {
    if (!_canInteract) return;
    widget.game.startGame();
  }

  String _getMotivationalText(int score) {
    if (score < 30) return 'KEEP GOING';
    if (score < 100) return 'NOT BAD';
    if (score < 250) return 'NICE RUN';
    if (score < 500) return 'IMPRESSIVE';
    if (score < 1000) return 'INCREDIBLE';
    if (score < 2000) return 'UNSTOPPABLE';
    return 'LEGENDARY';
  }

  void _menu() {
    if (!_canInteract) return;
    widget.game.goToMenu();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _retry,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.8,
            colors: [
              const Color(0xE0100008),
              const Color(0xE0000000),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 4),

              // Score section
              _buildScoreSection(),

              const Spacer(flex: 3),

              // Action buttons
              _buildActions(),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreSection() {
    return ValueListenableBuilder<int>(
      valueListenable: widget.game.scoreNotifier,
      builder: (context, score, child) {
        final skin = widget.game.skinService.currentSkin;
        final leftColor = skin.leftColor;
        final rightColor = skin.rightColor;

        return Column(
          children: [
            // Red accent line
            Container(
              width: 60,
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFFFF3333).withValues(alpha: 0.6),
                    Colors.transparent,
                  ],
                ),
              ),
            )
                .animate()
                .scaleX(begin: 0, end: 1, duration: 400.ms, delay: 600.ms, curve: Curves.easeOutCubic),

            const SizedBox(height: 20),

            // Motivational text
            Text(
              _getMotivationalText(score),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.45),
                letterSpacing: 5,
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 500.ms),

            const SizedBox(height: 12),

            // Score number
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [leftColor, Colors.white, rightColor],
                stops: const [0.0, 0.5, 1.0],
              ).createShader(bounds),
              child: Text(
                '$score',
                style: const TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 4,
                  height: 1,
                  shadows: [
                    Shadow(color: Colors.white24, blurRadius: 20),
                  ],
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 300.ms, delay: 800.ms)
                .scale(begin: const Offset(1.5, 1.5), end: const Offset(1, 1), duration: 400.ms, delay: 800.ms, curve: Curves.easeOutCubic),

            const SizedBox(height: 8),

            // "METER" with gradient lines
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 0.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        leftColor.withValues(alpha: 0.4),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'METER',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.5),
                    letterSpacing: 8,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 24,
                  height: 0.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        rightColor.withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ],
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 1000.ms),

            const SizedBox(height: 16),

            // New record badge
            ValueListenableBuilder<bool>(
              valueListenable: widget.game.newRecordNotifier,
              builder: (context, isNew, child) {
                if (!isNew) return const SizedBox(height: 28);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFFFCC44).withValues(alpha: 0.5),
                      width: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(2),
                    color: const Color(0xFFFFCC44).withValues(alpha: 0.06),
                  ),
                  child: const Text(
                    'NEW RECORD',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFFCC44),
                      letterSpacing: 4,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 300.ms, delay: 1200.ms)
                    .shimmer(duration: 1500.ms, delay: 1400.ms, color: const Color(0x40FFCC44));
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        // Tap to retry prompt
        Column(
          children: [
            Icon(
              Icons.keyboard_arrow_up_rounded,
              color: Colors.white.withValues(alpha: 0.4),
              size: 28,
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .moveY(begin: 0, end: -6, duration: 800.ms, curve: Curves.easeInOut),
            const SizedBox(height: 4),
            Text(
              'TAP TO RETRY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.5),
                letterSpacing: 4,
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fadeIn(duration: 1200.ms)
                .then()
                .fadeOut(duration: 1200.ms),
          ],
        )
            .animate()
            .fadeIn(duration: 400.ms, delay: 1600.ms),

        const SizedBox(height: 28),

        // Button row
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionButton(
              onTap: _menu,
              label: 'MENU',
              icon: null,
              color: Colors.white.withValues(alpha: 0.35),
              borderColor: Colors.white.withValues(alpha: 0.1),
              delay: 1800,
            ),
            const SizedBox(width: 10),
            _buildActionButton(
              onTap: () {
                if (_canInteract) widget.game.leaderboardService.showLeaderboard();
              },
              label: 'RANKS',
              icon: Icons.leaderboard_rounded,
              color: const Color(0xFFB48CFF).withValues(alpha: 0.5),
              borderColor: const Color(0xFFB48CFF).withValues(alpha: 0.2),
              delay: 1900,
            ),
            const SizedBox(width: 10),
            _buildActionButton(
              onTap: () {
                if (!_canInteract) return;
                try {
                  final score = widget.game.scoreNotifier.value;
                  final biomeIdx = BiomeManager.getBiomeIndex(score);
                  final biomeName = BiomeManager.biomes[biomeIdx].name;
                  Share.share('I ran ${score}m through $biomeName in Mirror Runners!');
                } catch (_) {}
              },
              label: 'SHARE',
              icon: Icons.share_rounded,
              color: const Color(0xFFff6b35).withValues(alpha: 0.6),
              borderColor: const Color(0xFFff6b35).withValues(alpha: 0.3),
              delay: 2000,
            ),
          ],
        ),

        // Ad-free hint
        if (_adWasShown && !widget.game.adService.isAdFree) ...[
          const SizedBox(height: 20),
          TapScale(
            onTap: _isPurchasing ? null : () async {
              setState(() => _isPurchasing = true);
              await widget.game.adService.purchaseAdFree();
              if (mounted) setState(() => _isPurchasing = false);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFB48CFF).withValues(alpha: 0.3),
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(4),
                color: const Color(0xFFB48CFF).withValues(alpha: 0.06),
              ),
              child: _isPurchasing
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: const Color(0xFFB48CFF).withValues(alpha: 0.5),
                      ),
                    )
                  : Text(
                      'REMOVE ADS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFB48CFF).withValues(alpha: 0.7),
                        letterSpacing: 3,
                      ),
                    ),
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    required String label,
    required IconData? icon,
    required Color color,
    required Color borderColor,
    required int delay,
  }) {
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 0.5),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: Duration(milliseconds: delay));
  }
}
