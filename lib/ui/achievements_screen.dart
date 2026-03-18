import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../game/mirror_run_game.dart';
import 'tap_scale.dart';

class AchievementsScreen extends StatelessWidget {
  final MirrorRunGame game;
  const AchievementsScreen({super.key, required this.game});

  static const _accent = Color(0xFFB48CFF);

  static const _achievements = <_AchievementDef>[
    // Distance
    _AchievementDef('achievement_distance_75', '75m', 'DISTANCE', Color(0xFFB48CFF)),
    _AchievementDef('achievement_distance_100', '100m', 'DISTANCE', Color(0xFFB48CFF)),
    _AchievementDef('achievement_distance_300', '300m', 'DISTANCE', Color(0xFFB48CFF)),
    _AchievementDef('achievement_distance_500', '500m', 'DISTANCE', Color(0xFFB48CFF)),
    _AchievementDef('achievement_distance_750', '750m', 'DISTANCE', Color(0xFFB48CFF)),
    _AchievementDef('achievement_distance_1000', '1000m', 'DISTANCE', Color(0xFFB48CFF)),
    _AchievementDef('achievement_distance_1400', '1400m', 'DISTANCE', Color(0xFFB48CFF)),
    _AchievementDef('achievement_distance_2000', '2000m', 'DISTANCE', Color(0xFFB48CFF)),
    _AchievementDef('achievement_distance_2500', '2500m', 'DISTANCE', Color(0xFFB48CFF)),
    _AchievementDef('achievement_distance_3000', '3000m', 'DISTANCE', Color(0xFFB48CFF)),
    _AchievementDef('achievement_distance_3200', '3200m', 'DISTANCE', Color(0xFFB48CFF)),
    _AchievementDef('achievement_distance_5000', '5000m', 'DISTANCE', Color(0xFFB48CFF)),
    // Biomes
    _AchievementDef('achievement_biome_crystal', 'Crystal', 'BIOME', Color(0xFF40CCEE)),
    _AchievementDef('achievement_biome_volcano', 'Volcano', 'BIOME', Color(0xFFCC4400)),
    _AchievementDef('achievement_biome_desert', 'Desert', 'BIOME', Color(0xFFCC9933)),
    _AchievementDef('achievement_biome_ocean', 'Ocean', 'BIOME', Color(0xFF1080AA)),
    _AchievementDef('achievement_biome_neon', 'Neon', 'BIOME', Color(0xFF8800FF)),
    _AchievementDef('achievement_biome_void', 'Void', 'BIOME', Color(0xFFAAAAAA)),
    // Games
    _AchievementDef('achievement_games_10', '10 Games', 'GAMES', Color(0xFF44DDFF)),
    _AchievementDef('achievement_games_50', '50 Games', 'GAMES', Color(0xFF44DDFF)),
    _AchievementDef('achievement_games_100', '100 Games', 'GAMES', Color(0xFF44DDFF)),
    _AchievementDef('achievement_games_500', '500 Games', 'GAMES', Color(0xFF44DDFF)),
    // First
    _AchievementDef('achievement_first_game', '1st Run', 'FIRST RUN', Color(0xFFFF6644)),
  ];

  @override
  Widget build(BuildContext context) {
    final service = game.achievementService;
    final unlocked = service.unlockedCount;

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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    TapScale(
                      onTap: () {
                        game.overlays.remove('AchievementsScreen');
                        game.overlays.add('MenuScreen');
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
                      'ACHIEVEMENTS',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _accent,
                        letterSpacing: 6,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$unlocked/${_achievements.length}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _accent.withValues(alpha: 0.6),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Grid
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: _achievements.length,
                  itemBuilder: (context, index) {
                    final a = _achievements[index];
                    final isUnlocked = service.isUnlocked(a.id);
                    return _AchievementTile(
                      achievement: a,
                      unlocked: isUnlocked,
                      index: index,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AchievementDef {
  final String id;
  final String label;
  final String category;
  final Color color;
  const _AchievementDef(this.id, this.label, this.category, this.color);

  String get assetPath => 'assets/images/achievements/$id.png';
}

class _AchievementTile extends StatelessWidget {
  final _AchievementDef achievement;
  final bool unlocked;
  final int index;

  const _AchievementTile({
    required this.achievement,
    required this.unlocked,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: unlocked
                    ? achievement.color.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.06),
                width: 1,
              ),
              boxShadow: unlocked
                  ? [
                      BoxShadow(
                        color: achievement.color.withValues(alpha: 0.15),
                        blurRadius: 16,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: ColorFiltered(
                colorFilter: unlocked
                    ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                    : const ColorFilter.matrix([
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0.2126, 0.7152, 0.0722, 0, 0,
                        0, 0, 0, 0.3, 0,
                      ]),
                child: Image.asset(
                  achievement.assetPath,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          achievement.label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: unlocked
                ? Colors.white.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.2),
            letterSpacing: 1,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ).animate().fadeIn(
          duration: 300.ms,
          delay: Duration(milliseconds: 30 * index),
        );
  }
}
