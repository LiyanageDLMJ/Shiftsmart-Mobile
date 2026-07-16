import 'package:shiftsmart/utils/date_time_parser.dart';

class LeaveRequest {
  final int leaveRequestId;
  final int employeeId;
  final String employeeName;
  final String leaveType;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  String rejectionReason;
  String status;
  final DateTime requestedAt;
  final int tenantId;

  LeaveRequest({
    required this.leaveRequestId,
    required this.employeeId,
    this.employeeName = '',
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.rejectionReason = '',
    required this.status,
    required this.requestedAt,
    this.tenantId = 0,
  });

  factory LeaveRequest.fromJson(Map<String, dynamic> json) {
    int parseId(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is String) return int.tryParse(val) ?? 0;
      if (val is num) return val.toInt();
      return 0;
    }

    return LeaveRequest(
      leaveRequestId: parseId(json['LeaveRequestId']),
      employeeId: parseId(json['EmployeeId']),
      employeeName: json['EmployeeName'] ?? '',
      leaveType: json['LeaveType'] ?? '',
      startDate: parseServerDateTime(json['StartDate']?.toString() ?? '') ??
          DateTime.now(),
      endDate: parseServerDateTime(json['EndDate']?.toString() ?? '') ??
          DateTime.now(),
      reason: json['Reason'] ?? '',
      rejectionReason: json['RejectionReason'] ?? json['rejectionReason'] ?? '',
      status: json['Status'] ?? 'Pending',
      requestedAt: parseServerDateTime(json['RequestedAt']?.toString() ?? '') ??
          DateTime.now(),
      tenantId: parseId(json['TenantId']),
    );
  }

  bool get isPending {
    return status.toLowerCase() == 'pending';
  }

  bool get isAcceptedOrRejected {
    return status.toLowerCase() == 'approved' ||
        status.toLowerCase() == 'rejected' ||
        status.toLowerCase() == 'denied';
  }
}
