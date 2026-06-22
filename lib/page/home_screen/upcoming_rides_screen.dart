import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:uniqcars_driver/constant/constant.dart';
import 'package:uniqcars_driver/themes/app_them_data.dart';
import 'package:uniqcars_driver/utils/dark_theme_provider.dart';
import 'package:uniqcars_driver/utils/Preferences.dart';
import 'package:uniqcars_driver/page/booking_details_screens/booking_details_screen.dart';
import '../../controller/home_controller.dart';
import '../../model/booking_mode.dart';

class UpcomingRidesScreen extends StatelessWidget {
  const UpcomingRidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final controller = Get.find<HomeController>();
    return Obx(() {
      if (controller.isUpcomingLoading.value) {
        return const Expanded(
          child: Center(child: CircularProgressIndicator()),
        );
      }

      final hasActive = controller.upcomingRidesList.isNotEmpty;
      final hasCancelled = controller.recentlyCancelledRides.isNotEmpty;

      if (!hasActive && !hasCancelled) {
        return Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_available,
                  size: 64,
                  color: themeChange.getThem()
                      ? AppThemeData.neutralDark500
                      : AppThemeData.neutral500,
                ),
                const SizedBox(height: 16),
                Text(
                  "No upcoming scheduled rides",
                  style: AppThemeData.mediumTextStyle(
                    fontSize: 16,
                    color: themeChange.getThem()
                        ? AppThemeData.neutralDark500
                        : AppThemeData.neutral500,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Build a combined list: active rides first, then a "Recently Cancelled"
      // header followed by cancelled rides (last 24 h).
      final List<Widget> items = [];

      if (hasActive) {
        for (final ride in controller.upcomingRidesList) {
          items.add(_UpcomingRideCard(ride: ride, isCancelled: false));
        }
      }

      if (hasCancelled) {
        items.add(_CancelledSectionHeader());
        for (final ride in controller.recentlyCancelledRides) {
          items.add(_UpcomingRideCard(ride: ride, isCancelled: true));
        }
      }

      return Expanded(
        child: RefreshIndicator(
          onRefresh: controller.getUpcomingRides,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: items,
          ),
        ),
      );
    });
  }
}

/// Section divider shown above the recently-cancelled group.
class _CancelledSectionHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppThemeData.errorDefault.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppThemeData.errorDefault.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cancel_outlined,
                    size: 14, color: AppThemeData.errorDefault),
                const SizedBox(width: 5),
                Text(
                  "Recently Cancelled (last 24h)",
                  style: AppThemeData.semiBoldTextStyle(
                    fontSize: 12,
                    color: AppThemeData.errorDefault,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingRideCard extends StatelessWidget {
  final BookingData ride;
  final bool isCancelled;
  const _UpcomingRideCard({required this.ride, required this.isCancelled});

  String _formatScheduledAt(String? scheduledAt) {
    return scheduledAt ?? '';
  }

  String? _cleanValue(String? value) {
    if (value == null || value.isEmpty || value == 'null') {
      return null;
    }
    return value;
  }

  String _formatFare(String? montant) {
    if (montant == null || montant.isEmpty || montant == 'null') return '';
    try {
      final amount = double.parse(montant).toStringAsFixed(2);
      return Constant.symbolAtRight
          ? '$amount${Constant.currency ?? ''}'
          : '${Constant.currency ?? ''}$amount';
    } catch (_) {
      return montant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    final isDark = themeChange.getThem();

    final myDriverId = Preferences.getInt(Preferences.userId).toString();
    final assignedId = ride.assignedDriverId;
    final isAssignedToMe = assignedId != null &&
        assignedId.toString() != 'null' &&
        assignedId.toString().isNotEmpty &&
        assignedId.toString() == myDriverId;
    final isAssignedToOther = assignedId != null &&
        assignedId.toString() != 'null' &&
        assignedId.toString().isNotEmpty &&
        assignedId.toString() != myDriverId;

    final customerName =
        '${ride.user?.prenom ?? ''} ${ride.user?.nom ?? ''}'.trim();
    final fareStr = _formatFare(ride.montant);
    final distanceStr = (ride.distance != null && ride.distance != 'null')
        ? '${ride.distance} ${ride.distanceUnit ?? 'mi'}'
        : null;
    final durationStr =
        (ride.duree != null && ride.duree != 'null') ? ride.duree : null;
    final passengers = int.tryParse(ride.numberPoeple ?? '1') ?? 1;
    final cancelledBy = ride.cancelledBy != null &&
            ride.cancelledBy != 'null' &&
            ride.cancelledBy!.isNotEmpty
        ? ride.cancelledBy!
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCancelled
            ? BorderSide(
                color: AppThemeData.errorDefault.withValues(alpha: 0.6),
                width: 1.5)
            : BorderSide.none,
      ),
      color: isCancelled
          ? AppThemeData.errorDefault.withValues(alpha: 0.05)
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isCancelled
            ? null
            : () => Get.to(() => const BookingDetailsScreen(),
                arguments: {"bookingModel": ride}),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Scheduled time + fare ──────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule,
                          size: 16, color: AppThemeData.accentDefault),
                      const SizedBox(width: 6),
                      Text(
                        _formatScheduledAt(
                            ride.scheduledAtLondon ?? ride.scheduledAt),
                        style: AppThemeData.boldTextStyle(
                          fontSize: 14,
                          color: AppThemeData.accentDefault,
                        ),
                      ),
                    ],
                  ),
                  if (fareStr.isNotEmpty)
                    Text(
                      fareStr,
                      style: AppThemeData.boldTextStyle(
                        fontSize: 18,
                        color: isDark
                            ? AppThemeData.neutralDark900
                            : AppThemeData.neutral900,
                      ),
                    ),
                ],
              ),

              // ── Distance + duration ────────────────────────────────────
              if (distanceStr != null || durationStr != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (distanceStr != null) ...[
                      Icon(Icons.straighten,
                          size: 14,
                          color: isDark
                              ? AppThemeData.neutralDark500
                              : AppThemeData.neutral500),
                      const SizedBox(width: 4),
                      Text(
                        distanceStr,
                        style: AppThemeData.regularTextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppThemeData.neutralDark500
                              : AppThemeData.neutral500,
                        ),
                      ),
                    ],
                    if (distanceStr != null && durationStr != null)
                      Text(
                        '  ·  ',
                        style: AppThemeData.regularTextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppThemeData.neutralDark500
                                : AppThemeData.neutral500),
                      ),
                    if (durationStr != null) ...[
                      Icon(Icons.timer_outlined,
                          size: 14,
                          color: isDark
                              ? AppThemeData.neutralDark500
                              : AppThemeData.neutral500),
                      const SizedBox(width: 4),
                      Text(
                        '~$durationStr min',
                        style: AppThemeData.regularTextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppThemeData.neutralDark500
                              : AppThemeData.neutral500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],

              if (_cleanValue(ride.creer) != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.add_task_outlined,
                        size: 14,
                        color: isDark
                            ? AppThemeData.neutralDark500
                            : AppThemeData.neutral500),
                    const SizedBox(width: 4),
                    Text(
                      'Created: ${_cleanValue(ride.creer)!}',
                      style: AppThemeData.regularTextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppThemeData.neutralDark500
                            : AppThemeData.neutral500,
                      ),
                    ),
                  ],
                ),
              ],

              const Divider(height: 20),

              // ── Pickup ─────────────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.radio_button_checked,
                      color: AppThemeData.successDefault, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ride.departName ?? '',
                      style: AppThemeData.mediumTextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppThemeData.neutralDark900
                            : AppThemeData.neutral900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Dropoff ────────────────────────────────────────────────
              Row(
                children: [
                  const Icon(Icons.location_on,
                      color: AppThemeData.errorDefault, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ride.destinationName ?? '',
                      style: AppThemeData.mediumTextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppThemeData.neutralDark900
                            : AppThemeData.neutral900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const Divider(height: 20),

              // ── Customer + meta row ────────────────────────────────────
              Row(
                children: [
                  Icon(Icons.person_outline,
                      size: 15,
                      color: isDark
                          ? AppThemeData.neutralDark500
                          : AppThemeData.neutral500),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      customerName.isNotEmpty ? customerName : 'Customer',
                      style: AppThemeData.mediumTextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppThemeData.neutralDark900
                            : AppThemeData.neutral900,
                      ),
                    ),
                  ),
                  if (passengers > 1) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.group_outlined,
                        size: 15,
                        color: isDark
                            ? AppThemeData.neutralDark500
                            : AppThemeData.neutral500),
                    const SizedBox(width: 4),
                    Text(
                      '$passengers',
                      style: AppThemeData.regularTextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppThemeData.neutralDark500
                            : AppThemeData.neutral500,
                      ),
                    ),
                  ],
                ],
              ),

              if (isCancelled && cancelledBy != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.cancel_outlined,
                        size: 15, color: AppThemeData.errorDefault),
                    const SizedBox(width: 6),
                    Text(
                      'Cancelled by $cancelledBy',
                      style: AppThemeData.semiBoldTextStyle(
                        fontSize: 12,
                        color: AppThemeData.errorDefault,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // ── Booking # + badges ─────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Booking #${ride.bookingNumber ?? ride.id}",
                    style: AppThemeData.regularTextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppThemeData.neutralDark500
                          : AppThemeData.neutral500,
                    ),
                  ),
                  Row(
                    children: [
                      if (ride.seriesId != null)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppThemeData.infoDefault
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppThemeData.infoDefault
                                    .withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.event_repeat,
                                  size: 11, color: AppThemeData.infoDefault),
                              const SizedBox(width: 4),
                              Text(
                                "Recurring",
                                style: AppThemeData.semiBoldTextStyle(
                                  fontSize: 11,
                                  color: AppThemeData.infoDefault,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (ride.isPrepaid == true)
                        Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color:
                                AppThemeData.infoDefault.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppThemeData.infoDefault
                                    .withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            "Prepaid",
                            style: AppThemeData.semiBoldTextStyle(
                              fontSize: 11,
                              color: AppThemeData.infoDefault,
                            ),
                          ),
                        ),
                      if (isCancelled)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppThemeData.errorDefault
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppThemeData.errorDefault
                                    .withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cancel,
                                  size: 11, color: AppThemeData.errorDefault),
                              const SizedBox(width: 4),
                              Text(
                                "CANCELLED",
                                style: AppThemeData.semiBoldTextStyle(
                                  fontSize: 11,
                                  color: AppThemeData.errorDefault,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppThemeData.warningDefault
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: AppThemeData.warningDefault
                                    .withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            "Scheduled",
                            style: AppThemeData.semiBoldTextStyle(
                              fontSize: 11,
                              color: AppThemeData.warningDefault,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // ── Action button ──────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isCancelled)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color:
                            AppThemeData.errorDefault.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppThemeData.errorDefault
                                .withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cancel_outlined,
                              size: 14, color: AppThemeData.errorDefault),
                          const SizedBox(width: 4),
                          Text(
                            "Cancelled",
                            style: AppThemeData.semiBoldTextStyle(
                              fontSize: 12,
                              color: AppThemeData.errorDefault,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (isAssignedToMe)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color:
                            AppThemeData.successDefault.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppThemeData.successDefault
                                .withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              size: 14, color: AppThemeData.successDefault),
                          const SizedBox(width: 4),
                          Text(
                            "You accepted",
                            style: AppThemeData.semiBoldTextStyle(
                              fontSize: 12,
                              color: AppThemeData.successDefault,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (isAssignedToOther)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppThemeData.neutralDark100
                            : AppThemeData.neutral100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isDark
                                ? AppThemeData.neutralDark500
                                : AppThemeData.neutral500),
                      ),
                      child: Text(
                        "Taken",
                        style: AppThemeData.semiBoldTextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppThemeData.neutralDark500
                              : AppThemeData.neutral500,
                        ),
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () => Get.find<HomeController>()
                          .acceptUpcomingRide(ride.id ?? ''),
                      icon: const Icon(Icons.check, size: 16),
                      label: Text(
                        "Accept",
                        style: AppThemeData.semiBoldTextStyle(fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
