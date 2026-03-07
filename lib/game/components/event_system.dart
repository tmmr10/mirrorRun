import 'dart:math';
import 'package:flame/components.dart';
import '../game_state.dart';
import '../mirror_run_game.dart';

enum GameEvent { phantom, mirrorSwap }

class EventSystem extends Component with HasGameReference<MirrorRunGame> {
  final _rng = Random();

  double _eventCooldown = 0;
  GameEvent? activeEvent;
  double _eventTimer = 0;

  /// Warning time before event activates.
  double _warningTimer = 0;
  GameEvent? _pendingEvent;

  /// Phantom: 0 = fully visible, 1 = fully invisible.
  double phantomFade = 0;

  /// Mirror swap active flag.
  bool mirrorSwapped = false;

  /// Flash intensity for mirror swap (0..1).
  double swapFlash = 0;

  /// Recovery flash when event ends (1..0).
  double recoveryFlash = 0;

  static const double _warningDuration = 1.5;
  static const double _phantomDuration = 1.5;
  static const double _swapDuration = 4.0;

  /// Min score before events can trigger.
  static const int _minScore = 40;

  /// Force-activate an event (for screenshots/debug).
  void forceEvent(GameEvent event) {
    activeEvent = event;
    _eventCooldown = 999;
    switch (event) {
      case GameEvent.phantom:
        _eventTimer = _phantomDuration;
        phantomFade = 0.3;
      case GameEvent.mirrorSwap:
        _eventTimer = _swapDuration;
        mirrorSwapped = true;
        swapFlash = 0.4;
    }
    game.eventWarningNotifier.value = null;
    game.eventNotifier.value = event;
  }

  bool get isWarning => _pendingEvent != null && _warningTimer > 0;
  String get warningLabel => _pendingEvent == GameEvent.phantom ? 'PHANTOM' : 'SWAP';

  /// Warning progress 0..1.
  double get warningProgress => _pendingEvent != null
      ? 1 - (_warningTimer / _warningDuration)
      : 0;

  @override
  void update(double dt) {
    super.update(dt);
    if (game.playState != PlayState.playing) return;

    // Decay recovery flash
    if (recoveryFlash > 0) {
      recoveryFlash = (recoveryFlash - dt * 2.0).clamp(0.0, 1.0);
    }

    // Update active event
    if (activeEvent != null) {
      _eventTimer -= dt;

      if (activeEvent == GameEvent.phantom) {
        // Fade in quickly, sustain, fade out
        final remaining = _eventTimer;
        final total = _phantomDuration;
        final elapsed = total - remaining;
        if (elapsed < 0.3) {
          phantomFade = (elapsed / 0.3).clamp(0.0, 1.0);
        } else if (remaining < 0.5) {
          phantomFade = (remaining / 0.5).clamp(0.0, 1.0);
        } else {
          phantomFade = 1.0;
        }
      }

      if (activeEvent == GameEvent.mirrorSwap) {
        swapFlash = (swapFlash - dt * 3).clamp(0.0, 1.0);
      }

      if (_eventTimer <= 0) {
        _endEvent();
      }
      return;
    }

    // Update warning
    if (_pendingEvent != null) {
      _warningTimer -= dt;
      if (_warningTimer <= 0) {
        _startEvent(_pendingEvent!);
        _pendingEvent = null;
      }
      return;
    }

    // Try to trigger new event
    if (game.score < _minScore) return;
    _eventCooldown -= dt;
    if (_eventCooldown <= 0) {
      _triggerRandomEvent();
    }
  }

  void _triggerRandomEvent() {
    // Pick event based on score thresholds
    final events = <GameEvent>[];
    events.add(GameEvent.phantom);
    if (game.score >= 60) events.add(GameEvent.mirrorSwap);

    _pendingEvent = events[_rng.nextInt(events.length)];
    _warningTimer = _warningDuration;
    game.eventWarningNotifier.value = _pendingEvent == GameEvent.phantom ? 'PHANTOM' : 'SWAP';
  }

  void _startEvent(GameEvent event) {
    activeEvent = event;
    game.eventWarningNotifier.value = null;
    game.eventNotifier.value = event;

    switch (event) {
      case GameEvent.phantom:
        _eventTimer = _phantomDuration;
        phantomFade = 0;
      case GameEvent.mirrorSwap:
        _eventTimer = _swapDuration;
        mirrorSwapped = true;
        swapFlash = 1.0;
    }
  }

  void _endEvent() {
    if (activeEvent == GameEvent.mirrorSwap) {
      mirrorSwapped = false;
      swapFlash = 0;
    }
    if (activeEvent == GameEvent.phantom) {
      phantomFade = 0;
    }

    activeEvent = null;
    game.eventNotifier.value = null;
    game.eventEndNotifier.value++;
    recoveryFlash = 1.0;

    // Cooldown until next event (shorter at higher scores)
    final baseCooldown = max(8.0, 18.0 - game.score * 0.02);
    _eventCooldown = baseCooldown + _rng.nextDouble() * 5;
  }

  void reset() {
    activeEvent = null;
    _pendingEvent = null;
    _eventTimer = 0;
    _warningTimer = 0;
    _eventCooldown = 5;
    phantomFade = 0;
    mirrorSwapped = false;
    swapFlash = 0;
    recoveryFlash = 0;
  }
}
