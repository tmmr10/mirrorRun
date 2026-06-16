import 'dart:math';
import 'package:flame/components.dart';
import '../game_state.dart';
import '../mirror_run_game.dart';
import 'obstacle.dart';
import 'power_up.dart';

/// Spawns power-ups rarely, only in lanes free of obstacles, after a warm-up.
class PowerUpSpawner extends Component with HasGameReference<MirrorRunGame> {
  final Random _rng;
  PowerUpSpawner({Random? rng}) : _rng = rng ?? Random();

  double _spawnTimer = 9.0;

  /// Power-ups don't appear until the player has some distance under their belt.
  static const int _minScore = 30;

  // NOTE: no update(dt) override — driven from the fixed step (MirrorRunGame._tick).

  /// One fixed simulation step, invoked from [MirrorRunGame._tick].
  void fixedUpdate(double step) {
    if (game.playState != PlayState.playing) return;
    if (game.score < _minScore) return;

    _spawnTimer -= step;
    if (_spawnTimer <= 0) {
      _trySpawn();
      // 11–17 s between power-ups — scarce but frequent enough to matter.
      _spawnTimer = 11.0 + _rng.nextDouble() * 6.0;
    }
  }

  void _trySpawn() {
    final side = _rng.nextBool() ? 'left' : 'right';
    final lanes = side == 'left'
        ? MirrorRunGame.mirrorLanesL
        : MirrorRunGame.mirrorLanesR;

    final freeLanes = <int>[];
    for (int lane = 0; lane < 3; lane++) {
      if (_isLaneFree(side, lane)) freeLanes.add(lane);
    }
    if (freeLanes.isEmpty) return;

    final lane = freeLanes[_rng.nextInt(freeLanes.length)];
    final type = PowerUpType.values[_rng.nextInt(PowerUpType.values.length)];
    game.world.add(PowerUp(
      side: side,
      lane: lane,
      laneCenterX: lanes[lane],
      type: type,
      scrollPos: -40,
    ));
  }

  bool _isLaneFree(String side, int lane) {
    final obstacles = game.world.children
        .whereType<Obstacle>()
        .where((o) => o.side == side && o.scrollPos > -140 && o.scrollPos < 120);
    for (final o in obstacles) {
      if (o.blockedLanes.contains(lane)) return false;
    }
    final existing = game.world.children
        .whereType<PowerUp>()
        .where((p) => p.side == side && p.lane == lane && p.scrollPos < 80);
    return existing.isEmpty;
  }
}
