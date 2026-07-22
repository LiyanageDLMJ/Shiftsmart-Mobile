import 'package:shiftsmart/models/job_role.dart';

class Job {
  final int jobId;
  final int tenantId;
  final String title;
  final String description;
  final String startDate;
  final String jobDueDate;
  final String status;
  final int projectId;
  final int siteId;
  final int? shiftId;
  final int? employeeId;
  final String? startTime;
  final String? endTime;
  final int totalEstimatedTime;
  final String jobImageUrl;
  final String createdAt;
  final String? updatedAt;
  final String? completedAt;
  final String? companyName;
  final String? siteName;
  final List<JobRole> jobRoles;

  Job({
    required this.jobId,
    this.tenantId = 0,
    required this.title,
    required this.description,
    required this.startDate,
    required this.jobDueDate,
    required this.status,
    required this.projectId,
    required this.siteId,
    this.shiftId,
    this.employeeId,
    this.startTime,
    this.endTime,
    required this.totalEstimatedTime,
    required this.jobImageUrl,
    this.createdAt = '',
    this.updatedAt,
    this.completedAt,
    this.companyName,
    this.siteName,
    required this.jobRoles,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    try {
      return Job(
        jobId: _readInt(json['JobId']),
        tenantId: _readInt(json['TenantId']),
        title: _readString(json['Title'] ?? json['name'],
            fallback: 'Unknown Title'),
        description: _readString(json['Description']),
        status: _readString(json['Status'], fallback: 'Unknown'),
        projectId: _readInt(json['ProjectId']),
        siteId: _readInt(json['SiteId']),
        startDate: _readString(json['StartDate']),
        jobDueDate: _readString(json['JobDueDate'] ?? json['projectDue']),
        totalEstimatedTime: _readInt(json['TotalEstimatedTime']),
        jobImageUrl: _readString(json['JobImageUrl']),
        createdAt: _readString(json['CreatedAt']),
        updatedAt: _readNullableString(json['UpdatedAt']),
        completedAt: _readNullableString(json['CompletedAt']),
        companyName: _readNullableString(json['companyName']),
        siteName: _readNullableString(json['siteName']),
        shiftId: _readNullableInt(json['ShiftId'] ?? json['shiftId']),
        employeeId: _readNullableInt(json['EmployeeId'] ?? json['employeeId']),
        startTime: json['StartTime'] ?? json['startTime'] as String?,
        endTime: json['EndTime'] ?? json['endTime'] as String?,
        jobRoles: ((json['JobRoles'] ?? json['jobRoles']) as List<dynamic>?)
                ?.map((role) => JobRole.fromJson(role))
                .toList() ??
            [],
      );
    } catch (e) {
      print('Error parsing Job from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  static String _readString(dynamic value, {String fallback = ''}) {
    if (value == null || value.toString().trim().isEmpty) return fallback;
    return value.toString().trim();
  }

  static String? _readNullableString(dynamic value) {
    final parsed = _readString(value);
    return parsed.isEmpty ? null : parsed;
  }

  static int? _readNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'JobId': jobId,
      'TenantId': tenantId,
      'Title': title,
      'Description': description,
      'Status': status,
      'ProjectId': projectId,
      'SiteId': siteId,
      'StartDate': startDate,
      'JobDueDate': jobDueDate,
      'TotalEstimatedTime': totalEstimatedTime,
      'JobImageUrl': jobImageUrl,
      'CreatedAt': createdAt,
      'UpdatedAt': updatedAt,
      'CompletedAt': completedAt,
      'companyName': companyName,
      'siteName': siteName,
      'shiftId': shiftId,
      'employeeId': employeeId,
      'startTime': startTime,
      'endTime': endTime,
      'JobRoles': jobRoles.map((role) => role.toJson()).toList(),
    };
  }
}
