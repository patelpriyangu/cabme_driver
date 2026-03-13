import 'package:file_picker/file_picker.dart';
import 'package:uniqcars_driver/constant/constant.dart';
import 'package:uniqcars_driver/constant/show_toast_dialog.dart';
import 'package:uniqcars_driver/controller/document_status_contoller.dart';
import 'package:uniqcars_driver/model/driver_upload_model.dart';
import 'package:uniqcars_driver/themes/app_them_data.dart';
import 'package:uniqcars_driver/themes/responsive.dart';
import 'package:uniqcars_driver/utils/dark_theme_provider.dart';
import 'package:uniqcars_driver/utils/network_image_widget.dart';
import 'package:uniqcars_driver/widget/custom_alert_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class DocumentStatusScreen extends StatelessWidget {
  DocumentStatusScreen({super.key});

  final ImagePicker _imagePicker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final themeChange = Provider.of<DarkThemeProvider>(context);

    return GetX<DocumentStatusController>(
      init: DocumentStatusController(),
      builder: (controller) {
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload Your Documents'.tr,
                        style: AppThemeData.boldTextStyle(
                          fontSize: 22,
                          color: themeChange.getThem()
                              ? AppThemeData.neutralDark900
                              : AppThemeData.neutral900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'We need to verify your identity.'.tr,
                        style: AppThemeData.mediumTextStyle(
                          fontSize: 16,
                          color: themeChange.getThem()
                              ? AppThemeData.neutralDark500
                              : AppThemeData.neutral500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: controller.uploadList.isEmpty
                            ? _buildEmptyState(context, themeChange, controller)
                            : ListView.builder(
                                itemCount: controller.uploadList.length,
                                itemBuilder: (context, index) {
                                  return _buildUploadCard(
                                    context,
                                    themeChange,
                                    controller,
                                    controller.uploadList[index],
                                  );
                                },
                              ),
                      ),
                      // Upload button at the bottom
                      if (controller.uploadList.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppThemeData.primaryDefault,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              icon: const Icon(Icons.add_photo_alternate_outlined,
                                  color: Colors.white),
                              label: Text(
                                'Add More Documents'.tr,
                                style: AppThemeData.semiBoldTextStyle(
                                    fontSize: 15,
                                    color: AppThemeData.neutral50),
                              ),
                              onPressed: () =>
                                  _showPickerSheet(context, themeChange, controller),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, DarkThemeProvider themeChange,
      DocumentStatusController controller) {
    return InkWell(
      onTap: () => _showPickerSheet(context, themeChange, controller),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
        decoration: BoxDecoration(
          color: themeChange.getThem()
              ? AppThemeData.neutralDark100
              : AppThemeData.neutral100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: themeChange.getThem()
                ? AppThemeData.neutralDark300
                : AppThemeData.neutral300,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset('assets/icons/ic_documenr.svg'),
            const SizedBox(height: 12),
            Text(
              'Upload Files'.tr,
              style: AppThemeData.semiBoldTextStyle(
                fontSize: 16,
                color: themeChange.getThem()
                    ? AppThemeData.neutralDark900
                    : AppThemeData.neutral900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload any identity, licence, insurance or other documents required for verification.'
                  .tr,
              textAlign: TextAlign.center,
              style: AppThemeData.mediumTextStyle(
                fontSize: 13,
                color: themeChange.getThem()
                    ? AppThemeData.neutralDark500
                    : AppThemeData.neutral500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard(
    BuildContext context,
    DarkThemeProvider themeChange,
    DocumentStatusController controller,
    DriverUploadData upload,
  ) {
    final bool isImage = _isImageUrl(upload.fileUrl ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: themeChange.getThem()
            ? AppThemeData.neutralDark100
            : AppThemeData.neutral100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: themeChange.getThem()
              ? AppThemeData.neutralDark300
              : AppThemeData.neutral300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File preview
          if (isImage && upload.fileUrl != null && upload.fileUrl!.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(8)),
              child: NetworkImageWidget(
                height: Responsive.height(22, context),
                width: double.infinity,
                fit: BoxFit.cover,
                imageUrl: upload.fileUrl!,
              ),
            )
          else
            Container(
              height: Responsive.height(10, context),
              width: double.infinity,
              decoration: BoxDecoration(
                color: themeChange.getThem()
                    ? AppThemeData.neutralDark200
                    : AppThemeData.neutral200,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Center(
                child: Icon(Icons.insert_drive_file,
                    size: 48,
                    color: themeChange.getThem()
                        ? AppThemeData.neutralDark500
                        : AppThemeData.neutral500),
              ),
            ),

          // Footer row: file name + status badge
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    upload.fileName?.isNotEmpty == true
                        ? upload.fileName!
                        : 'Document'.tr,
                    overflow: TextOverflow.ellipsis,
                    style: AppThemeData.mediumTextStyle(
                      fontSize: 13,
                      color: themeChange.getThem()
                          ? AppThemeData.neutralDark700
                          : AppThemeData.neutral700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Only show Approved or Disapprove badge; hide Pending
                if (upload.documentStatus == 'Approved')
                  _statusBadge(
                      'Approved'.tr,
                      AppThemeData.successLight,
                      AppThemeData.successDefault),
                if (upload.documentStatus == 'Disapprove') ...[
                  _statusBadge(
                      'Disapprove'.tr,
                      AppThemeData.errorLight,
                      AppThemeData.errorDefault),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        barrierColor: Colors.black26,
                        context: context,
                        builder: (_) => CustomAlertDialog(
                          title:
                              "${'reason'.tr} ${upload.comment == null || upload.comment!.isEmpty ? 'underVerification'.tr : upload.comment!}",
                          negativeButtonEnable: false,
                          onPressPositive: () => Get.back(),
                          onPressNegative: () {},
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppThemeData.errorLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(Icons.info,
                          color: AppThemeData.errorDefault, size: 16),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: AppThemeData.semiBoldTextStyle(fontSize: 12, color: textColor),
      ),
    );
  }

  bool _isImageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');
  }

  Future<void> _showPickerSheet(BuildContext context, themeChange,
      DocumentStatusController controller) async {
    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: Responsive.height(22, context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 15, bottom: 10),
                child: Text(
                  'Please Select'.tr,
                  textAlign: TextAlign.center,
                  style: AppThemeData.boldTextStyle(
                    fontSize: 18,
                    color: themeChange.getThem()
                        ? AppThemeData.neutralDark500
                        : AppThemeData.neutral500,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _pickerOption(
                    themeChange: themeChange,
                    icon: Icons.camera_alt,
                    label: 'Camera'.tr,
                    onTap: () => _pickCamera(controller),
                  ),
                  const SizedBox(width: 10),
                  _pickerOption(
                    themeChange: themeChange,
                    icon: Icons.photo_library_sharp,
                    label: 'Gallery'.tr,
                    onTap: () => _pickGallery(controller),
                  ),
                  const SizedBox(width: 10),
                  _pickerOption(
                    themeChange: themeChange,
                    icon: Icons.insert_drive_file,
                    label: 'Document',
                    onTap: () => _pickDocument(controller),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _pickerOption({
    required DarkThemeProvider themeChange,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        children: [
          IconButton(
            onPressed: () {
              Get.back();
              onTap();
            },
            icon: Icon(icon, size: 32),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              label,
              style: AppThemeData.mediumTextStyle(
                fontSize: 16,
                color: themeChange.getThem()
                    ? AppThemeData.neutralDark500
                    : AppThemeData.neutral500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCamera(DocumentStatusController controller) async {
    try {
      final XFile? image =
          await _imagePicker.pickImage(source: ImageSource.camera);
      if (image == null) return;
      controller.uploadFiles([image.path]);
    } on PlatformException catch (e) {
      ShowToastDialog.showToast("${"Failed to Pick".tr}: $e");
    }
  }

  Future<void> _pickGallery(DocumentStatusController controller) async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isEmpty) return;
      controller.uploadFiles(images.map((x) => x.path).toList());
    } on PlatformException catch (e) {
      ShowToastDialog.showToast("${"Failed to Pick".tr}: $e");
    }
  }

  Future<void> _pickDocument(DocumentStatusController controller) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );
    if (result != null && result.files.isNotEmpty) {
      final paths = result.files
          .where((f) => f.path != null)
          .map((f) => f.path!)
          .toList();
      if (paths.isNotEmpty) controller.uploadFiles(paths);
    } else {
      ShowToastDialog.showToast('No file selected');
    }
  }
}
