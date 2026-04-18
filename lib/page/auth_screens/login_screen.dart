import 'dart:convert';

import 'package:uniqcars_driver/constant/show_toast_dialog.dart';
import 'package:uniqcars_driver/controller/login_conroller.dart';
import 'package:uniqcars_driver/model/user_model.dart';
import 'package:uniqcars_driver/page/auth_screens/signup_screen.dart';
import 'package:uniqcars_driver/service/api.dart';
import 'package:uniqcars_driver/utils/Preferences.dart';
import 'package:uniqcars_driver/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../themes/app_them_data.dart';
import '../../themes/round_button_fill.dart';
import '../../themes/text_field_widget.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX(
        init: LoginController(),
        builder: (controller) {
          return Scaffold(
            resizeToAvoidBottomInset: true,
            body: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 50),
                    child: Image.asset(
                      themeChange.getThem()
                          ? "assets/images/login_image_2.png"
                          : "assets/images/login_image.png",
                      height: 220,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 40,
                        ),
                        Text(
                          'Let’s get you started'.tr,
                          textAlign: TextAlign.center,
                          style: AppThemeData.boldTextStyle(
                              fontSize: 22,
                              color: themeChange.getThem()
                                  ? AppThemeData.neutralDark900
                                  : AppThemeData.neutral900),
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Text(
                          'Login with your User ID and PIN'.tr,
                          textAlign: TextAlign.center,
                          style: AppThemeData.mediumTextStyle(
                              fontSize: 14,
                              color: themeChange.getThem()
                                  ? AppThemeData.neutralDark500
                                  : AppThemeData.neutral500),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        TextFieldWidget(
                          controller: controller.userIdController.value,
                          hintText: 'Enter your User ID',
                          title: 'User ID',
                          textInputType: TextInputType.number,
                          prefix: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: SvgPicture.asset(
                                "assets/icons/ic_email_login.svg"),
                          ),
                        ),
                        TextFieldWidget(
                          controller: controller.pinController.value,
                          hintText: 'Enter your PIN',
                          title: 'PIN',
                          obscureText: controller.isPinShow.value,
                          textInputType: TextInputType.number,
                          prefix: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: SvgPicture.asset(
                                "assets/icons/ic_lock_login.svg"),
                          ),
                          suffix: InkWell(
                            onTap: () {
                              controller.isPinShow.value =
                                  !controller.isPinShow.value;
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 18),
                              child: Obx(
                                () => controller.isPinShow.value
                                    ? SvgPicture.asset(
                                        "assets/icons/ic_hide.svg")
                                    : SvgPicture.asset(
                                        "assets/icons/ic_show.svg"),
                              ),
                            ),
                          ),
                        ),
                        TextFieldWidget(
                          controller: controller.registrationController.value,
                          hintText: 'Enter vehicle registration no',
                          title: 'Registration No',
                          inputFormatters: [
                            TextInputFormatter.withFunction(
                              (oldValue, newValue) => newValue.copyWith(
                                  text: newValue.text.toUpperCase()),
                            ),
                          ],
                          prefix: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: SvgPicture.asset(
                                "assets/icons/ic_lock_login.svg"),
                          ),
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        RoundedButtonFill(
                          title: "Log in".tr,
                          height: 5.5,
                          color: AppThemeData.primaryDefault,
                          textColor: Colors.white,
                          onPress: () async {
                            FocusScope.of(context).unfocus();
                            if (controller.userIdController.value.text.isEmpty) {
                              ShowToastDialog.showToast(
                                  'Please enter your User ID');
                            } else if (controller
                                .pinController.value.text.isEmpty) {
                              ShowToastDialog.showToast(
                                  'Please enter your PIN');
                            } else if (controller
                                .registrationController.value.text.isEmpty) {
                              ShowToastDialog.showToast(
                                  'Please enter your vehicle registration number');
                            } else {
                              FocusScope.of(context).unfocus();
                              Map<String, String> bodyParams = {
                                'user_id': controller.userIdController.value.text.trim(),
                                'pin': controller.pinController.value.text,
                                'numberplate': controller.registrationController.value.text.trim().toUpperCase(),
                                'user_cat': "driver",
                              };
                              await controller
                                  .loginAPI(bodyParams)
                                  .then((value) async {
                                if (value != null) {
                                  await Preferences.setString(
                                      Preferences.user, jsonEncode(value));
                                  await Preferences.setBoolean(
                                      Preferences.isLogin, true);
                                  UserData? userData = value.userData;
                                  if (userData == null) return;
                                  Preferences.setString(Preferences.accesstoken,
                                      userData.accesstoken.toString());
                                  API.headers['accesstoken'] =
                                      userData.accesstoken.toString();
                                  await Preferences.setInt(Preferences.userId,
                                      int.parse(userData.id.toString()));
                                  bool isPlanExpired = false;

                                  if (userData.subscriptionPlanId != null) {
                                    if (userData.subscriptionExpiryDate == null) {
                                      isPlanExpired = userData.subscriptionPlan?.expiryDay != '-1';
                                    } else {
                                      final expiryDate = DateTime.tryParse(userData.subscriptionExpiryDate!);
                                      isPlanExpired = expiryDate != null && expiryDate.isBefore(DateTime.now());
                                    }
                                  } else {
                                    isPlanExpired = true;
                                  }

                                  showLoginWarningIfNeeded(() =>
                                      LoginController.navigateAfterLogin(userData, isPlanExpired));
                                }
                              });
                            }
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have an account?".tr,
                                style: AppThemeData.mediumTextStyle(
                                    fontSize: 14,
                                    color: themeChange.getThem()
                                        ? AppThemeData.neutralDark500
                                        : AppThemeData.neutral500),
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () {
                                  Get.to(() => const SignupScreen(),
                                      arguments: {'login_type': 'email'});
                                },
                                child: Text(
                                  "Sign Up".tr,
                                  style: AppThemeData.semiBoldTextStyle(
                                      fontSize: 14,
                                      color: AppThemeData.primaryDefault),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}
