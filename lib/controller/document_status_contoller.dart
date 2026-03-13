// ignore_for_file: unused_local_variable

import 'dart:async';
import 'dart:io';
import 'package:uniqcars_driver/constant/constant.dart';
import 'package:uniqcars_driver/constant/show_toast_dialog.dart';
import 'package:uniqcars_driver/model/driver_upload_model.dart';
import 'package:uniqcars_driver/model/user_model.dart';
import 'package:uniqcars_driver/service/api.dart';
import 'package:uniqcars_driver/utils/Preferences.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DocumentStatusController extends GetxController {
  RxBool isLoading = true.obs;

  Rx<UserModel> userModel = UserModel().obs;

  RxList<DriverUploadData> uploadList = <DriverUploadData>[].obs;

  @override
  void onInit() {
    getData();
    super.onInit();
  }

  Future<void> getData() async {
    userModel.value = Constant.getUserData();
    await getDriverUploads();
    isLoading.value = false;
  }

  Future<void> getDriverUploads() async {
    final Map<String, String> bodyParams = {
      'driver_id': Preferences.getInt(Preferences.userId).toString(),
    };
    await API
        .handleApiRequest(
            request: () => http.post(
                  Uri.parse(API.driverGetUploads),
                  body: jsonEncode(bodyParams),
                  headers: API.headers,
                ),
            showLoader: false)
        .then((value) {
      if (value != null) {
        if (value['success'] == 'Failed') {
          // No uploads yet — clear list silently
          uploadList.value = [];
        } else {
          final model = DriverUploadModel.fromJson(value);
          uploadList.value = model.data ?? [];
        }
      }
    });
  }

  /// Upload one or more files (any type, no predefined categories).
  Future<void> uploadFiles(List<String> paths) async {
    if (paths.isEmpty) return;

    List<http.MultipartFile> files = [];
    for (final path in paths) {
      files.add(http.MultipartFile.fromBytes(
        'attachment',
        File(path).readAsBytesSync(),
        filename: File(path).path.split('/').last,
      ));
    }

    final Map<String, String> fields = {
      'driver_id': Preferences.getInt(Preferences.userId).toString(),
    };

    final response = await API.handleMultipartRequest(
      url: API.driverUploadFiles,
      headers: API.headers,
      fields: fields,
      files: files,
      showLoader: true,
    );

    if (response != null &&
        (response['success'] == 'Success' || response['success'] == 'success')) {
      await getDriverUploads();
      ShowToastDialog.showToast('Documents Uploaded Successfully'.tr);
    }
  }
}
