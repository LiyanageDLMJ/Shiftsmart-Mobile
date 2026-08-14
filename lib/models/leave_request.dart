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
    dynamic read(List<String> keys) {
      for (final key in keys) {
        if (json.containsKey(key)) return json[key];
      }
      return null;
    }

    int parseId(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      if (val is String) return int.tryParse(val) ?? 0;
      if (val is num) return val.toInt();
      return 0;
    }

    String parseString(dynamic val, {String fallback = ''}) {
      if (val == null || val.toString().trim().isEmpty) return fallback;
      return val.toString().trim();
    }

    return LeaveRequest(
      leaveRequestId: parseId(read(const [
        'LeaveRequestId',
        'leaveRequestId',
        'Id',
        'id',
      ])),
      employeeId: parseId(read(const ['EmployeeId', 'employeeId'])),
      employeeName: parseString(read(const [
        'EmployeeName',
        'employeeName',
        'FullName',
        'fullName',
      ])),
      leaveType: parseString(read(const ['LeaveType', 'leaveType'])),
      startDate: parseServerDateTime(
              read(const ['StartDate', 'startDate'])?.toString() ?? '') ??
          DateTime.now(),
      endDate: parseServerDateTime(
              read(const ['EndDate', 'endDate'])?.toString() ?? '') ??
          DateTime.now(),
      reason: parseString(read(const ['Reason', 'reason'])),
      rejectionReason: parseString(read(const [
        'RejectionReason'
      ])),
      status: parseString(read(const ['Status', 'status']), fallback: 'Pending'),
      requestedAt: parseServerDateTime(
              read(const ['RequestedAt', 'requestedAt', 'CreatedAt', 'createdAt'])
                      ?.toString() ??
                  '') ??
          DateTime.now(),
      tenantId: parseId(read(const ['TenantId', 'tenantId'])),
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
