import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shiftsmart/models/attendance.dart';
import 'package:shiftsmart/utils/date_time_parser.dart';
import 'api_client.dart';

class AttendanceService {
  final ApiClient _apiClient = ApiClient();

  //  PROD ENDPOINT CONFIGURATION (from func-attendance)
  final String baseUrl =
      dotenv.env['ATTENDANCE_BASE_URL'] ?? dotenv.env['BASE_URL'] ?? "";
  final String shiftBaseUrl =
      dotenv.env['SHIFT_BASE_URL'] ?? dotenv.env['BASE_URL'] ?? "";

  //  SHIFT ENDPOINT KEYS (for Cross-Service Updates)
  final String shiftAttendanceKey = dotenv.env['SHIFT_ATTENDANCE_KEY'] ?? "";
  final String shiftSyncKey = dotenv.env['SHIFT_SYNC_ATTENDANCE_KEY'] ?? "";
  final String shiftReportKey = dotenv.env['SHIFT_GET_REPORT_KEY'] ?? "";

  //  PROD ENDPOINT KEYS (from func-attendance)
  final String attendanceAddKey = dotenv.env['ATTENDANCE_ADD_KEY'] ?? "";
  final String attendanceGetAllKey = dotenv.env['ATTENDANCE_GET_ALL_KEY'] ?? "";
  final String attendanceGetActiveKey =
      dotenv.env['ATTENDANCE_GET_ACTIVE_KEY'] ?? "";
  final String attendanceGetByEmployeeKey =
      dotenv.env['ATTENDANCE_GET_BY_EMPLOYEE_KEY'] ?? "";
  final String attendanceGetMyRecordsKey =
      dotenv.env['ATTENDANCE_GET_MY_RECORDS_KEY'] ?? "";
  final String attendanceClockInKey =
      dotenv.env['ATTENDANCE_CLOCKIN_KEY'] ?? "";
  final String attendanceClockOutKey =
      dotenv.env['ATTENDANCE_CLOCKOUT_KEY'] ?? "";
  final String attendanceBreakStartKey =
      dotenv.env['ATTENDANCE_BREAK_START_KEY'] ?? "";
  final String attendanceBreakEndKey =
      dotenv.env['ATTENDANCE_BREAK_END_KEY'] ?? "";
  final String attendanceBreakSummaryKey =
      dotenv.env['ATTENDANCE_BREAK_SUMMARY_KEY'] ?? "";
  final String attendanceViewClockInPhotoKey =
      dotenv.env['ATTENDANCE_VIEW_CLOCKIN_PHOTO_KEY'] ?? "";
  final String attendanceViewClockOutPhotoKey =
      dotenv.env['ATTENDANCE_VIEW_CLOCKOUT_PHOTO_KEY'] ?? "";
  final String activeLocationsBySiteKey =
      dotenv.env['ACTIVE_LOCATIONS_BY_SITE_KEY'] ?? "";
  final String locationUpdateKey = dotenv.env['LOCATION_UPDATE_KEY'] ?? "";

  AttendanceService() {
    if (baseUrl.isEmpty) {
      debugPrint(" AttendanceService: ATTENDANCE_BASE_URL is missing");
    }
  }

  Map<String, dynamic> _failedResult(
    int statusCode,
    String responseBody,
    String fallbackMessage,
  ) {
    String message = responseBody.trim();
    if (message.isNotEmpty) {
      try {
        final decoded = jsonDecode(message);
        if (decoded is Map<String, dynamic>) {
          message = (decoded['message'] ??
                  decoded['Message'] ??
                  decoded['error'] ??
                  decoded['Error'] ??
                  message)
              .toString();
        }
      } catch (_) {}
    }

    return {
      'success': false,
      'statusCode': statusCode,
      'error': message.isNotEmpty ? message : fallbackMessage,
    };
  }

  dynamic _readField(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      if (data.containsKey(key)) return data[key];
    }
    return null;
  }

  int? _readIntField(Map<String, dynamic> data, List<String> keys) {
    final value = _readField(data, keys);
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  List<dynamic> _decodeAttendanceList(String body) {
    final decoded = jsonDecode(body);
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic>) {
      final data = decoded['data'] ?? decoded['Data'] ?? decoded['records'];
      if (data is List) return data;
    }
    return const [];
  }

  Map<String, dynamic>? _findShiftRecord(List<dynamic> records, int shiftId) {
    for (final record in records) {
      if (record is Map<String, dynamic> &&
          _readIntField(record, const ['ShiftId', 'shiftId']) == shiftId) {
        return record;
      }
    }
    return null;
  }

  String? _validPhotoUrl(dynamic value) {
    final url = value?.toString().trim();
    if (url == null || url.isEmpty) return null;

    final lower = url.toLowerCase();
    if (lower == 'null' || lower == 'undefined' || lower == 'none') {
      return null;
    }

    if (lower.startsWith('data:image')) return url;

    final uri = Uri.tryParse(url);
    if (uri != null && uri.hasScheme) return url;

    // Some attendance endpoints return raw base64 image data instead of a URL.
    if (RegExp(r'^[A-Za-z0-9+/=\r\n]+$').hasMatch(url) && url.length > 100) {
      return url;
    }

    return null;
  }

  DateTime _defaultPhotoExpiry() =>
      DateTime.now().toUtc().add(const Duration(minutes: 10));

  List<AttendancePhoto> _photoFromValue(
    dynamic value, {
    DateTime? expiresAt,
  }) {
    if (value == null) return const [];

    if (value is List) {
      return value
          .expand((item) => _photoFromValue(item, expiresAt: expiresAt))
          .toList(growable: false);
    }

    if (value is Map<String, dynamic>) {
      final photo = AttendancePhoto.fromJson(value);
      return _validPhotoUrl(photo.url) == null ? const [] : [photo];
    }

    final text = value.toString().trim();
    if (text.isEmpty) return const [];

    final values = text.toLowerCase().startsWith('data:image')
        ? [text]
        : text.split(',').map((url) => url.trim()).toList();

    return values
        .map(_validPhotoUrl)
        .whereType<String>()
        .map((url) => AttendancePhoto(
              url: url,
              expiresAt: expiresAt ?? _defaultPhotoExpiry(),
            ))
        .toList(growable: false);
  }

  List<AttendancePhoto> _parsePhotoPayload(dynamic payload) {
    if (payload == null) return const [];

    if (payload is List) {
      return _photoFromValue(payload);
    }

    if (payload is Map<String, dynamic>) {
      final photos = payload['photos'] ?? payload['Photos'];
      final parsedPhotos = _photoFromValue(photos);
      if (parsedPhotos.isNotEmpty) return parsedPhotos;

      final expiresAtValue = payload['expiresAt'] ?? payload['ExpiresAt'];
      final expiresAt = expiresAtValue == null
          ? null
          : DateTime.tryParse(expiresAtValue.toString());

      final photoUrls = payload['photoUrls'] ??
          payload['PhotoUrls'] ??
          payload['urls'] ??
          payload['Urls'];
      final parsedPhotoUrls = _photoFromValue(photoUrls, expiresAt: expiresAt);
      if (parsedPhotoUrls.isNotEmpty) return parsedPhotoUrls;

      return _photoFromValue(
        payload['photoUrl'] ??
            payload['PhotoUrl'] ??
            payload['url'] ??
            payload['Url'] ??
            payload['imageUrl'] ??
            payload['ImageUrl'] ??
            payload['data'] ??
            payload['Data'] ??
            payload['base64'] ??
            payload['Base64'],
        expiresAt: expiresAt,
      );
    }

    return _photoFromValue(payload);
  }

  String _imageDataUriFromResponse(http.Response response) {
    final contentType = response.headers['content-type'] ?? 'image/jpeg';
    return 'data:$contentType;base64,${base64Encode(response.bodyBytes)}';
  }

  Future<List<AttendancePhoto>> _fetchClockPhotos(
    int attendanceId, {
    required bool isClockIn,
  }) async {
    final endpoint = isClockIn ? 'view-clockin-photo' : 'view-clockout-photo';
    final photoKey = isClockIn
        ? attendanceViewClockInPhotoKey
        : attendanceViewClockOutPhotoKey;
    final label = isClockIn ? 'clock-in' : 'clock-out';

    if (photoKey.isEmpty) {
      debugPrint(
          'AttendanceService: ${isClockIn ? "ATTENDANCE_VIEW_CLOCKIN_PHOTO_KEY" : "ATTENDANCE_VIEW_CLOCKOUT_PHOTO_KEY"} is missing');
      return const [];
    }

    try {
      final uri = Uri.parse('$baseUrl/attendance/$endpoint/$attendanceId')
          .replace(queryParameters: {'code': photoKey});
      final response = await _apiClient.get(uri.toString(), useAuth: true);

      if (response.statusCode == 404) {
        debugPrint('AttendanceService: no $label photo for $attendanceId');
        return const [];
      }

      if (response.statusCode != 200) {
        debugPrint(
            'AttendanceService: failed to fetch $label photos. Status: ${response.statusCode}');
        return const [];
      }

      final contentType = response.headers['content-type'] ?? '';
      if (contentType.toLowerCase().startsWith('image/')) {
        return [
          AttendancePhoto(
            url: _imageDataUriFromResponse(response),
            expiresAt: _defaultPhotoExpiry(),
          )
        ];
      }

      final decoded = jsonDecode(response.body);
      final payload = decoded is Map<String, dynamic>
          ? decoded['data'] ?? decoded['Data'] ?? decoded
          : decoded;

      return _parsePhotoPayload(payload)
          .where((photo) => !photo.isExpired)
          .toList(growable: false);
    } catch (e) {
      debugPrint('Error fetching $label attendance photos: $e');
      return const [];
    }
  }

  Future<List<AttendancePhoto>> fetchClockInPhotos(int attendanceId) {
    return _fetchClockPhotos(attendanceId, isClockIn: true);
  }

  Future<List<AttendancePhoto>> fetchClockOutPhotos(int attendanceId) {
    return _fetchClockPhotos(attendanceId, isClockIn: false);
  }

  Future<List<dynamic>> fetchMyAttendanceRecords({
    int pageNumber = 1,
    int pageSize = 100,
  }) async {
    if (attendanceGetMyRecordsKey.isEmpty) {
      debugPrint("AttendanceService: ATTENDANCE_GET_MY_RECORDS_KEY is missing");
      return const [];
    }

    final uri = Uri.parse('$baseUrl/attendance/me').replace(
      queryParameters: {
        'code': attendanceGetMyRecordsKey,
        'pageNumber': pageNumber.toString(),
        'pageSize': pageSize.toString(),
      },
    );

    final response = await _apiClient.get(uri.toString(), useAuth: true);
    if (response.statusCode == 200) {
      return _decodeAttendanceList(response.body);
    }

    debugPrint(
        "Failed to fetch my attendance records: ${response.statusCode} - ${response.body}");
    return const [];
  }

  Future<Map<String, dynamic>?> fetchMyAttendanceForShift(int shiftId) async {
    final records = await fetchMyAttendanceRecords();
    return _findShiftRecord(records, shiftId);
  }

  Future<String?> fetchClockPhotoUrl(int attendanceId,
      {required isClockIn}) async {
    final photos = await _fetchClockPhotos(attendanceId, isClockIn: isClockIn);
    return photos.isEmpty ? null : photos.first.url;
  }

  Future<Map<String, List<AttendancePhoto>>> fetchAttendancePhotoLists(
      int employeeId, int shiftId) async {
    try {
      final myRecord = await fetchMyAttendanceForShift(shiftId);
      if (myRecord != null) {
        final attendanceId = _readIntField(
            myRecord, const ['AttendanceId', 'attendanceId', 'Id', 'id']);
        if (attendanceId != null && attendanceId > 0) {
          final clockInPhotos = await fetchClockInPhotos(attendanceId);
          final clockOutPhotos = await fetchClockOutPhotos(attendanceId);
          return {
            'clockIn': clockInPhotos,
            'clockOut': clockOutPhotos,
          };
        }

        return {
          'clockIn': const [],
          'clockOut': const [],
        };
      }

      final url =
          "$baseUrl/attendance/by-employee/$employeeId?code=$attendanceGetByEmployeeKey";
      final response = await _apiClient.get(url, useAuth: true);

      if (response.statusCode == 200) {
        final jsonData = _decodeAttendanceList(response.body);
        final record = _findShiftRecord(jsonData, shiftId);
        if (record == null) return {};
        final attendanceId = _readIntField(
            record, const ['AttendanceId', 'attendanceId', 'Id', 'id']);
        if (attendanceId != null && attendanceId > 0) {
          final clockInPhotos = await fetchClockInPhotos(attendanceId);
          final clockOutPhotos = await fetchClockOutPhotos(attendanceId);
          return {
            'clockIn': clockInPhotos,
            'clockOut': clockOutPhotos,
          };
        }

        return {
          'clockIn': const [],
          'clockOut': const [],
        };
      }
    } catch (e) {
      debugPrint("Error fetching attendance photos: $e");
    }
    return {};
  }

  Future<Map<String, String?>> fetchAttendancePhotos(
      int employeeId, int shiftId) async {
    final photos = await fetchAttendancePhotoLists(employeeId, shiftId);
    final clockInPhotos = photos['clockIn'] ?? const <AttendancePhoto>[];
    final clockOutPhotos = photos['clockOut'] ?? const <AttendancePhoto>[];

    return {
      'clockIn': clockInPhotos.isEmpty ? null : clockInPhotos.first.url,
      'clockOut': clockOutPhotos.isEmpty ? null : clockOutPhotos.first.url,
    };
  }

  Future<dynamic> getShiftsByShiftId(int employeeId, {int? shiftId}) async {
    try {
      if (shiftId != null) {
        final myRecord = await fetchMyAttendanceForShift(shiftId);
        if (myRecord != null) return myRecord;
      } else {
        final myRecords = await fetchMyAttendanceRecords();
        if (myRecords.isNotEmpty) return myRecords;
      }

      final url =
          '$baseUrl/attendance/by-employee/$employeeId?code=$attendanceGetByEmployeeKey';
      final response = await _apiClient.get(url, useAuth: true);

      if (response.statusCode == 200) {
        final shifts = _decodeAttendanceList(response.body);
        if (shiftId != null) {
          return _findShiftRecord(shifts, shiftId);
        }
        return shifts;
      } else {
        throw Exception("Failed to fetch shifts: HTTP ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Error fetching shifts for employee $employeeId: $e");
    }
  }

  Future<Map<String, dynamic>> clockIn({
    required int employeeId,
    required int shiftId,
    required int siteId,
    required String scheduledStartTime,
    required List<File> photos,
    required DateTime clockInTime,
    required double latitude,
    required double longitude,
  }) async {
    final url =
        Uri.parse('$baseUrl/attendance/clockin?code=$attendanceClockInKey');
    try {
      final validationError = ApiClient.validateUploadFiles(
        files: photos,
        maxFiles: 5,
        maxFileBytes: 5 * ApiClient.mb,
        maxRequestBytes: 30 * ApiClient.mb,
        allowPdf: false,
        fileLabel: 'Attendance photo',
      );
      if (validationError != null) {
        return {'success': false, 'error': validationError};
      }

      final request = http.MultipartRequest("POST", url);

      final token = await _apiClient.getAppToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      for (var file in photos) {
        final mimeType = ApiClient.uploadMimeType(file, allowPdf: false)!;
        request.files.add(await http.MultipartFile.fromPath(
          'photo',
          file.path,
          contentType: MediaType.parse(mimeType),
        ));
      }

      request.fields['employeeId'] = employeeId.toString();
      request.fields['shiftId'] = shiftId.toString();
      request.fields['siteId'] = siteId.toString();
      request.fields['scheduledStartTime'] = scheduledStartTime.toString();
      request.fields['clockInTime'] = formatDateTimeForServer(clockInTime);
      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      debugPrint('Clock-in HTTP status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        dynamic decoded;
        try {
          decoded = jsonDecode(responseBody);
        } catch (e) {
          decoded = {'message': responseBody};
        }

        final resultData = (decoded is Map<String, dynamic> &&
                (decoded.containsKey('data') || decoded.containsKey('Data')))
            ? decoded['data'] ?? decoded['Data']
            : decoded;

        final attendanceIdValue = resultData is Map<String, dynamic>
            ? resultData['AttendanceId'] ?? resultData['attendanceId']
            : null;

        await _triggerShiftAttendanceUpdate(shiftId, "clockin");

        return {
          'success': true,
          'data': resultData,
          'attendanceId': attendanceIdValue ??
              decoded['AttendanceId'] ??
              decoded['attendanceId'],
        };
      } else {
        return _failedResult(
          response.statusCode,
          responseBody,
          'Unable to clock in.',
        );
      }
    } catch (e) {
      debugPrint("Clock in service error: $e");
      return {
        'success': false,
        'error': 'Unable to clock in. Please try again.'
      };
    }
  }

  Future<Map<String, dynamic>> clockOut({
    required int attendanceId,
    required int shiftId,
    required DateTime clockOutTime,
    required List<File> photos,
    required double latitude,
    required double longitude,
    DateTime? clockInTime,
    int? totalBreakMinutes,
    String? earlyExitReason,
    Duration? timeout,
  }) async {
    final url = Uri.parse(
        '$baseUrl/attendance/clockout/$attendanceId?code=$attendanceClockOutKey');
    try {
      final validationError = ApiClient.validateUploadFiles(
        files: photos,
        maxFiles: 5,
        maxFileBytes: 5 * ApiClient.mb,
        maxRequestBytes: 30 * ApiClient.mb,
        allowPdf: false,
        fileLabel: 'Attendance photo',
      );
      if (validationError != null) {
        return {'success': false, 'error': validationError};
      }

      final request = http.MultipartRequest('PUT', url);

      final token = await _apiClient.getAppToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      for (var file in photos) {
        final mimeType = ApiClient.uploadMimeType(file, allowPdf: false)!;
        request.files.add(await http.MultipartFile.fromPath(
          'photo',
          file.path,
          contentType: MediaType.parse(mimeType),
        ));
      }

      request.fields['attendanceId'] = attendanceId.toString();
      request.fields['clockOutTime'] = formatDateTimeForServer(clockOutTime);
      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();

      // Add reason if provided (backend expects 'reason' for early exits)
      if (earlyExitReason != null && earlyExitReason.isNotEmpty) {
        request.fields['reason'] = earlyExitReason;
      }

      final response = timeout != null
          ? await request.send().timeout(timeout)
          : await request.send();

      final responseBody = await response.stream.bytesToString();
      debugPrint('Clock-out HTTP status: ${response.statusCode}');

      if (response.statusCode == 200) {
        dynamic result;
        if (responseBody.isNotEmpty) {
          try {
            result = jsonDecode(responseBody);
          } catch (e) {
            result = {'message': responseBody};
          }
        } else {
          result = {};
        }

        // Trigger shift attendance update
        await _triggerShiftAttendanceUpdate(
          shiftId,
          "clockout",
          reason: earlyExitReason,
          clockInTime: clockInTime,
          clockOutTime: clockOutTime,
          totalBreakMinutes: totalBreakMinutes,
        );

        // Sync attendance data to Shift Service
        await _syncAttendanceToShiftService(
          shiftId,
          attendanceId,
          clockInTime: clockInTime,
          clockOutTime: clockOutTime,
          totalBreakMinutes: totalBreakMinutes,
        );

        return {'success': true, 'data': result};
      } else {
        return _failedResult(
          response.statusCode,
          responseBody,
          'Unable to clock out.',
        );
      }
    } catch (e) {
      debugPrint("Clock out service error: $e");
      return {
        'success': false,
        'error': 'Unable to clock out. Please try again.'
      };
    }
  }

  Future<Map<String, dynamic>> emergencyClockOut({
    required int attendanceId,
    required int shiftId,
    required String emergencyReason,
    double? latitude,
    double? longitude,
    Duration? timeout,
  }) async {
    debugPrint('==========================================');
    debugPrint('EMERGENCY CLOCK-OUT INITIATED');
    debugPrint('Shift ID: $shiftId');
    debugPrint('Reason: $emergencyReason');
    debugPrint('==========================================');

    try {
      final url =
          '$shiftBaseUrl/shift/$shiftId/clockout?code=$shiftAttendanceKey';

      final body = {
        "Reason": emergencyReason,
        "IsEmergency": true,
      };

      final response = await _apiClient.post(
        url,
        body: body,
        useAuth: true,
      );

      if (response.statusCode == 200) {
        debugPrint('Emergency clock-out successful via Shift Handler');

        dynamic responseData;
        try {
          responseData = jsonDecode(response.body);
        } catch (e) {
          responseData = {'message': response.body};
        }

        return {
          'success': true,
          'data': responseData,
          'message': 'Emergency clock-out recorded successfully.'
        };
      } else {
        debugPrint(
            'Emergency clock-out failed: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'error': 'Failed to record emergency clock-out: ${response.body}'
        };
      }
    } catch (e) {
      debugPrint("Emergency clock-out error: $e");
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<bool?> breakStart(int attendanceId,
      {required DateTime startTime}) async {
    final url =
        '$baseUrl/attendance/break/start/$attendanceId?code=$attendanceBreakStartKey';

    try {
      final response = await _apiClient.put(
        url,
        body: {
          'breakStartTime': formatDateTimeForServer(startTime),
        },
        useAuth: true,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint(
            "Break start failed: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      throw Exception("Error :$e");
    }
  }

  Future<bool?> endBreak(int attendanceId, {required DateTime endTime}) async {
    final url =
        '$baseUrl/attendance/break/end/$attendanceId?code=$attendanceBreakEndKey';

    try {
      final response = await _apiClient.put(
        url,
        body: {
          'breakEndTime': formatDateTimeForServer(endTime),
        },
        useAuth: true,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint(
            "Break end failed: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  Future<bool> approveAttendance(int attendanceId, String status,
      {File? proofPhoto}) async {
    final url = Uri.parse('$baseUrl/attendance/approve/$attendanceId');
    try {
      final request = http.MultipartRequest('PUT', url);

      final token = await _apiClient.getAppToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['approvalStatus'] = status;

      if (proofPhoto != null) {
        final validationError = ApiClient.validateUploadFiles(
          files: [proofPhoto],
          maxFiles: 1,
          maxFileBytes: 5 * ApiClient.mb,
          maxRequestBytes: 30 * ApiClient.mb,
          allowPdf: false,
          fileLabel: 'Attendance photo',
        );
        if (validationError != null) return false;

        final mimeType = ApiClient.uploadMimeType(proofPhoto, allowPdf: false)!;
        request.files.add(await http.MultipartFile.fromPath(
          'proofPhoto',
          proofPhoto.path,
          contentType: MediaType.parse(mimeType),
        ));
      }

      final response = await request.send();
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error approving attendance: $e");
      return false;
    }
  }

  Future<void> _triggerShiftAttendanceUpdate(int shiftId, String action,
      {String? reason,
      DateTime? clockInTime,
      DateTime? clockOutTime,
      int? totalBreakMinutes}) async {
    final url = '$shiftBaseUrl/shift/$shiftId/$action?code=$shiftAttendanceKey';
    try {
      final Map<String, dynamic> body = {};
      if (action == "clockout") {
        if (reason != null) body["Reason"] = reason;
        if (clockInTime != null) {
          body["ClockInTime"] = formatDateTimeForServer(clockInTime);
        }
        if (clockOutTime != null) {
          body["ClockOutTime"] = formatDateTimeForServer(clockOutTime);
        }
        if (totalBreakMinutes != null) {
          body["BreakDuration"] = totalBreakMinutes;
        }
      }

      final response = await _apiClient.post(
        url,
        body: body.isNotEmpty ? body : null,
        useAuth: true,
      );
      if (response.statusCode == 200) {
        debugPrint("Shift status updated successfully for $action");
        if (action == "clockout") {
          await _generateAndSendReport(shiftId);
        }
      } else {
        debugPrint(
            "Failed to update shift status: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      debugPrint("Error updating shift status: $e");
    }
  }

  /// Syncs attendance data to the Shift Service after successful clock-out
  /// This ensures the Shift Service has the latest attendance information
  Future<void> _syncAttendanceToShiftService(int shiftId, int attendanceId,
      {DateTime? clockInTime,
      DateTime? clockOutTime,
      int? totalBreakMinutes}) async {
    debugPrint(" Syncing attendance data to Shift Service...");
    try {
      final syncUrl = '$shiftBaseUrl/shift/sync/attendance?code=$shiftSyncKey';

      final response = await _apiClient.post(
        syncUrl,
        body: {
          'ShiftId': shiftId,
          'AttendanceId': attendanceId,
          'ClockInTime': formatDateTimeForServer(clockInTime),
          'ClockOutTime': formatDateTimeForServer(clockOutTime),
          'BreakDuration': totalBreakMinutes,
        },
        useAuth: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint(" Attendance data synced successfully to Shift Service");
      } else {
        debugPrint(
            " Failed to sync attendance data: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      debugPrint(" Error syncing attendance data: $e");
    }
  }

  Future<void> _generateAndSendReport(int shiftId) async {
    debugPrint("Generating post-shift report for Shift ID: $shiftId...");
    try {
      // 1. Fetch Shift Details (Assuming we can get by shiftId, might need employeeId context or a different call if strict)
      // For now, we might not have employeeId readily available without passing it down.
      // Ideally, the backend triggers this, but per request, we do it here.
      // We will skip the fetch if we don't have employeeId, or rely on what we have.
      // Better approach: User passes necessary data or we just send a 'trigger report' signal.

      // Let's constructing a specific report payload if possible.
      // Since 'getShiftsByShiftId' requires employeeId, and we don't have it here easily (only shiftId),
      // we will make a direct call to a report generation endpoint on the backend.

      final reportUrl =
          '$shiftBaseUrl/shift/$shiftId/report?code=$shiftReportKey';
      // Using shiftAttendanceKey as generic key for now

      final response = await _apiClient.post(
        reportUrl,
        body: {}, // Backend should pull data from DB based on ShiftId
        useAuth: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("Report generated and sent successfully!");
      } else {
        debugPrint("Failed to generate report: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error generating report: $e");
    }
  }
}
