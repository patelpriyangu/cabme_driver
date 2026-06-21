import 'package:uniqcars_driver/constant/show_toast_dialog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:location/location.dart';

class LocationPermissionDisclosureDialog extends StatelessWidget {
  const LocationPermissionDisclosureDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Location Access Disclosure'),
      content: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'This app collects location data to enable ride dispatch, pickup and drop-off navigation, and customer ride tracking even when the app is closed or not in use.',
            ),
            SizedBox(height: 10),
            Text(
              'Location sharing starts only when you go online or have an active trip, and stops when you go offline.',
            ),
          ],
        ),
      ),
      actions: <Widget>[
        MaterialButton(
          onPressed: () {
            _requestLocationPermission();
          },
          child: const Text(
            'Allow Location Access',
            style: TextStyle(color: Colors.green),
          ),
        ),
        MaterialButton(
          onPressed: () {
            Get.back();
          },
          child: const Text('Not Now', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  // Method to request location permission using permission_handler package
  void _requestLocationPermission() async {
    PermissionStatus location = await Location().requestPermission();
    if (location == PermissionStatus.granted) {
      Get.back();
    } else {
      ShowToastDialog.showToast("Permission Denied");
    }
  }
}
