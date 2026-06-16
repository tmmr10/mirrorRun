import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../game/mirror_run_game.dart';
import '../l10n/game_l10n.dart';
import '../l10n/l10n_ext.dart';
import '../services/upgrade_service.dart';
import 'tap_scale.dart';
import 'theme.dart';

/// Permanent perk / upgrade shop. Coins are the long-term sink: every perk has
/// one or more levels with rising costs, bought levels persist forever.
class PerkScreen extends StatefulWidget {
  final MirrorRunGame game;
  const PerkScreen({super.key, required this.game});

  @override
  State<PerkScreen> createState() => _PerkScreenState();
}

class _PerkScreenState extends State<PerkScreen> {
  static const _accent = MR.accent;
  bool _purchasing = false;

  UpgradeService get _upgrades => widget.game.upgradeService;

  @override
  void initState() {
    super.initState();
    _upgrades.revision.addListener(_onRevisionChanged);
  }

  void _onRevisionChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _upgrades.revision.removeListener(_onRevisionChanged);
    super.dispose();
  }

  IconData _iconFor(Perk perk) {
    switch (perk) {
      case Perk.startShield:
        return Icons.shield_outlined;
      case Perk.coinMagnet:
        return Icons.gps_fixed_rounded;
      case Perk.powerUpDuration:
        return Icons.timer_outlined;
      case Perk.startCombo:
        return Icons.local_fire_department_rounded;
      case Perk.coinBonus:
        return Icons.monetization_on_outlined;
    }
  }

  Future<void> _buy(Perk perk) async {
    if (_purchasing) return; // guard against double-tap double-spend
    setState(() => _purchasing = true);
    try {
      final ok = await _upgrades.tryPurchase(perk, widget.game.coinsService);
      if (!mounted) return;
      if (ok) {
        HapticFeedback.selectionClick();
      }
    } finally {
      if (mounted) {
        setState(() => _purchasing = false);
      } else {
        _purchasing = false;
      }
    }
  }

  void _back() {
    widget.game.overlays.remove('PerkScreen');
    widget.game.overlays.add('MenuScreen');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: MR.bgGradient),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                itemCount: UpgradeService.perks.length,
                itemBuilder: (context, index) {
                  final def = UpgradeService.perks[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildPerkCard(def),
                  )
                      .animate()
                      .fadeIn(duration: 350.ms, delay: (60 * index).ms)
                      .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
                },
              ),
            ),
          ],
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
            context.l10n.perkTitle,
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

  Widget _buildPerkCard(PerkDef def) {
    final perk = def.perk;
    final level = _upgrades.level(perk);
    final maxed = _upgrades.isMaxed(perk);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: maxed
              ? MR.gold.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.06),
          width: maxed ? 1 : 0.5,
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.04),
            Colors.white.withValues(alpha: 0.01),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: _accent.withValues(alpha: 0.08),
              border: Border.all(
                color: _accent.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            child: Icon(
              _iconFor(perk),
              color: _accent.withValues(alpha: 0.85),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          // Title + effect + level dots
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  perkTitleLocalized(context, perk),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withValues(alpha: 0.9),
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  perkEffectLocalized(context, perk),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.55),
                    letterSpacing: 0.5,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                _buildLevelDots(level, def.maxLevel),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Buy button / MAXED
          maxed ? _buildMaxedBadge() : _buildBuyButton(perk),
        ],
      ),
    );
  }

  Widget _buildLevelDots(int level, int maxLevel) {
    return Row(
      children: List.generate(maxLevel, (i) {
        final filled = i < level;
        return Container(
          margin: const EdgeInsets.only(right: 6),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled
                ? _accent.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.12),
            border: filled
                ? null
                : Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
          ),
        );
      }),
    );
  }

  Widget _buildMaxedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: MR.gold.withValues(alpha: 0.4), width: 0.5),
        color: MR.gold.withValues(alpha: 0.08),
      ),
      child: Text(
        context.l10n.perkMaxed,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: MR.gold,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildBuyButton(Perk perk) {
    final cost = _upgrades.nextCost(perk);
    if (cost == null) return _buildMaxedBadge();

    return ValueListenableBuilder<int>(
      valueListenable: widget.game.coinsService.coinsNotifier,
      builder: (context, coins, _) {
        final affordable = coins >= cost;
        // Dim + disable while a purchase is in flight (visual feedback).
        final enabled = affordable && !_purchasing;
        final color =
            affordable ? MR.gold : Colors.white.withValues(alpha: 0.25);
        return Opacity(
          opacity: _purchasing ? 0.5 : 1.0,
          child: TapScale(
          minSize: MR.minTouchTarget,
          onTap: enabled ? () => _buy(perk) : null,
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
                  context.l10n.perkBuy,
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
