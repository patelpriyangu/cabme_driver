import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:uniqcars_driver/constant/constant.dart';
import 'package:uniqcars_driver/controller/waiting_controller.dart';
import 'package:uniqcars_driver/themes/app_them_data.dart';
import 'package:uniqcars_driver/utils/dark_theme_provider.dart';

/// Inline widget shown on the active-ride screen to start/stop a "Waiting"
/// meter. Visible only when the [waitingContext] is meaningful (driver
/// arrived but ride not started, or ride in progress).
class WaitingTimerWidget extends StatefulWidget {
  final String rideId;

  /// API request type — 'requete' for normal rides.
  final String rideType;

  /// 'pre_ride' or 'mid_ride' — drives label & API context value.
  final String waitingContext;

  const WaitingTimerWidget({
    super.key,
    required this.rideId,
    required this.rideType,
    required this.waitingContext,
  });

  @override
  State<WaitingTimerWidget> createState() => _WaitingTimerWidgetState();
}

class _WaitingTimerWidgetState extends State<WaitingTimerWidget> {
  late WaitingController _controller;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<WaitingController>()) {
      _controller = Get.find<WaitingController>();
    } else {
      _controller = Get.put(WaitingController(), permanent: false);
    }
    // Bind asynchronously so initState stays light.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.bindRide(rideId: widget.rideId, rideType: widget.rideType);
    });
  }

  @override
  void didUpdateWidget(covariant WaitingTimerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rideId != widget.rideId ||
        oldWidget.rideType != widget.rideType) {
      _controller.bindRide(rideId: widget.rideId, rideType: widget.rideType);
    }
  }

  @override
  void dispose() {
    // Tear down the controller so the timer/state doesn't leak across rides.
    if (Get.isRegistered<WaitingController>()) {
      Get.delete<WaitingController>();
    }
    super.dispose();
  }

  String _formatMoney(double value) {
    final fixed = value.toStringAsFixed(
        int.tryParse(Constant.decimal ?? '2') ?? 2);
    return Constant.symbolAtRight
        ? '$fixed${Constant.currency ?? ''}'
        : '${Constant.currency ?? ''}$fixed';
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();
    return Obx(() {
      final bool active = _controller.isActive.value;
      final bool busy = _controller.isBusy.value;
      final bool inGrace = _controller.isInGrace;
      final String elapsed = _controller.formattedElapsed;
      final double rate = _controller.accruingRatePerMinute.value;
      final int graceMin = _controller.gracePeriodMinutes.value;
      final double charge = _controller.accruingCharge.value;

      final String chargeDisplay = active
          ? (inGrace
              ? '${_formatMoney(rate)}/min (after $graceMin min grace)'
              : '${_formatMoney(charge)} accrued')
          : '${_formatMoney(rate)}/min after $graceMin min grace';

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: active
              ? AppThemeData.warningDefault.withValues(alpha: 0.08)
              : (isDark
                  ? AppThemeData.neutralDark100
                  : AppThemeData.neutral100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? AppThemeData.warningDefault.withValues(alpha: 0.5)
                : (isDark
                    ? AppThemeData.neutralDark300
                    : AppThemeData.neutral300),
          ),
        ),
        child: Row(
          children: [
            Icon(
              active ? Icons.timer : Icons.timer_outlined,
              size: 22,
              color: active
                  ? AppThemeData.warningDefault
                  : (isDark
                      ? AppThemeData.neutralDark700
                      : AppThemeData.neutral700),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        active ? 'Waiting'.tr : 'Waiting Meter'.tr,
                        style: AppThemeData.boldTextStyle(
                          fontSize: 14,
                          color: isDark
                              ? AppThemeData.neutralDark900
                              : AppThemeData.neutral900,
                        ),
                      ),
                      if (active) ...[
                        const SizedBox(width: 8),
                        Text(
                          elapsed,
                          style: AppThemeData.boldTextStyle(
                            fontSize: 14,
                            color: AppThemeData.warningDefault,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    chargeDisplay,
                    style: AppThemeData.regularTextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppThemeData.neutralDark500
                          : AppThemeData.neutral500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (active) {
                        await _controller.stopWaiting();
                      } else {
                        await _controller.startWaiting(
                            waitingContext: widget.waitingContext);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: active
                    ? AppThemeData.errorDefault
                    : AppThemeData.successDefault,
                foregroundColor: AppThemeData.neutral50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
              ),
              child: busy
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      active ? 'Stop Waiting'.tr : 'Start Waiting'.tr,
                      style: AppThemeData.semiBoldTextStyle(
                        fontSize: 12,
                        color: AppThemeData.neutral50,
                      ),
                    ),
            ),
          ],
        ),
      );
    });
  }
}
