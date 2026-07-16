class EmployeeCertificate {
  final int? documentId; // Nullable
  final int? employeeId; // Nullable
  final String fileName;
  final String fileType;
  final String documentUrl;
  final String documentType;
  final String status;
  final String? remarks; // Nullable
  final String uploadedAt;
  final String? updatedAt; // Nullable

  EmployeeCertificate({
    this.documentId, // Nullable
    this.employeeId, // Nullable
    required this.fileName,
    required this.fileType,
    required this.documentUrl,
    required this.documentType,
    required this.status,
    this.remarks,
    required this.uploadedAt,
    this.updatedAt,
  });

  factory EmployeeCertificate.fromJson(Map<String, dynamic> json) {
    return EmployeeCertificate(
      documentId: json["DocumentId"] != null ? json["DocumentId"] as int : null,
      employeeId: json["EmployeeId"] != null ? json["EmployeeId"] as int : null,
      fileName: json["FileName"] ?? '',
      fileType: json["FileType"] ?? '',
      documentUrl: json["DocumentUrl"] ?? '',
      documentType: json["DocumentType"] ?? '',
      status: json["Status"] ?? '',
      remarks: json["Remarks"],
      uploadedAt: json["UploadedAt"] ?? '',
      updatedAt: json["UpdatedAt"],
    );
  }
}
