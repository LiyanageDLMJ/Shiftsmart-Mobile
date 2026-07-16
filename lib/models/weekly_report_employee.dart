class WeeklyReportEmployee {
  final int employeeId;
  final String employeeName;
  final String reportStart;
  final String reportEnd;
  final int numberOfShifts;
  final double totalBreakHours;
  final int lateArrivals;
  final int performanceScore;

  WeeklyReportEmployee({
    required this.employeeId,
    required this.employeeName,
    required this.reportStart,
    required this.reportEnd,
    required this.numberOfShifts,
    required this.totalBreakHours,
    required this.lateArrivals,
    required this.performanceScore,
  });

  factory WeeklyReportEmployee.fromJson(Map<String, dynamic> json) {
    return WeeklyReportEmployee(
      employeeId: json['employeeId'] ?? 0, 
      employeeName: json['employeeName'] ?? '',
      reportStart: json['reportStart'] ?? '', 
      reportEnd: json['reportEnd'] ?? '', 
      numberOfShifts: json['numberOfShifts'] ?? 0,  
      totalBreakHours: (json['totalBreakHours'] as num?)?.toDouble() ?? 0.0, 
      lateArrivals: json['lateArrivals'] ?? 0,  
      performanceScore: json['performanceScore'] ?? 0,  
    );
  }
}
