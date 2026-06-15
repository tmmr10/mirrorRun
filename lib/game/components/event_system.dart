import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/services.dart';
import '../game_state.dart';
import '../mirror_run_game.dart';
import '../../services/analytics_service.dart';

enum GameEvent { phantom, mirrorSwap, desync, blackout }

String eventLabel(GameEvent e) {
  switch (e) {
    case GameEvent.phantom:
      return 'PHANTOM';
    case GameEvent.mirrorSwap:
      return 'SWAP';
    case GameEvent.desync:
      return 'DESYNC';
    case GameEvent.blackout:
      return 'BLACKOUT';
  }
}

String eventAnalyticsId(GameEvent e) {
  switch (e) {
    case GameEvent.phantom:
      return 'phantom';
    case GameEvent.mirrorSwap:
      return 'mirror_swap';
    case GameEvent.desync:
      return 'desync';
    case GameEvent.blackout:
      return 'blackout';
  }
}

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

  /// Desync: per-side scroll-speed multipliers (1.0 = normal).
  double desyncLeftFactor = 1.0;
  double desyncRightFactor = 1.0;

  /// Blackout: which side is darkened ('left'/'right') and the dim strength 0..1.
  String? blackoutSide;
  double blackoutFade = 0;

  /// Track which event types have already been logged this run (analytics quota).
  final Set<GameEvent> _loggedThisRun = {};

  static const double _warningDuration = 1.5;
  static const double _phantomDuration = 1.5;
  static const double _desyncDuration = 2.2;
  static const double _blackoutDuration = 2.2;
  // Swap no longer uses a timer — stays until next swap event.

  /// Min score before events can trigger.
  static const int _minScore = 25;

  /// Score gates for the harder cognitive events.
  static const int _desyncMinScore = 90;
  static const int _blackoutMinScore = 130;

  /// Force-activate an event (for screenshots/debug).
  void forceEvent(GameEvent event) {
    activeEvent = event;
    _eventCooldown = 999;
    switch (event) {
      case GameEvent.phantom:
        _eventTimer = _phantomDuration;
        phantomFade = 0.3;
      case GameEvent.mirrorSwap:
        mirrorSwapped = !mirrorSwapped;
        _eventTimer = 0.8;
        swapFlash = 0.4;
      case GameEvent.desync:
        _eventTimer = _desyncDuration;
        _applyDesyncFactors();
      case GameEvent.blackout:
        _eventTimer = _blackoutDuration;
        blackoutSide = _rng.nextBool() ? 'left' : 'right';
        blackoutFade = 1.0;
    }
    game.eventWarningNotifier.value = null;
    game.eventNotifier.value = event;
  }

  void _applyDesyncFactors() {
    // One side rushes, the other crawls — decouples the two timing streams.
    if (_rng.nextBool()) {
      desyncLeftFactor = 1.6;
      desyncRightFactor = 0.6;
    } else {
      desyncLeftFactor = 0.6;
      desyncRightFactor = 1.6;
    }
  }

  bool get isWarning => _pendingEvent != null && _warningTimer > 0;
  String get warningLabel =>
      _pendingEvent == null ? '' : eventLabel(_pendingEvent!);

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

      if (activeEvent == GameEvent.blackout) {
        // Fade in fast, sustain, fade out.
        final remaining = _eventTimer;
        final elapsed = _blackoutDuration - remaining;
        if (elapsed < 0.3) {
          blackoutFade = (elapsed / 0.3).clamp(0.0, 1.0);
        } else if (remaining < 0.4) {
          blackoutFade = (remaining / 0.4).clamp(0.0, 1.0);
        } else {
          blackoutFade = 1.0;
        }
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
    // Pick event based on score thresholds — more event types unlock as the
    // run progresses, so late game keeps introducing new cognitive load.
    final events = <GameEvent>[];
    events.add(GameEvent.phantom);
    if (game.score >= 60) events.add(GameEvent.mirrorSwap);
    if (game.score >= _desyncMinScore) events.add(GameEvent.desync);
    if (game.score >= _blackoutMinScore) events.add(GameEvent.blackout);

    _pendingEvent = events[_rng.nextInt(events.length)];
    _warningTimer = _warningDuration;
    game.eventWarningNotifier.value = eventLabel(_pendingEvent!);
  }

  void _startEvent(GameEvent event) {
    activeEvent = event;
    game.eventWarningNotifier.value = null;
    game.eventNotifier.value = event;
    if (game.settingsService.hapticEnabled) {
      HapticFeedback.mediumImpact();
    }
    // Only log each event type once per run to avoid flooding analytics quota
    if (!_loggedThisRun.contains(event)) {
      _loggedThisRun.add(event);
      unawaited(AnalyticsService.logEventTriggered(
        eventType: eventAnalyticsId(event),
      ));
    }

    switch (event) {
      case GameEvent.phantom:
        _eventTimer = _phantomDuration;
        phantomFade = 0;
      case GameEvent.mirrorSwap:
        // Toggle: if already swapped, swap back; otherwise swap
        mirrorSwapped = !mirrorSwapped;
        swapFlash = 1.0;
        // Short timer just for the flash/indicator, then clear active event
        _eventTimer = 0.8;
      case GameEvent.desync:
        _eventTimer = _desyncDuration;
        _applyDesyncFactors();
      case GameEvent.blackout:
        _eventTimer = _blackoutDuration;
        blackoutSide = _rng.nextBool() ? 'left' : 'right';
        blackoutFade = 0;
    }
  }

  void _endEvent() {
    if (activeEvent == GameEvent.phantom) {
      phantomFade = 0;
    }
    if (activeEvent == GameEvent.mirrorSwap) {
      // Don't reset mirrorSwapped — it stays until next swap toggles it
      swapFlash = 0;
    }
    if (activeEvent == GameEvent.desync) {
      desyncLeftFactor = 1.0;
      desyncRightFactor = 1.0;
    }
    if (activeEvent == GameEvent.blackout) {
      blackoutSide = null;
      blackoutFade = 0;
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
    _eventCooldown = 3;
    phantomFade = 0;
    mirrorSwapped = false;
    swapFlash = 0;
    recoveryFlash = 0;
    desyncLeftFactor = 1.0;
    desyncRightFactor = 1.0;
    blackoutSide = null;
    blackoutFade = 0;
    _loggedThisRun.clear();
  }
}
