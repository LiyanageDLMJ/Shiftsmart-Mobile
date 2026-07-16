import 'package:shiftsmart/utils/date_time_parser.dart';

class EmployeeResponse {
  final int employeeId;
  final String status;
  final String? reason;
  final DateTime? respondedAt;
  final DateTime? clockInTime;
  final DateTime? clockOutTime;
  final bool isEarlyExit;
  final String? earlyExitReason;
  final String? approvalStatus;
  final DateTime? completedAt;

  bool get isSwapRequested => status.toLowerCase() == 'swap requested';

  EmployeeResponse({
    required this.employeeId,
    required this.status,
    this.reason,
    this.respondedAt,
    this.clockInTime,
    this.clockOutTime,
    required this.isEarlyExit,
    this.earlyExitReason,
    this.approvalStatus,
    this.completedAt,
  });

  factory EmployeeResponse.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is String) return int.tryParse(val) ?? 0;
      return (val as num).toInt();
    }

    return EmployeeResponse(
      employeeId: parseId(json['EmployeeId'] ?? json['employeeId']),
      status: (json['Status'] ?? json['status'])?.toString() ?? 'Pending',
      reason: (json['RejectionReason'] ?? json['rejectionReason'])?.toString(),
      respondedAt:
          parseServerDateTime(json['ResponseDate'] ?? json['responseDate']),
      clockInTime:
          parseServerDateTime(json['ClockInTime'] ?? json['clockInTime']),
      clockOutTime:
          parseServerDateTime(json['ClockOutTime'] ?? json['clockOutTime']),
      isEarlyExit: json['IsEarlyExit'] == true ||
          json['IsEarlyExit']?.toString().toLowerCase() == 'true' ||
          json['isEarlyExit'] == true ||
          json['isEarlyExit']?.toString().toLowerCase() == 'true',
      earlyExitReason:
          (json['EarlyExitReason'] ?? json['earlyExitReason'])?.toString(),
      approvalStatus:
          (json['ApprovalStatus'] ?? json['approvalStatus'])?.toString(),
      completedAt: DateTime.tryParse(
          (json['CompletedAt'] ?? json['completedAt'])?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'EmployeeId': employeeId,
      'Status': status,
      'RejectionReason': reason,
      'ResponseDate': formatDateTimeForServer(respondedAt),
      'ClockInTime': formatDateTimeForServer(clockInTime),
      'ClockOutTime': formatDateTimeForServer(clockOutTime),
      'IsEarlyExit': isEarlyExit,
      'EarlyExitReason': earlyExitReason,
      'ApprovalStatus': approvalStatus,
      'CompletedAt': formatDateTimeForServer(completedAt),
    };
  }
}

class Shift {
  final int shiftId;
  final int projectId;
  final String taskName;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String location;
  final String status;
  final List<int> assignedEmployeeIds;
  final List<EmployeeResponse> employeeResponses;
  final int? jobId;
  final int? siteId;
  final String? latitude;
  final String? longitude;
  final DateTime? completedAt;

  Shift({
    required this.shiftId,
    required this.projectId,
    required this.taskName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.status,
    required this.assignedEmployeeIds,
    this.employeeResponses = const [],
    this.jobId,
    this.siteId,
    this.latitude,
    this.longitude,
    this.completedAt,
  });

  Shift copyWith({
    int? shiftId,
    int? projectId,
    String? taskName,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? location,
    String? status,
    List<int>? assignedEmployeeIds,
    List<EmployeeResponse>? employeeResponses,
    int? siteId,
    String? latitude,
    String? longitude,
    int? jobId,
    DateTime? completedAt,
  }) {
    return Shift(
      shiftId: shiftId ?? this.shiftId,
      projectId: projectId ?? this.projectId,
      taskName: taskName ?? this.taskName,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      status: status ?? this.status,
      assignedEmployeeIds: assignedEmployeeIds ?? this.assignedEmployeeIds,
      employeeResponses: employeeResponses ?? this.employeeResponses,
      siteId: siteId ?? this.siteId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      jobId: jobId ?? this.jobId,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  factory Shift.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is String) return int.tryParse(val) ?? 0;
      if (val is num) return val.toInt();
      return 0;
    }

    List<int> parseIdList(dynamic val) {
      if (val == null) return [];
      if (val is List) {
        return val.map<int>((e) => parseId(e)).toList();
      }
      if (val is String && val.isNotEmpty) {
        return val.split(',').map((e) => parseId(e.trim())).toList();
      }
      return [];
    }

    try {
      final rawStatus = (json['Status'] ?? json['status'])?.toString().trim();
      final employeeResponsesJson = json['Assignments'] ??
          json['assignments'] ??
          json['EmployeeResponses'] ??
          json['employeeResponses'];

      return Shift(
        shiftId: parseId(json['ShiftId'] ?? json['shiftId']),
        projectId: parseId(json['ProjectId'] ?? json['projectId']),
        taskName: (json['TaskName'] ?? json['taskName'])?.toString() ?? '',
        date: parseServerDateTime(json['Date'] ?? json['date']) ??
            DateTime.now(),
        startTime: (json['StartTime'] ?? json['startTime'])?.toString() ?? '',
        endTime: (json['EndTime'] ?? json['endTime'])?.toString() ?? '',
        location: (json['Location'] ?? json['location'])?.toString() ?? '',
        status:
            rawStatus == null || rawStatus.isEmpty ? 'Scheduled' : rawStatus,
        jobId: (json['JobId'] ?? json['jobId']) != null
            ? parseId(json['JobId'] ?? json['jobId'])
            : null,
        assignedEmployeeIds: parseIdList(
            json['AssignedEmployeeIds'] ?? json['assignedEmployeeIds']),
        employeeResponses: employeeResponsesJson is List
            ? employeeResponsesJson
                .map<EmployeeResponse>((e) => EmployeeResponse.fromJson(e))
                .toList()
            : [],
        siteId: (json['SiteId'] ?? json['siteId']) != null
            ? parseId(json['SiteId'] ?? json['siteId'])
            : null,
        latitude: (json['Latitude'] ?? json['latitude'])?.toString(),
        longitude: (json['Longitude'] ?? json['longitude'])?.toString(),
        completedAt:
            parseServerDateTime(json['CompletedAt'] ?? json['completedAt']),
      );
    } catch (e, stack) {
      // debugPrint is not defined in this context, assuming print is intended or debugPrint needs to be imported.
      // Keeping original print for now to avoid introducing new dependencies without explicit instruction.
      print(" ERROR in Shift.fromJson(): $e\n$stack");
      // Don't rethrow, return a fallback empty shift if possible, or let the caller handle []
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'ShiftId': shiftId,
      'ProjectId': projectId,
      'TaskName': taskName,
      'Date': formatDateTimeForServer(date),
      'StartTime': startTime,
      'EndTime': endTime,
      'Location': location,
      'Status': status,
      'AssignedEmployeeIds': assignedEmployeeIds,
      'EmployeeResponses': employeeResponses.map((e) => e.toJson()).toList(),
      'JobId': jobId,
      'SiteId': siteId,
      'Latitude': latitude,
      'Longitude': longitude,
      'CompletedAt': formatDateTimeForServer(completedAt),
    };
  }
}
