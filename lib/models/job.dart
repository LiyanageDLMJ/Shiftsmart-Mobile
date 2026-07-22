import 'package:shiftsmart/models/job_role.dart';

class Job {
  final int jobId;
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
  final List<JobRole> jobRoles;

  Job({
    required this.jobId,
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
    required this.jobRoles,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    try {
      return Job(
        jobId: json['JobId'] ?? json['jobId'] ?? 0,
        title: json['Title'] ?? json['title'] ?? 'Unknown Title',
        description: json['Description'] ?? json['description'] ?? '',
        startDate: json['StartDate'] ?? json['startDate'] ?? '',
        jobDueDate: json['JobDueDate'] ?? json['jobDueDate'] ?? '',
        status: json['Status'] ?? json['status'] ?? 'Unknown',
        projectId: json['ProjectId'] ?? json['projectId'] ?? 0,
        siteId: json['SiteId'] ?? json['siteId'] ?? 0,
        shiftId: json['ShiftId'] ?? json['shiftId'] as int?,
        employeeId: json['EmployeeId'] ?? json['employeeId'] as int?,
        startTime: json['StartTime'] ?? json['startTime'] as String?,
        endTime: json['EndTime'] ?? json['endTime'] as String?,
        totalEstimatedTime:
            json['TotalEstimatedTime'] ?? json['totalEstimatedTime'] ?? 0,
        jobImageUrl:
            (json['JobImageUrl'] ?? json['jobImageUrl'] ?? '').toString(),
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

  Map<String, dynamic> toJson() {
    return {
      'JobId': jobId,
      'Title': title,
      'Description': description,
      'StartDate': startDate,
      'JobDueDate': jobDueDate,
      'Status': status,
      'ProjectId': projectId,
      'SiteId': siteId,
      'shiftId': shiftId,
      'employeeId': employeeId,
      'startTime': startTime,
      'endTime': endTime,
      'TotalEstimatedTime': totalEstimatedTime,
      'JobImageUrl': jobImageUrl,
      'JobRoles': jobRoles.map((role) => role.toJson()).toList(),
    };
  }
}
