import 'dart:async';
import 'dart:convert';

import 'package:uniqcars_driver/constant/show_toast_dialog.dart';
import 'package:uniqcars_driver/model/user_model.dart';
import 'package:uniqcars_driver/page/auth_screens/otp_screen.dart';
import 'package:uniqcars_driver/page/owner_dashboard_screen.dart';
import 'package:uniqcars_driver/service/api.dart';
import 'package:uniqcars_driver/utils/Preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../page/auth_screens/signup_screen.dart';
import '../page/dashboard_screen.dart';

class PhoneNumberController extends GetxController {
  Rx<TextEditingController> phoneNumber = TextEditingController().obs;
  Rx<TextEditingController> countryCodeController =
      TextEditingController(text: "+91").obs;
  RxInt resendTokenData = 0.obs;

  Future<void> sendCode() async {
    await FirebaseAuth.instance
        .verifyPhoneNumber(
            phoneNumber: countryCodeController.value.text +
                phoneNumber.value.text.trim(),
            verificationCompleted: (PhoneAuthCredential credential) {},
            verificationFailed: (FirebaseAuthException e) {
              ShowToastDialog.closeLoader();
              print(e.message.toString());
              if (e.code == 'invalid-phone-number') {
                ShowToastDialog.showToast(
                    "The provided phone number is not valid.");
              } else {
                ShowToastDialog.showToast(e.message.toString());
              }
            },
            codeSent: (String verificationId, int? resendToken) {
              resendTokenData.value = resendToken ?? 0;
              ShowToastDialog.closeLoader();
              Get.to(
                () => const OtpScreen(),
                arguments: {
                  'phoneNumber': phoneNumber.value.text.trim(),
                  'countryCode': countryCodeController.value.text,
                  'verificationId': verificationId,
                  'resendTokenData': resendTokenData.value,
                },
              );
            },
            codeAutoRetrievalTimeout: (String verificationId) {},
            forceResendingToken: resendTokenData.value)
        .catchError((error) {
      ShowToastDialog.closeLoader();
      ShowToastDialog.showToast(
          "You have try many time please send otp after some time");
    });
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
                    if (value.userData!.isOwner == "true") {
                      Get.offAll(OwnerDashboardScreen(),
                          transition: Transition.rightToLeft);
                    } else {
                      Get.offAll(DashboardScreen(),
                          transition: Transition.rightToLeft);
                    }
                  } else {
                    ShowToastDialog.showToast(value.error);
                  }
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
