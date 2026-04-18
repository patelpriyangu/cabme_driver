import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

/// Manages the Uber/Ola-style looping alert sound and vibration
/// when a new ride request arrives for the driver.
class RideAlertService {
  RideAlertService._();
  static final RideAlertService _instance = RideAlertService._();
  factory RideAlertService() => _instance;

  bool _isPlaying = false;
  Timer? _vibrationTimer;
  Timer? _autoStopTimer;

  /// Maximum duration the alert will play before auto-stopping (seconds).
  static const int _autoStopSeconds = 45;

  /// Whether an alert is currently active.
  bool get isPlaying => _isPlaying;

  /// Start the ride alert: custom sound + periodic vibration.
  /// Safe to call multiple times — will not stack alerts.
  void play() {
    if (_isPlaying) return;
    _isPlaying = true;

    // Play custom UniqCars alert sound
    FlutterRingtonePlayer().play(
      fromAsset: 'assets/sounds/new_ride_alert.wav',
      looping: true,
      volume: 1.0,
      asAlarm: true,
    );

    // Vibrate every 1.5 seconds
    HapticFeedback.heavyImpact();
    _vibrationTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      HapticFeedback.heavyImpact();
    });

    // Auto-stop after timeout so it doesn't ring forever
    _autoStopTimer = Timer(Duration(seconds: _autoStopSeconds), () {
      stop();
    });
  }

  /// Stop the alert sound and vibration.
  void stop() {
    if (!_isPlaying) return;
    _isPlaying = false;

    FlutterRingtonePlayer().stop();

    _vibrationTimer?.cancel();
    _vibrationTimer = null;

    _autoStopTimer?.cancel();
    _autoStopTimer = null;
  }
}
