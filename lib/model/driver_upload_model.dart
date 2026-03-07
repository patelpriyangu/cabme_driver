class DriverUploadModel {
  String? success;
  String? error;
  String? message;
  List<DriverUploadData>? data;

  DriverUploadModel({this.success, this.error, this.message, this.data});

  DriverUploadModel.fromJson(Map<String, dynamic> json) {
    success = json['success']?.toString();
    error = json['error']?.toString();
    message = json['message']?.toString();
    if (json['data'] != null) {
      data = <DriverUploadData>[];
      for (final v in (json['data'] as List)) {
        data!.add(DriverUploadData.fromJson(v));
      }
    }
  }
}

class DriverUploadData {
  String? id;
  String? fileUrl;
  String? fileName;
  String? documentStatus;
  String? comment;
  String? createdAt;

  DriverUploadData({
    this.id,
    this.fileUrl,
    this.fileName,
    this.documentStatus,
    this.comment,
    this.createdAt,
  });

  DriverUploadData.fromJson(Map<String, dynamic> json) {
    id = json['id']?.toString();
    fileUrl = json['file_url']?.toString();
    fileName = json['file_name']?.toString();
    documentStatus = json['document_status']?.toString();
    comment = json['comment']?.toString();
    createdAt = json['created_at']?.toString();
  }
}
