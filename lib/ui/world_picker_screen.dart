import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../game/mirror_run_game.dart';
import '../game/world/biome.dart';
import '../l10n/game_l10n.dart';
import '../l10n/l10n_ext.dart';
import '../services/world_unlock_service.dart';
import 'overlay_shell.dart';
import 'tap_scale.dart';
import 'theme.dart';

/// Overlay screen letting the player pick an unlocked world to start a run in,
/// or spend coins to unlock a locked one. Mirrors the look of [PerkScreen] and
/// [SkinSelector]: bg gradient, header with back chevron + live coin chip, and
/// a scrollable list of cards.
class WorldPickerScreen extends StatefulWidget {
  final MirrorRunGame game;
  const WorldPickerScreen({super.key, required this.game});

  @override
  State<WorldPickerScreen> createState() => _WorldPickerScreenState();
}

class _WorldPickerScreenState extends State<WorldPickerScreen> {
  static const _accent = MR.accent;
  bool _unlocking = false;

  WorldUnlockService get _worlds => widget.game.worldUnlockService;

  @override
  void initState() {
    super.initState();
    _worlds.revision.addListener(_onRevisionChanged);
  }

  void _onRevisionChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _worlds.revision.removeListener(_onRevisionChanged);
    super.dispose();
  }

  void _back() {
    widget.game.overlays.remove('WorldPicker');
    widget.game.overlays.add('MenuScreen');
  }

  void _start(int index) {
    HapticFeedback.selectionClick();
    widget.game.startGameAtWorld(index);
  }

  Future<void> _unlock(int index) async {
    if (_unlocking) return; // guard against double-tap double-spend
    setState(() => _unlocking = true);
    try {
      final ok = await _worlds.tryUnlock(index, widget.game.coinsService);
      if (!mounted) return;
      if (ok) {
        HapticFeedback.selectionClick();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.skinNotEnoughCoins),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _unlocking = false);
      } else {
        _unlocking = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final biomes = BiomeManager.biomes;
    return Container(
      decoration: const BoxDecoration(gradient: MR.bgGradient),
      child: SafeArea(
        child: OverlayShell(
          child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            Expanded(
              child: CenterableScroll(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var index = 0; index < biomes.length; index++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildWorldCard(biomes[index], index),
                      )
                          .animate()
                          .fadeIn(duration: 350.ms, delay: (50 * index).ms)
                          .slideY(
                              begin: 0.08, end: 0, curve: Curves.easeOutCubic),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 24, right: 20),
      child: Row(
        children: [
          TapScale(
            minSize: MR.minTouchTarget,
            onTap: _back,
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
            context.l10n.worldsTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: _accent,
              letterSpacing: 6,
            ),
          ),
          const Spacer(),
          // Live coin balance
          ValueListenableBuilder<int>(
            valueListenable: widget.game.coinsService.coinsNotifier,
            builder: (context, coins, _) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.circle, size: 10, color: MR.gold),
                  const SizedBox(width: 6),
                  Text(
                    '$coins',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: MR.gold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildWorldCard(BiomeData biome, int index) {
    final unlocked = _worlds.isUnlocked(index);
    final isFurthest = index == _worlds.maxReachedIndex;
    final accentColor = biome.lineL;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFurthest
              ? accentColor.withValues(alpha: 0.5)
              : (unlocked
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.white.withValues(alpha: 0.04)),
          width: isFurthest ? 1 : 0.5,
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: unlocked ? 0.04 : 0.02),
            Colors.white.withValues(alpha: 0.01),
            Colors.transparent,
          ],
        ),
        boxShadow: isFurthest
            ? [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.14),
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Color badge — index number / lock
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: accentColor.withValues(alpha: unlocked ? 0.12 : 0.05),
              border: Border.all(
                color: accentColor.withValues(alpha: unlocked ? 0.4 : 0.15),
                width: 0.5,
              ),
            ),
            child: Center(
              child: unlocked
                  ? Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: accentColor.withValues(alpha: 0.95),
                        letterSpacing: 1,
                      ),
                    )
                  : Icon(
                      Icons.lock_outline_rounded,
                      color: Colors.white.withValues(alpha: 0.18),
                      size: 20,
                    ),
            ),
          ),
          const SizedBox(width: 14),
          // Name + start distance (+ free-play note)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  biomeNameLocalized(context, biome.name),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: unlocked
                        ? accentColor.withValues(alpha: 0.95)
                        : Colors.white.withValues(alpha: 0.3),
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.worldStartAt(biome.startM),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.5),
                    letterSpacing: 0.5,
                    height: 1.3,
                  ),
                ),
                if (unlocked && index > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.worldFreePlayNote,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white.withValues(alpha: 0.35),
                      letterSpacing: 0.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Action: START or UNLOCK
          unlocked ? _buildStartButton(index) : _buildUnlockButton(index),
        ],
      ),
    );
  }

  Widget _buildStartButton(int index) {
    return TapScale(
      minSize: MR.minTouchTarget,
      onTap: () => _start(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: _accent.withValues(alpha: 0.5),
            width: 0.5,
          ),
          color: _accent.withValues(alpha: 0.1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.play_arrow_rounded,
              size: 16,
              color: _accent.withValues(alpha: 0.95),
            ),
            const SizedBox(width: 4),
            Text(
              context.l10n.worldStart,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: _accent.withValues(alpha: 0.95),
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockButton(int index) {
    final cost = _worlds.unlockCost(index);
    if (cost == null) return const SizedBox.shrink();

    return ValueListenableBuilder<int>(
      valueListenable: widget.game.coinsService.coinsNotifier,
      builder: (context, coins, _) {
        final affordable = coins >= cost;
        // Dim + disable while an unlock is in flight (visual feedback).
        final enabled = affordable && !_unlocking;
        final color =
            affordable ? MR.gold : Colors.white.withValues(alpha: 0.25);
        return Opacity(
          opacity: _unlocking ? 0.5 : 1.0,
          child: TapScale(
          minSize: MR.minTouchTarget,
          onTap: enabled ? () => _unlock(index) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.5), width: 0.5),
              color: affordable
                  ? MR.gold.withValues(alpha: 0.08)
                  : Colors.transparent,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: color),
                    const SizedBox(width: 4),
                    Text(
                      '$cost',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  context.l10n.worldUnlock,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: color.withValues(alpha: 0.75),
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }
}
