import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uniqcars_driver/controller/call_controller.dart';

class ActiveCallScreen extends StatelessWidget {
  const ActiveCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CallController callController = Get.find<CallController>();

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        body: SafeArea(
          child: Obx(() => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24, width: 3),
                ),
                child: ClipOval(
                  child: callController.callerPhoto.value.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: callController.callerPhoto.value,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Icon(Icons.person, size: 60, color: Colors.white54),
                          errorWidget: (_, __, ___) => const Icon(Icons.person, size: 60, color: Colors.white54),
                        )
                      : const Icon(Icons.person, size: 60, color: Colors.white54),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                callController.callerName.value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontFamily: 'Manrope-Bold',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                callController.callStatus.value == 'ringing'
                    ? 'Ringing...'
                    : callController.callStatus.value == 'connecting'
                        ? 'Connecting...'
                        : callController.formattedDuration,
                style: const TextStyle(
                  color: Colors.white60,
                  fontSize: 18,
                  fontFamily: 'Manrope-Regular',
                ),
              ),
              const Spacer(flex: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(
                      icon: callController.isMuted.value ? Icons.mic_off : Icons.mic,
                      label: callController.isMuted.value ? 'Unmute' : 'Mute',
                      color: callController.isMuted.value ? Colors.white24 : Colors.white12,
                      onTap: () => callController.toggleMute(),
                    ),
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () => callController.endCall(),
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.call_end, color: Colors.white, size: 32),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text('End', style: TextStyle(color: Colors.white60, fontFamily: 'Manrope-Medium')),
                      ],
                    ),
                    _buildControlButton(
                      icon: callController.isSpeakerOn.value ? Icons.volume_up : Icons.volume_down,
                      label: 'Speaker',
                      color: callController.isSpeakerOn.value ? Colors.white24 : Colors.white12,
                      onTap: () => callController.toggleSpeaker(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
            ],
          )),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white60, fontFamily: 'Manrope-Medium')),
      ],
    );
  }
}
