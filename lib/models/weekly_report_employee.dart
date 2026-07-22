class WeeklyReportEmployee {
  final int employeeId;
  final String employeeName;
  final String reportStart;
  final String reportEnd;
  final int numberOfShifts;
  final double totalBreakHours;
  final int lateArrivals;
  final int performanceScore;
  final String generatedAt;

  WeeklyReportEmployee({
    required this.employeeId,
    required this.employeeName,
    required this.reportStart,
    required this.reportEnd,
    required this.numberOfShifts,
    required this.totalBreakHours,
    required this.lateArrivals,
    required this.performanceScore,
    this.generatedAt = '',
  });

  factory WeeklyReportEmployee.fromJson(Map<String, dynamic> json) {
    final range = _readMap(json['range']);
    final metrics = _readMap(json['metrics']);

    return WeeklyReportEmployee(
      employeeId: _readInt(json['employeeId']),
      employeeName: _readString(json['employeeName']),
      reportStart: _readString(range['start']),
      reportEnd: _readString(range['end']),
      numberOfShifts: _readInt(metrics['numberOfShifts']),
      totalBreakHours: _readDouble(metrics['totalBreakHours']),
      lateArrivals: _readInt(metrics['lateArrivals']),
      performanceScore: _readInt(metrics['performanceScore']),
      generatedAt: _readString(json['generatedAt']),
    );
  }

  WeeklyReportEmployee copyWith({
    int? employeeId,
    String? employeeName,
    String? reportStart,
    String? reportEnd,
    int? numberOfShifts,
    double? totalBreakHours,
    int? lateArrivals,
    int? performanceScore,
    String? generatedAt,
  }) {
    return WeeklyReportEmployee(
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      reportStart: reportStart ?? this.reportStart,
      reportEnd: reportEnd ?? this.reportEnd,
      numberOfShifts: numberOfShifts ?? this.numberOfShifts,
      totalBreakHours: totalBreakHours ?? this.totalBreakHours,
      lateArrivals: lateArrivals ?? this.lateArrivals,
      performanceScore: performanceScore ?? this.performanceScore,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  static Map<String, dynamic> _readMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  static String _readString(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return '';
    return value.toString().trim();
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
    return 0;
  }

  static double _readDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
    return 0;
  }
}
