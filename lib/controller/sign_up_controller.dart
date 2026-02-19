import 'dart:async';
import 'dart:convert';

import 'package:uniqcars_driver/constant/constant.dart';
import 'package:uniqcars_driver/constant/show_toast_dialog.dart';
import 'package:uniqcars_driver/model/user_model.dart';
import 'package:uniqcars_driver/page/auth_screens/login_screen.dart';
import 'package:uniqcars_driver/page/dashboard_screen.dart';
import 'package:uniqcars_driver/page/owner_dashboard_screen.dart';
import 'package:uniqcars_driver/page/subscription_plan_screen/subscription_plan_screen.dart';
import 'package:uniqcars_driver/service/api.dart';
import 'package:uniqcars_driver/utils/Preferences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class SignUpController extends GetxController {
  Rx<TextEditingController> firstNameController = TextEditingController().obs;
  Rx<TextEditingController> lastNameController = TextEditingController().obs;
  Rx<TextEditingController> phoneNumber = TextEditingController().obs;
  Rx<TextEditingController> countryCodeController =
      TextEditingController(text: "+91").obs;
  Rx<TextEditingController> emailController = TextEditingController().obs;
  Rx<TextEditingController> passwordController = TextEditingController().obs;
  Rx<TextEditingController> conformPasswordController =
      TextEditingController().obs;

  RxBool isPasswordShow = true.obs;
  RxBool isConformPasswordShow = true.obs;

  RxString loginType = "".obs;
  RxString selectedValue = "Individual".obs;

  RxList<dynamic> selectedService = <dynamic>[].obs;

  @override
  void onInit() {
    dynamic argumentData = Get.arguments;
    if (argumentData != null) {
      loginType.value = argumentData['login_type'];
      if (loginType.value == "phoneNumber") {
        phoneNumber.value.text = '${argumentData['phoneNumber']}';
        countryCodeController.value.text = '${argumentData['countryCode']}';
      } else if (loginType.value != "email") {
        // social login (google/apple) — pre-fill name and email
        emailController.value.text = argumentData['email'] ?? "";
        firstNameController.value.text = argumentData['firstName'] ?? "";
        lastNameController.value.text = argumentData['lastname'] ?? "";
      }
      // "email" login_type: all fields left empty for the user to fill
    }
    super.onInit();
  }

  Future<UserModel?> signUp(Map<String, String> bodyParams) async {
    UserModel? userModel;
    await API
        .handleApiRequest(
            request: () => http.post(Uri.parse(API.userSignUP),
                headers: API.authheader, body: jsonEncode(bodyParams)),
            showLoader: true)
        .then(
      (value) {
        if (value != null) {
          if (value['status'] == "Failed") {
            ShowToastDialog.showToast(value['message']);
          } else {
            ShowToastDialog.closeLoader();
            userModel = UserModel.fromJson(value);
          }
        }
      },
    );
    return userModel;
  }

  Future<UserModel?> getDataByPhoneNumber(
      Map<String, String> bodyParams) async {
    UserModel? userModel;
    await API
        .handleApiRequest(
            request: () => http.post(Uri.parse(API.getProfileByPhone),
                headers: API.headers, body: jsonEncode(bodyParams)),
            showLoader: true)
        .then(
      (value) {
        if (value != null) {
          if (value['success'] == "Failed" || value['success'] == "failed") {
            ShowToastDialog.showToast(value['error']);
            return null;
          }
          userModel = UserModel.fromJson(value);
        }
      },
    );
    return userModel;
  }

  /// Called after a successful Google/Apple signup to immediately log the driver in.
  Future<void> autoLoginAfterSocialSignup(
      String email, String socialLoginType) async {
    Map<String, String> bodyParams = {
      'email': email,
      'user_cat': 'driver',
      'login_type': socialLoginType,
    };
    await getDataByPhoneNumber(bodyParams).then((value) {
      if (value != null && value.success == "success") {
        Preferences.setInt(Preferences.userId,
            int.parse(value.userData!.id.toString()));
        Preferences.setString(Preferences.user, jsonEncode(value));
        Preferences.setString(Preferences.accesstoken,
            value.userData!.accesstoken.toString());
        API.headers['accesstoken'] = value.userData!.accesstoken.toString();
        Preferences.setBoolean(Preferences.isLogin, true);

        UserData userData = value.userData!;
        bool isPlanExpired = false;

        /// Case 1: Admin Commission = 'no' and Subscription model = false
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

        /// Case 3: Owner's Driver (driver under an owner)
        bool isOwnerDriver = userData.isOwner == "false" &&
            userData.ownerId != null &&
            userData.ownerId!.isNotEmpty;
        if (isOwnerDriver) {
          Get.offAll(() => DashboardScreen(),
              transition: Transition.rightToLeft);
          return;
        }

        /// Case 2: Individual Driver / Owner — check subscription
        bool isIndividualDriver = userData.isOwner == "false" &&
            (userData.ownerId == null || userData.ownerId!.isEmpty);

        if (isIndividualDriver || userData.isOwner == "true") {
          if (userData.subscriptionPlanId != null) {
            if (userData.subscriptionExpiryDate == null) {
              isPlanExpired =
                  userData.subscriptionPlan?.expiryDay != '-1';
            } else {
              final expiryDate =
                  DateTime.tryParse(userData.subscriptionExpiryDate!);
              isPlanExpired = expiryDate != null &&
                  expiryDate.isBefore(DateTime.now());
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
        ShowToastDialog.showToast(
            "Account created. Please sign in.".tr);
        Get.offAll(() => LoginScreen());
      }
    });
  }
}
