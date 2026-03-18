import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../game/mirror_run_game.dart';
import '../models/player_skin.dart';
import 'player_scene_painter.dart';
import 'tap_scale.dart';

class SkinSelector extends StatefulWidget {
  final MirrorRunGame game;
  const SkinSelector({super.key, required this.game});

  @override
  State<SkinSelector> createState() => _SkinSelectorState();
}

class _SkinSelectorState extends State<SkinSelector> with SingleTickerProviderStateMixin {
  static const _accent = Color(0xFFB48CFF);
  late final AnimationController _glowController;

  List<CustomSkinData> get _customSkins => widget.game.skinService.customSkins;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0a0a0f), Color(0xFF080812), Color(0xFF0a060f)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 24, right: 20),
              child: Row(
                children: [
                  TapScale(
                    onTap: () {
                      widget.game.overlays.remove('SkinSelector');
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
                    'SKINS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _accent,
                      letterSpacing: 6,
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(duration: 400.ms),
            ),
            const SizedBox(height: 16),

            // Scrollable rows
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: SKIN CREATOR
                    _buildSectionHeader('SKIN CREATOR'),
                    SizedBox(
                      height: 200,
                      child: _buildCreatorRow(),
                    ),

                    const SizedBox(height: 20),

                    // Row 2: COLLECTION
                    _buildSectionHeader('COLLECTION'),
                    SizedBox(
                      height: 200,
                      child: _buildCollectionRow(),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white.withValues(alpha: 0.3),
          letterSpacing: 4,
        ),
      ),
    );
  }

  // --- Row 1: Creator row (Create button + custom skins) ---
  Widget _buildCreatorRow() {
    final skinService = widget.game.skinService;
    final unlocked = skinService.customSkinUnlocked;
    final customs = _customSkins;

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 1 + customs.length, // Create + custom skins
      itemBuilder: (context, index) {
        if (index == 0) {
          // Create button
          return TapScale(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (unlocked) {
                _openBuilder();
              } else {
                _showIapPrompt();
              }
            },
            child: _buildCreateCard(unlocked),
          );
        }

        // Custom skin card
        final customIdx = index - 1;
        final custom = customs[customIdx];
        final selected = skinService.isCustomSelected &&
            skinService.selectedCustomIndex == customIdx;
        return TapScale(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            skinService.selectCustomSkin(customIdx);
            setState(() {});
          },
          child: _buildCustomSkinCard(custom, customIdx, selected),
        );
      },
    );
  }

  Widget _buildCreateCard(bool unlocked) {
    const cardWidth = 140.0;
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        return Container(
          width: cardWidth,
          margin: const EdgeInsets.only(right: 12),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: unlocked
                  ? _accent.withValues(alpha: 0.3)
                  : _accent.withValues(alpha: 0.1),
              width: 0.5,
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.03),
                Colors.white.withValues(alpha: 0.01),
                Colors.transparent,
              ],
            ),
          ),
          child: unlocked
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      color: _accent.withValues(alpha: 0.6),
                      size: 36,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'CREATE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.7),
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'NEW SKIN',
                      style: TextStyle(
                        fontSize: 8,
                        color: _accent.withValues(alpha: 0.5),
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Teaser preview
                    Opacity(
                      opacity: 0.25,
                      child: SizedBox(
                        height: 80,
                        child: CustomPaint(
                          painter: PlayerScenePainter(
                            leftColor: const Color(0xFFFF6B9D),
                            rightColor: const Color(0xFF00E5FF),
                            glowT: _glowController.value,
                            headDecoration: HeadDecoration.crown,
                            faceDecoration: FaceDecoration.goggles,
                          ),
                          size: const Size(120, 80),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.lock_outline_rounded,
                      color: _accent.withValues(alpha: 0.3),
                      size: 16,
                    ),
                    const SizedBox(height: 6),
                    // Rainbow bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF0000), Color(0xFFFF8800),
                              Color(0xFFFFFF00), Color(0xFF00FF00),
                              Color(0xFF0088FF), Color(0xFF8800FF),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.workspace_premium_rounded,
                          color: const Color(0xFFFFD700).withValues(alpha: 0.7),
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'GO PRO',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFFFD700).withValues(alpha: 0.7),
                            letterSpacing: 3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildCustomSkinCard(CustomSkinData skin, int index, bool selected) {
    const cardWidth = 140.0;
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        final glowT = _glowController.value;
        return Container(
          width: cardWidth,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? Color.lerp(skin.leftColor, skin.rightColor, glowT)!.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.06),
              width: selected ? 1.5 : 0.5,
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
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: skin.leftColor.withValues(alpha: 0.12 + glowT * 0.08),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              SizedBox(
                height: 90,
                child: CustomPaint(
                  painter: PlayerScenePainter(
                    leftColor: skin.leftColor,
                    rightColor: skin.rightColor,
                    glowT: glowT,
                    headDecoration: skin.headDecoration,
                    faceDecoration: skin.faceDecoration,
                  ),
                  size: const Size(120, 90),
                ),
              ),
              const Spacer(),
              Text(
                skin.name,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.9),
                  letterSpacing: 3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (selected)
                Text(
                  'EQUIPPED',
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    color: skin.leftColor.withValues(alpha: 0.8),
                    letterSpacing: 2,
                  ),
                )
              else
                Text(
                  'TAP TO EQUIP',
                  style: TextStyle(
                    fontSize: 7,
                    color: Colors.white.withValues(alpha: 0.2),
                    letterSpacing: 2,
                  ),
                ),
              const SizedBox(height: 6),
              // Edit
              TapScale(
                onTap: () => _openBuilder(editIndex: index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    'EDIT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.3),
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        );
      },
    );
  }

  // --- Row 2: Collection row (standard skins) ---
  Widget _buildCollectionRow() {
    final skinService = widget.game.skinService;

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: PlayerSkin.all.length,
      itemBuilder: (context, index) {
        final skin = PlayerSkin.all[index];
        final unlocked = skinService.isUnlocked(skin.id);
        final selected = !skinService.isCustomSelected &&
            skinService.selectedId == skin.id;

        return TapScale(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (unlocked) {
              skinService.selectSkin(skin.id);
              setState(() {});
            }
          },
          child: _buildStandardSkinCard(skin, unlocked, selected),
        );
      },
    );
  }

  Widget _buildStandardSkinCard(PlayerSkin skin, bool unlocked, bool selected) {
    const cardWidth = 140.0;
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, _) {
        final glowT = _glowController.value;
        return Container(
          width: cardWidth,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? Color.lerp(skin.leftColor, skin.rightColor, glowT)!.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.06),
              width: selected ? 1.5 : 0.5,
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
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: skin.leftColor.withValues(alpha: 0.12 + glowT * 0.08),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: unlocked
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),
                    SizedBox(
                      height: 90,
                      child: CustomPaint(
                        painter: PlayerScenePainter(
                          leftColor: skin.leftColor,
                          rightColor: skin.rightColor,
                          glowT: glowT,
                          headDecoration: skin.headDecoration,
                          faceDecoration: skin.faceDecoration,
                        ),
                        size: const Size(120, 90),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      skin.name,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.9),
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (selected)
                      Text(
                        'EQUIPPED',
                        style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                          color: skin.leftColor.withValues(alpha: 0.8),
                          letterSpacing: 2,
                        ),
                      )
                    else
                      Text(
                        'TAP TO EQUIP',
                        style: TextStyle(
                          fontSize: 7,
                          color: Colors.white.withValues(alpha: 0.2),
                          letterSpacing: 2,
                        ),
                      ),
                    const Spacer(flex: 2),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),
                    Icon(
                      Icons.lock_outline_rounded,
                      color: Colors.white.withValues(alpha: 0.1),
                      size: 32,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      skin.name,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white.withValues(alpha: 0.2),
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        skin.unlockDescription,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 8,
                          color: Colors.white.withValues(alpha: 0.15),
                          letterSpacing: 1,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const Spacer(flex: 2),
                  ],
                ),
        );
      },
    );
  }

  void _openBuilder({int? editIndex}) {
    widget.game.overlays.remove('SkinSelector');
    widget.game.skinBuilderEditIndex = editIndex;
    widget.game.overlays.add('SkinBuilder');
  }

  void _showIapPrompt() {
    widget.game.overlays.add('ProScreen');
  }

}
