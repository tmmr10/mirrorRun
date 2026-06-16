import 'dart:math';
import 'package:flame/components.dart';
import '../game_state.dart';
import '../mirror_run_game.dart';
import 'collectible.dart';
import 'obstacle.dart';

class CollectibleSpawner extends Component with HasGameReference<MirrorRunGame> {
  final Random _rng;
  CollectibleSpawner({Random? rng}) : _rng = rng ?? Random();

  double _spawnTimer = 1.5;

  // NOTE: no update(dt) override — driven from the fixed step (MirrorRunGame._tick).

  /// One fixed simulation step, invoked from [MirrorRunGame._tick].
  void fixedUpdate(double step) {
    if (game.playState != PlayState.playing) return;

    _spawnTimer -= step;
    if (_spawnTimer <= 0) {
      _trySpawn();
      // 2.5-4.5s between coin spawns (less frequent than obstacles)
      _spawnTimer = 2.5 + _rng.nextDouble() * 2.0;
    }
  }

  void _trySpawn() {
    final side = _rng.nextBool() ? 'left' : 'right';
    final lanes = side == 'left'
        ? MirrorRunGame.mirrorLanesL
        : MirrorRunGame.mirrorLanesR;

    // Find all lanes that aren't blocked by obstacles in the spawn zone
    final freeLanes = <int>[];
    for (int lane = 0; lane < 3; lane++) {
      if (_isLaneFree(side, lane)) freeLanes.add(lane);
    }
    if (freeLanes.isEmpty) return;

    final lane = freeLanes[_rng.nextInt(freeLanes.length)];
    game.world.add(Collectible(
      side: side,
      lane: lane,
      laneCenterX: lanes[lane],
      scrollPos: -30,
    ));
  }

  bool _isLaneFree(String side, int lane) {
    // Check no obstacles in the upcoming spawn zone block this lane
    final obstacles = game.world.children
        .whereType<Obstacle>()
        .where((o) => o.side == side && o.scrollPos > -120 && o.scrollPos < 100);
    for (final o in obstacles) {
      if (o.blockedLanes.contains(lane)) return false;
    }
    // Avoid stacking with other collectibles in the same lane near the top
    final existing = game.world.children
        .whereType<Collectible>()
        .where((c) => c.side == side && c.lane == lane && c.scrollPos < 60);
    return existing.isEmpty;
  }
}
