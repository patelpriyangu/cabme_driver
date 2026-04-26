import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:uniqcars_driver/constant/show_toast_dialog.dart';
import 'package:uniqcars_driver/service/api.dart';
import 'package:uniqcars_driver/utils/Preferences.dart';

/// Controls a Start/Stop "Waiting" meter for a single ride context.
///
/// Two contexts are supported per ride:
///   - `pre_ride`  : driver has marked Arrived but ride hasn't started.
///   - `mid_ride`  : ride is in progress and passenger asked to wait.
///
/// State is persisted server-side (idempotent start endpoint), so this
/// controller calls `waiting-status` on init / when asked, to recover any
/// active session if the app was killed and restored mid-wait.
class WaitingController extends GetxController {
  /// Live counter — seconds elapsed in the current active session.
  RxInt elapsedSeconds = 0.obs;

  /// Whether a waiting session is currently active.
  RxBool isActive = false.obs;

  /// Whether an API call (start/stop/status) is in flight.
  RxBool isBusy = false.obs;

  /// Server-reported context for the active session (pre_ride / mid_ride).
  RxString context = ''.obs;

  /// Per-minute charging rate (after grace expires). E.g. `0.50` GBP/min.
  RxDouble accruingRatePerMinute = 0.0.obs;

  /// Free grace period in minutes — no charge accrues until this passes.
  RxInt gracePeriodMinutes = 3.obs;

  /// Currently accruing charge (computed locally from elapsed + rate).
  RxDouble accruingCharge = 0.0.obs;

  /// Total cumulative waiting minutes for this ride across all sessions.
  RxString totalWaitingMinutes = '0'.obs;

  /// Total cumulative waiting charge across all sessions.
  RxString totalWaitingCharge = '0'.obs;

  Timer? _ticker;

  /// Identifies the ride this controller is bound to so we can decide
  /// whether to refresh on context changes.
  String? _rideId;
  String? _rideType;

  /// Bind this controller to a specific ride/type. Safe to call multiple
  /// times — if the ride changes we reset state and re-fetch status.
  Future<void> bindRide({
    required String rideId,
    required String rideType,
  }) async {
    if (_rideId == rideId && _rideType == rideType) {
      return;
    }
    _rideId = rideId;
    _rideType = rideType;
    _resetLocalState();
    await refreshStatus();
  }

  void _resetLocalState() {
    _ticker?.cancel();
    _ticker = null;
    elapsedSeconds.value = 0;
    isActive.value = false;
    context.value = '';
    accruingCharge.value = 0.0;
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      elapsedSeconds.value = elapsedSeconds.value + 1;
      _recomputeAccruingCharge();
    });
  }

  void _recomputeAccruingCharge() {
    final int graceSecs = gracePeriodMinutes.value * 60;
    if (elapsedSeconds.value <= graceSecs) {
      accruingCharge.value = 0.0;
      return;
    }
    final int chargeableSecs = elapsedSeconds.value - graceSecs;
    final double minutesElapsed = chargeableSecs / 60.0;
    accruingCharge.value = minutesElapsed * accruingRatePerMinute.value;
  }

  /// Returns true if we are still inside the free grace window.
  bool get isInGrace {
    return elapsedSeconds.value < (gracePeriodMinutes.value * 60);
  }

  /// MM:SS formatted live elapsed display.
  String get formattedElapsed {
    final int total = elapsedSeconds.value;
    final int m = total ~/ 60;
    final int s = total % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Hit `waiting-status` and rehydrate local state. Safe to call any time.
  Future<void> refreshStatus() async {
    if (_rideId == null || _rideType == null) return;
    final String url = '${API.waitingStatus}'
        '?request_id=$_rideId&type=$_rideType';
    try {
      final response = await http
          .get(Uri.parse(url), headers: API.headers)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return;
      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map) return;
      _applyStatusPayload(Map<String, dynamic>.from(decoded));
    } catch (e) {
      if (kDebugMode) {
        // Silent failure — UI stays in last-known state.
        // ignore: avoid_print
        print('WaitingController.refreshStatus error: $e');
      }
    }
  }

  void _applyStatusPayload(Map<String, dynamic> payload) {
    // Backend wraps response as {success, code, message, data: {...}}.
    final Map<String, dynamic> inner = (payload['data'] is Map)
        ? Map<String, dynamic>.from(payload['data'] as Map)
        : payload;

    final bool active = inner['active'] == true;
    totalWaitingMinutes.value =
        inner['total_waiting_minutes']?.toString() ?? '0';
    totalWaitingCharge.value =
        inner['total_waiting_charge']?.toString() ?? '0';

    if (!active) {
      _resetLocalState();
      return;
    }

    // Active session — apply server-provided fields if present.
    context.value = inner['context']?.toString() ?? '';
    final dynamic rate = inner['accruing_rate_per_minute'];
    if (rate != null) {
      accruingRatePerMinute.value =
          double.tryParse(rate.toString()) ?? accruingRatePerMinute.value;
    }
    final dynamic grace = inner['grace_period_minutes'];
    if (grace != null) {
      gracePeriodMinutes.value =
          int.tryParse(grace.toString()) ?? gracePeriodMinutes.value;
    }
    final dynamic elapsed = inner['current_session_elapsed_seconds'];
    if (elapsed != null) {
      elapsedSeconds.value =
          int.tryParse(elapsed.toString()) ?? elapsedSeconds.value;
    } else {
      // If server didn't send elapsed but said active, start from 0.
      elapsedSeconds.value = 0;
    }
    final dynamic accruing = inner['accruing_charge'];
    if (accruing != null) {
      accruingCharge.value =
          double.tryParse(accruing.toString()) ?? accruingCharge.value;
    } else {
      _recomputeAccruingCharge();
    }

    isActive.value = true;
    _startTicker();
  }

  /// Calls POST start-waiting. Safe to call when already active (idempotent).
  Future<void> startWaiting({required String waitingContext}) async {
    if (_rideId == null || _rideType == null) {
      ShowToastDialog.showToast('Ride not ready');
      return;
    }
    if (isBusy.value) return;
    isBusy.value = true;
    try {
      final body = {
        'request_id': _rideId,
        'type': _rideType,
        'context': waitingContext,
        'id_driver': Preferences.getInt(Preferences.userId),
      };
      final value = await API.handleApiRequest(
        request: () => http.post(
          Uri.parse(API.startWaiting),
          headers: API.headers,
          body: jsonEncode(body),
        ),
        showLoader: false,
      );
      if (value == null) return;
      if (value['success'] == 'Failed' || value['success'] == 'failed') {
        ShowToastDialog.showToast(value['error']?.toString() ??
            value['message']?.toString() ??
            'Could not start waiting');
        return;
      }

      // Backend wraps response as {success, code, message, data: {...}}.
      final Map<String, dynamic> data = (value['data'] is Map)
          ? Map<String, dynamic>.from(value['data'] as Map)
          : <String, dynamic>{};

      // Apply returned config to local state.
      context.value =
          data['context']?.toString() ?? waitingContext;
      final dynamic rate = data['accruing_rate_per_minute'];
      if (rate != null) {
        accruingRatePerMinute.value =
            double.tryParse(rate.toString()) ?? accruingRatePerMinute.value;
      }
      final dynamic grace = data['grace_period_minutes'];
      if (grace != null) {
        gracePeriodMinutes.value =
            int.tryParse(grace.toString()) ?? gracePeriodMinutes.value;
      }

      // If the server says it was already active and tells us how long,
      // honour that; otherwise start from 0.
      final dynamic elapsed = data['current_session_elapsed_seconds'];
      if (elapsed != null) {
        elapsedSeconds.value =
            int.tryParse(elapsed.toString()) ?? 0;
      } else {
        elapsedSeconds.value = 0;
      }

      isActive.value = true;
      _recomputeAccruingCharge();
      _startTicker();
    } catch (e) {
      ShowToastDialog.showToast('Network error: $e');
    } finally {
      isBusy.value = false;
    }
  }

  /// Calls POST stop-waiting and resets the live counter.
  Future<void> stopWaiting() async {
    if (_rideId == null || _rideType == null) return;
    if (isBusy.value) return;
    isBusy.value = true;
    try {
      final body = {
        'request_id': _rideId,
        'type': _rideType,
        'id_driver': Preferences.getInt(Preferences.userId),
      };
      final value = await API.handleApiRequest(
        request: () => http.post(
          Uri.parse(API.stopWaiting),
          headers: API.headers,
          body: jsonEncode(body),
        ),
        showLoader: false,
      );
      if (value == null) return;
      if (value['success'] == 'Failed' || value['success'] == 'failed') {
        ShowToastDialog.showToast(value['error']?.toString() ??
            value['message']?.toString() ??
            'Could not stop waiting');
        return;
      }

      // Backend wraps response as {success, code, message, data: {...}}.
      final Map<String, dynamic> data = (value['data'] is Map)
          ? Map<String, dynamic>.from(value['data'] as Map)
          : <String, dynamic>{};

      totalWaitingMinutes.value =
          data['total_waiting_minutes']?.toString() ??
              totalWaitingMinutes.value;
      totalWaitingCharge.value =
          data['total_waiting_charge']?.toString() ??
              totalWaitingCharge.value;

      _resetLocalState();
    } catch (e) {
      ShowToastDialog.showToast('Network error: $e');
    } finally {
      isBusy.value = false;
    }
  }

  @override
  void onClose() {
    _ticker?.cancel();
    _ticker = null;
    super.onClose();
  }
}
