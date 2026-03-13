import 'dart:convert';

import 'package:uniqcars_driver/constant/constant.dart';
import 'package:uniqcars_driver/constant/show_toast_dialog.dart';
import 'package:uniqcars_driver/model/get_vehicle_data_model.dart';
import 'package:uniqcars_driver/model/user_model.dart';
import 'package:uniqcars_driver/service/api.dart';
import 'package:uniqcars_driver/utils/Preferences.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class AddVehicleController extends GetxController {
  RxBool isLoading = true.obs;

  Rx<TextEditingController> vehicleTypeController = TextEditingController().obs;
  Rx<TextEditingController> brandController = TextEditingController().obs;
  Rx<TextEditingController> modelController = TextEditingController().obs;
  Rx<TextEditingController> colorController = TextEditingController().obs;
  Rx<TextEditingController> councilCarBadgeNumberController = TextEditingController().obs;
  Rx<TextEditingController> numberPlateController = TextEditingController().obs;
  Rx<TextEditingController> councilDriverRegistrationNumberController = TextEditingController().obs;
  Rx<TextEditingController> councilDriverBadgeNumberController = TextEditingController().obs;

  final RxInt passenger = 1.obs;

  Rx<UserModel> userModel = UserModel().obs;
  Rx<VehicleData> vehicleData = VehicleData().obs;

  @override
  void onInit() {
    userModel.value = Constant.getUserData();
    getArguments();
    super.onInit();
  }

  Future<void> getArguments() async {
    final args = Get.arguments;
    if (args != null) {
      vehicleData.value = args["vehicleData"];
      if (vehicleData.value.id != null) {
        vehicleTypeController.value.text = vehicleData.value.vehicleTypeText ?? '';
        brandController.value.text = vehicleData.value.brand ?? '';
        modelController.value.text = vehicleData.value.model ?? '';
        colorController.value.text = vehicleData.value.color ?? '';
        councilCarBadgeNumberController.value.text = vehicleData.value.councilCarBadgeNumber ?? '';
        numberPlateController.value.text = vehicleData.value.numberplate ?? '';
        councilDriverRegistrationNumberController.value.text = vehicleData.value.councilDriverRegistrationNumber ?? '';
        councilDriverBadgeNumberController.value.text = vehicleData.value.councilDriverBadgeNumber ?? '';
        passenger.value = (vehicleData.value.passenger ?? '').isEmpty
            ? 1
            : int.tryParse(vehicleData.value.passenger.toString()) ?? 1;
      }
    }
    isLoading.value = false;
  }

  Future<void> saveVehicle() async {
    Map<String, dynamic> bodyParams = {
      'id_vehicle': Get.arguments == null ? '' : vehicleData.value.id?.toString() ?? '',
      'owner_id': Preferences.getInt(Preferences.userId).toString(),
      'vehicle_type_text': vehicleTypeController.value.text,
      'brand': brandController.value.text,
      'model': modelController.value.text,
      'color': colorController.value.text,
      'council_car_badge_number': councilCarBadgeNumberController.value.text,
      'carregistration': numberPlateController.value.text,
      'council_driver_registration_number': councilDriverRegistrationNumberController.value.text,
      'driving_license_number': councilDriverBadgeNumberController.value.text,
      'passenger': passenger.value.toString(),
    };
    await API
        .handleApiRequest(
            request: () => http.post(Uri.parse(API.ownerVehicleRegister),
                headers: API.headers, body: jsonEncode(bodyParams)),
            showLoader: true)
        .then(
      (value) {
        if (value != null) {
          if (value['success'] == "failed" || value['success'] == "Failed") {
            ShowToastDialog.showToast(value['message']);
            return null;
          } else {
            ShowToastDialog.showToast(value['message']);
            Get.back(result: true);
          }
        }
      },
    );
  }
}
