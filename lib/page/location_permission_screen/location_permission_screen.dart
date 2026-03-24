import 'package:uniqcars_driver/controller/location_permission_controller.dart';
import 'package:uniqcars_driver/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../themes/app_them_data.dart';
import '../../widget/round_button_fill.dart';

class LocationPermissionScreen extends StatelessWidget {
  const LocationPermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetBuilder(
        init: LocationPermissionController(),
        builder: (controller) {
          return Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SvgPicture.asset("assets/images/location_image.svg"),
                  SizedBox(height: 80),
                  Text(
                    "Enable Location Access".tr,
                    textAlign: TextAlign.center,
                    style: AppThemeData.boldTextStyle(
                        fontSize: 22,
                        color: themeChange.getThem()
                            ? AppThemeData.neutral900
                            : AppThemeData.neutral900),
                  ),
                  Text(
                    "To find nearby passengers and provide accurate navigation, we need access to your real-time location. This helps ensure smooth pickups and efficient routing."
                        .tr,
                    textAlign: TextAlign.center,
                    style: AppThemeData.regularTextStyle(
                        fontSize: 14,
                        color: themeChange.getThem()
                            ? AppThemeData.neutral500
                            : AppThemeData.neutral500),
                  ),
                  SizedBox(height: 30),
                  RoundedButtonFill(
                    title: 'Continue'.tr,
                    width: 50,
                    textColor: AppThemeData.neutral900,
                    color: AppThemeData.primaryDefault,
                    onPress: () {
                      controller.requestPermission();
                    },
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => controller.proceedWithoutLocation(),
                    child: Text(
                      'Not Now'.tr,
                      style: AppThemeData.mediumTextStyle(
                        fontSize: 14,
                        color: themeChange.getThem() ? AppThemeData.neutralDark500 : AppThemeData.neutral500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          );
        });
  }
}
