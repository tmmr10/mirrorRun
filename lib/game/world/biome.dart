import 'dart:ui';
import '../game_state.dart';

class BiomePhase {
  final int maxM;
  final List<ObstacleType> types;
  final int minInterval;

  const BiomePhase({
    required this.maxM,
    required this.types,
    required this.minInterval,
  });
}

class BiomeData {
  final int startM;
  final String name;
  final BiomeType type;
  final List<Color> skyL;
  final List<Color> skyR;
  final Color groundL;
  final Color groundR;
  final Color lineL;
  final Color lineR;
  final Color obsL;
  final Color obsR;
  final Color obsGlowL;
  final Color obsGlowR;
  final List<BiomePhase> phases;

  const BiomeData({
    required this.startM,
    required this.name,
    required this.type,
    required this.skyL,
    required this.skyR,
    required this.groundL,
    required this.groundR,
    required this.lineL,
    required this.lineR,
    required this.obsL,
    required this.obsR,
    required this.obsGlowL,
    required this.obsGlowR,
    required this.phases,
  });

  BiomePhase getPhase(int meters) {
    for (final ph in phases) {
      if (meters < ph.maxM) return ph;
    }
    return phases.last;
  }
}

class BiomeManager {
  static const List<BiomeData> biomes = [
    // 1. Forest (0m)
    BiomeData(
      startM: 0,
      name: 'FOREST',
      type: BiomeType.forest,
      skyL: [Color(0xFF1b2e1b), Color(0xFF0d180d)],
      skyR: [Color(0xFF1b1b2e), Color(0xFF0d0d18)],
      groundL: Color(0xFF1a3a1a),
      groundR: Color(0xFF1a1a3a),
      lineL: Color(0xFF2a6a2a),
      lineR: Color(0xFF2a2a6a),
      obsL: Color(0xFF2d8c3a),
      obsR: Color(0xFF2d3a8c),
      obsGlowL: Color(0xB32d8c3a),
      obsGlowR: Color(0xB32d3a8c),
      phases: [
        BiomePhase(maxM: 40, types: [ObstacleType.wall, ObstacleType.spike], minInterval: 130),
        BiomePhase(maxM: 70, types: [ObstacleType.wall, ObstacleType.spike, ObstacleType.shifter], minInterval: 110),
        BiomePhase(maxM: 9999, types: [ObstacleType.wall, ObstacleType.spike, ObstacleType.shifter, ObstacleType.doubleWall], minInterval: 95),
      ],
    ),

    // 2. City (100m)
    BiomeData(
      startM: 100,
      name: 'CITY',
      type: BiomeType.city,
      skyL: [Color(0xFF1a1a2a), Color(0xFF0a0a15)],
      skyR: [Color(0xFF2a1a1a), Color(0xFF150a0a)],
      groundL: Color(0xFF2a2a2a),
      groundR: Color(0xFF1a1212),
      lineL: Color(0xFF555566),
      lineR: Color(0xFF664444),
      obsL: Color(0xFF4a5a7a),
      obsR: Color(0xFF7a3a3a),
      obsGlowL: Color(0xCC465a82),
      obsGlowR: Color(0xCC823737),
      phases: [
        BiomePhase(maxM: 150, types: [ObstacleType.wall, ObstacleType.spike, ObstacleType.shifter, ObstacleType.doubleWall], minInterval: 100),
        BiomePhase(maxM: 9999, types: [ObstacleType.wall, ObstacleType.spike, ObstacleType.doubleWall, ObstacleType.shifter], minInterval: 80),
      ],
    ),

    // 3. Crystal (200m)
    BiomeData(
      startM: 200,
      name: 'CRYSTAL',
      type: BiomeType.crystal,
      skyL: [Color(0xFF0a1a2a), Color(0xFF050d18)],
      skyR: [Color(0xFF0a2a2a), Color(0xFF051818)],
      groundL: Color(0xFF102030),
      groundR: Color(0xFF0a1828),
      lineL: Color(0xFF40AACC),
      lineR: Color(0xFF30AADD),
      obsL: Color(0xFF40CCEE),
      obsR: Color(0xFF30BBDD),
      obsGlowL: Color(0xCC40CCEE),
      obsGlowR: Color(0xCC30BBDD),
      phases: [
        BiomePhase(maxM: 260, types: [ObstacleType.wall, ObstacleType.spike, ObstacleType.doubleWall], minInterval: 90),
        BiomePhase(maxM: 320, types: [ObstacleType.wall, ObstacleType.spike, ObstacleType.doubleWall, ObstacleType.shifter], minInterval: 80),
        BiomePhase(maxM: 9999, types: [ObstacleType.wall, ObstacleType.spike, ObstacleType.doubleWall, ObstacleType.shifter], minInterval: 72),
      ],
    ),

    // 4. Volcano (350m)
    BiomeData(
      startM: 350,
      name: 'VOLCANO',
      type: BiomeType.volcano,
      skyL: [Color(0xFF2a0800), Color(0xFF120400)],
      skyR: [Color(0xFF2a1000), Color(0xFF140600)],
      groundL: Color(0xFF3a1a0a),
      groundR: Color(0xFF2a0a0a),
      lineL: Color(0xFFaa4422),
      lineR: Color(0xFF884400),
      obsL: Color(0xFFcc4400),
      obsR: Color(0xFFaa2200),
      obsGlowL: Color(0xCCff6600),
      obsGlowR: Color(0xCCdd4400),
      phases: [
        BiomePhase(maxM: 450, types: [ObstacleType.wall, ObstacleType.spike, ObstacleType.doubleWall], minInterval: 85),
        BiomePhase(maxM: 9999, types: [ObstacleType.wall, ObstacleType.spike, ObstacleType.doubleWall, ObstacleType.shifter], minInterval: 65),
      ],
    ),

    // 5. Desert (600m)
    BiomeData(
      startM: 600,
      name: 'DESERT',
      type: BiomeType.desert,
      skyL: [Color(0xFF2a1a08), Color(0xFF180e04)],
      skyR: [Color(0xFF2a2008), Color(0xFF181204)],
      groundL: Color(0xFF3a2a10),
      groundR: Color(0xFF2a1a08),
      lineL: Color(0xFFCC9933),
      lineR: Color(0xFFBB8822),
      obsL: Color(0xFFCC9933),
      obsR: Color(0xFFBB8822),
      obsGlowL: Color(0xCCCC9933),
      obsGlowR: Color(0xCCBB8822),
      phases: [
        BiomePhase(maxM: 750, types: [ObstacleType.wall, ObstacleType.spike, ObstacleType.doubleWall], minInterval: 78),
        BiomePhase(maxM: 900, types: [ObstacleType.wall, ObstacleType.spike, ObstacleType.doubleWall, ObstacleType.shifter], minInterval: 66),
        BiomePhase(maxM: 9999, types: [ObstacleType.wall, ObstacleType.spike, ObstacleType.doubleWall, ObstacleType.shifter], minInterval: 58),
      ],
    ),

    // 6. Ocean (1000m)
    BiomeData(
      startM: 1000,
      name: 'OCEAN',
      type: BiomeType.ocean,
      skyL: [Color(0xFF041828), Color(0xFF020c18)],
      skyR: [Color(0xFF082030), Color(0xFF041018)],
      groundL: Color(0xFF0a2838),
      groundR: Color(0xFF082030),
      lineL: Color(0xFF1a6090),
      lineR: Color(0xFF185080),
      obsL: Color(0xFF1080aa),
      obsR: Color(0xFF0060aa),
      obsGlowL: Color(0xCC20a0dd),
      obsGlowR: Color(0xCC0080cc),
      phases: [
        BiomePhase(maxM: 1200, types: [ObstacleType.wall, ObstacleType.spike, ObstacleType.doubleWall, ObstacleType.shifter], minInterval: 70),
        BiomePhase(maxM: 9999, types: [ObstacleType.wall, ObstacleType.spike, ObstacleType.doubleWall, ObstacleType.shifter], minInterval: 52),
      ],
    ),

    // 7. Ruins (1500m)
    BiomeData(
      startM: 1500,
      name: 'RUINS',
      type: BiomeType.ruins,
      skyL: [Color(0xFF0a1a0a), Color(0xFF050d05)],
      skyR: [Color(0xFF1a1a0a), Color(0xFF0d0d05)],
      groundL: Color(0xFF1a2a1a),
      groundR: Color(0xFF1a1a10),
      lineL: Color(0xFF5A8A5A),
      lineR: Color(0xFF6A7A5A),
      obsL: Color(0xFF5A8A5A),
      obsR: Color(0xFF6A7A5A),
      obsGlowL: Color(0xCC5A8A5A),
      obsGlowR: Color(0xCC6A7A5A),
      phases: [
        BiomePhase(maxM: 1750, types: [ObstacleType.wall, ObstacleType.spike, ObstacleType.doubleWall], minInterval: 62),
        BiomePhase(maxM: 2000, types: [ObstacleType.wall, ObstacleType.spike, ObstacleType.doubleWall, ObstacleType.shifter], minInterval: 52),
        BiomePhase(maxM: 9999, types: [ObstacleType.wall, ObstacleType.spike, ObstacleType.doubleWall, ObstacleType.shifter], minInterval: 46),
      ],
    ),

    // 8. Space (2100m)
    BiomeData(
      startM: 2100,
      name: 'SPACE',
      type: BiomeType.space,
      skyL: [Color(0xFF050510), Color(0xFF000008)],
      skyR: [Color(0xFF100508), Color(0xFF080002)],
      groundL: Color(0xFF080818),
      groundR: Color(0xFF180808),
      lineL: Color(0xFF2020aa),
      lineR: Color(0xFFaa2020),
      obsL: Color(0xFF103060),
      obsR: Color(0xFF400820),
      obsGlowL: Color(0xCC143c78),
      obsGlowR: Color(0xCC500f28),
      phases: [
        BiomePhase(maxM: 2400, types: [ObstacleType.wall, ObstacleType.doubleWall, ObstacleType.shifter], minInterval: 55),
        BiomePhase(maxM: 9999, types: [ObstacleType.wall, ObstacleType.spike, ObstacleType.doubleWall, ObstacleType.shifter], minInterval: 42),
      ],
    ),

    // 9. Storm (2800m)
    BiomeData(
      startM: 2800,
      name: 'STORM',
      type: BiomeType.storm,
      skyL: [Color(0xFF0a0418), Color(0xFF05020c)],
      skyR: [Color(0xFF18040a), Color(0xFF0c0205)],
      groundL: Color(0xFF140a20),
      groundR: Color(0xFF200a14),
      lineL: Color(0xFF7744BB),
      lineR: Color(0xFF9944AA),
      obsL: Color(0xFF7744BB),
      obsR: Color(0xFF9944AA),
      obsGlowL: Color(0xCC7744BB),
      obsGlowR: Color(0xCC9944AA),
      phases: [
        BiomePhase(maxM: 3100, types: [ObstacleType.wall, ObstacleType.spike, ObstacleType.doubleWall], minInterval: 48),
        BiomePhase(maxM: 3400, types: [ObstacleType.wall, ObstacleType.spike, ObstacleType.doubleWall, ObstacleType.shifter], minInterval: 42),
        BiomePhase(maxM: 9999, types: [ObstacleType.wall, ObstacleType.spike, ObstacleType.doubleWall, ObstacleType.shifter], minInterval: 38),
      ],
    ),

    // 10. Neon (3600m)
    BiomeData(
      startM: 3600,
      name: 'NEON',
      type: BiomeType.neon,
      skyL: [Color(0xFF0a0020), Color(0xFF060014)],
      skyR: [Color(0xFF200020), Color(0xFF140014)],
      groundL: Color(0xFF14002a),
      groundR: Color(0xFF2a0014),
      lineL: Color(0xFF8800ff),
      lineR: Color(0xFFff0088),
      obsL: Color(0xFF6600cc),
      obsR: Color(0xFFcc0066),
      obsGlowL: Color(0xCC8800ff),
      obsGlowR: Color(0xCCff0088),
      phases: [
        BiomePhase(maxM: 4000, types: [ObstacleType.wall, ObstacleType.spike, ObstacleType.doubleWall, ObstacleType.shifter], minInterval: 42),
        BiomePhase(maxM: 9999, types: [ObstacleType.wall, ObstacleType.spike, ObstacleType.doubleWall, ObstacleType.shifter], minInterval: 34),
      ],
    ),

    // 11. Void (4500m)
    BiomeData(
      startM: 4500,
      name: 'VOID',
      type: BiomeType.void_,
      skyL: [Color(0xFF020202), Color(0xFF000000)],
      skyR: [Color(0xFF020202), Color(0xFF000000)],
      groundL: Color(0xFF0a0a0a),
      groundR: Color(0xFF0a0a0a),
      lineL: Color(0xFF333333),
      lineR: Color(0xFF333333),
      obsL: Color(0xFFdddddd),
      obsR: Color(0xFFdddddd),
      obsGlowL: Color(0xCCffffff),
      obsGlowR: Color(0xCCffffff),
      phases: [
        BiomePhase(maxM: 9999, types: [ObstacleType.wall, ObstacleType.spike, ObstacleType.doubleWall, ObstacleType.shifter], minInterval: 30),
      ],
    ),
  ];

  static int getBiomeIndex(int meters) {
    int idx = 0;
    for (int j = 0; j < biomes.length; j++) {
      if (meters >= biomes[j].startM) idx = j;
    }
    return idx;
  }

  static BiomeData getBiome(int meters) => biomes[getBiomeIndex(meters)];
}
