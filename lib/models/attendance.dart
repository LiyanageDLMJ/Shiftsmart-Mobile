class Attendance {
  final int attendanceId;
  final int employeeId;
  final int shiftId;
  final String employeeName;
  final String shiftName;
  final String scheduledStartTime;
  final String clockInTime;
  final String clockOutTime;
  final String clockInPhotoUrl;
  final String clockOutPhotoUrl;
  final List<String> clockInPhotoUrls;
  final List<String> clockOutPhotoUrls;
  final String breakStart;
  final String breakEnd;
  final bool isEmergency;
  final String emergencyReason;
  final String? approvalStatus;

  Attendance({
    required this.attendanceId,
    required this.employeeId,
    required this.shiftId,
    required this.employeeName,
    required this.shiftName,
    required this.scheduledStartTime,
    required this.clockInTime,
    required this.clockOutTime,
    required this.clockInPhotoUrl,
    required this.clockOutPhotoUrl,
    List<String>? clockInPhotoUrls,
    List<String>? clockOutPhotoUrls,
    required this.breakStart,
    required this.breakEnd,
    this.isEmergency = false,
    this.emergencyReason = '',
    this.approvalStatus,
  })  : clockInPhotoUrls = clockInPhotoUrls ??
            (clockInPhotoUrl.isNotEmpty ? [clockInPhotoUrl] : const []),
        clockOutPhotoUrls = clockOutPhotoUrls ??
            (clockOutPhotoUrl.isNotEmpty ? [clockOutPhotoUrl] : const []);

  factory Attendance.fromJson(Map<String, dynamic> json) {
    final clockInPhotos = _readPhotoUrls(json, const [
      'ClockInPhotoUrls',
      'clockInPhotoUrls',
      'ClockInPhotos',
      'clockInPhotos',
      'ClockInImages',
      'clockInImages',
      'ClockInPhotoUrl',
      'clockInPhotoUrl',
      'ClockInPhotoURL',
      'clockInPhotoURL',
      'ClockInPhoto',
      'clockInPhoto',
      'ClockInImage',
      'clockInImage',
      'ClockInImageUrl',
      'clockInImageUrl',
    ]);
    final clockOutPhotos = _readPhotoUrls(json, const [
      'ClockOutPhotoUrls',
      'clockOutPhotoUrls',
      'ClockOutPhotos',
      'clockOutPhotos',
      'ClockOutImages',
      'clockOutImages',
      'ClockOutPhotoUrl',
      'clockOutPhotoUrl',
      'ClockOutPhotoURL',
      'clockOutPhotoURL',
      'ClockOutPhoto',
      'clockOutPhoto',
      'ClockOutImage',
      'clockOutImage',
      'ClockOutImageUrl',
      'clockOutImageUrl',
    ]);

    return Attendance(
      attendanceId: json['AttendanceId'] ?? 0,
      employeeId: json['EmployeeId'] ?? 0,
      shiftId: json['ShiftId'] ?? 0,
      employeeName: json['EmployeeName'] ?? 'Unknown',
      shiftName: json['ShiftName'] ?? 'Unknown',
      scheduledStartTime: json['ScheduledStartTime'] ?? '',
      clockInTime: json['ClockInTime'] ?? '',
      clockOutTime: json['ClockOutTime'] ?? '',
      clockInPhotoUrl: clockInPhotos.isNotEmpty ? clockInPhotos.first : '',
      clockOutPhotoUrl: clockOutPhotos.isNotEmpty ? clockOutPhotos.first : '',
      clockInPhotoUrls: clockInPhotos,
      clockOutPhotoUrls: clockOutPhotos,
      breakStart: json['BreakStart'] ?? '',
      breakEnd: json['BreakEnd'] ?? '',
      isEmergency: json['IsEmergency'] ?? false,
      emergencyReason: json['EmergencyReason'] ?? '',
      approvalStatus: json['ApprovalStatus'],
    );
  }

  static List<String> _readPhotoUrls(
    Map<String, dynamic> json,
    List<String> keys,
  ) {
    final urls = <String>[];
    for (final key in keys) {
      _appendPhotoUrls(urls, json[key]);
    }

    final photos =
        json['Photos'] ?? json['photos'] ?? json['Images'] ?? json['images'];
    if (photos is List) {
      for (final photo in photos) {
        if (photo is Map<String, dynamic>) {
          final type = (photo['Type'] ??
                  photo['type'] ??
                  photo['PhotoType'] ??
                  photo['photoType'])
              ?.toString()
              .toLowerCase();
          final isClockIn =
              keys.any((key) => key.toLowerCase().contains('clockin'));
          if (type == null ||
              (isClockIn && type.contains('in')) ||
              (!isClockIn && type.contains('out'))) {
            _appendPhotoUrls(
                urls,
                photo['Url'] ??
                    photo['url'] ??
                    photo['PhotoUrl'] ??
                    photo['photoUrl'] ??
                    photo['ImageUrl'] ??
                    photo['imageUrl'] ??
                    photo['Data'] ??
                    photo['data'] ??
                    photo['Base64'] ??
                    photo['base64']);
          }
        }
      }
    }

    return urls.toSet().toList(growable: false);
  }

  static void _appendPhotoUrls(List<String> urls, dynamic value) {
    if (value == null) return;

    if (value is List) {
      for (final item in value) {
        _appendPhotoUrls(urls, item);
      }
      return;
    }

    if (value is Map<String, dynamic>) {
      _appendPhotoUrls(
          urls,
          value['Url'] ??
              value['url'] ??
              value['PhotoUrl'] ??
              value['photoUrl'] ??
              value['ImageUrl'] ??
              value['imageUrl'] ??
              value['Data'] ??
              value['data'] ??
              value['Base64'] ??
              value['base64']);
      return;
    }

    final url = value.toString().trim();
    if (url.isEmpty || url.toLowerCase() == 'null') return;
    urls.add(url);
  }
}
