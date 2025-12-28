import 'dart:async';
import 'package:cabme_driver/constant/constant.dart';
import 'package:cabme_driver/constant/show_toast_dialog.dart';
import 'package:cabme_driver/model/settings_model.dart';
import 'package:cabme_driver/service/api.dart';
import 'package:cabme_driver/service/notification_service.dart';
import 'package:cabme_driver/service/pusher_service.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../themes/app_them_data.dart';

class SettingsController extends GetxController {
  @override
  void onInit() {
    notificationInit();
    getSettingsData();
    super.onInit();
  }

  RxBool isLoading = true.obs;

  Future getSettingsData() async {
    await API.handleApiRequest(request: () => http.get(Uri.parse(API.settings), headers: API.authheader), showLoader: false).then(
      (value) async {
        if (value != null) {
          if (value['success'] == "success" || value['success'] == "Success") {
            SettingsModel model = SettingsModel.fromJson(value);
            Constant.adminCommission = model.data!.adminCommission!;
            Constant.subscriptionModel = bool.parse(model.data!.subscriptionModel!);
            Constant.liveTrackingMapType = model.data?.mapType ?? '';
            Constant.selectedMapType = model.data?.mapForApplication != null ? '${model.data?.mapForApplication?.toLowerCase()}' : '';
            Constant.activeServices = model.data!.activeServices!;
            AppThemeData.primaryDefault = Color(int.parse(model.data!.driverappColor!.replaceFirst("#", "0xff")));
            Constant.distanceUnit = model.data!.deliveryDistance!;
            Constant.appVersion = model.data!.appVersion.toString();
            Constant.decimal = model.data!.decimalDigit!;

            Constant.currency = model.data!.currency!;
            Constant.symbolAtRight = model.data!.symbolAtRight! == 'true' ? true : false;
            Constant.kGoogleApiKey = model.data!.googleMapApiKey!;
            Constant.contactUsEmail = model.data!.contactUsEmail!;
            Constant.contactUsAddress = model.data!.contactUsAddress!;
            Constant.minimumWalletBalance = model.data!.minimumDepositAmount!;
            Constant.contactUsPhone = model.data!.contactUsPhone!;
            Constant.rideOtp = model.data!.showRideOtp!;
            Constant.driverLocationUpdateUnit = model.data!.driverLocationUpdate!;
            Constant.minimumWithdrawalAmount = model.data!.minimumWithdrawalAmount!;
            Constant.deliveryChargeParcel = model.data!.deliveryChargeParcel!;

            Constant.parcelPerWeightCharge = model.data!.parcelPerWeightCharge!;
            Constant.senderId = model.data!.senderId!;
            Constant.jsonNotificationFileURL = model.data!.serviceJson!;
            Constant.ownerDocVerification = model.data!.ownerDocVerification!;
            Constant.driverDocVerification = model.data!.driverDocVerification!;

            Constant.pusherApiKey = model.data!.pusherSettings!.pusherKey;
            Constant.cluster = model.data!.pusherSettings!.pusherCluster;

            await PusherService().init(
              apiKey: Constant.pusherApiKey!,
              cluster: Constant.cluster!,
            );
          } else {
            ShowToastDialog.showToast(value['error'] ?? "Something went wrong");
          }
        }
      },
    );

    isLoading.value = false;
    update();
  }

  NotificationService notificationService = NotificationService();

  void notificationInit() {
    notificationService.initInfo();
  }
}
