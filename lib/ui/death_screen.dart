import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../game/mirror_run_game.dart';
import '../game/world/biome.dart';
import '../models/player_skin.dart';
import '../services/analytics_service.dart';
import 'tap_scale.dart';
import 'theme.dart';

const Duration _kContinueWindow = Duration(seconds: 5);

class DeathScreen extends StatefulWidget {
  final MirrorRunGame game;
  const DeathScreen({super.key, required this.game});

  @override
  State<DeathScreen> createState() => _DeathScreenState();
}

class _DeathScreenState extends State<DeathScreen> with TickerProviderStateMixin {
  bool _canInteract = false;
  bool _adWasShown = false;
  late final Timer _interactTimer;

  // CONTINUE panel state
  bool _continueVisible = false;
  bool _revivingInProgress = false;
  Timer? _continueTimeoutTimer;
  AnimationController? _continueProgressController;

  @override
  void initState() {
    super.initState();
    _interactTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _canInteract = true);
    });
    widget.game.adService.proStatusNotifier.addListener(_onProStatus);

    // Offer CONTINUE immediately (don't wait for _canInteract — revive has its own window)
    _setupContinueOffer();

    final adService = widget.game.adService;
    // Show interstitial only if revive isn't being offered (avoid stacking ads)
    if (!_continueVisible && adService.shouldShowAd(widget.game.lastRunDuration)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        adService.showAd(() {
          if (mounted) setState(() => _adWasShown = true);
        });
      });
    }
  }

  void _setupContinueOffer() {
    final game = widget.game;
    if (!game.canRevive) return;

    final adReady = game.adService.isRewardedAdReady;
    final canProFreeRevive = game.adService.canUseFreeProRevive();

    // Show panel if any revive path is available: Pro-free, rewarded ad, or coins.
    if (!adReady && !canProFreeRevive && !game.canAffordCoinRevive) return;

    _continueVisible = true;
    _continueProgressController = AnimationController(
      vsync: this,
      duration: _kContinueWindow,
    )..forward();
    _continueTimeoutTimer = Timer(_kContinueWindow, () {
      if (mounted && _continueVisible && !_revivingInProgress) {
        unawaited(AnalyticsService.logReviveDeclined(score: widget.game.scoreNotifier.value));
        setState(() => _continueVisible = false);
      }
    });
    unawaited(AnalyticsService.logReviveOffered());
  }

  void _onProStatus() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _interactTimer.cancel();
    _continueTimeoutTimer?.cancel();
    _continueProgressController?.dispose();
    widget.game.adService.proStatusNotifier.removeListener(_onProStatus);
    super.dispose();
  }

  void _reviveViaAd() {
    if (_revivingInProgress) return;
    setState(() => _revivingInProgress = true);
    _continueTimeoutTimer?.cancel();
    _continueProgressController?.stop();

    widget.game.adService.showRewardedAd(
      onEarnedReward: () {
        if (!mounted) return;
        widget.game.revivePlayer(viaAd: true);
      },
      onDismissed: () {
        if (!mounted) return;
        // If revive didn't fire (ad closed without earning reward), hide panel
        if (widget.game.canRevive) {
          setState(() {
            _revivingInProgress = false;
            _continueVisible = false;
          });
        }
      },
    );
  }

  void _reviveFreeForPro() async {
    if (_revivingInProgress) return;
    setState(() => _revivingInProgress = true);
    _continueTimeoutTimer?.cancel();
    _continueProgressController?.stop();
    final consumed = await widget.game.adService.consumeFreeProRevive();
    if (!consumed) {
      // Cap hit or state changed — fall back to ad if available
      if (mounted && widget.game.adService.isRewardedAdReady) {
        setState(() => _revivingInProgress = false);
        _reviveViaAd();
      } else if (mounted) {
        setState(() {
          _revivingInProgress = false;
          _continueVisible = false;
        });
      }
      return;
    }
    widget.game.revivePlayer(viaAd: false);
  }

  void _reviveWithCoins() async {
    if (_revivingInProgress) return;
    setState(() => _revivingInProgress = true);
    _continueTimeoutTimer?.cancel();
    _continueProgressController?.stop();
    final ok = await widget.game.reviveWithCoins();
    // On success revivePlayer() removes this overlay; on failure re-enable.
    if (!ok && mounted) {
      setState(() => _revivingInProgress = false);
    }
  }

  void _declineContinue() {
    _continueTimeoutTimer?.cancel();
    _continueProgressController?.stop();
    unawaited(AnalyticsService.logReviveDeclined(score: widget.game.scoreNotifier.value));
    setState(() => _continueVisible = false);
  }

  void _retry() {
    // Never retry from a stray tap while the revive panel is up — that would
    // throw away the run AND the continue offer at once.
    if (!_canInteract || _continueVisible) return;
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
    // Absorb stray taps (so they don't fall through to the game) WITHOUT
    // triggering retry — retry lives only on the explicit prompt below.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
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

              const Spacer(flex: 2),

              // CONTINUE panel (above action buttons)
              if (_continueVisible) _buildContinuePanel(),

              const Spacer(),

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

            // Session coins earned
            if (widget.game.coinsService.sessionEarned > 0) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: MR.gold.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: MR.gold.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.circle,
                      color: MR.gold,
                      size: 9,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '+${widget.game.coinsService.sessionEarned} COINS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: MR.gold.withValues(alpha: 0.9),
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 1100.ms)
                  .slideY(begin: 0.2, end: 0, duration: 400.ms, delay: 1100.ms)
                  .shimmer(duration: 1500.ms, delay: 1300.ms, color: MR.gold.withValues(alpha: 0.25)),
            ],

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
                      color: MR.gold.withValues(alpha: 0.5),
                      width: 0.5,
                    ),
                    borderRadius: BorderRadius.circular(2),
                    color: MR.gold.withValues(alpha: 0.06),
                  ),
                  child: Text(
                    'NEW RECORD',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: MR.gold,
                      letterSpacing: 4,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 300.ms, delay: 1200.ms)
                    .shimmer(duration: 1500.ms, delay: 1400.ms, color: const Color(0x40FFCC44));
              },
            ),

            // Unlock banners (skins + achievements) — bounded + scrollable so a
            // record run with many simultaneous unlocks can't overflow into the
            // action buttons on small screens.
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 176),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ValueListenableBuilder<List<SkinId>>(
                      valueListenable: widget.game.newSkinsNotifier,
                      builder: (context, newSkins, child) {
                        if (newSkins.isEmpty) return const SizedBox.shrink();
                        return Column(
                          children: [
                            const SizedBox(height: 10),
                            for (final skinId in newSkins)
                              _buildSkinUnlockBanner(skinId),
                          ],
                        );
                      },
                    ),
                    ValueListenableBuilder<List<String>>(
                      valueListenable: widget.game.newAchievementsNotifier,
                      builder: (context, newAchievements, child) {
                        if (newAchievements.isEmpty) return const SizedBox.shrink();
                        return Column(
                          children: [
                            const SizedBox(height: 10),
                            for (final id in newAchievements)
                              _buildAchievementUnlockBanner(id),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSkinUnlockBanner(SkinId skinId) {
    final skin = PlayerSkin.getById(skinId);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(
          color: skin.leftColor.withValues(alpha: 0.5),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(2),
        gradient: LinearGradient(
          colors: [
            skin.leftColor.withValues(alpha: 0.08),
            skin.rightColor.withValues(alpha: 0.08),
          ],
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [skin.leftColor, skin.rightColor],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'NEW SKIN: ${skin.name}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.85),
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 1500.ms)
        .slideY(begin: 0.3, end: 0, duration: 400.ms, delay: 1500.ms, curve: Curves.easeOutCubic)
        .shimmer(duration: 1500.ms, delay: 1800.ms, color: skin.leftColor.withValues(alpha: 0.3));
  }

  String _achievementLabel(String id) {
    if (id.startsWith('achievement_distance_')) return '${id.replaceFirst('achievement_distance_', '')}m';
    if (id.startsWith('achievement_biome_')) return id.replaceFirst('achievement_biome_', '').toUpperCase();
    if (id.startsWith('achievement_games_')) return '${id.replaceFirst('achievement_games_', '')} GAMES';
    if (id == 'achievement_first_game') return '1ST RUN';
    return id.toUpperCase();
  }

  Widget _buildAchievementUnlockBanner(String id) {
    const color = MR.gold;
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
        borderRadius: BorderRadius.circular(2),
        color: color.withValues(alpha: 0.06),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events_rounded, color: color.withValues(alpha: 0.8), size: 14),
          const SizedBox(width: 10),
          Text(
            _achievementLabel(id),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color.withValues(alpha: 0.9),
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 1600.ms)
        .slideY(begin: 0.3, end: 0, duration: 400.ms, delay: 1600.ms, curve: Curves.easeOutCubic)
        .shimmer(duration: 1500.ms, delay: 1900.ms, color: color.withValues(alpha: 0.3));
  }

  Widget _buildActions() {
    return Column(
      children: [
        // Tap to retry prompt — the ONLY touch target that restarts the run.
        TapScale(
          onTap: _retry,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
            child: Column(
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
            ),
          ),
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
            if (defaultTargetPlatform != TargetPlatform.android) ...[
              const SizedBox(width: 10),
              _buildActionButton(
                onTap: () {
                  if (_canInteract) widget.game.leaderboardService.showLeaderboard();
                },
                label: 'RANKS',
                icon: Icons.leaderboard_rounded,
                color: MR.accent.withValues(alpha: 0.5),
                borderColor: MR.accent.withValues(alpha: 0.2),
                delay: 1900,
              ),
            ],
            const SizedBox(width: 10),
            Builder(
              builder: (ctx) => _buildActionButton(
              onTap: () {
                if (!_canInteract) return;
                try {
                  final score = widget.game.scoreNotifier.value;
                  final biomeIdx = BiomeManager.getBiomeIndex(score);
                  final biomeName = BiomeManager.biomes[biomeIdx].name;
                  final box = ctx.findRenderObject() as RenderBox?;
                  final origin = box != null
                      ? box.localToGlobal(Offset.zero) & box.size
                      : null;
                  Share.share(
                    'I ran ${score}m through $biomeName in Mirror Runners!',
                    sharePositionOrigin: origin,
                  );
                  unawaited(AnalyticsService.logShareTapped(score: score));
                } catch (_) {}
              },
              label: 'SHARE',
              icon: Icons.share_rounded,
              color: MR.danger.withValues(alpha: 0.6),
              borderColor: MR.danger.withValues(alpha: 0.3),
              delay: 2000,
            ),
            ),
          ],
        ),

        // GO PRO hint
        if (_adWasShown && !widget.game.adService.isPro) ...[
          const SizedBox(height: 20),
          TapScale(
            onTap: () {
              widget.game.overlays.add('ProScreen');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(
                  color: MR.gold.withValues(alpha: 0.3),
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(4),
                color: MR.gold.withValues(alpha: 0.06),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.workspace_premium_rounded,
                    color: MR.gold.withValues(alpha: 0.7),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'GO PRO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: MR.gold.withValues(alpha: 0.7),
                      letterSpacing: 3,
                    ),
                  ),
                ],
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

  Widget _buildContinuePanel() {
    final game = widget.game;
    final isPro = game.adService.isPro;
    final adReady = game.adService.isRewardedAdReady;
    final canProFreeRevive = game.adService.canUseFreeProRevive();
    final proRemaining = game.adService.getProFreeRevivesRemaining();
    const gold = MR.gold;
    const cyan = MR.cyan;

    // Guard: if no actionable button available, hide panel entirely.
    // Coin-revive counts — otherwise the coin button below would never show
    // when neither an ad nor a Pro revive is ready.
    final hasAction =
        (isPro && canProFreeRevive) || adReady || game.canAffordCoinRevive;
    if (!hasAction) return const SizedBox.shrink();

    final progressCtrl = _continueProgressController;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xCC0a0a14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: gold.withValues(alpha: 0.3), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: gold.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 14, color: gold),
              const SizedBox(width: 8),
              Text(
                'CONTINUE?',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: gold,
                  letterSpacing: 4,
                ),
              ),
              const Spacer(),
              TapScale(
                onTap: _declineContinue,
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Countdown progress bar
          if (progressCtrl != null)
            AnimatedBuilder(
              animation: progressCtrl,
              builder: (context, _) => Container(
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(1),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (1.0 - progressCtrl.value).clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [gold.withValues(alpha: 0.8), gold],
                      ),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),

          // Buttons — simplified: Pro-free revive OR watch ad, not both
          if (isPro && canProFreeRevive) ...[
            _buildReviveButton(
              label: 'FREE REVIVE',
              subtitle: '$proRemaining / 3 TODAY',
              icon: Icons.workspace_premium_rounded,
              color: gold,
              onTap: _reviveFreeForPro,
            ),
            const SizedBox(height: 4),
            Text(
              'RESETS AT MIDNIGHT',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.3),
                letterSpacing: 2,
              ),
            ),
          ] else if (adReady)
            _buildReviveButton(
              label: 'WATCH AD',
              subtitle: 'CONTINUE',
              icon: Icons.play_circle_outline,
              color: cyan,
              onTap: _reviveViaAd,
            ),

          // Coin revive — always offered when affordable (alternative to ad/Pro).
          if (widget.game.canAffordCoinRevive) ...[
            const SizedBox(height: 8),
            _buildReviveButton(
              label: 'CONTINUE',
              subtitle: '${MirrorRunGame.reviveCoinCost} COINS',
              icon: Icons.monetization_on_outlined,
              color: gold,
              onTap: _reviveWithCoins,
            ),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.2, end: 0, duration: 300.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildReviveButton({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return TapScale(
      onTap: _revivingInProgress ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.25),
              color.withValues(alpha: 0.1),
            ],
          ),
          border: Border.all(color: color.withValues(alpha: 0.5), width: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.5),
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
