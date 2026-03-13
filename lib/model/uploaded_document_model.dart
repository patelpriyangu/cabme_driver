class UploadedDocumentModel {
  String? success;
  String? error;
  String? message;
  List<UploadedDocumentData>? data;

  UploadedDocumentModel({this.success, this.error, this.message, this.data});

  UploadedDocumentModel.fromJson(Map<String, dynamic> json) {
    success = json['success'].toString();
    error = json['error'].toString();
    message = json['message'].toString();
    if (json['data'] != null) {
      data = <UploadedDocumentData>[];
      json['data'].forEach((v) {
        data!.add(UploadedDocumentData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['error'] = error;
    data['message'] = message;
    if (this.data != null) {
      data['data'] = this.data!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class UploadedDocumentData {
  String? id;
  String? title;
  String? isEnabled;
  String? createdAt;
  String? updatedAt;
  String? documentPath;
  String? documentStatus;
  String? comment;
  String? documentName;
  List<String> documentFiles;

  UploadedDocumentData({
    this.id,
    this.title,
    this.isEnabled,
    this.createdAt,
    this.updatedAt,
    this.documentPath,
    this.documentStatus,
    this.comment,
    this.documentName,
    this.documentFiles = const [],
  });

  UploadedDocumentData.fromJson(Map<String, dynamic> json)
      : documentFiles = [] {
    id = json['id'].toString();
    title = json['title'].toString();
    isEnabled = json['is_enabled'].toString();
    createdAt = json['created_at'].toString();
    updatedAt = json['updated_at'].toString();
    documentPath = json['document_path'].toString();
    documentStatus = json['document_status'].toString();
    comment = json['comment'].toString();
    documentName = json['document_name'].toString();

    if (json['document_files'] != null && json['document_files'] is List) {
      documentFiles = List<String>.from(
          (json['document_files'] as List).map((e) => e.toString()));
    } else if (documentPath != null &&
        documentPath!.isNotEmpty &&
        documentPath != 'null') {
      documentFiles = [documentPath!];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['is_enabled'] = isEnabled;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['document_path'] = documentPath;
    data['document_status'] = documentStatus;
    data['comment'] = comment;
    data['document_name'] = documentName;
    data['document_files'] = documentFiles;
    return data;
  }

  bool get hasFiles =>
      documentFiles.isNotEmpty ||
      (documentPath != null &&
          documentPath!.isNotEmpty &&
          documentPath != 'null');
}
