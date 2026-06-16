import 'dart:math';
import 'package:flame/components.dart';
import '../game_state.dart';
import '../mirror_run_game.dart';
import '../world/biome.dart';
import 'obstacle.dart';

class ObstacleSpawner extends Component with HasGameReference<MirrorRunGame> {
  /// The 3 valid lane states in mirror mode (left lane, right lane).
  static const List<(int, int)> validStates = [(0, 2), (1, 1), (2, 0)];

  /// Optional seeded RNG for deterministic daily-seed runs.
  final Random _rng;
  ObstacleSpawner({Random? rng}) : _rng = rng ?? Random();

  double _spawnTimerLeft = 0;
  double _spawnTimerRight = 0.4;

  // NOTE: no update(dt) override — spawning is driven from the fixed step
  // (MirrorRunGame._tick) for framerate-independent, seed-deterministic RNG.

  /// One fixed simulation step, invoked from [MirrorRunGame._tick].
  void fixedUpdate(double step) {
    if (game.playState != PlayState.playing) return;

    _spawnTimerLeft -= step;
    if (_spawnTimerLeft <= 0) {
      _trySpawnSide('left');
      _spawnTimerLeft = _nextInterval('left');
    }
    _spawnTimerRight -= step;
    if (_spawnTimerRight <= 0) {
      _trySpawnSide('right');
      _spawnTimerRight = _nextInterval('right');
    }
  }

  /// During DESYNC one side scrolls faster (factor > 1). On that side obstacles
  /// approach quicker, so the same spawn interval yields a denser, less fair
  /// field. To keep the fast side beatable we stretch its spawn interval by its
  /// desync factor (≥1 only), giving the player proportionally more reaction
  /// time / gap. The slow side (factor < 1) is left unchanged.
  double _sideDesyncFactor(String side) {
    final f = side == 'left'
        ? game.eventSystem.desyncLeftFactor
        : game.eventSystem.desyncRightFactor;
    return f > 1.0 ? f : 1.0;
  }

  double _nextInterval(String side) {
    final biome = BiomeManager.getBiome(game.score);
    final phase = biome.getPhase(game.score);
    final base = phase.minInterval + max(0, 15 - game.score * 0.05);
    final interval = max(0.15, (base + _rng.nextDouble() * 30 - 15) / 60);
    // Fairness: widen the interval on the faster (desynced) side.
    return interval * _sideDesyncFactor(side);
  }

  void _trySpawnSide(String side) {
    final biome = BiomeManager.getBiome(game.score);
    final phase = biome.getPhase(game.score);
    var type = phase.types[_rng.nextInt(phase.types.length)];

    final lanes = side == 'left'
        ? MirrorRunGame.mirrorLanesL
        : MirrorRunGame.mirrorLanesR;

    // Fairness during DESYNC: on the fast side a double-wall (blocks 2 of 3
    // lanes) plus the higher approach speed becomes near-unavoidable, so demote
    // it to a single wall. The slow side keeps the full obstacle set.
    if (type == ObstacleType.doubleWall && _sideDesyncFactor(side) > 1.0) {
      type = ObstacleType.wall;
    }

    if (type == ObstacleType.doubleWall) {
      _spawnDoubleWall(side, lanes);
    } else if (type == ObstacleType.shifter) {
      _spawnShifter(side, lanes);
    } else {
      _spawnSingleLane(side, type, lanes);
    }
  }

  void _spawnSingleLane(String side, ObstacleType type, List<double> lanes) {
    final lane = _rng.nextInt(3);
    if (!_isSolvableAfterSpawn(side, [lane])) return;

    final dims = _getDimensions(type);
    game.world.add(Obstacle(
      side: side,
      type: type,
      lane: lane,
      laneCenterX: lanes[lane],
      scrollPos: -60,
      w: dims.$1,
      h: dims.$2,
    ));
  }

  void _spawnDoubleWall(String side, List<double> lanes) {
    final startLane = _rng.nextInt(2);
    final endLane = startLane + 1;

    if (!_isSolvableAfterSpawn(side, [startLane, endLane])) return;

    final dims = _getDimensions(ObstacleType.doubleWall);
    game.world.add(Obstacle(
      side: side,
      type: ObstacleType.doubleWall,
      lane: startLane,
      laneCenterX: lanes[startLane],
      scrollPos: -60,
      w: dims.$1,
      h: dims.$2,
      secondLaneCenterX: lanes[endLane],
      secondLane: endLane,
    ));
  }

  void _spawnShifter(String side, List<double> lanes) {
    final startLane = _rng.nextInt(3);
    int targetLane;
    if (startLane == 0) {
      targetLane = 1;
    } else if (startLane == 2) {
      targetLane = 1;
    } else {
      targetLane = _rng.nextBool() ? 0 : 2;
    }

    if (!_isSolvableAfterSpawn(side, [startLane, targetLane])) return;

    final dims = _getDimensions(ObstacleType.shifter);
    game.world.add(Obstacle(
      side: side,
      type: ObstacleType.shifter,
      lane: startLane,
      laneCenterX: lanes[startLane],
      scrollPos: -60,
      w: dims.$1,
      h: dims.$2,
      secondLaneCenterX: lanes[targetLane],
      secondLane: targetLane,
    ));
  }

  bool _isSolvableAfterSpawn(String side, List<int> newLanes) {
    const spawnPos = -60.0;
    // On the fast (desynced) side obstacles converge quicker, so widen the
    // window we require to be clear — this enforces a bigger reachable gap and
    // prevents back-to-back walls the player can't physically dodge in time.
    final dangerZoneHeight = (Obstacle.playerH + 50) * _sideDesyncFactor(side);

    final nearbyObs = game.world.children
        .whereType<Obstacle>()
        .where((o) => (o.scrollPos - spawnPos).abs() < dangerZoneHeight)
        .toList();

    final blockedLeft = <int>{};
    final blockedRight = <int>{};
    for (final o in nearbyObs) {
      if (o.side == 'left') {
        blockedLeft.addAll(o.blockedLanes);
      } else {
        blockedRight.addAll(o.blockedLanes);
      }
    }

    if (side == 'left') {
      blockedLeft.addAll(newLanes);
    } else {
      blockedRight.addAll(newLanes);
    }

    for (final state in validStates) {
      if (!blockedLeft.contains(state.$1) && !blockedRight.contains(state.$2)) {
        return true;
      }
    }
    return false;
  }

  (double, double) _getDimensions(ObstacleType type) {
    return switch (type) {
      ObstacleType.wall => (26, 30),
      ObstacleType.spike => (30, 18),
      ObstacleType.doubleWall => (26, 30),
      ObstacleType.shifter => (28, 28),
    };
  }
}
