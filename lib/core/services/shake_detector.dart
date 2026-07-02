import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Fires [onShake] once the device has been shaken *continuously* for
/// [sustainedFor] (default 1.22s). A short idle gap resets the window, and a
/// cooldown prevents repeat triggers from one long shake.
class ShakeDetector {
  final VoidCallback onShake;
  final Duration sustainedFor;
  final double gThreshold;
  final Duration cooldown;

  StreamSubscription<AccelerometerEvent>? _sub;
  DateTime? _shakeStart;
  DateTime? _lastShakeAt;
  DateTime? _lastTrigger;

  ShakeDetector({
    required this.onShake,
    this.sustainedFor = const Duration(milliseconds: 1220),
    this.gThreshold = 1.8,
    this.cooldown = const Duration(seconds: 2),
  });

  void start() {
    _sub ??= accelerometerEventStream(
      samplingPeriod: SensorInterval.gameInterval,
    ).listen(_onData);
  }

  void _onData(AccelerometerEvent e) {
    // g-force magnitude (includes gravity → ~1.0 at rest).
    final gForce = sqrt(e.x * e.x + e.y * e.y + e.z * e.z) / 9.80665;
    final now = DateTime.now();

    if (gForce > gThreshold) {
      _lastShakeAt = now;
      _shakeStart ??= now;

      if (now.difference(_shakeStart!) >= sustainedFor) {
        final onCooldown =
            _lastTrigger != null && now.difference(_lastTrigger!) < cooldown;
        if (!onCooldown) {
          _lastTrigger = now;
          _shakeStart = null;
          onShake();
        }
      }
    } else if (_lastShakeAt != null &&
        now.difference(_lastShakeAt!) > const Duration(milliseconds: 300)) {
      // Shaking paused for too long — reset the sustained window.
      _shakeStart = null;
    }
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
