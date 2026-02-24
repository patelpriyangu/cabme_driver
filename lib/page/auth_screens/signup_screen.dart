// ignore_for_file: must_be_immutable

import 'package:uniqcars_driver/constant/show_toast_dialog.dart';
import 'package:uniqcars_driver/controller/sign_up_controller.dart';
import 'package:uniqcars_driver/page/auth_screens/login_screen.dart';
import 'package:uniqcars_driver/themes/app_them_data.dart';
import 'package:uniqcars_driver/utils/dark_theme_provider.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../themes/text_field_widget.dart';
import '../../widget/round_button_fill.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX<SignUpController>(
        init: SignUpController(),
        builder: (controller) {
          return Scaffold(
            resizeToAvoidBottomInset: true, // <-- IMPORTANT
            appBar: AppBar(
              leading: InkWell(
                  onTap: () {
                    Get.back();
                  },
                  child: Icon(Icons.arrow_back)),
            ),
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 20,
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
                      'Start booking your rides in just a few taps.'.tr,
                      textAlign: TextAlign.center,
                      style: AppThemeData.mediumTextStyle(
                          fontSize: 14,
                          color: themeChange.getThem()
                              ? AppThemeData.neutralDark500
                              : AppThemeData.neutral500),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 20,
                        ),
                        Text(
                          'Continue as a.'.tr,
                          textAlign: TextAlign.center,
                          style: AppThemeData.mediumTextStyle(
                              fontSize: 14,
                              color: themeChange.getThem()
                                  ? AppThemeData.neutralDark700
                                  : AppThemeData.neutral700),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<String>(
                                title: Text('Individual'.tr),
                                value: 'Individual',
                                groupValue: controller.selectedValue.value,
                                onChanged: (value) {
                                  controller.selectedValue.value = value!;
                                },
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<String>(
                                title: Text('Company'.tr),
                                value: 'Company',
                                groupValue: controller.selectedValue.value,
                                onChanged: (value) {
                                  controller.selectedValue.value = value!;
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        Text(
                          'Service Type',
                          style: AppThemeData.semiBoldTextStyle(
                            fontSize: 14,
                            color: themeChange.getThem()
                                ? AppThemeData.neutralDark700
                                : AppThemeData.neutral700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: themeChange.getThem()
                                ? AppThemeData.neutralDark100
                                : AppThemeData.neutral100,
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              color: themeChange.getThem()
                                  ? AppThemeData.neutralDark300
                                  : AppThemeData.neutral300,
                            ),
                          ),
                          child: Text(
                            'Ride',
                            style: AppThemeData.mediumTextStyle(
                              fontSize: 14,
                              color: themeChange.getThem()
                                  ? AppThemeData.neutralDark900
                                  : AppThemeData.neutral900,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        TextFieldWidget(
                          controller: controller.firstNameController.value,
                          hintText: 'Enter First Name',
                          title: 'First Name',
                          prefix: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: SvgPicture.asset("assets/icons/ic_user.svg"),
                          ),
                        ),
                        TextFieldWidget(
                          controller: controller.lastNameController.value,
                          hintText: 'Enter Last Name',
                          title: 'Last Name',
                          prefix: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: SvgPicture.asset("assets/icons/ic_user.svg"),
                          ),
                        ),
                        TextFieldWidget(
                          controller: controller.emailController.value,
                          hintText: 'Enter Email Address',
                          title: 'Email Address',
                          enable: controller.loginType.value == "phoneNumber" ||
                              controller.loginType.value == "email",
                          prefix: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: SvgPicture.asset(
                                "assets/icons/ic_email_login.svg"),
                          ),
                        ),
                        TextFieldWidget(
                          controller: controller.phoneNumber.value,
                          hintText: 'Enter Mobile Number',
                          title: 'Mobile Number',
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp('[0-9]')),
                          ],
                          enable: controller.loginType.value == "phoneNumber"
                              ? false
                              : true,
                          prefix: CountryCodePicker(
                            onChanged: (value) {
                              controller.countryCodeController.value.text =
                                  value.dialCode.toString();
                            },
                            dialogTextStyle: TextStyle(
                              color: themeChange.getThem()
                                  ? AppThemeData.neutralDark900
                                  : AppThemeData.neutral900,
                              fontWeight: FontWeight.w500,
                              fontFamily: AppThemeData.medium,
                            ),
                            dialogBackgroundColor: themeChange.getThem()
                                ? AppThemeData.neutralDark50
                                : AppThemeData.neutral50,
                            initialSelection:
                                controller.countryCodeController.value.text,
                            comparator: (a, b) =>
                                b.name!.compareTo(a.name.toString()),
                            flagDecoration: const BoxDecoration(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(2)),
                            ),
                            textStyle: TextStyle(
                              color: themeChange.getThem()
                                  ? AppThemeData.neutralDark900
                                  : AppThemeData.neutral900,
                              fontWeight: FontWeight.w500,
                              fontFamily: AppThemeData.medium,
                            ),
                            searchDecoration: InputDecoration(
                              iconColor: themeChange.getThem()
                                  ? AppThemeData.neutralDark900
                                  : AppThemeData.neutral900,
                            ),
                            searchStyle: TextStyle(
                              color: themeChange.getThem()
                                  ? AppThemeData.neutralDark900
                                  : AppThemeData.neutral900,
                              fontWeight: FontWeight.w500,
                              fontFamily: AppThemeData.medium,
                            ),
                          ),
                        ),
                        TextFieldWidget(
                          controller:
                              controller.registrationNumberController.value,
                          hintText: 'Enter Vehicle Registration Number',
                          title: 'Registration Number',
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp('[a-zA-Z0-9 ]')),
                          ],
                        ),
                        if (controller.loginType.value != "google" &&
                            controller.loginType.value != "apple") ...[
                          TextFieldWidget(
                            controller: controller.pinController.value,
                            hintText: 'Enter PIN',
                            title: 'PIN',
                            obscureText: controller.isPinShow.value,
                            textInputType: TextInputType.number,
                            prefix: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 18),
                              child: SvgPicture.asset(
                                  "assets/icons/ic_lock_login.svg"),
                            ),
                            suffix: InkWell(
                              onTap: () {
                                controller.isPinShow.value =
                                    !controller.isPinShow.value;
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18),
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
                            controller: controller.confirmPinController.value,
                            hintText: 'Confirm PIN',
                            title: 'Confirm PIN',
                            obscureText: controller.isConfirmPinShow.value,
                            textInputType: TextInputType.number,
                            prefix: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 18),
                              child: SvgPicture.asset(
                                  "assets/icons/ic_lock_login.svg"),
                            ),
                            suffix: InkWell(
                              onTap: () {
                                controller.isConfirmPinShow.value =
                                    !controller.isConfirmPinShow.value;
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18),
                                child: Obx(
                                  () => controller.isConfirmPinShow.value
                                      ? SvgPicture.asset(
                                          "assets/icons/ic_hide.svg")
                                      : SvgPicture.asset(
                                          "assets/icons/ic_show.svg"),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: RoundedButtonFill(
                title: "Create Account".tr,
                height: 5.5,
                color: AppThemeData.primaryDefault,
                textColor: AppThemeData.neutral50,
                onPress: () async {
                  FocusScope.of(context).unfocus();
                  if (controller.firstNameController.value.text.isEmpty) {
                    ShowToastDialog.showToast("Please enter a first name");
                  } else if (controller.lastNameController.value.text.isEmpty) {
                    ShowToastDialog.showToast("Please enter a last name");
                  } else if (controller.emailController.value.text.isEmpty) {
                    ShowToastDialog.showToast("Please enter a email");
                  } else if (controller.phoneNumber.value.text.isEmpty) {
                    ShowToastDialog.showToast("Please enter a phone number");
                  } else if (controller
                      .registrationNumberController.value.text.isEmpty) {
                    ShowToastDialog.showToast(
                        "Please enter vehicle registration number");
                  } else if (controller.loginType.value != "google" &&
                      controller.loginType.value != "apple" &&
                      controller.pinController.value.text.isEmpty) {
                    ShowToastDialog.showToast("Please enter a PIN");
                  } else if (controller.loginType.value != "google" &&
                      controller.loginType.value != "apple" &&
                      controller.pinController.value.text.trim() !=
                          controller.confirmPinController.value.text.trim()) {
                    ShowToastDialog.showToast("PIN and confirm PIN do not match");
                  } else {
                    Map<String, String> bodyParams = {
                      'firstname': controller.firstNameController.value.text
                          .trim()
                          .toString(),
                      'lastname': controller.lastNameController.value.text
                          .trim()
                          .toString(),
                      'phone': controller.phoneNumber.value.text.trim(),
                      'country_code':
                          controller.countryCodeController.value.text,
                      'email': controller.emailController.value.text.trim(),
                      if (controller.loginType.value != "google" &&
                          controller.loginType.value != "apple")
                        'pin': controller.pinController.value.text,
                      'login_type': controller.loginType.value,
                      'tonotify': 'yes',
                      'account_type':
                          controller.selectedValue.value == "Company"
                              ? "owner"
                              : 'driver',
                      'service_type': 'ride',
                      'registration_number': controller
                          .registrationNumberController.value.text
                          .trim()
                          .toUpperCase(),
                    };
                    await controller.signUp(bodyParams).then((value) async {
                      if (value != null) {
                        if (value.success == "success") {
                          if (controller.loginType.value == "google" ||
                              controller.loginType.value == "apple") {
                            await controller.autoLoginAfterSocialSignup(
                              controller.emailController.value.text.trim(),
                              controller.loginType.value,
                            );
                          } else {
                            final driverId = value.userData?.id ?? '';
                            if (!context.mounted) return;
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => AlertDialog(
                                title: Text('Account Created'.tr),
                                content: Text(
                                  '${'Your account has been created. Your User ID is'.tr} $driverId. ${'Please use this ID along with your PIN to log in.'.tr}',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Get.offAll(() => LoginScreen());
                                    },
                                    child: Text('OK'.tr),
                                  ),
                                ],
                              ),
                            );
                          }
                        } else {
                          ShowToastDialog.showToast(value.message);
                        }
                      }
                    });
                  }
                },
              ),
            ),
          );
        });
  }
}
