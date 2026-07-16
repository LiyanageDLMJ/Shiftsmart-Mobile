import 'package:shiftsmart/utils/date_time_parser.dart';

class ReportEmployee {
  // NEW: Added ReportId and EmployeeId fields
  final int ReportId;
  final int EmployeeId;
  final String EmployeeName;
  final int NumberOfShifts;
  final int Leaves;
  final double TotalBreakHours;
  final int LateArrivals;
  final int TasksCompleted;
  final double PerformanceScore;
  final String GeneratedBy;
  final DateTime GeneratedAt;

  ReportEmployee({
    // UPDATED: Added new fields to constructor
    required this.ReportId,
    required this.EmployeeId,
    required this.EmployeeName,
    required this.NumberOfShifts,
    required this.Leaves,
    required this.TotalBreakHours,
    required this.LateArrivals,
    required this.TasksCompleted,
    required this.PerformanceScore,
    required this.GeneratedBy,
    required this.GeneratedAt,
  });

  factory ReportEmployee.fromJson(Map<String, dynamic> json) {
    return ReportEmployee(
      // UPDATED: Mapping all fields from the new JSON response
      ReportId: json['ReportId'] ?? 0,
      EmployeeId: json['EmployeeId'] ?? 0,
      EmployeeName: json['EmployeeName'] ?? '',
      NumberOfShifts: json['NumberOfShifts'] ?? 0,
      Leaves: json['Leaves'] ?? 0,
      TotalBreakHours: (json['TotalBreakHours'] ?? 0.0).toDouble(),
      LateArrivals: json['LateArrivals'] ?? 0,
      TasksCompleted: json['TasksCompleted'] ?? 0,
      PerformanceScore: (json['PerformanceScore'] ?? 0.0).toDouble(),
      GeneratedBy: json['GeneratedBy'] ?? 'System',
      GeneratedAt: json['GeneratedAt'] != null
          ? parseServerDateTime(json['GeneratedAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // UPDATED: Added new fields to toJson method
      'ReportId': ReportId,
      'EmployeeId': EmployeeId,
      'EmployeeName': EmployeeName,
      'NumberOfShifts': NumberOfShifts,
      'Leaves': Leaves,
      'TotalBreakHours': TotalBreakHours,
      'LateArrivals': LateArrivals,
      'TasksCompleted': TasksCompleted,
      'PerformanceScore': PerformanceScore,
      'GeneratedBy': GeneratedBy,
      'GeneratedAt': formatDateTimeForServer(GeneratedAt),
    };
  }
}
