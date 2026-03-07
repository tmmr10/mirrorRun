import 'package:flutter/material.dart';
import '../game/mirror_run_game.dart';
import '../game/world/biome.dart';
import '../models/player_skin.dart';
import '../utils/screenshot_tour.dart';
import 'tap_scale.dart';

class DebugOverlay extends StatefulWidget {
  final MirrorRunGame game;
  const DebugOverlay({super.key, required this.game});

  @override
  State<DebugOverlay> createState() => _DebugOverlayState();
}

class _DebugOverlayState extends State<DebugOverlay> {
  static const _accent = Color(0xFFB48CFF);
  static const _red = Color(0xFFFF4444);
  static const _green = Color(0xFF44FF88);

  MirrorRunGame get game => widget.game;

  @override
  Widget build(BuildContext context) {
    final skinService = game.skinService;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TapScale(
                    onTap: () {
                      game.debugStartScore = 0;
                      game.overlays.remove('DebugOverlay');
                      game.overlays.add('MenuScreen');
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: _accent.withValues(alpha: 0.5),
                        size: 20,
                      ),
                    ),
                  ),
                  Text(
                    'DEBUG',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _red,
                      letterSpacing: 6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Start in Biome:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.5),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              TapScale(
                onTap: () {
                  game.overlays.remove('DebugOverlay');
                  runScreenshotTour(game);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: _red.withValues(alpha: 0.5), width: 1),
                    borderRadius: BorderRadius.circular(6),
                    color: _red.withValues(alpha: 0.1),
                  ),
                  child: const Text(
                    'SCREENSHOT TOUR',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF4444),
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    // --- Biome list ---
                    ...BiomeManager.biomes.map((biome) {
                      return TapScale(
                        onTap: () {
                          game.debugStartScore = biome.startM;
                          game.overlays.remove('DebugOverlay');
                          game.overlays.add('MenuScreen');
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: biome.lineL.withValues(alpha: 0.4),
                              width: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            color: biome.lineL.withValues(alpha: 0.06),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                biome.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: biome.lineL,
                                  letterSpacing: 3,
                                ),
                              ),
                              Text(
                                '${biome.startM}m',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    // --- Ads section ---
                    const SizedBox(height: 24),
                    Text(
                      'Ads:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.5),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildToggle(
                      label: 'ALWAYS SHOW AD',
                      color: const Color(0xFFFF8800),
                      isOn: game.adService.debugAlwaysShowAd,
                      onTap: () {
                        game.adService.debugAlwaysShowAd = !game.adService.debugAlwaysShowAd;
                        setState(() {});
                      },
                    ),

                    // --- Skin Unlocks section ---
                    const SizedBox(height: 24),
                    Text(
                      'Skin Unlocks:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.5),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Custom Skin Creator toggle
                    _buildToggle(
                      label: 'CUSTOM SKIN CREATOR',
                      color: const Color(0xFFFF66AA),
                      isOn: skinService.customSkinUnlocked,
                      onTap: () async {
                        await skinService.setCustomSkinUnlocked(
                          !skinService.customSkinUnlocked,
                        );
                        setState(() {});
                      },
                    ),

                    // Individual skin toggles
                    ...PlayerSkin.all.where((s) => s.unlockBiomeIndex != null).map((skin) {
                      final unlocked = skinService.isUnlocked(skin.id);
                      return _buildToggle(
                        label: skin.name,
                        color: skin.leftColor,
                        isOn: unlocked,
                        onTap: () async {
                          if (unlocked) {
                            await skinService.debugLockSkin(skin.id);
                          } else {
                            await skinService.debugUnlockSkin(skin.id);
                          }
                          setState(() {});
                        },
                      );
                    }),

                    // Unlock all / Lock all buttons
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TapScale(
                            onTap: () async {
                              for (final skin in PlayerSkin.all) {
                                if (skin.unlockBiomeIndex != null) {
                                  await skinService.debugUnlockSkin(skin.id);
                                }
                              }
                              await skinService.setCustomSkinUnlocked(true);
                              setState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _green.withValues(alpha: 0.4),
                                  width: 0.5,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                color: _green.withValues(alpha: 0.08),
                              ),
                              child: Center(
                                child: Text(
                                  'UNLOCK ALL',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _green,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TapScale(
                            onTap: () async {
                              for (final skin in PlayerSkin.all) {
                                if (skin.unlockBiomeIndex != null) {
                                  await skinService.debugLockSkin(skin.id);
                                }
                              }
                              await skinService.setCustomSkinUnlocked(false);
                              setState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _red.withValues(alpha: 0.4),
                                  width: 0.5,
                                ),
                                borderRadius: BorderRadius.circular(6),
                                color: _red.withValues(alpha: 0.08),
                              ),
                              child: Center(
                                child: Text(
                                  'LOCK ALL',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _red,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggle({
    required String label,
    required Color color,
    required bool isOn,
    required VoidCallback onTap,
  }) {
    return TapScale(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: color.withValues(alpha: isOn ? 0.5 : 0.15),
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(6),
          color: color.withValues(alpha: isOn ? 0.1 : 0.02),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: isOn ? 1.0 : 0.3),
                letterSpacing: 2,
              ),
            ),
            Container(
              width: 40,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(11),
                color: isOn
                    ? _green.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: isOn
                      ? _green.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.15),
                  width: 0.5,
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 150),
                alignment: isOn ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOn ? _green : Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
