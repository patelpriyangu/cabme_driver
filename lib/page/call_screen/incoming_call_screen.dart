import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uniqcars_driver/controller/call_controller.dart';

class IncomingCallScreen extends StatelessWidget {
  const IncomingCallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CallController callController = Get.find<CallController>();

    return Scaffold(
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
            const Text(
              'Incoming Voice Call',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 16,
                fontFamily: 'Manrope-Regular',
              ),
            ),
            const Spacer(flex: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () => callController.rejectCall(),
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
                      const SizedBox(height: 12),
                      const Text('Decline', style: TextStyle(color: Colors.white60, fontFamily: 'Manrope-Medium')),
                    ],
                  ),
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () => callController.acceptCall(),
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.call, color: Colors.white, size: 32),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Accept', style: TextStyle(color: Colors.white60, fontFamily: 'Manrope-Medium')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
          ],
        )),
      ),
    );
  }
}
