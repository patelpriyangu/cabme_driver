import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:uniqcars_driver/constant/constant.dart';
import 'package:uniqcars_driver/constant/ride_satatus.dart';
import 'package:uniqcars_driver/constant/show_toast_dialog.dart';
import 'package:uniqcars_driver/model/booking_mode.dart';
import 'package:uniqcars_driver/model/driver_upload_model.dart';
import 'package:uniqcars_driver/model/parcel_bokking_model.dart';
import 'package:uniqcars_driver/model/rental_booking_model.dart';
import 'package:uniqcars_driver/model/user_model.dart';
import 'package:uniqcars_driver/page/auth_screens/login_screen.dart';
import 'package:uniqcars_driver/service/api.dart';
import 'package:uniqcars_driver/controller/call_controller.dart';
import 'package:uniqcars_driver/service/pusher_service.dart';
import 'package:uniqcars_driver/utils/Preferences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:uniqcars_driver/service/ride_alert_service.dart';

class HomeController extends GetxController {
  RxBool isLoading = true.obs;
  RxString status = "no".obs;
  RxList<ParcelBookingData> parcelList = <ParcelBookingData>[].obs;
  RxList<BookingData> upcomingRidesList = <BookingData>[].obs;
  RxList<BookingData> recentlyCancelledRides = <BookingData>[].obs;
  RxBool isUpcomingLoading = false.obs;

  /// Documents expiring within 30 days (for home screen banner).
  RxList<DriverUploadData> nearExpiryDocs = <DriverUploadData>[].obs;

  Rx<UserModel> userModel = UserModel().obs;
  Rx<TextEditingController> otpController = TextEditingController().obs;
  Rx<TextEditingController> currentKilometerController =
      TextEditingController().obs;
  Rx<TextEditingController> completeKilometerController =
      TextEditingController().obs;
  final RxString selectedTabType = ''.obs;

  @override
  void onInit() {
    getData();
    _subscribeToCallEvents();
    update();
    super.onInit();
  }

  @override
  void onClose() {
    _stopDriverLocationTracking();
    RideAlertService().stop();
    super.onClose();
  }

  void _subscribeToCallEvents() {
    final userId = Preferences.getInt(Preferences.userId).toString();
    final callController = Get.find<CallController>();
    PusherService().subscribeToCallEvent(
      userId: userId,
      userType: 'driver',
      onIncomingCall: (data) => callController.handleIncomingCall(data),
      onCallEnded: (data) => callController.handleCallEnded(data),
      onCallRejected: (data) => callController.handleCallRejected(data),
      onCallAccepted: (data) {},
    );
  }

  void setAvailableTabs(List<String> tabs) {
    if (tabs.isNotEmpty && selectedTabType.value.isEmpty) {
      selectedTabType.value = tabs.first;
    }
  }

  Future<void> getData() async {
    userModel.value = Constant.getUserData();
    await getUserData();
    await getBookingData();
    status.value = userModel.value.userData?.online ?? "no";
    if (status.value == "yes") {
      await updateCurrentLocation();
      await getBooking();
      await getParcelList();
      await getRentalSearchBooking();
    }
    await getUpcomingRides();
    await checkNearExpiryDocs();

    isLoading.value = false;
  }

  Future<void> checkNearExpiryDocs() async {
    final driverId = Preferences.getInt(Preferences.userId);
    await API
        .handleApiRequest(
            request: () => http.post(Uri.parse(API.driverGetUploads),
                headers: API.headers,
                body: jsonEncode({'driver_id': driverId})),
            showLoader: false)
        .then((value) {
      if (value != null && value['success'] == 'success') {
        final model = DriverUploadModel.fromJson(value);
        nearExpiryDocs.value = (model.data ?? []).where((doc) {
          final days = doc.daysUntilExpiry;
          return days != null && days >= 0 && days <= 30;
        }).toList();
      }
    });
  }

  void updateTabType(String type) {
    selectedTabType.value = type;
  }

  Rx<BookingModel> bookingModel = BookingModel().obs;
  RxList<Stops> locationData = <Stops>[].obs;

  Future<void> getBookingData() async {
    PusherService().subscribeDriverRecentRide<BookingModel>(
      driverId: Preferences.getInt(Preferences.userId).toString(),
      event: 'updated',
      fromJson: BookingModel.fromJson,
      onData: (ride) {
        log("Ride updated: ${ride.toJson().toString()}");
        setBookingData(ride);
      },
    );
    update();
  }

  RxString subTotal = "0.0".obs;
  RxString discount = "0.0".obs;
  RxString taxAmount = "0.0".obs;
  RxString totalAmount = "0.0".obs;

  void calculateTotalAmount() {
    taxAmount = "0.0".obs;
    subTotal.value = bookingModel.value.data!.montant.toString();
    for (var element in bookingModel.value.data!.tax ?? []) {
      taxAmount.value = (double.parse(taxAmount.value) +
              Constant().calculateTax(
                  amount: ((double.parse(subTotal.value)) -
                          (double.parse(discount.value)))
                      .toString(),
                  taxModel: element))
          .toStringAsFixed(int.tryParse(Constant.decimal.toString()) ?? 2);
    }
    if (bookingModel.value.data!.discountType != null) {
      discount.value = Constant.calculateDiscountOrder(
              amount: subTotal.value,
              offerModel: bookingModel.value.data!.discountType)
          .toString();
    }
    totalAmount.value =
        ((double.parse(subTotal.value) - (double.parse(discount.value))) +
                double.parse(taxAmount.value))
            .toStringAsFixed(int.tryParse(Constant.decimal.toString()) ?? 2);
    update();
  }

  void setBookingData(BookingModel booking) {
    bookingModel.value = booking;
    if (booking.data != null) {
      if (booking.data!.statut == RideStatus.newRide ||
          booking.data!.statut == RideStatus.confirmed ||
          booking.data!.statut == RideStatus.arrived ||
          booking.data!.statut == RideStatus.onRide) {
        // Play alert sound for new ride requests
        if (booking.data!.statut == RideStatus.newRide) {
          RideAlertService().play();
        } else {
          // Stop alert for any other active status (driver already interacted)
          RideAlertService().stop();
        }

        locationData.clear();
        locationData.add(Stops(
            location: booking.data!.departName,
            latitude: booking.data!.latitudeDepart,
            longitude: booking.data!.longitudeDepart));
        if (booking.data!.stops != null) {
          locationData.addAll(booking.data!.stops!.map((e) => Stops(
              location: e.location,
              latitude: e.latitude,
              longitude: e.longitude)));
        }
        locationData.add(Stops(
            location: booking.data!.destinationName,
            latitude: booking.data!.latitudeArrivee,
            longitude: booking.data!.longitudeArrivee));
        calculateTotalAmount();
      } else if (booking.data!.statut == RideStatus.canceled ||
          booking.data!.statut == RideStatus.completed ||
          booking.data!.statut == RideStatus.rejected) {
        RideAlertService().stop();

        // If a SCHEDULED ride assigned to this driver is cancelled, show an
        // alert dialog so the driver is clearly aware before the card clears.
        final wasScheduled = booking.data!.scheduledAt != null &&
            booking.data!.scheduledAt!.isNotEmpty &&
            booking.data!.scheduledAt != 'null';
        final wasCancelled = booking.data!.statut == RideStatus.canceled ||
            booking.data!.statut == RideStatus.rejected;
        final myDriverId = Preferences.getInt(Preferences.userId).toString();
        final assignedId = booking.data!.assignedDriverId;
        final isAssignedToMe = assignedId != null &&
            assignedId.toString() != 'null' &&
            assignedId.toString().isNotEmpty &&
            assignedId.toString() == myDriverId;

        // Show payment confirmation dialog when ride completes via online payment
        // (e.g. WorldPay) — the Pusher 'completed' event fires as soon as the
        // customer's payment succeeds, so the driver needs visual confirmation.
        final isSchoolRun =
            (booking.data!.rideType ?? '').toLowerCase() == 'school_run';
        if (booking.data!.statut == RideStatus.completed && !isSchoolRun) {
          final bookingNum =
              booking.data!.bookingNumber ?? booking.data!.id ?? '';
          final amount = booking.data!.montant ?? '0';
          final payMethod = booking.data!.paymentMethod ?? '';
          Future.delayed(const Duration(milliseconds: 200), () {
            if (Get.isDialogOpen != true) {
              Get.dialog(
                AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: Colors.green, size: 24),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          "Payment Received",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  content: Text(
                    "Ride #$bookingNum has been completed.\nPayment of ${Constant().amountShow(amount: amount)} received via $payMethod.",
                    style: const TextStyle(fontSize: 14),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text(
                        "Done",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
                barrierDismissible: false,
              );
            }
          });
        }

        if (wasScheduled && wasCancelled && isAssignedToMe) {
          final bookingNum =
              booking.data!.bookingNumber ?? booking.data!.id ?? '';
          // Delay slightly so the dialog doesn't race with any ongoing
          // navigation triggered by the same Pusher event.
          Future.delayed(const Duration(milliseconds: 300), () {
            if (Get.isDialogOpen != true) {
              Get.dialog(
                AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: Row(
                    children: [
                      Icon(Icons.cancel_outlined, color: Colors.red, size: 24),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          "Scheduled Ride Cancelled",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  content: Text(
                    "Your scheduled ride #$bookingNum has been cancelled by the customer.",
                    style: const TextStyle(fontSize: 14),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Get.back();
                        // Refresh the upcoming list so the cancelled ride
                        // appears in the recently cancelled section.
                        getUpcomingRides();
                      },
                      child: const Text(
                        "OK",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
                barrierDismissible: false,
              );
            }
          });
        }

        bookingModel.value = BookingModel();
        update();
      }
    }
    update();
  }

  Future<void> getBooking() async {
    Map<String, dynamic> bodyParams = {
      'id_driver': Preferences.getInt(Preferences.userId),
    };

    await API
        .handleApiRequest(
            request: () => http.post(Uri.parse(API.driverRecentRide),
                headers: API.headers, body: jsonEncode(bodyParams)),
            showLoader: false)
        .then(
      (value) async {
        if (value != null) {
          if (value['success'] == "Failed" || value['success'] == "failed") {
            bookingModel.value = BookingModel();
            return null;
          } else {
            BookingModel booking = BookingModel.fromJson(value);
            setBookingData(booking);
          }
        }
      },
    );
  }

  Future<void> acceptBooking(String rideId) async {
    RideAlertService().stop();

    Map<String, dynamic> bodyParams = {
      'id_driver': Preferences.getInt(Preferences.userId),
      'id_ride': rideId,
    };

    await API
        .handleApiRequest(
            request: () => http.post(Uri.parse(API.conformRide),
                headers: API.headers, body: jsonEncode(bodyParams)),
            showLoader: true)
        .then(
      (value) async {
        if (value != null) {
          if (value['success'] == "Failed" || value['success'] == "failed") {
            ShowToastDialog.showToast(value['error']);
            return null;
          } else {
            await getBooking();
            ShowToastDialog.showToast("Ride accepted successfully");
          }
        }
      },
    );
  }

  Future<void> arrivedRequest() async {
    Map<String, dynamic> bodyParams = {
      'id_driver': Preferences.getInt(Preferences.userId),
      'id_ride': bookingModel.value.data!.id,
    };

    await API
        .handleApiRequest(
            request: () => http.post(Uri.parse(API.arrivedRequest),
                headers: API.headers, body: jsonEncode(bodyParams)),
            showLoader: true)
        .then(
      (value) async {
        if (value != null) {
          if (value['success'] == "Failed" || value['success'] == "failed") {
            ShowToastDialog.showToast(value['message']);
            return null;
          } else {
            await getBooking();
            ShowToastDialog.showToast("Notify: Driver Arrived");
          }
        }
      },
    );
  }

  Future<void> onRideStatus() async {
    Map<String, dynamic> bodyParams = {
      'id_driver': Preferences.getInt(Preferences.userId),
      'id_ride': bookingModel.value.data!.id,
      'otp': otpController.value.text.trim(),
    };

    await API
        .handleApiRequest(
            request: () => http.post(Uri.parse(API.onRideRequest),
                headers: API.headers, body: jsonEncode(bodyParams)),
            showLoader: true)
        .then(
      (value) async {
        if (value != null) {
          if (value['success'] == "Failed" || value['success'] == "failed") {
            ShowToastDialog.showToast(value['message']);
            return null;
          } else {
            await getBooking();
            otpController.value.clear();
            ShowToastDialog.showToast("Ride accepted successfully");
            Get.back();
          }
        }
      },
    );
  }

  String calculateParcelTotalAmountBooking(
      ParcelBookingData parcelBookingData) {
    String subTotal = parcelBookingData.amount.toString();
    String discount = "0.0";
    String taxAmount = "0.0";
    if (parcelBookingData.discountType != null) {
      discount = Constant.calculateDiscountOrder(
              amount: subTotal, offerModel: parcelBookingData.discountType)
          .toString();
    }
    for (var element in parcelBookingData.tax!) {
      taxAmount = (double.parse(taxAmount) +
              Constant().calculateTax(
                  amount: (double.parse(subTotal) - double.parse(discount))
                      .toString(),
                  taxModel: element))
          .toStringAsFixed(int.tryParse(Constant.decimal.toString()) ?? 2);
    }

    return ((double.parse(subTotal) - (double.parse(discount))) +
            double.parse(taxAmount))
        .toStringAsFixed(int.tryParse(Constant.decimal.toString()) ?? 2);
  }

  Future<void> completeBooking() async {
    Map<String, dynamic> requestBody = {
      "id_ride": bookingModel.value.data!.id,
      "id_user": bookingModel.value.data!.user!.id,
      "id_driver": bookingModel.value.data!.driver!.id,
      "id_payment": bookingModel.value.data!.idPaymentMethod,
      "transaction_id": DateTime.now().microsecondsSinceEpoch.toString(),
      "discount": "0",
      "tip": "0",
    };

    await API
        .handleApiRequest(
            request: () => http.post(Uri.parse(API.completeRequest),
                headers: API.headers, body: jsonEncode(requestBody)),
            debugPayload: requestBody,
            showLoader: true)
        .then(
      (value) async {
        if (value != null) {
          if (value['success'] == "Failed" || value['success'] == "ailed") {
            ShowToastDialog.showToast(value['error']);
            return null;
          } else {
            Get.back();
            await getBooking();
            ShowToastDialog.showToast("Payment received successfully !!");
          }
        }
      },
    );
  }

  Future<void> resendPaymentLink() async {
    final booking = bookingModel.value.data;
    if (booking == null) {
      ShowToastDialog.showToast("Booking data not found");
      return;
    }

    final requestBody = {
      "id_ride": booking.id,
      "id_driver": Preferences.getInt(Preferences.userId),
      "channel": "both",
    };

    await API
        .handleApiRequest(
            request: () => http.post(Uri.parse(API.resendPaymentLink),
                headers: API.headers, body: jsonEncode(requestBody)),
            debugPayload: requestBody,
            showLoader: true)
        .then(
      (value) {
        if (value != null) {
          if (value['success'] == "Failed" || value['success'] == "failed") {
            ShowToastDialog.showToast(
                value['error'] ?? "Payment link was not sent");
            return;
          }
          ShowToastDialog.showToast(
              value['message'] ?? "Payment link sent to customer");
        }
      },
    );
  }

  Future<void> rejectBooking(String rideId) async {
    RideAlertService().stop();

    Map<String, dynamic> bodyParams = {
      'id_driver': Preferences.getInt(Preferences.userId),
      'id_ride': rideId,
      'reason': "Driver rejected the ride",
    };

    await API
        .handleApiRequest(
            request: () => http.post(Uri.parse(API.rejectRide),
                headers: API.headers, body: jsonEncode(bodyParams)),
            showLoader: true)
        .then(
      (value) async {
        if (value != null) {
          if (value['success'] == "Failed" || value['success'] == "failed") {
            ShowToastDialog.showToast(value['error']);
            return null;
          } else {
            await getBooking();
            ShowToastDialog.showToast("Ride rejected successfully");
          }
        }
      },
    );
  }

  Future<bool> changeStatus(String value) async {
    final previousStatus = status.value;
    status.value = value;
    Map<String, dynamic> bodyParams = {
      'id_driver': Preferences.getInt(Preferences.userId),
      'online': status.value,
    };

    bool success = false;
    await API
        .handleApiRequest(
            request: () => http.post(Uri.parse(API.changeStatus),
                headers: API.headers, body: jsonEncode(bodyParams)),
            showLoader: true)
        .then(
      (value) async {
        if (value != null) {
          if (value['success'] == "Failed" || value['success'] == "failed") {
            // Revert local status on failure
            status.value = previousStatus;
            if (value['error'] == 'document_verification_required') {
              // Handled by caller (home_screen) — silently revert
            } else {
              ShowToastDialog.showToast(value['error']);
            }
            if (previousStatus == "yes") {
              updateCurrentLocation();
            }
            return null;
          } else {
            success = true;
            await getData();
            ShowToastDialog.showToast(status.value == "yes"
                ? "You are online now"
                : status.value == "break"
                    ? "You are on break"
                    : "You are offline now");
            if (status.value == "yes") {
              updateCurrentLocation();
            } else {
              _stopDriverLocationTracking();
            }
          }
        }
      },
    );
    return success;
  }

  Future<void> getUserData() async {
    Map<String, String> bodyParams = {
      'phone': userModel.value.userData!.phone.toString(),
      'country_code': userModel.value.userData!.countryCode.toString(),
      'user_cat': "driver",
      'email': userModel.value.userData!.email.toString(),
      'login_type': userModel.value.userData!.loginType.toString(),
    };
    await API
        .handleApiRequest(
            request: () => http.post(Uri.parse(API.getProfileByPhone),
                headers: API.headers, body: jsonEncode(bodyParams)),
            showLoader: false)
        .then(
      (value) {
        if (value != null) {
          if (value['success'] == "Failed" || value['success'] == "failed") {
            ShowToastDialog.showToast(value['error']);
            Preferences.clearKeyData(Preferences.isLogin);
            Preferences.clearKeyData(Preferences.user);
            Preferences.clearKeyData(Preferences.userId);
            Preferences.clearKeyData(Preferences.accesstoken);
            Get.offAll(const LoginScreen());
            return null;
          } else {
            userModel.value = UserModel.fromJson(value);
            Preferences.setString(Preferences.user, jsonEncode(value));
          }
        }
      },
    );
  }

  Location location = Location();
  StreamSubscription<LocationData>? locationSubscription;
  Timer? _driverLocationHeartbeatTimer;
  String? _lastDriverLatitude;
  String? _lastDriverLongitude;

  Future<void> updateCurrentLocation() async {
    if (status.value != "yes") {
      _stopDriverLocationTracking();
      return;
    }

    try {
      if (!Preferences.getBoolean(Preferences.backgroundLocationConsent)) {
        final bool consentGranted = await _showBackgroundLocationDisclosure();
        if (!consentGranted) {
          status.value = "no";
          return;
        }
        await Preferences.setBoolean(
            Preferences.backgroundLocationConsent, true);
      }

      PermissionStatus permissionStatus = await location.hasPermission();
      if (permissionStatus != PermissionStatus.granted) {
        permissionStatus = await location.requestPermission();
      }
      if (permissionStatus != PermissionStatus.granted) {
        return;
      }

      await location.changeSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter:
              double.parse(Constant.driverLocationUpdateUnit.toString()));

      await _sendCurrentOrLastKnownLocation();
      _startDriverLocationStream();
      _startDriverLocationHeartbeat();
    } catch (e) {
      log("Driver location tracking error: $e");
    }
  }

  Future<bool> _showBackgroundLocationDisclosure() async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text("Background Location Access"),
        content: const SingleChildScrollView(
          child: Text(
            "This app collects location data to enable ride dispatch, pickup and drop-off navigation, and customer ride tracking even when the app is closed or not in use. Location sharing starts only when you go online or have an active trip, and stops when you go offline.",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text("Not Now"),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: const Text("Agree"),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    return result == true;
  }

  void _startDriverLocationStream() {
    if (locationSubscription != null) {
      return;
    }

    locationSubscription = location.onLocationChanged.listen((locationData) {
      _cacheDriverLocation(locationData);
      _sendLastKnownDriverLocation();
    }, onError: (error) {
      log("Driver location stream error: $error");
    });
  }

  void _startDriverLocationHeartbeat() {
    if (_driverLocationHeartbeatTimer?.isActive == true) {
      return;
    }

    _driverLocationHeartbeatTimer =
        Timer.periodic(const Duration(seconds: 30), (_) {
      if (status.value == "yes") {
        _sendCurrentOrLastKnownLocation();
      } else {
        _stopDriverLocationTracking();
      }
    });
  }

  Future<void> _sendCurrentOrLastKnownLocation() async {
    try {
      final currentLocation = await location.getLocation();
      _cacheDriverLocation(currentLocation);
    } catch (e) {
      log("Driver current location lookup error: $e");
    }

    await _sendLastKnownDriverLocation();
  }

  void _cacheDriverLocation(LocationData locationData) {
    if (locationData.latitude != null && locationData.longitude != null) {
      _lastDriverLatitude = locationData.latitude.toString();
      _lastDriverLongitude = locationData.longitude.toString();
    }
  }

  Future<void> _sendLastKnownDriverLocation() async {
    final latitude = _lastDriverLatitude;
    final longitude = _lastDriverLongitude;
    if (latitude == null || longitude == null || status.value != "yes") {
      return;
    }

    await setDriverLocationUpdate(latitude, longitude);
  }

  Future<void> _stopDriverLocationTracking() async {
    _driverLocationHeartbeatTimer?.cancel();
    _driverLocationHeartbeatTimer = null;
    await locationSubscription?.cancel();
    locationSubscription = null;
  }

  Future<void> setDriverLocationUpdate(
      String latitude, String longitude) async {
    if (status.value != "yes") {
      return;
    }

    Map<String, dynamic> bodyParams = {
      'id_user': Preferences.getInt(Preferences.userId),
      'user_cat': userModel.value.userData!.userCat.toString(),
      'latitude': latitude,
      'longitude': longitude
    };
    try {
      await API.handleApiRequest(
          request: () => http.post(Uri.parse(API.updateLocation),
              headers: API.headers, body: jsonEncode(bodyParams)),
          showLoader: false);
    } catch (e) {
      log("Driver location update error: $e");
    }
  }

  var selectedIndex = 0.obs;

  void updateIndex(int index) {
    selectedIndex.value = index;
  }

  Future<void> getParcelList() async {
    Map<String, dynamic> bodyParams = {
      'id_driver': Preferences.getInt(Preferences.userId),
    };

    await API
        .handleApiRequest(
            request: () => http.post(Uri.parse(API.getDriverParcelOrders),
                headers: API.headers, body: jsonEncode(bodyParams)),
            showLoader: false)
        .then(
      (value) async {
        if (value != null) {
          if (value['success'] == "Failed" || value['success'] == "failed") {
            parcelList.clear();
            return null;
          } else {
            parcelList.value = (value['data'] as List)
                .map((e) => ParcelBookingData.fromJson(e))
                .toList();
          }
        }
      },
    );
  }

  Future<void> pickUpParcelBooking(ParcelBookingData parcelBookingData) async {
    Map<String, dynamic> bodyParams = {
      'id_driver': Preferences.getInt(Preferences.userId),
      'id_parcel': parcelBookingData.id,
    };

    await API
        .handleApiRequest(
            request: () => http.post(Uri.parse(API.parcelOnride),
                headers: API.headers, body: jsonEncode(bodyParams)),
            showLoader: true)
        .then(
      (value) async {
        if (value != null) {
          if (value['success'] == "Failed" || value['success'] == "failed") {
            return null;
          } else {
            await getParcelList();
            ShowToastDialog.showToast("Parcel picked up successfully");
          }
        }
      },
    );
  }

  Future<void> completeParcelBooking(
      ParcelBookingData parcelBookingData) async {
    Map<String, dynamic> bodyParams = {
      'id_driver': Preferences.getInt(Preferences.userId),
      'id_parcel': parcelBookingData.id,
    };

    await API
        .handleApiRequest(
            request: () => http.post(Uri.parse(API.parcelComplete),
                headers: API.headers, body: jsonEncode(bodyParams)),
            showLoader: true)
        .then(
      (value) async {
        if (value != null) {
          if (value['success'] == "Failed" || value['success'] == "failed") {
            ShowToastDialog.showToast(value['error']);
            return null;
          } else {
            await getParcelList();
            ShowToastDialog.showToast("Parcel delivered successfully");
          }
        }
      },
    );
  }

  Future<void> getUpcomingRides() async {
    Map<String, dynamic> bodyParams = {
      'driver_id': Preferences.getInt(Preferences.userId).toString(),
    };
    await API
        .handleApiRequest(
            request: () => http.post(Uri.parse(API.driverUpcomingRides),
                headers: API.headers, body: jsonEncode(bodyParams)),
            showLoader: false)
        .then(
      (value) async {
        if (value != null) {
          if (value['data'] != null && value['data'] is List) {
            final allRides = (value['data'] as List)
                .map((e) => BookingData.fromJson(e))
                .toList();

            final now = DateTime.now().toUtc();
            final cutoff24h = now.subtract(const Duration(hours: 24));

            // Separate active/scheduled rides from recently cancelled ones.
            // A ride is "recently cancelled" if it was cancelled/rejected AND
            // its scheduled_at (or created_at via creer) falls within the last
            // 24 hours, so the driver can still see what happened.
            final List<BookingData> active = [];
            final List<BookingData> cancelled = [];

            for (final ride in allRides) {
              final isCancelled = ride.statut == RideStatus.canceled ||
                  ride.statut == RideStatus.rejected;
              if (isCancelled) {
                // Use scheduledAt to determine recency; fall back to creer.
                DateTime? rideTime;
                try {
                  if (ride.scheduledAt != null &&
                      ride.scheduledAt!.isNotEmpty &&
                      ride.scheduledAt != 'null') {
                    rideTime =
                        DateTime.parse(ride.scheduledAtUtc ?? ride.scheduledAt!)
                            .toUtc();
                  } else if (ride.creer != null &&
                      ride.creer!.isNotEmpty &&
                      ride.creer != 'null') {
                    rideTime = DateTime.parse(ride.creer!).toUtc();
                  }
                } catch (_) {}

                if (rideTime != null && rideTime.isAfter(cutoff24h)) {
                  cancelled.add(ride);
                }
              } else {
                active.add(ride);
              }
            }

            upcomingRidesList.value = active;
            recentlyCancelledRides.value = cancelled;
          } else {
            upcomingRidesList.clear();
            recentlyCancelledRides.clear();
          }
        } else {
          upcomingRidesList.clear();
          recentlyCancelledRides.clear();
        }
      },
    );
  }

  /// Returns true when there is at least one upcoming scheduled ride within
  /// the next [withinMinutes] minutes that is assigned to this driver.
  bool hasUpcomingRideSoon({int withinMinutes = 120}) {
    final myDriverId = Preferences.getInt(Preferences.userId).toString();
    final now = DateTime.now().toUtc();
    final horizon = now.add(Duration(minutes: withinMinutes));

    for (final ride in upcomingRidesList) {
      if (ride.statut == RideStatus.canceled ||
          ride.statut == RideStatus.rejected) {
        continue;
      }

      final assignedId = ride.assignedDriverId;
      final isAssignedToMe = assignedId != null &&
          assignedId.toString() != 'null' &&
          assignedId.toString().isNotEmpty &&
          assignedId.toString() == myDriverId;
      if (!isAssignedToMe) {
        continue;
      }

      try {
        if (ride.scheduledAt != null &&
            ride.scheduledAt!.isNotEmpty &&
            ride.scheduledAt != 'null') {
          final scheduledUtc =
              DateTime.parse(ride.scheduledAtUtc ?? ride.scheduledAt!).toUtc();
          if (scheduledUtc.isAfter(now) && scheduledUtc.isBefore(horizon)) {
            return true;
          }
        }
      } catch (_) {}
    }
    return false;
  }

  Future<void> acceptUpcomingRide(String rideId) async {
    final driverId = Preferences.getInt(Preferences.userId).toString();
    await API
        .handleApiRequest(
            request: () => http.post(
                  Uri.parse(API.acceptUpcomingRide),
                  headers: API.headers,
                  body: jsonEncode({'ride_id': rideId, 'driver_id': driverId}),
                ),
            showLoader: true)
        .then((value) async {
      if (value != null) {
        if (value['success'] == true || value['success'] == 'success') {
          ShowToastDialog.showToast(
              "Ride accepted! It will be dispatched to you at the scheduled time.");
          await getUpcomingRides(); // refresh the list
        } else {
          ShowToastDialog.showToast(
              value['message'] ?? "Could not accept ride");
        }
      }
    });
  }

  RxList<RentalBookingData> rentalBookingData = <RentalBookingData>[].obs;

  Future<void> getRentalSearchBooking() async {
    Map<String, dynamic> bodyParams = {
      'driver_id': Preferences.getInt(Preferences.userId).toString(),
    };
    await API
        .handleApiRequest(
            request: () => http.post(Uri.parse(API.getRecentDriverRentalOrder),
                headers: API.headers, body: jsonEncode(bodyParams)),
            showLoader: false)
        .then(
      (value) async {
        if (value != null) {
          RentalBookingModel model = RentalBookingModel.fromJson(value);
          if (model.success == "Failed" || model.success == "failed") {
            rentalBookingData.clear();
            return null;
          } else {
            rentalBookingData.value = (value['data'] as List)
                .map((e) => RentalBookingData.fromJson(e))
                .toList();
          }
        }
      },
    );
  }

  Future<void> onRideStatusRental(String bookingId) async {
    Map<String, dynamic> bodyParams = {
      'id_driver': Preferences.getInt(Preferences.userId),
      'id_rental': bookingId,
      'otp': otpController.value.text.trim(),
      'current_km': currentKilometerController.value.text.trim(),
    };

    await API
        .handleApiRequest(
            request: () => http.post(Uri.parse(API.rentalOnRide),
                headers: API.headers, body: jsonEncode(bodyParams)),
            showLoader: true)
        .then(
      (value) async {
        if (value != null) {
          if (value['success'] == "Failed" || value['success'] == "failed") {
            ShowToastDialog.showToast(value['message']);
            return null;
          } else {
            await getRentalSearchBooking();
            ShowToastDialog.showToast("Ride accepted successfully");
            Get.back();
          }
        }
      },
    );
  }

  Future<void> setFinalKilometerOfRental(String bookingId) async {
    Map<String, dynamic> bodyParams = {
      'id_rental': bookingId,
      'complete_km': completeKilometerController.value.text.trim(),
    };

    await API
        .handleApiRequest(
            request: () => http.post(Uri.parse(API.rentalSetFinalKm),
                headers: API.headers, body: jsonEncode(bodyParams)),
            showLoader: true)
        .then(
      (value) async {
        if (value != null) {
          if (value['success'] == "Failed" || value['success'] == "failed") {
            ShowToastDialog.showToast(value['message']);
            return null;
          } else {
            await getRentalSearchBooking();
            ShowToastDialog.showToast("Kilometer updated successfully");
            Get.back();
          }
        }
      },
    );
  }
}
