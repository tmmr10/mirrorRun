import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../game/mirror_run_game.dart';

class MenuScreen extends StatefulWidget {
  final MirrorRunGame game;
  const MenuScreen({super.key, required this.game});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with TickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFB48CFF);

    return GestureDetector(
      onTap: () => widget.game.startGame(),
      onVerticalDragEnd: (details) {
        if (details.velocity.pixelsPerSecond.dy < -100) {
          widget.game.startGame();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xF00a0a0f),
              const Color(0xF0080812),
              const Color(0xF00f0a14),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Vertical mirror line accent
            Positioned(
              left: MediaQuery.of(context).size.width / 2 - 0.5,
              top: 0,
              bottom: 0,
              child: AnimatedBuilder(
                animation: _shimmerController,
                builder: (context, child) {
                  final t = _shimmerController.value;
                  return Container(
                    width: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          accentColor.withValues(alpha: 0.0),
                          accentColor.withValues(alpha: 0.4 + 0.3 * sin(t * pi * 2)),
                          accentColor.withValues(alpha: 0.0),
                          Colors.transparent,
                        ],
                        stops: [
                          0.0,
                          (0.3 + t * 0.4).clamp(0.0, 0.95),
                          (0.4 + t * 0.4).clamp(0.05, 0.98),
                          (0.5 + t * 0.4).clamp(0.1, 1.0),
                          1.0,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title block
                  _buildTitle(accentColor),
                  const SizedBox(height: 56),

                  // Start prompt
                  _buildStartPrompt(accentColor),
                  const SizedBox(height: 48),

                  // Biome roadmap
                  _buildBiomeRoadmap(),
                ],
              ),
            ),

            // Settings gear
            Positioned(
              top: 48,
              right: 20,
              child: GestureDetector(
                onTap: () {
                  widget.game.overlays.remove('MenuScreen');
                  widget.game.overlays.add('SettingsScreen');
                },
                child: Icon(
                  Icons.settings,
                  color: accentColor.withValues(alpha: 0.5),
                  size: 24,
                ),
              ),
            ),

            // Remove ads button
            if (!widget.game.adService.isAdFree)
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () => widget.game.adService.purchaseAdFree(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.5),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.3),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Text(
                        'AD FREE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 3,
                          shadows: [
                            Shadow(color: accentColor.withValues(alpha: 0.8), blurRadius: 20),
                            Shadow(color: accentColor.withValues(alpha: 0.4), blurRadius: 40),
                          ],
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms, delay: 1600.ms),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitle(Color accent) {
    return Column(
      children: [
        // "MIRROR" reflected
        Text(
          'MIRROR',
          style: TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.w100,
            color: Colors.white.withValues(alpha: 0.15),
            letterSpacing: 18,
            height: 1,
          ),
        )
            .animate()
            .fadeIn(duration: 800.ms, delay: 200.ms)
            .slideY(begin: -0.3, end: 0, duration: 600.ms, curve: Curves.easeOutCubic),

        Transform(
          alignment: Alignment.center,
          transform: Matrix4.diagonal3Values(1.0, -1.0, 1.0),
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [accent.withValues(alpha: 0.5), Colors.transparent],
            ).createShader(bounds),
            child: Text(
              'MIRROR',
              style: TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w100,
                color: Colors.white,
                letterSpacing: 18,
                height: 1,
              ),
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 800.ms, delay: 400.ms),

        const SizedBox(height: 8),

        // Divider line
        Container(
          width: 180,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                accent.withValues(alpha: 0.8),
                Colors.transparent,
              ],
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 600.ms, delay: 600.ms)
            .scaleX(begin: 0, end: 1, duration: 500.ms, delay: 600.ms, curve: Curves.easeOutCubic),

        const SizedBox(height: 12),

        // "RUN" bold
        Text(
          'RUN',
          style: TextStyle(
            fontSize: 52,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 24,
            height: 1,
            shadows: [
              Shadow(color: accent.withValues(alpha: 0.6), blurRadius: 40),
              Shadow(color: accent.withValues(alpha: 0.3), blurRadius: 80),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 600.ms, delay: 500.ms)
            .slideY(begin: 0.3, end: 0, duration: 500.ms, curve: Curves.easeOutCubic),
      ],
    );
  }

  Widget _buildStartPrompt(Color accent) {
    return Column(
      children: [
        // Animated arrow up
        Icon(
          Icons.keyboard_arrow_up_rounded,
          color: accent.withValues(alpha: 0.5),
          size: 28,
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(begin: 0, end: -6, duration: 800.ms, curve: Curves.easeInOut),
        const SizedBox(height: 4),
        Text(
          'TAP TO START',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: accent.withValues(alpha: 0.7),
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
        .fadeIn(duration: 400.ms, delay: 1200.ms);
  }

  Widget _buildBiomeRoadmap() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: [
        _biomeChip('FOREST', const Color(0xFF2d8c3a)),
        _biomeDot(),
        _biomeChip('CITY', const Color(0xFF4a5a7a)),
        _biomeDot(),
        _biomeChip('CRYSTAL', const Color(0xFF40CCEE)),
        _biomeDot(),
        _biomeChip('VOLCANO', const Color(0xFFaa4422)),
        _biomeDot(),
        _biomeChip('DESERT', const Color(0xFFCC9933)),
        _biomeDot(),
        _biomeChip('OCEAN', const Color(0xFF1a6090)),
        _biomeDot(),
        _biomeChip('RUINS', const Color(0xFF5A8A5A)),
        _biomeDot(),
        _biomeChip('SPACE', const Color(0xFF2020aa)),
        _biomeDot(),
        _biomeChip('STORM', const Color(0xFF7744BB)),
        _biomeDot(),
        _biomeChip('NEON', const Color(0xFF8800ff)),
        _biomeDot(),
        _biomeChip('VOID', const Color(0xFF333333)),
      ],
    )
        .animate()
        .fadeIn(duration: 500.ms, delay: 1400.ms);
  }

  Widget _biomeChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: color.withValues(alpha: 0.6),
          letterSpacing: 1.5,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _biomeDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: 3,
        height: 3,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
