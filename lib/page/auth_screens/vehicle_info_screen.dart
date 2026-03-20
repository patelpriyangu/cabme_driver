import 'package:uniqcars_driver/constant/constant.dart';
import 'package:uniqcars_driver/constant/show_toast_dialog.dart';
import 'package:uniqcars_driver/controller/vehicle_info_controller.dart';
import 'package:uniqcars_driver/themes/app_them_data.dart';
import 'package:uniqcars_driver/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../themes/text_field_widget.dart';
import '../../widget/round_button_fill.dart';

class VehicleInfoScreen extends StatelessWidget {
  const VehicleInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX(
        init: VehicleInfoController(),
        builder: (controller) {
          final bool isOwnerDriver =
              (controller.userModel.value.userData?.ownerId?.isNotEmpty ?? false);
          final bool editable = !isOwnerDriver;

          return Scaffold(
            appBar: AppBar(
              leading: InkWell(
                onTap: () => Get.back(),
                child: const Icon(Icons.arrow_back),
              ),
              centerTitle: false,
            ),
            body: controller.isLoading.value
                ? Constant.loader(context)
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tell Us About Your Vehicle'.tr,
                            style: AppThemeData.boldTextStyle(
                                fontSize: 22,
                                color: themeChange.getThem()
                                    ? AppThemeData.neutralDark900
                                    : AppThemeData.neutral900),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Enter your vehicle details accurately.'.tr,
                            style: AppThemeData.mediumTextStyle(
                                fontSize: 16,
                                color: themeChange.getThem()
                                    ? AppThemeData.neutralDark500
                                    : AppThemeData.neutral500),
                          ),
                          const SizedBox(height: 20),
                          TextFieldWidget(
                            controller: controller.vehicleTypeController.value,
                            hintText: 'Enter Vehicle Type'.tr,
                            title: 'Vehicle Type'.tr,
                            enable: editable,
                          ),
                          TextFieldWidget(
                            controller: controller.brandController.value,
                            hintText: 'Enter Brand'.tr,
                            title: 'Brand'.tr,
                            enable: editable,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: TextFieldWidget(
                                  controller: controller.modelController.value,
                                  hintText: 'Enter Model'.tr,
                                  title: 'Model'.tr,
                                  enable: editable,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFieldWidget(
                                  controller: controller.colorController.value,
                                  hintText: 'Enter Color'.tr,
                                  title: 'Color'.tr,
                                  enable: editable,
                                ),
                              ),
                            ],
                          ),
                          TextFieldWidget(
                            controller: controller.councilCarBadgeNumberController.value,
                            hintText: 'Enter Council Car Badge Number'.tr,
                            title: 'Council Car Badge Number'.tr,
                            enable: editable,
                          ),
                          TextFieldWidget(
                            controller: controller.numberPlateController.value,
                            hintText: 'Enter Vehicle Registration Number'.tr,
                            title: 'Vehicle Registration Number'.tr,
                            enable: editable,
                          ),
                          TextFieldWidget(
                            controller: controller.councilDriverRegistrationNumberController.value,
                            hintText: 'Enter Council Driver Registration Number'.tr,
                            title: 'Council Driver Registration Number'.tr,
                            enable: editable,
                          ),
                          TextFieldWidget(
                            controller: controller.councilDriverBadgeNumberController.value,
                            hintText: 'Enter Driving License Number'.tr,
                            title: 'Driving License Number'.tr,
                            enable: editable,
                          ),
                          TextFieldWidget(
                            controller: controller.pinNumberController.value,
                            hintText: 'Enter Login PIN'.tr,
                            title: 'Login PIN'.tr,
                            enable: editable,
                          ),
                          TextFieldWidget(
                            controller: controller
                                .councilRegistrationNumberController.value,
                            hintText: 'Enter DBS Number'.tr,
                            title: 'DBS Number'.tr,
                            enable: editable,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Passenger Capacity'.tr,
                                  style: AppThemeData.semiBoldTextStyle(
                                      fontSize: 14,
                                      color: themeChange.getThem()
                                          ? AppThemeData.neutralDark700
                                          : AppThemeData.neutral700),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                    color: themeChange.getThem()
                                        ? AppThemeData.neutralDark100
                                        : AppThemeData.neutral100,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                        color: themeChange.getThem()
                                            ? AppThemeData.neutralDark300
                                            : AppThemeData.neutral300)),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 6),
                                  child: Row(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          if (!editable) return;
                                          if (controller.passenger.value > 1) {
                                            controller.passenger.value -= 1;
                                          } else {
                                            ShowToastDialog.showToast(
                                                "Passenger capacity cannot be less than 1".tr);
                                          }
                                        },
                                        child: Icon(Icons.remove,
                                            color: themeChange.getThem()
                                                ? AppThemeData.neutralDark700
                                                : AppThemeData.neutral700),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10),
                                        child: Text(
                                          controller.passenger.value.toString(),
                                          style: AppThemeData.semiBoldTextStyle(
                                              fontSize: 14,
                                              color: themeChange.getThem()
                                                  ? AppThemeData.neutralDark900
                                                  : AppThemeData.neutral900),
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () {
                                          if (!editable) return;
                                          controller.passenger.value += 1;
                                        },
                                        child: Icon(Icons.add,
                                            color: themeChange.getThem()
                                                ? AppThemeData.neutralDark700
                                                : AppThemeData.neutral700),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
            bottomNavigationBar: isOwnerDriver
                ? const SizedBox()
                : Padding(
                    padding: const EdgeInsets.only(
                        bottom: 30, right: 16, left: 16, top: 10),
                    child: RoundedButtonFill(
                      title: "Save".tr,
                      height: 5.5,
                      color: AppThemeData.primaryDefault,
                      textColor: AppThemeData.neutral50,
                      onPress: () async {
                        if (controller.vehicleTypeController.value.text.isEmpty) {
                          ShowToastDialog.showToast("Please enter vehicle type".tr);
                        } else if (controller.brandController.value.text.isEmpty) {
                          ShowToastDialog.showToast("Please enter brand".tr);
                        } else if (controller.modelController.value.text.isEmpty) {
                          ShowToastDialog.showToast("Please enter model".tr);
                        } else if (controller.colorController.value.text.isEmpty) {
                          ShowToastDialog.showToast("Please enter color".tr);
                        } else if (controller.councilCarBadgeNumberController.value.text.isEmpty) {
                          ShowToastDialog.showToast("Please enter council car badge number".tr);
                        } else if (controller.numberPlateController.value.text.isEmpty) {
                          ShowToastDialog.showToast("Please enter vehicle registration number".tr);
                        } else if (controller.councilDriverRegistrationNumberController.value.text.isEmpty) {
                          ShowToastDialog.showToast("Please enter council driver registration number".tr);
                        } else if (controller.councilDriverBadgeNumberController.value.text.isEmpty) {
                          ShowToastDialog.showToast("Please enter driving license number".tr);
                        } else if (controller.pinNumberController.value.text.isEmpty) {
                          ShowToastDialog.showToast("Please enter login PIN".tr);
                        } else if (controller.councilRegistrationNumberController.value.text.isEmpty) {
                          ShowToastDialog.showToast("Please enter DBS number".tr);
                        } else {
                          controller.saveVehicle();
                        }
                      },
                    ),
                  ),
          );
        });
  }
}
