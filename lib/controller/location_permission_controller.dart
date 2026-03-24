import 'package:uniqcars_driver/constant/constant.dart';
import 'package:uniqcars_driver/model/user_model.dart';
import 'package:uniqcars_driver/on_boarding_screen.dart';
import 'package:uniqcars_driver/page/dashboard_screen.dart';
import 'package:uniqcars_driver/page/owner_dashboard_screen.dart';
import 'package:uniqcars_driver/page/subscription_plan_screen/subscription_plan_screen.dart';
import 'package:uniqcars_driver/utils/Preferences.dart';
import 'package:uniqcars_driver/utils/utils.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import '../constant/show_toast_dialog.dart';
import '../page/auth_screens/login_screen.dart';
import '../page/localization_screens/localization_screen.dart';
import '../themes/app_them_data.dart';
import '../widget/round_button_fill.dart';

class LocationPermissionController extends GetxController {
  Future<void> requestPermission() async {
    ShowToastDialog.showLoader("Please wait");
    bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!isLocationServiceEnabled) {
      ShowToastDialog.closeLoader();
      _showEnableGPSDialog();
      return;
    } else {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        Constant.currentLocation = await Utils.getCurrentLocation();
        ShowToastDialog.closeLoader();
        if (Preferences.getString(Preferences.languageCodeKey)
            .toString()
            .isEmpty) {
          Get.offAll(LocalizationScreens(intentType: "main"));
        } else {
          if (Preferences.getBoolean(Preferences.isFinishOnBoardingKey)) {
            if (Preferences.getBoolean(Preferences.isLogin) == false) {
              Get.offAll(LoginScreen());
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
            Get.offAll(OnBoardingScreen());
          }
        }
      } else {
        ShowToastDialog.closeLoader();
        _showPermissionDeniedDialog();
      }
    }
  }

  /// Navigate to the normal app flow without location
  void proceedWithoutLocation() {
    if (Preferences.getString(Preferences.languageCodeKey)
        .toString()
        .isEmpty) {
      Get.offAll(LocalizationScreens(intentType: "main"));
    } else if (Preferences.getBoolean(Preferences.isFinishOnBoardingKey)) {
      if (Preferences.getBoolean(Preferences.isLogin) == false) {
        Get.offAll(LoginScreen());
      } else {
        UserModel value = Constant.getUserData();
        UserData? userData = value.userData;
        if (userData?.isOwner == "true") {
          Get.offAll(() => OwnerDashboardScreen(),
              transition: Transition.rightToLeft);
        } else {
          Get.offAll(() => DashboardScreen(),
              transition: Transition.rightToLeft);
        }
      }
    } else {
      Get.offAll(OnBoardingScreen());
    }
  }

  /// Show Permission Denied Dialog
  void _showPermissionDeniedDialog() {
    Get.defaultDialog(
      title: "Location Not Available",
      middleText:
          "You can still browse the app, but you'll need location access enabled to accept rides. You can enable location access anytime from your device Settings.",
      barrierDismissible: true,
      confirm: RoundedButtonFill(
        onPress: () {
          Get.back();
          requestPermission();
        },
        title: 'Try Again',
        width: 40,
        height: 5,
        color: AppThemeData.primaryDefault,
      ),
      cancel: RoundedButtonFill(
        onPress: () {
          Get.back();
          proceedWithoutLocation();
        },
        title: 'Continue',
        width: 40,
        height: 5,
        color: AppThemeData.primaryDefault,
      ),
    );
  }

  /// Show Dialog when GPS is disabled
  void _showEnableGPSDialog() {
    Get.defaultDialog(
      title: "Location Services Disabled",
      middleText:
          "Location services are turned off. You can still use the app, but you'll need location enabled to accept rides. Enable location services in your device Settings for full functionality.",
      barrierDismissible: true,
      confirm: RoundedButtonFill(
        onPress: () {
          Get.back();
          requestPermission();
        },
        title: 'Try Again',
        width: 40,
        height: 5,
        color: AppThemeData.primaryDefault,
      ),
      cancel: RoundedButtonFill(
        onPress: () {
          Get.back();
          proceedWithoutLocation();
        },
        title: 'Continue',
        width: 40,
        height: 5,
        color: AppThemeData.primaryDefault,
      ),
    );
  }
}
