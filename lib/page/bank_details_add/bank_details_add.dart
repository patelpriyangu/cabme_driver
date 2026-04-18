import 'package:uniqcars_driver/constant/show_toast_dialog.dart';
import 'package:uniqcars_driver/controller/bank_details_add_controller.dart';
import 'package:uniqcars_driver/themes/app_them_data.dart';
import 'package:uniqcars_driver/themes/text_field_widget.dart';
import 'package:uniqcars_driver/utils/dark_theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../../themes/round_button_fill.dart';

class BankDetailsAdd extends StatelessWidget {
  const BankDetailsAdd({super.key});

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);
    return GetX(
        init: BankDetailsAddController(),
        builder: (controller) {
          return Scaffold(
            appBar: AppBar(
              leading: InkWell(
                onTap: () {
                  Get.back();
                },
                child: Icon(Icons.arrow_back),
              ),
              centerTitle: false,
              title: Text(
                "Bank Details".tr,
                style: AppThemeData.semiBoldTextStyle(fontSize: 18),
              ),
            ),
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: themeChange.getThem()
                          ? AppThemeData.neutralDark200
                          : const Color(0xFFFFF8E1),
                      border: Border.all(
                        color: const Color(0xFFFFB300),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline,
                            color: Color(0xFFFFB300), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Please ensure the account holder name matches exactly with your registered driver profile. Payments will only be processed to verified accounts with matching details.'
                                .tr,
                            style: AppThemeData.regularTextStyle(
                              fontSize: 13,
                              color: themeChange.getThem()
                                  ? AppThemeData.neutralDark700
                                  : const Color(0xFF5D4037),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                /*  TextFieldWidget(
                    controller: controller.bankNameController.value,
                    hintText: 'Enter Bank Name',
                    title: 'Bank Name',
                  ),
                  TextFieldWidget(
                    controller: controller.branchController.value,
                    hintText: 'Enter Branch Name',
                    title: 'Branch Name',
                  ),*/
                  TextFieldWidget(
                    controller: controller.holderNameController.value,
                    hintText: 'Enter Bank Holder Name',
                    title: 'Bank Holder Name',
                  ),
                  TextFieldWidget(
                    controller: controller.accountNumberController.value,
                    hintText: 'Enter Bank Account number',
                    title: 'Bank Account Number',
                  ),
                  TextFieldWidget(
                    controller: controller.ifcsCodeController.value,
                    hintText: 'Enter Bank Short Code',
                    title: 'Short Code',
                  ),
                  TextFieldWidget(
                    controller: controller.informationController.value,
                    hintText: 'Enter information',
                    title: 'Information',
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: RoundedButtonFill(
                      title: "Add Account".tr,
                      height: 5.5,
                      color: AppThemeData.primaryDefault,
                      textColor: Colors.white,
                      onPress: () async {
                        if (controller.bankNameController.value.text.isEmpty) {
                          ShowToastDialog.showToast("Please enter bank name");
                        } else if (controller
                            .branchController.value.text.isEmpty) {
                          ShowToastDialog.showToast("Please enter branch name");
                        } else if (controller
                            .holderNameController.value.text.isEmpty) {
                          ShowToastDialog.showToast(
                              "Please enter bank holder name");
                        } else if (controller
                            .accountNumberController.value.text.isEmpty) {
                          ShowToastDialog.showToast(
                              "Please enter bank account number");
                        } else if (controller
                            .ifcsCodeController.value.text.isEmpty) {
                          ShowToastDialog.showToast("Please enter bank short code");
                        } else if (controller
                            .informationController.value.text.isEmpty) {
                          ShowToastDialog.showToast("Please enter information");
                        } else {
                          controller.submitBankDetails();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}
