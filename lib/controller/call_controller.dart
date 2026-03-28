import 'dart:async';
import 'dart:convert';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:uniqcars_driver/constant/constant.dart';
import 'package:uniqcars_driver/page/call_screen/active_call_screen.dart';
import 'package:uniqcars_driver/page/call_screen/incoming_call_screen.dart';
import 'package:uniqcars_driver/service/api.dart';
import 'package:uniqcars_driver/utils/Preferences.dart';

class CallController extends GetxController {
  var callStatus = 'idle'.obs; // idle, ringing, connecting, active, ended
  var isMuted = false.obs;
  var isSpeakerOn = false.obs;
  var callDuration = 0.obs;
  var callerName = ''.obs;
  var callerPhoto = ''.obs;
  var currentCallId = 0.obs;
  var currentChannelName = ''.obs;

  RtcEngine? _agoraEngine;
  Timer? _callTimer;
  Timer? _missedCallTimer;

  Map<String, dynamic>? _incomingCallData;

  @override
  void onClose() {
    _dispose();
    super.onClose();
  }

  Future<void> _dispose() async {
    _callTimer?.cancel();
    _missedCallTimer?.cancel();
    await _agoraEngine?.leaveChannel();
    await _agoraEngine?.release();
    _agoraEngine = null;
  }

  Future<bool> _requestMicPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> _initAgoraEngine() async {
    if (_agoraEngine != null) return;

    _agoraEngine = createAgoraRtcEngine();
    await _agoraEngine!.initialize(RtcEngineContext(
      appId: Constant.agoraAppId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    _agoraEngine!.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
        debugPrint('Agora: Joined channel ${connection.channelId}');
      },
      onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
        debugPrint('Agora: Remote user $remoteUid joined');
        callStatus.value = 'active';
        _startCallTimer();
      },
      onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
        debugPrint('Agora: Remote user $remoteUid left');
        endCall();
      },
      onError: (ErrorCodeType err, String msg) {
        debugPrint('Agora Error: $err - $msg');
      },
    ));

    await _agoraEngine!.enableAudio();
    await _agoraEngine!.setEnableSpeakerphone(false);
  }

  /// Initiate outgoing call
  Future<void> initiateCall({
    required int receiverId,
    required String receiverType,
    int? rideId,
    String? receiverName,
    String? receiverPhoto,
  }) async {
    if (callStatus.value != 'idle') return;

    final hasMic = await _requestMicPermission();
    if (!hasMic) {
      Get.snackbar('Permission Denied', 'Microphone permission is required for calls');
      return;
    }

    callStatus.value = 'connecting';
    callerName.value = receiverName ?? 'Unknown';
    callerPhoto.value = receiverPhoto ?? '';

    final userId = Preferences.getString(Preferences.userId);

    final response = await API.handleApiRequest(
      showLoader: false,
      request: () => http.post(
        Uri.parse(API.callInitiate),
        headers: API.headers,
        body: jsonEncode({
          'caller_type': 'driver',
          'caller_id': userId,
          'receiver_type': receiverType,
          'receiver_id': receiverId,
          'ride_id': rideId,
        }),
      ),
    );

    if (response != null && response['success'] == 'success') {
      final data = response['data'];
      currentCallId.value = data['call_id'];
      currentChannelName.value = data['channel_name'];

      await _initAgoraEngine();
      await _agoraEngine!.joinChannel(
        token: data['agora_token'],
        channelId: data['channel_name'],
        uid: data['agora_uid'],
        options: const ChannelMediaOptions(
          autoSubscribeAudio: true,
          publishMicrophoneTrack: true,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
        ),
      );

      callStatus.value = 'ringing';
      Get.to(() => const ActiveCallScreen());

      _missedCallTimer = Timer(const Duration(seconds: 30), () {
        if (callStatus.value == 'ringing') {
          _markMissed();
          endCall();
        }
      });
    } else {
      callStatus.value = 'idle';
    }
  }

  /// Handle incoming call from Pusher event
  void handleIncomingCall(Map<String, dynamic> data) {
    if (callStatus.value != 'idle') return;

    _incomingCallData = data;
    callerName.value = data['caller_name'] ?? 'Unknown';
    callerPhoto.value = data['caller_photo'] ?? '';
    currentCallId.value = data['call_id'] ?? 0;
    currentChannelName.value = data['channel_name'] ?? '';
    callStatus.value = 'ringing';

    Get.to(() => const IncomingCallScreen());

    _missedCallTimer = Timer(const Duration(seconds: 30), () {
      if (callStatus.value == 'ringing' && _incomingCallData != null) {
        _markMissed();
        dismissIncomingCall();
      }
    });
  }

  /// Accept incoming call
  Future<void> acceptCall() async {
    if (_incomingCallData == null) return;

    _missedCallTimer?.cancel();
    callStatus.value = 'connecting';

    final hasMic = await _requestMicPermission();
    if (!hasMic) {
      rejectCall();
      return;
    }

    await API.handleApiRequest(
      showLoader: false,
      request: () => http.post(
        Uri.parse(API.callAccept),
        headers: API.headers,
        body: jsonEncode({'call_id': currentCallId.value}),
      ),
    );

    await _initAgoraEngine();
    await _agoraEngine!.joinChannel(
      token: _incomingCallData!['agora_token'],
      channelId: _incomingCallData!['channel_name'],
      uid: _incomingCallData!['agora_uid'],
      options: const ChannelMediaOptions(
        autoSubscribeAudio: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
    );

    callStatus.value = 'active';
    _startCallTimer();

    Get.off(() => const ActiveCallScreen());
    _incomingCallData = null;
  }

  /// Reject incoming call
  Future<void> rejectCall() async {
    _missedCallTimer?.cancel();

    await API.handleApiRequest(
      showLoader: false,
      request: () => http.post(
        Uri.parse(API.callReject),
        headers: API.headers,
        body: jsonEncode({'call_id': currentCallId.value}),
      ),
    );

    dismissIncomingCall();
  }

  /// End active call
  Future<void> endCall() async {
    _callTimer?.cancel();
    _missedCallTimer?.cancel();

    if (currentCallId.value > 0) {
      await API.handleApiRequest(
        showLoader: false,
        request: () => http.post(
          Uri.parse(API.callEnd),
          headers: API.headers,
          body: jsonEncode({'call_id': currentCallId.value}),
        ),
      );
    }

    await _agoraEngine?.leaveChannel();
    await _agoraEngine?.release();
    _agoraEngine = null;

    callStatus.value = 'idle';
    callDuration.value = 0;
    currentCallId.value = 0;
    currentChannelName.value = '';
    _incomingCallData = null;

    if (Get.isDialogOpen == true || Get.isBottomSheetOpen == true) {
      Get.back();
    }
    if (Get.currentRoute == '/ActiveCallScreen' || Get.currentRoute == '/IncomingCallScreen') {
      Get.back();
    }
  }

  /// Handle call ended by other party (from Pusher)
  void handleCallEnded(Map<String, dynamic> data) {
    if (data['call_id'] == currentCallId.value) {
      endCall();
    }
  }

  /// Handle call rejected by receiver (from Pusher)
  void handleCallRejected(Map<String, dynamic> data) {
    if (data['call_id'] == currentCallId.value) {
      endCall();
    }
  }

  void dismissIncomingCall() {
    callStatus.value = 'idle';
    currentCallId.value = 0;
    currentChannelName.value = '';
    _incomingCallData = null;
    if (Get.currentRoute == '/IncomingCallScreen') {
      Get.back();
    }
  }

  void toggleMute() {
    isMuted.value = !isMuted.value;
    _agoraEngine?.muteLocalAudioStream(isMuted.value);
  }

  void toggleSpeaker() {
    isSpeakerOn.value = !isSpeakerOn.value;
    _agoraEngine?.setEnableSpeakerphone(isSpeakerOn.value);
  }

  void _startCallTimer() {
    _callTimer?.cancel();
    callDuration.value = 0;
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      callDuration.value++;
    });
  }

  Future<void> _markMissed() async {
    if (currentCallId.value > 0) {
      await API.handleApiRequest(
        showLoader: false,
        request: () => http.post(
          Uri.parse(API.callMissed),
          headers: API.headers,
          body: jsonEncode({'call_id': currentCallId.value}),
        ),
      );
    }
  }

  String get formattedDuration {
    final minutes = (callDuration.value ~/ 60).toString().padLeft(2, '0');
    final seconds = (callDuration.value % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
