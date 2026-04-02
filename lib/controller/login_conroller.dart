import 'dart:async';
import 'dart:convert';

import 'package:uniqcars_driver/constant/constant.dart';
import 'package:uniqcars_driver/constant/show_toast_dialog.dart';
import 'package:uniqcars_driver/model/user_model.dart';
import 'package:uniqcars_driver/page/auth_screens/signup_screen.dart';
import 'package:uniqcars_driver/page/dashboard_screen.dart';
import 'package:uniqcars_driver/page/owner_dashboard_screen.dart';
import 'package:uniqcars_driver/page/subscription_plan_screen/subscription_plan_screen.dart';
import 'package:uniqcars_driver/service/api.dart';
import 'package:uniqcars_driver/utils/Preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

Future<void> showLoginWarningIfNeeded(VoidCallback onConfirmed) async {
  if (Constant.driverLoginWarningEnabled != 'yes' ||
      Constant.driverLoginWarningMessage.isEmpty) {
    onConfirmed();
    return;
  }
  await Get.dialog(
    AlertDialog(
      title: const Text('Warning', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Text(Constant.driverLoginWarningMessage),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () {
              Get.back();
              onConfirmed();
            },
            child: const Text('OK', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
        ),
      ],
    ),
    barrierDismissible: false,
  );
}

class LoginController extends GetxController {
  Rx<TextEditingController> userIdController = TextEditingController().obs;
  Rx<TextEditingController> pinController = TextEditingController().obs;
  Rx<TextEditingController> registrationController = TextEditingController().obs;

  RxBool isPinShow = true.obs;

  static void navigateAfterLogin(UserData userData, bool isPlanExpired) {
    /// Case 1: Admin Commission = 'no' and Subscription model = false
    if (Constant.adminCommission?.statut == "no" &&
        Constant.subscriptionModel == false) {
      if (userData.isOwner == "true") {
        Get.offAll(() => OwnerDashboardScreen(),
            transition: Transition.rightToLeft);
      } else {
        Get.offAll(() => DashboardScreen(), transition: Transition.rightToLeft);
      }
      return;
    }

    /// Case 3: Owner's Driver (driver under an owner)
    bool isOwnerDriver = userData.isOwner == "false" &&
        userData.ownerId != null &&
        userData.ownerId!.isNotEmpty;
    if (isOwnerDriver) {
      Get.offAll(() => DashboardScreen(), transition: Transition.rightToLeft);
      return;
    }

    /// Case 2: Individual Driver or Owner → Check subscription
    bool isIndividualDriver = userData.isOwner == "false" &&
        (userData.ownerId == null || userData.ownerId!.isEmpty);

    if (isIndividualDriver || userData.isOwner == "true") {
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
  }

  Future<UserModel?> loginAPI(Map<String, String> bodyParams) async {
    print(bodyParams);
    UserModel? userModel;
    await API
        .handleApiRequest(
            request: () => http.post(Uri.parse(API.userLogin),
                headers: API.authheader, body: jsonEncode(bodyParams)),
            showLoader: true)
        .then(
      (value) {
        if (value != null) {
          if (value['success'] == "Failed") {
            ShowToastDialog.showToast(value['error']);
            return null;
          } else {
            userModel = UserModel.fromJson(value);
          }
        }
      },
    );
    return userModel;
  }

  Future<bool?> phoneNumberIsExit(Map<String, String> bodyParams) async {
    bool? isExits;
    await API
        .handleApiRequest(
            request: () => http.post(Uri.parse(API.getExistingUserOrNot),
                headers: API.authheader, body: jsonEncode(bodyParams)),
            showLoader: true)
        .then(
      (value) {
        if (value != null) {
          if (value['success'] == "Failed" || value['success'] == "failed") {
            ShowToastDialog.showToast(value['error']);
            return null;
          } else {
            if (value['data'] == true) {
              isExits = true;
            } else {
              isExits = false;
            }
          }
        }
      },
    );
    return isExits;
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

  Future<void> loginWithGoogle() async {
    ShowToastDialog.showLoader("please wait...".tr);
    await signInWithGoogle().then((googleUser) async {
      ShowToastDialog.closeLoader();
      if (googleUser != null) {
        Map<String, String> bodyParams = {
          'user_cat': "driver",
          'email': googleUser.user!.email.toString(),
          'login_type': "google",
        };
        print("==>$bodyParams");
        await phoneNumberIsExit(bodyParams).then((value) async {
          if (value != null) {
            if (value == true) {
              Map<String, String> bodyParams = {
                'email': googleUser.user!.email.toString(),
                'user_cat': "driver",
                'login_type': "google",
              };
              await getDataByPhoneNumber(bodyParams).then((value) {
                if (value != null) {
                  if (value.success == "success") {
                    ShowToastDialog.closeLoader();

                    Preferences.setInt(Preferences.userId,
                        int.parse(value.userData!.id.toString()));
                    Preferences.setString(Preferences.user, jsonEncode(value));
                    Preferences.setString(Preferences.accesstoken,
                        value.userData!.accesstoken.toString());
                    API.headers['accesstoken'] =
                        value.userData!.accesstoken.toString();
                    Preferences.setBoolean(Preferences.isLogin, true);

                    UserData userData = value.userData!;
                    bool isPlanExpired = false;

                    if (userData.subscriptionPlanId != null) {
                      if (userData.subscriptionExpiryDate == null) {
                        isPlanExpired =
                            userData.subscriptionPlan?.expiryDay != '-1';
                      } else {
                        final expiryDate = DateTime.tryParse(
                            userData.subscriptionExpiryDate!);
                        isPlanExpired = expiryDate != null &&
                            expiryDate.isBefore(DateTime.now());
                      }
                    } else {
                      isPlanExpired = true;
                    }

                    showLoginWarningIfNeeded(() =>
                        LoginController.navigateAfterLogin(userData, isPlanExpired));
                  } else {
                    ShowToastDialog.showToast(
                        value.error ?? 'Something went wrong'.tr);
                  }
                } else {
                  ShowToastDialog.showToast(
                      'Something went wrong, please try again'.tr);
                }
              });
            } else if (value == false) {
              ShowToastDialog.closeLoader();
              Get.to(() => SignupScreen(), arguments: {
                'email': googleUser.user!.email,
                'firstName': googleUser.user!.displayName,
                'login_type': "google",
              });
            }
          } else {
            ShowToastDialog.showToast(
                'Something went wrong, please try again'.tr);
          }
        });
      }
    });
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final credential =
          GoogleAuthProvider.credential(idToken: googleAuth.idToken);
      return await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      print('Google Sign-In error: $e');
      return null;
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }
}
