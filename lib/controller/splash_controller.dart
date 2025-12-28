import 'dart:async';

import 'package:uniqcars_driver/constant/constant.dart';
import 'package:uniqcars_driver/model/user_model.dart';
import 'package:uniqcars_driver/on_boarding_screen.dart';
import 'package:uniqcars_driver/page/auth_screens/login_screen.dart';
import 'package:uniqcars_driver/page/dashboard_screen.dart';
import 'package:uniqcars_driver/page/localization_screens/localization_screen.dart';
import 'package:uniqcars_driver/page/location_permission_screen/location_permission_screen.dart';
import 'package:uniqcars_driver/page/owner_dashboard_screen.dart';
import 'package:uniqcars_driver/page/subscription_plan_screen/subscription_plan_screen.dart';
import 'package:uniqcars_driver/utils/Preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

class SplashController extends GetxController {
  @override
  void onInit() {
    Timer(const Duration(seconds: 3), () => redirectScreen());
    super.onInit();
  }

  Future<void> redirectScreen() async {
    bool isLocationPermission = await _checkLocationPermission();
    if (isLocationPermission) {
      if (Preferences.getString(Preferences.languageCodeKey)
          .toString()
          .isEmpty) {
        Get.offAll(LocalizationScreens(intentType: "main"));
      } else {
        if (Preferences.getBoolean(Preferences.isFinishOnBoardingKey)) {
          if (Preferences.getBoolean(Preferences.isLogin) == false) {
            Get.offAll(() => LoginScreen());
          } else {
            UserModel value = Constant.getUserData();
            UserData? userData = value.userData;
            await Preferences.setInt(
                Preferences.userId, int.parse(userData!.id.toString()));
            bool isPlanExpired = false;

            /// Case 1: Admin Commission is 'no' and Subscription model is disabled
            if (Constant.adminCommission?.statut == "no" &&
                Constant.subscriptionModel == false) {
              if (userData.isOwner == "true") {
                Get.offAll(() => OwnerDashboardScreen(),
                    transition: Transition.rightToLeft);
              } else {
                Get.offAll(() => DashboardScreen(),
                    transition: Transition.rightToLeft);
              }
              return;
            }

            /// ✅ Updated: User is a driver *under an owner*
            bool isOwnerDriver = userData.isOwner == "false" &&
                userData.ownerId != null &&
                userData.ownerId!.isNotEmpty;

            if (isOwnerDriver) {
              Get.offAll(() => DashboardScreen(),
                  transition: Transition.rightToLeft);
              return;
            }

            /// Owner user - check for subscription
            if (userData.subscriptionPlanId != null) {
              if (userData.subscriptionExpiryDate == null) {
                isPlanExpired = userData.subscriptionPlan?.expiryDay != '-1';
              } else {
                final expiryDate =
                    DateTime.tryParse(userData.subscriptionExpiryDate!);
                isPlanExpired =
                    expiryDate != null && expiryDate.isBefore(DateTime.now());
              }
            } else {
              isPlanExpired = true;
            }

            if (userData.subscriptionPlanId == null || isPlanExpired) {
              Get.to(() => SubscriptionPlanScreen(),
                  arguments: {'isSplashScreen': true});
            } else {
              if (userData.isOwner == "true") {
                Get.offAll(() => OwnerDashboardScreen(),
                    transition: Transition.rightToLeft);
              } else {
                Get.offAll(() => DashboardScreen(),
                    transition: Transition.rightToLeft);
              }
            }
          }
        } else {
          Get.offAll(() => OnBoardingScreen());
        }
      }
    } else {
      Get.offAll(const LocationPermissionScreen());
    }
  }

  Future<bool> _checkLocationPermission() async {
    bool isLocationEnable;
    bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();

    if (isLocationServiceEnabled == false) {
      isLocationEnable = false;
    } else {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        isLocationEnable = true;
      } else {
        isLocationEnable = false;
      }
    }

    return isLocationEnable;
  }
}
