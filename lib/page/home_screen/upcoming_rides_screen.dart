import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uniqcars_driver/constant/constant.dart';
import 'package:uniqcars_driver/themes/app_them_data.dart';
import 'package:uniqcars_driver/utils/Preferences.dart';
import '../../controller/home_controller.dart';
import '../../model/booking_mode.dart';

class UpcomingRidesScreen extends StatelessWidget {
  const UpcomingRidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<HomeController>();
    return Obx(() {
      if (controller.isUpcomingLoading.value) {
        return const Expanded(
          child: Center(child: CircularProgressIndicator()),
        );
      }
      if (controller.upcomingRidesList.isEmpty) {
        return Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_available, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  "No upcoming scheduled rides",
                  style: AppThemeData.mediumTextStyle(
                    fontSize: 16,
                    color: AppThemeData.neutral500,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return Expanded(
        child: RefreshIndicator(
          onRefresh: controller.getUpcomingRides,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.upcomingRidesList.length,
            itemBuilder: (context, index) {
              final ride = controller.upcomingRidesList[index];
              return _UpcomingRideCard(ride: ride);
            },
          ),
        ),
      );
    });
  }
}

class _UpcomingRideCard extends StatelessWidget {
  final BookingData ride;
  const _UpcomingRideCard({required this.ride});

  String _formatScheduledAt(String? scheduledAt) {
    if (scheduledAt == null) return '';
    try {
      final utc = DateTime.parse(scheduledAt).toUtc();
      // Simple DST-aware London time: BST (UTC+1) runs April–October,
      // GMT (UTC+0) runs November–March. This is a close approximation.
      final month = utc.month;
      final offset = (month >= 4 && month <= 10) ? 1 : 0;
      final london = utc.add(Duration(hours: offset));
      final suffix = offset == 1 ? 'BST' : 'GMT';
      return "${london.day.toString().padLeft(2, '0')}/"
          "${london.month.toString().padLeft(2, '0')}/"
          "${london.year} "
          "${london.hour.toString().padLeft(2, '0')}:"
          "${london.minute.toString().padLeft(2, '0')} $suffix";
    } catch (_) {
      return scheduledAt;
    }
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      _formatScheduledAt(ride.scheduledAt),
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
                      color: AppThemeData.neutral900,
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
                    const Icon(Icons.straighten,
                        size: 14, color: AppThemeData.neutral500),
                    const SizedBox(width: 4),
                    Text(
                      distanceStr,
                      style: AppThemeData.regularTextStyle(
                        fontSize: 12,
                        color: AppThemeData.neutral500,
                      ),
                    ),
                  ],
                  if (distanceStr != null && durationStr != null)
                    Text(
                      '  ·  ',
                      style: AppThemeData.regularTextStyle(
                          fontSize: 12, color: AppThemeData.neutral500),
                    ),
                  if (durationStr != null) ...[
                    const Icon(Icons.timer_outlined,
                        size: 14, color: AppThemeData.neutral500),
                    const SizedBox(width: 4),
                    Text(
                      '~$durationStr min',
                      style: AppThemeData.regularTextStyle(
                        fontSize: 12,
                        color: AppThemeData.neutral500,
                      ),
                    ),
                  ],
                ],
              ),
            ],

            const Divider(height: 20),

            // ── Pickup ─────────────────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.radio_button_checked,
                    color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ride.departName ?? '',
                    style: AppThemeData.mediumTextStyle(fontSize: 13),
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
                const Icon(Icons.location_on, color: Colors.red, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ride.destinationName ?? '',
                    style: AppThemeData.mediumTextStyle(fontSize: 13),
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
                const Icon(Icons.person_outline,
                    size: 15, color: AppThemeData.neutral500),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    customerName.isNotEmpty ? customerName : 'Customer',
                    style: AppThemeData.mediumTextStyle(
                      fontSize: 13,
                      color: AppThemeData.neutral900,
                    ),
                  ),
                ),
                if (passengers > 1) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.group_outlined,
                      size: 15, color: AppThemeData.neutral500),
                  const SizedBox(width: 4),
                  Text(
                    '$passengers',
                    style: AppThemeData.regularTextStyle(
                      fontSize: 12,
                      color: AppThemeData.neutral500,
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // ── Booking # + badges ─────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Booking #${ride.bookingNumber ?? ride.id}",
                  style: AppThemeData.regularTextStyle(
                    fontSize: 12,
                    color: AppThemeData.neutral500,
                  ),
                ),
                Row(
                  children: [
                    if (ride.isPrepaid == true)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue.shade300),
                        ),
                        child: Text(
                          "Prepaid",
                          style: AppThemeData.semiBoldTextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Text(
                        "Scheduled",
                        style: AppThemeData.semiBoldTextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade700,
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
                if (isAssignedToMe)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade400),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle,
                            size: 14, color: Colors.green.shade700),
                        const SizedBox(width: 4),
                        Text(
                          "You accepted",
                          style: AppThemeData.semiBoldTextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
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
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: Text(
                      "Taken",
                      style: AppThemeData.semiBoldTextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
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
    );
  }
}
