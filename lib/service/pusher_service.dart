import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

class PusherService {
  static final PusherService _instance = PusherService._internal();

  factory PusherService() => _instance;

  final PusherChannelsFlutter pusher = PusherChannelsFlutter.getInstance();

  final Map<String, Function(dynamic)> _eventCallbacks = {};
  final Set<String> _subscribedChannels = {};
  bool _initialized = false;

  PusherService._internal();

  /// Safely subscribe to a channel, ignoring "Already subscribed" errors.
  Future<void> _safeSubscribe(String channelName) async {
    try {
      await pusher.subscribe(channelName: channelName);
    } catch (e) {
      // "Already subscribed" from native SDK — safe to ignore.
      // This happens after hot restart or reconnect.
      debugPrint("⚠️ Subscribe warning ($channelName): ${e.toString().split('\n').first}");
    }
  }

  /// Initialize Pusher
  Future<void> init({
    required String apiKey,
    required String cluster,
  }) async {
    if (_initialized) return;

    await pusher.init(
      apiKey: apiKey,
      cluster: cluster,
      activityTimeout: 120000,
      pongTimeout: 30000,
      maxReconnectionAttempts: 6,
      maxReconnectGapInSeconds: 30,
      onEvent: (PusherEvent event) {
        final key = '${event.channelName}:${event.eventName}';
        final raw = event.data;

        if (_eventCallbacks.containsKey(key)) {
          dynamic decoded = raw;
          try {
            if (raw is String && raw.trim().startsWith("{")) {
              decoded = jsonDecode(raw);
            }
          } catch (e) {
            debugPrint("❌ JSON decode error: $e | raw: $raw");
          }

          try {
            _eventCallbacks[key]?.call(decoded);
          } catch (e, stack) {
            debugPrint("❌ Callback error: $e\n$stack");
          }
        }
      },
      onConnectionStateChange: (currentState, previousState) {
        debugPrint("🔌 Connection state changed: $previousState → $currentState");

        // On reconnect, re-subscribe to all tracked channels.
        // Uses _safeSubscribe to handle "Already subscribed" from native SDK.
        if (currentState == 'CONNECTED' && previousState == 'RECONNECTING') {
          _resubscribeAll();
        }
      },
      onSubscriptionSucceeded: (channelName, data) {
        debugPrint("✅ Subscribed to $channelName");
      },
      onError: (message, code, e) {
        debugPrint("❗ Pusher Error: $message ($code)");
      },
    );

    await pusher.connect();
    _initialized = true;
  }

  Future<void> _resubscribeAll() async {
    for (final channel in _subscribedChannels.toList()) {
      await _safeSubscribe(channel);
    }
  }

  // -----------------------------
  // Driver New Order Channel
  // -----------------------------
  Future<void> subscribeDriverRecentRide<T>(
      {required String driverId,
      required String event,
      required T Function(Map<String, dynamic>) fromJson,
      required void Function(T) onData}) async {
    final channelName = 'driverNewOrder.$driverId';
    final eventKey = '$channelName:$event';

    _eventCallbacks[eventKey] = (data) {
      final pretty = data is Map || data is List
          ? const JsonEncoder.withIndent('  ').convert(data)
          : data.toString();
      log("📬 Received event [$eventKey]: $pretty");
      try {
        final parsed = data is String ? jsonDecode(data) : Map<String, dynamic>.from(data);
        final model = fromJson(parsed);
        onData(model);
      } catch (e, stack) {
        debugPrint("❌ Error parsing DriverRecentRide model: $e\n$stack\nData: $data");
      }
    };

    if (!_subscribedChannels.contains(channelName)) {
      _subscribedChannels.add(channelName);
      await _safeSubscribe(channelName);
    }
  }

  Future<void> unsubscribeDriverRecentRide(String driverId) async {
    final channel = 'driverNewOrder.$driverId';
    try { await pusher.unsubscribe(channelName: channel); } catch (_) {}
    _subscribedChannels.remove(channel);
    _eventCallbacks.removeWhere((key, _) => key.startsWith('$channel:'));
  }

  // -----------------------------
  // Ride Channel
  // -----------------------------
  Future<void> subscribeToRideEvent<T>({
    required String rideId,
    required String event,
    required T Function(Map<String, dynamic>) fromJson,
    required void Function(T) onData,
  }) async {
    final channelName = 'ride.$rideId';
    final eventKey = '$channelName:$event';

    _eventCallbacks[eventKey] = (data) {
      final pretty = data is Map || data is List
          ? const JsonEncoder.withIndent('  ').convert(data)
          : data.toString();
      log("📬 Received event [$eventKey]: $pretty");
      try {
        final parsed = data is String ? jsonDecode(data) : Map<String, dynamic>.from(data);
        final model = fromJson(parsed);
        onData(model);
      } catch (e, stack) {
        debugPrint("❌ Error parsing Ride model: $e\n$stack\nData: $data");
      }
    };

    if (!_subscribedChannels.contains(channelName)) {
      _subscribedChannels.add(channelName);
      await _safeSubscribe(channelName);
    }
  }

  Future<void> unsubscribeRide(String rideId) async {
    final channel = 'ride.$rideId';
    try { await pusher.unsubscribe(channelName: channel); } catch (_) {}
    _subscribedChannels.remove(channel);
    _eventCallbacks.removeWhere((key, _) => key.startsWith('$channel:'));
  }

  // -----------------------------
  // Call Channel
  // -----------------------------
  Future<void> subscribeToCallEvent({
    required String userId,
    required String userType,
    required void Function(Map<String, dynamic>) onIncomingCall,
    required void Function(Map<String, dynamic>) onCallEnded,
    required void Function(Map<String, dynamic>) onCallRejected,
    required void Function(Map<String, dynamic>) onCallAccepted,
  }) async {
    final channelName = 'call.$userType.$userId';

    _eventCallbacks['$channelName:incoming'] = (data) {
      try {
        final parsed = data is String ? jsonDecode(data) : Map<String, dynamic>.from(data);
        onIncomingCall(parsed);
      } catch (e) {
        debugPrint("Error parsing incoming call: $e");
      }
    };

    _eventCallbacks['$channelName:ended'] = (data) {
      try {
        final parsed = data is String ? jsonDecode(data) : Map<String, dynamic>.from(data);
        onCallEnded(parsed);
      } catch (e) {
        debugPrint("Error parsing call ended: $e");
      }
    };

    _eventCallbacks['$channelName:rejected'] = (data) {
      try {
        final parsed = data is String ? jsonDecode(data) : Map<String, dynamic>.from(data);
        onCallRejected(parsed);
      } catch (e) {
        debugPrint("Error parsing call rejected: $e");
      }
    };

    _eventCallbacks['$channelName:accepted'] = (data) {
      try {
        final parsed = data is String ? jsonDecode(data) : Map<String, dynamic>.from(data);
        onCallAccepted(parsed);
      } catch (e) {
        debugPrint("Error parsing call accepted: $e");
      }
    };

    if (!_subscribedChannels.contains(channelName)) {
      _subscribedChannels.add(channelName);
      await _safeSubscribe(channelName);
      debugPrint("Subscribed to call channel: $channelName");
    }
  }

  // -----------------------------
  // Driver Channel
  // -----------------------------
  Future<void> subscribeToDriverEvent<T>({
    required String driverId,
    required String event,
    required T Function(Map<String, dynamic>) fromJson,
    required void Function(T) onData,
  }) async {
    final channelName = 'driver.$driverId';
    final eventKey = '$channelName:$event';

    _eventCallbacks[eventKey] = (data) {
      final pretty = data is Map || data is List
          ? const JsonEncoder.withIndent('  ').convert(data)
          : data.toString();
      log("📬 Received event [$eventKey]: $pretty");
      try {
        final parsed = data is String ? jsonDecode(data) : Map<String, dynamic>.from(data);
        final model = fromJson(parsed);
        onData(model);
      } catch (e, stack) {
        debugPrint("❌ Error parsing Driver model: $e\n$stack\nData: $data");
      }
    };

    if (!_subscribedChannels.contains(channelName)) {
      _subscribedChannels.add(channelName);
      await _safeSubscribe(channelName);
    }
  }

  Future<void> unsubscribeDriver(String driverId) async {
    final channel = 'driver.$driverId';
    try { await pusher.unsubscribe(channelName: channel); } catch (_) {}
    _subscribedChannels.remove(channel);
    _eventCallbacks.removeWhere((key, _) => key.startsWith('$channel:'));
  }
}
