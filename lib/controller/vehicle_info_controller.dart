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

class VehicleInfoController extends GetxController {
  Rx<TextEditingController> vehicleTypeController = TextEditingController().obs;
  Rx<TextEditingController> brandController = TextEditingController().obs;
  Rx<TextEditingController> modelController = TextEditingController().obs;
  Rx<TextEditingController> colorController = TextEditingController().obs;
  Rx<TextEditingController> numberPlateController = TextEditingController().obs;
  Rx<TextEditingController> councilCarBadgeNumberController = TextEditingController().obs;
  Rx<TextEditingController> councilDriverRegistrationNumberController = TextEditingController().obs;
  Rx<TextEditingController> councilDriverBadgeNumberController = TextEditingController().obs;
  Rx<TextEditingController> pinNumberController = TextEditingController().obs;
  Rx<TextEditingController> councilRegistrationNumberController = TextEditingController().obs;

  Rx<UserModel> userModel = UserModel().obs;
  Rx<VehicleData> vehicleData = VehicleData().obs;

  final RxInt passenger = 1.obs;

  RxBool isLoading = true.obs;

  @override
  void onInit() {
    getUserdata();
    super.onInit();
  }

  Future<void> getUserdata() async {
    userModel.value = Constant.getUserData();
    await loadVehicleData();
    isLoading.value = false;
  }

  Future<void> loadVehicleData() async {
    await API
        .handleApiRequest(
            request: () => http.get(
                Uri.parse(
                    "${API.getVehicleData}${Preferences.getInt(Preferences.userId)}"),
                headers: API.headers),
            showLoader: false)
        .then(
      (value) {
        if (value != null) {
          if (value['success'] == "failed" || value['success'] == "Failed") {
            return null;
          } else {
            GetVehicleDataModel model = GetVehicleDataModel.fromJson(value);
            vehicleData.value = model.vehicleData!;
          }
        }
      },
    );

    if (vehicleData.value.id != null) {
      vehicleTypeController.value.text = vehicleData.value.vehicleTypeText ?? '';
      brandController.value.text = vehicleData.value.brand ?? '';
      modelController.value.text = vehicleData.value.model ?? '';
      colorController.value.text = vehicleData.value.color ?? '';
      numberPlateController.value.text = vehicleData.value.numberplate ?? '';
      passenger.value = (vehicleData.value.passenger ?? '').isEmpty
          ? 1
          : int.tryParse(vehicleData.value.passenger.toString()) ?? 1;
      councilCarBadgeNumberController.value.text =
          vehicleData.value.councilCarBadgeNumber ?? '';
      councilDriverRegistrationNumberController.value.text =
          vehicleData.value.councilDriverRegistrationNumber ?? '';
      councilDriverBadgeNumberController.value.text =
          vehicleData.value.councilDriverBadgeNumber ?? '';
      pinNumberController.value.text = vehicleData.value.pin ?? vehicleData.value.pinNumber ?? '';
      councilRegistrationNumberController.value.text =
          vehicleData.value.councilRegistrationNumber ?? '';
    } else {
      // Pre-populate registration number from driver profile if entered during signup
      final regNumber = userModel.value.userData?.registrationNumber;
      if (regNumber != null && regNumber.isNotEmpty) {
        numberPlateController.value.text = regNumber;
      }
    }
  }

  Future<void> saveVehicle() async {
    Map<String, dynamic> bodyParams = {
      'id_driver': userModel.value.userData?.id ?? '',
      'vehicle_type_text': vehicleTypeController.value.text,
      'brand': brandController.value.text,
      'model': modelController.value.text,
      'color': colorController.value.text,
      'carregistration': numberPlateController.value.text,
      'car_make': null,
      'milage': null,
      'km_driven': null,
      'passenger': passenger.value.toString(),
      'council_car_badge_number': councilCarBadgeNumberController.value.text,
      'council_driver_registration_number': councilDriverRegistrationNumberController.value.text,
      'driving_license_number': councilDriverBadgeNumberController.value.text,
      'pin': pinNumberController.value.text,
      'dbs_number': councilRegistrationNumberController.value.text,
      'zone_id': '',
    };
    debugPrint("🚗 [saveVehicle] URL: ${API.vehicleRegister}");
    debugPrint("🚗 [saveVehicle] Headers: ${API.headers}");
    debugPrint("🚗 [saveVehicle] Body: ${jsonEncode(bodyParams)}");
    await API
        .handleApiRequest(
            request: () => http.post(Uri.parse(API.vehicleRegister),
                headers: API.headers, body: jsonEncode(bodyParams)),
            showLoader: true)
        .then(
      (value) {
        if (value != null) {
          if (value['success'] == "failed" || value['success'] == "Failed") {
            ShowToastDialog.showToast(value['error']);
            return null;
          } else {
            ShowToastDialog.showToast(value['message']);
            // Update cached user model so home screen sees statut_vehicule = 'yes'
            final String storedUser = Preferences.getString(Preferences.user);
            if (storedUser.isNotEmpty) {
              try {
                final Map<String, dynamic> userMap = jsonDecode(storedUser);
                if (userMap['data'] != null) {
                  userMap['data']['statut_vehicule'] = 'yes';
                } else {
                  userMap['statut_vehicule'] = 'yes';
                }
                Preferences.setString(Preferences.user, jsonEncode(userMap));
              } catch (_) {}
            }
            Get.back(result: true);
          }
        }
      },
    );
  }
}
