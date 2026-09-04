import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shiftsmart/models/attendance.dart';
import 'package:shiftsmart/models/job.dart';
import 'package:shiftsmart/models/site.dart';
import 'package:shiftsmart/providers/user_provider.dart';
import 'package:shiftsmart/screens/employee/employee_tracking_screen.dart';
import 'package:shiftsmart/services/attendance_service.dart';
import 'package:shiftsmart/services/image_picker_service.dart';
import 'package:shiftsmart/services/location_service.dart';
import 'package:shiftsmart/services/shift_service.dart';
import 'package:shiftsmart/services/site_service.dart';
import 'package:shiftsmart/services/notification_service.dart';
import 'package:shiftsmart/utils/date_time_parser.dart';
import 'package:shiftsmart/utils/fullscreen_helper.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/gradienthorizontal.dart';
import 'package:shiftsmart/widgets/sidenav.dart';
import 'package:shiftsmart/widgets/uppernavbar.dart';

class Employeeshiftview extends StatefulWidget {
  final Job job;
  final int shiftId;
  final int employeeId;
  final String scheduledStartTime;
  final String scheduledEndTime;
  final LocationService locationService;
  final ImagePickerService imagePickerService;

  const Employeeshiftview({
    super.key,
    required this.job,
    required this.shiftId,
    required this.employeeId,
    required this.scheduledStartTime,
    required this.scheduledEndTime,
    required this.locationService,
    required this.imagePickerService,
  });

  @override
  State<Employeeshiftview> createState() => _EmployeeshiftviewState();
}

class _EmployeeshiftviewState extends State<Employeeshiftview> {
  List<Map<String, DateTime>> breaks = [];
  Map<String, dynamic>? shiftDetails;
  Timer? _attendanceRefreshTimer;
  DateTime? currentBreakStart;
  Timer? _breakTicker;
  Duration _activeBreakElapsed = Duration.zero;
  DateTime? clockInTime;
  DateTime? clockOutTime;
  bool isClockedIn = false;
  File? clockInPhoto;
  File? clockOutPhoto;
  String? clockInPhotoUrl;
  String? clockOutPhotoUrl;
  List<AttendancePhoto> _clockInSignedPhotos = [];
  List<AttendancePhoto> _clockOutSignedPhotos = [];
  bool _isLoadingAttendancePhotos = false;
  String? earlyExitReason;
  int? attendanceId;
  Site? currentSite;
  bool isLoading = false;
  bool _isAttendanceRefreshInProgress = false;
  bool _isLocationTrackingActive = false;

  // New Variables
  String myStatus = "Pending";
  String? myRejectionReason;
  bool isActionLoading = false;
  final List<File> _capturedPhotos = [];

  final SiteService _siteService = SiteService();
  final AttendanceService _attendanceService = AttendanceService();
  final ShiftService _shiftService = ShiftService();
  final Color green = const Color.fromARGB(255, 1, 126, 42);
  static const Duration networkTimeout = Duration(seconds: 30);

  // --- Helpers ---

  void _startBreakTicker() {
    _breakTicker?.cancel();
    if (currentBreakStart == null) return;
    _activeBreakElapsed = DateTime.now().difference(currentBreakStart!);
    _breakTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && currentBreakStart != null) {
        setState(() {
          _activeBreakElapsed = DateTime.now().difference(currentBreakStart!);
        });
      }
    });
  }

  void _stopBreakTicker() {
    _breakTicker?.cancel();
    _breakTicker = null;
    _activeBreakElapsed = Duration.zero;
  }

  String _formatBreakDuration(Duration duration) {
    final safeDuration = duration.isNegative ? Duration.zero : duration;
    final hours = safeDuration.inHours.toString().padLeft(2, '0');
    final minutes =
        safeDuration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        safeDuration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String _activeBreakTimeText() {
    if (currentBreakStart == null) return 'Time: 00:00:00';
    return 'Time: ${_formatBreakDuration(_activeBreakElapsed)}';
  }

  bool get _hasActiveAttendance => clockInTime != null && clockOutTime == null;

  String _cleanErrorMessage(Object error) {
    final message = error.toString();
    return message.startsWith('Exception: ')
        ? message.substring('Exception: '.length)
        : message;
  }

  String _formatDeviceLocalTime(DateTime time) {
    return DateFormat('hh:mm a').format(time.toLocal());
  }

  String _formatDeviceLocalTimeWithSeconds(DateTime time) {
    return DateFormat('hh:mm:ss a').format(time.toLocal());
  }

  String? _stringValue(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }
    return null;
  }

  dynamic _fieldValue(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      if (data.containsKey(key)) return data[key];
    }
    return null;
  }

  int? _intValue(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  Map<String, dynamic>? _myShiftResponse(Map<String, dynamic> shift) {
    final responses = shift['Assignments'] ??
        shift['assignments'] ??
        shift['EmployeeResponses'] ??
        shift['employeeResponses'];

    if (responses is! List) return null;

    for (final response in responses) {
      if (response is Map<String, dynamic> &&
          _intValue(response['EmployeeId'] ?? response['employeeId']) ==
              widget.employeeId) {
        return response;
      }
    }
    return null;
  }

  bool _isStatus(String status) {
    return myStatus.trim().toLowerCase() == status.toLowerCase();
  }

  String get _normalizedStatus => myStatus.trim().toLowerCase();

  bool get _isSwapPendingStatus =>
      _normalizedStatus == 'swap requested' ||
      _normalizedStatus == 'swap pending' ||
      _normalizedStatus == 'pending swap';

  bool get _isSwapApprovedStatus =>
      _normalizedStatus == 'swap approved' ||
      _normalizedStatus == 'swap accepted';

  bool get _isSwapRejectedStatus =>
      _normalizedStatus == 'swap rejected' ||
      _normalizedStatus == 'swap declined';

  bool _isCompletedStatusValue(String? value) {
    final status = value?.trim().toLowerCase() ?? '';
    return status == 'completed' ||
        status == 'complete' ||
        status == 'done' ||
        status == 'clocked out' ||
        status == 'clockout';
  }

  bool _isCompletedStatus() => _isCompletedStatusValue(myStatus);

  String formatTime(String timeString) {
    try {
      final time = TimeOfDay(
        hour: int.parse(timeString.split(':')[0]),
        minute: int.parse(timeString.split(':')[1]),
      );
      return time.format(context);
    } catch (e) {
      return timeString;
    }
  }

  double? _parseCoordinate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final cleaned = value.trim();
    final normalized = cleaned.replaceAll(RegExp(r'[\s]+'), '');
    if (normalized.contains(',') && !normalized.contains('.')) {
      return double.tryParse(normalized.replaceAll(',', '.'));
    }
    final match =
        RegExp(r'[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?').firstMatch(normalized);
    return match != null ? double.tryParse(match.group(0)!) : null;
  }

  List<List<double>> _parsePolygonCoordinates(String? rawCoordinates) {
    final raw = rawCoordinates?.trim() ?? '';
    if (raw.isEmpty) return const [];

    final points = <List<double>>[];

    void addPoint(dynamic latValue, dynamic lngValue) {
      final lat = _parseCoordinate(latValue?.toString());
      final lng = _parseCoordinate(lngValue?.toString());
      if (lat != null && lng != null) {
        points.add([lat, lng]);
      }
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map) {
            addPoint(
              item['lat'] ?? item['latitude'] ?? item['Latitude'],
              item['lng'] ??
                  item['lon'] ??
                  item['longitude'] ??
                  item['Longitude'],
            );
          } else if (item is List && item.length >= 2) {
            addPoint(item[0], item[1]);
          }
        }
      }
    } catch (_) {
      final matches =
          RegExp(r'[-+]?\d*\.?\d+(?:[eE][-+]?\d+)?').allMatches(raw).toList();
      for (var i = 0; i + 1 < matches.length; i += 2) {
        addPoint(matches[i].group(0), matches[i + 1].group(0));
      }
    }

    return points;
  }

  bool _isPointInPolygon(
    double latitude,
    double longitude,
    List<List<double>> polygon,
  ) {
    var inside = false;
    for (var i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
      final yi = polygon[i][0];
      final xi = polygon[i][1];
      final yj = polygon[j][0];
      final xj = polygon[j][1];

      final intersects = ((yi > latitude) != (yj > latitude)) &&
          (longitude <
              (xj - xi) * (latitude - yi) / ((yj - yi) == 0 ? 1 : yj - yi) +
                  xi);
      if (intersects) inside = !inside;
    }
    return inside;
  }

  void _ensureAccurateFreshPosition(Position position) {
    if (position.accuracy > 30) {
      throw Exception(
          'Location accuracy is low (${position.accuracy.toStringAsFixed(0)}m). Please wait and try again.');
    }

    final age = DateTime.now().difference(position.timestamp);
    if (age > const Duration(minutes: 2)) {
      throw Exception('Location is too old. Please try again.');
    }
  }

  DateTime _getScheduledStartDateTime() {
    final now = DateTime.now();
    try {
      String timeStr = widget.scheduledStartTime.trim();
      int hour = 0;
      int minute = 0;

      if (timeStr.toLowerCase().contains("pm") ||
          timeStr.toLowerCase().contains("am")) {
        if (timeStr.split(':').length > 2) {
          timeStr =
              "${timeStr.split(':')[0]}:${timeStr.split(':')[1]} ${timeStr.split(' ')[1]}";
        }
        final dt = DateFormat("h:mm a").parse(timeStr);
        hour = dt.hour;
        minute = dt.minute;
      } else {
        final parts = timeStr.split(':');
        hour = int.parse(parts[0]);
        minute = int.parse(parts[1]);
      }
      return DateTime(now.year, now.month, now.day, hour, minute);
    } catch (e) {
      debugPrint(" Start Date Parsing Error: $e");
      return DateTime.now();
    }
  }

  DateTime _getScheduledEndDateTime() {
    final now = DateTime.now();
    try {
      String timeStr = widget.scheduledEndTime.trim();
      int hour = 0;
      int minute = 0;

      if (timeStr.toLowerCase().contains("pm") ||
          timeStr.toLowerCase().contains("am")) {
        if (timeStr.split(':').length > 2) {
          timeStr =
              "${timeStr.split(':')[0]}:${timeStr.split(':')[1]} ${timeStr.split(' ')[1]}";
        }
        final dt = DateFormat("h:mm a").parse(timeStr);
        hour = dt.hour;
        minute = dt.minute;
      } else {
        final parts = timeStr.split(':');
        hour = int.parse(parts[0]);
        minute = int.parse(parts[1]);
      }
      return DateTime(now.year, now.month, now.day, hour, minute);
    } catch (e) {
      debugPrint(" End Date Parsing Error: $e");
      return DateTime.now();
    }
  }

  bool _isBeforeScheduledEnd(DateTime time) {
    return time.isBefore(_getScheduledEndDateTime());
  }

  @override
  void initState() {
    super.initState();
    NotificationService().initializeFCM(
      employeeId: widget.employeeId,
      userTag: 'user_${widget.employeeId}',
      onForegroundMessage: _handleShiftNotification,
      onNotificationOpenedApp: _handleShiftNotification,
    );
    _loadSiteData();
    _loadShiftDetailsAndStatus();
    _loadShiftProgress();
    _startBreakTicker();
    enableFullScreen();
  }

  @override
  void dispose() {
    _breakTicker?.cancel();
    _attendanceRefreshTimer?.cancel();
    if (!_hasActiveAttendance) {
      widget.locationService.stopTracking();
    }
    if (mounted) _disposePhotos();
    super.dispose();
  }

  void _disposePhotos() {
    clockInPhoto = null;
    clockOutPhoto = null;
  }

  void _syncAttendanceEvidence(Map<String, dynamic> data) {
    final nextClockInTime = parseServerDateTime(_fieldValue(data, [
      'ClockInTime',
    ]));
    final nextClockOutTime = parseServerDateTime(_fieldValue(data, [
      'ClockOutTime',
    ]));
    final nextEarlyExitReason = _stringValue(data, [
      'EarlyExitReason',
      'earlyExitReason',
      'EmergencyReason',
      'emergencyReason',
      'Reason',
      'reason',
    ]);

    if (nextClockInTime != null && nextClockInTime.year > 1900) {
      clockInTime = nextClockInTime;
    }
    if (nextClockOutTime != null && nextClockOutTime.year > 1900) {
      clockOutTime = nextClockOutTime;
    }
    earlyExitReason = nextEarlyExitReason ?? earlyExitReason;
    attendanceId = _intValue(_fieldValue(data, [
          'AttendanceId',
          'attendanceId',
        ])) ??
        attendanceId;
  }

  void _handleShiftNotification(RemoteMessage message) {
    final values = [
      message.notification?.title,
      message.notification?.body,
      ...message.data.entries.map((entry) => '${entry.key}:${entry.value}'),
    ].whereType<String>().join(' ').toLowerCase();

    final shouldRefreshAttendance =
        values.contains('automatically clocked out') ||
            values.contains('automatic_clock_out') ||
            values.contains('auto_clock_out') ||
            values.contains('clockout') ||
            values.contains('clocked out') ||
            values.contains('outside site boundary');

    if (shouldRefreshAttendance) {
      _refreshActiveAttendanceFromBackend();
    }
  }

  void _clearActiveLocalBreakState() {
    currentBreakStart = null;
    _activeBreakElapsed = Duration.zero;
    _stopBreakTicker();
  }

  Future<void> _syncActiveShiftMonitoring() async {
    if (_hasActiveAttendance) {
      await _startLocationTracking();
      _startAttendanceRefreshTimer();
    } else if (clockOutTime != null) {
      await _stopLocationTracking();
      _stopAttendanceRefreshTimer();
      _clearActiveLocalBreakState();
    }
  }

  Future<void> _startLocationTracking() async {
    if (_isLocationTrackingActive || !_hasActiveAttendance) return;
    _isLocationTrackingActive = true;
    await widget.locationService.startContinuousTracking(
      employeeId: widget.employeeId,
      heartbeatInterval: const Duration(seconds: 45),
      onError: (error) {
        debugPrint("Location tracking error: $error");
      },
    );
  }

  Future<void> _stopLocationTracking() async {
    if (!_isLocationTrackingActive) return;
    await widget.locationService.stopTracking();
    _isLocationTrackingActive = false;
  }

  void _startAttendanceRefreshTimer() {
    if (_attendanceRefreshTimer?.isActive == true || !_hasActiveAttendance) {
      return;
    }

    _attendanceRefreshTimer =
        Timer.periodic(const Duration(seconds: 45), (_) async {
      await _refreshActiveAttendanceFromBackend();
    });
  }

  void _stopAttendanceRefreshTimer() {
    _attendanceRefreshTimer?.cancel();
    _attendanceRefreshTimer = null;
  }

  Future<void> _refreshActiveAttendanceFromBackend() async {
    if (_isAttendanceRefreshInProgress || !mounted) return;
    if (clockOutTime != null) {
      await _syncActiveShiftMonitoring();
      return;
    }

    _isAttendanceRefreshInProgress = true;
    try {
      final attendance =
          await _attendanceService.fetchMyAttendanceForShift(widget.shiftId);
      if (attendance == null || !mounted) return;

      final backendClockOutTime = parseServerDateTime(_fieldValue(attendance, [
        'ClockOutTime',
        'clockOutTime',
      ]));
      final backendClockInTime = parseServerDateTime(_fieldValue(attendance, [
        'ClockInTime',
        'clockInTime',
      ]));
      final backendAttendanceId = _intValue(_fieldValue(attendance, [
        'AttendanceId',
        'attendanceId',
        'Id',
        'id',
      ]));

      if (backendClockInTime != null || backendClockOutTime != null) {
        setState(() {
          if (backendClockInTime != null && backendClockInTime.year > 1900) {
            clockInTime = backendClockInTime;
          }
          if (backendAttendanceId != null && backendAttendanceId > 0) {
            attendanceId = backendAttendanceId;
          }
          if (backendClockOutTime != null && backendClockOutTime.year > 1900) {
            clockOutTime = backendClockOutTime;
            _clearActiveLocalBreakState();
          }
          _syncAttendanceEvidence(attendance);
        });

        await _saveShiftProgress();
        await _syncActiveShiftMonitoring();
        if (clockOutTime != null) {
          await _loadAttendancePhotos();
        }
      }
    } catch (e) {
      debugPrint("Attendance refresh failed: $e");
    } finally {
      _isAttendanceRefreshInProgress = false;
    }
  }

  Future<void> _loadAttendancePhotos() async {
    if (attendanceId == null || attendanceId! <= 0) return;

    if (mounted) {
      setState(() => _isLoadingAttendancePhotos = true);
    }

    try {
      final nextClockInPhotos =
          await _attendanceService.fetchClockInPhotos(attendanceId!);
      final nextClockOutPhotos =
          await _attendanceService.fetchClockOutPhotos(attendanceId!);

      if (!mounted) return;

      setState(() {
        _clockInSignedPhotos = nextClockInPhotos;
        _clockOutSignedPhotos = nextClockOutPhotos;
        clockInPhotoUrl =
            nextClockInPhotos.isEmpty ? null : nextClockInPhotos.first.url;
        clockOutPhotoUrl =
            nextClockOutPhotos.isEmpty ? null : nextClockOutPhotos.first.url;
      });
    } catch (e) {
      debugPrint('Error loading attendance photos: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingAttendancePhotos = false);
      }
    }
  }

  Future<void> _loadShiftDetailsAndStatus() async {
    try {
      final myShifts =
          await _shiftService.fetchShiftsByEmployeeIdRaw(widget.employeeId);
      final shift = myShifts.firstWhere(
        (s) => s['ShiftId'] == widget.shiftId,
        orElse: () => {},
      );

      if (shift.isNotEmpty && mounted) {
        final myResponse = _myShiftResponse(shift);
        final topLevelStatus = (shift['Status'] ?? shift['status'])?.toString();
        final nextStatus = shift['MyStatus'] ??
            shift['myStatus'] ??
            myResponse?['Status'] ??
            myResponse?['status'] ??
            (_isCompletedStatusValue(topLevelStatus) ? topLevelStatus : null) ??
            "Pending";
        final responseClockInTime = myResponse == null
            ? null
            : parseServerDateTime(_fieldValue(myResponse, const [
                'ClockInTime',
              ]));
        final responseClockOutTime = myResponse == null
            ? null
            : parseServerDateTime(_fieldValue(myResponse, const [
                'ClockOutTime',
              ]));

        setState(() {
          shiftDetails = shift;
          myStatus = nextStatus.toString();
          myRejectionReason = (shift['MyRejectionReason'] ??
                  shift['RejectionReason'] ??
                  shift['Reason'] ??
                  shift['DeclineReason'] ??
                  myResponse?['Reason'] ??
                  myResponse?['reason'])
              ?.toString();
          if (responseClockInTime != null && responseClockInTime.year > 1900) {
            clockInTime = responseClockInTime;
          }
          if (responseClockOutTime != null &&
              responseClockOutTime.year > 1900) {
            clockOutTime = responseClockOutTime;
          }
          if (myResponse != null) {
            _syncAttendanceEvidence(myResponse);
          }
        });

        await _saveShiftProgress();
        await _syncActiveShiftMonitoring();

        // If SiteId was missing from Job object, try loading it from Shift details
        if (currentSite == null) {
          final int? siteIdFromShift = shift['SiteId'] ?? shift['siteId'];
          final String? latFromShift =
              shift['Latitude']?.toString() ?? shift['latitude']?.toString();
          final String? lngFromShift =
              shift['Longitude']?.toString() ?? shift['longitude']?.toString();

          if (siteIdFromShift != null && siteIdFromShift != 0) {
            debugPrint(
                "Site Loading: Found SiteId in shift details: $siteIdFromShift. Retrying load.");
            _loadSiteData(overrideSiteId: siteIdFromShift);
          } else if (latFromShift != null && lngFromShift != null) {
            debugPrint(
                "Site Loading: Found Coordinates in shift details. Creating virtual site.");
            setState(() {
              currentSite = Site(
                siteId: 0,
                siteName: shift['Location'] ?? "Shift Site",
                latitude: latFromShift,
                longitude: lngFromShift,
              );
            });
          }
        }
      }
    } catch (e) {
      debugPrint(' Error loading shift details & status: $e');
    }
  }

  // --- Actions ---

  Future<void> _handleAccept() async {
    setState(() => isActionLoading = true);
    try {
      bool success =
          await _shiftService.respondToShift(widget.shiftId, "Accept");
      if (success) {
        setState(() => myStatus = "Accepted");
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Shift Accepted!")));
      }
    } catch (e) {
      debugPrint("Error accepting shift: $e");
    } finally {
      setState(() => isActionLoading = false);
    }
  }

  Future<void> _handleDecline() async {
    TextEditingController reasonCtrl = TextEditingController();
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1C2230),
              title: const Text("Decline Shift",
                  style: TextStyle(color: Colors.white)),
              content: TextField(
                controller: reasonCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Reason (Required)",
                  hintStyle: TextStyle(color: Colors.white54),
                  enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54)),
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cancel")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    if (reasonCtrl.text.isEmpty) return;
                    Navigator.pop(ctx);
                    setState(() => isActionLoading = true);
                    bool success = await _shiftService.respondToShift(
                        widget.shiftId, "Decline",
                        reason: reasonCtrl.text);
                    if (success) {
                      setState(() {
                        myStatus = "Declined";
                        myRejectionReason = reasonCtrl.text.trim().isEmpty
                            ? null
                            : reasonCtrl.text.trim();
                      });
                    }
                    setState(() => isActionLoading = false);
                  },
                  child: const Text("Decline"),
                )
              ],
            ));
  }

  Future<void> _handleSwapRequest() async {
    setState(() => isActionLoading = true);
    try {
      bool success = await _shiftService.requestSwap(widget.shiftId);
      if (success) {
        setState(() => myStatus = "Swap Requested");
        await _saveShiftProgress();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Swap Requested Successfully")));
      }
    } catch (e) {
      debugPrint("Error requesting swap: $e");
    } finally {
      setState(() => isActionLoading = false);
    }
  }

  Future<void> _loadSiteData({int? overrideSiteId}) async {
    final targetSiteId = overrideSiteId ?? widget.job.siteId;

    if (mounted) setState(() => isLoading = true);
    debugPrint("Site Loading: Starting for SiteId: $targetSiteId");
    try {
      if (targetSiteId == 0) {
        debugPrint("Site Loading: Aborted. SiteId is 0.");
        return;
      }
      final site = await _siteService.fetchSiteById(targetSiteId);
      if (site != null) {
        if (mounted) {
          setState(() {
            currentSite = site;
          });
        }
        debugPrint("Site Loading: Success! Site Name: ${site.siteName}");
      } else {
        debugPrint(
            "Site Loading: Failed. Site not found for ID: $targetSiteId");
        if (currentSite == null && mounted) {
          final fallbackName = (shiftDetails?['Location'] ??
                  shiftDetails?['location'] ??
                  widget.job.title)
              .toString()
              .trim();
          setState(() {
            currentSite = Site(
              siteId: targetSiteId,
              siteName: fallbackName.isEmpty ? 'Shift Site' : fallbackName,
            );
          });
        }
      }
    } catch (e) {
      debugPrint('Site Loading: Error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- UPDATED: Properly syncs Break Status from Server ---
  Future<void> _loadShiftProgress() async {
    // 1. Load Local Data (Prevents flickering)
    final prefs = await SharedPreferences.getInstance();
    final key = 'shift_progress_${widget.employeeId}_${widget.shiftId}';
    final progressData = prefs.getString(key);

    if (progressData != null) {
      final progress = jsonDecode(progressData);
      if (mounted) {
        setState(() {
          clockInTime = parseServerDateTime(progress['clockInTime']);
          clockOutTime = parseServerDateTime(progress['clockOutTime']);
          if (progress['breaks'] != null) {
            breaks = (progress['breaks'] as List<dynamic>).map((b) {
              return {
                'start': parseServerDateTime(b['start']) ??
                    DateTime.parse(b['start']),
                'end':
                    parseServerDateTime(b['end']) ?? DateTime.parse(b['end']),
              };
            }).toList();
          }
          if (progress['currentBreakStart'] != null) {
            currentBreakStart =
                parseServerDateTime(progress['currentBreakStart']);
          }
          clockInPhotoUrl = null;
          clockOutPhotoUrl = null;
          earlyExitReason = progress['earlyExitReason'];
          attendanceId = progress['attendanceId'];
          myStatus = progress['myStatus'] ?? myStatus;
        });
        if (currentBreakStart != null) {
          _startBreakTicker();
        }
        if (clockOutTime != null) {
          await _loadAttendancePhotos();
        }
        await _syncActiveShiftMonitoring();
      }
    }

    try {
      // 2. Fetch Latest Status from Server
      final shift = await _attendanceService.getShiftsByShiftId(
          widget.employeeId,
          shiftId: widget.shiftId) as Map<String, dynamic>?;

      if (shift != null && mounted) {
        // --- Parse Backend Times ---
        final backendClockInTime = parseServerDateTime(_fieldValue(shift, [
          'ClockInTime',
          'clockInTime',
          'ClockinTime',
        ]));
        final backendClockOutTime = parseServerDateTime(_fieldValue(shift, [
          'ClockOutTime',
          'clockOutTime',
        ]));

        // --- NEW: Parse Backend Break Times ---
        final backendBreakStart = parseServerDateTime(_fieldValue(shift, [
          'BreakStart',
          'breakStart',
        ]));
        final backendBreakEnd = parseServerDateTime(_fieldValue(shift, [
          'BreakEnd',
          'breakEnd',
        ]));
        final backendAttendanceId = _intValue(_fieldValue(shift, [
          'AttendanceId',
          'attendanceId',
        ]));

        if (mounted) {
          setState(() {
            _syncAttendanceEvidence(shift);

            // Sync Clock In from backend. Backend attendance is authoritative
            // over any locally cached progress from a previous app session.
            if (backendClockInTime != null) {
              clockInTime = backendClockInTime;
              attendanceId = backendAttendanceId ?? attendanceId;
            }

            // Ensure we keep attendanceId if the backend returns an attendance record
            if (attendanceId == null && backendAttendanceId != null) {
              attendanceId = backendAttendanceId;
            }

            // Sync Clock Out
            if (backendClockOutTime != null &&
                backendClockOutTime.year > 1900) {
              clockOutTime = backendClockOutTime;
              if (attendanceId == null && backendAttendanceId != null) {
                attendanceId = backendAttendanceId;
              }
            }

            // --- Sync Break Status ---
            if (backendBreakStart != null) {
              // Active Break
              if (backendBreakEnd == null) {
                currentBreakStart = backendBreakStart;
                _activeBreakElapsed =
                    DateTime.now().difference(backendBreakStart);
              }
              // Finished Break
              else {
                currentBreakStart = null;
                _stopBreakTicker();
                final DateTime backendBreakEndNonNull = backendBreakEnd;
                // Add to history if unique
                bool exists = breaks.any((b) =>
                    b['start']!.isAtSameMomentAs(backendBreakStart) &&
                    b['end']!.isAtSameMomentAs(backendBreakEndNonNull));

                if (!exists) {
                  breaks.add({
                    'start': backendBreakStart,
                    'end': backendBreakEndNonNull,
                  });
                }
              }
            }
          });

          if (currentBreakStart != null) {
            _startBreakTicker();
          }
          await _saveShiftProgress();
          await _syncActiveShiftMonitoring();
          if (clockOutTime != null) {
            await _loadAttendancePhotos();
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching shift status: $e');
    }
  }

  Future<void> _saveShiftProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'shift_progress_${widget.employeeId}_${widget.shiftId}';
    final progressData = {
      'clockInTime': formatDateTimeForServer(clockInTime),
      'clockOutTime': formatDateTimeForServer(clockOutTime),
      'breaks': breaks
          .map((b) => {
                'start': formatDateTimeForServer(b['start']),
                'end': formatDateTimeForServer(b['end'])
              })
          .toList(),
      'currentBreakStart': formatDateTimeForServer(currentBreakStart),
      'clockInPhotoUrl': null,
      'clockOutPhotoUrl': null,
      'earlyExitReason': earlyExitReason,
      'attendanceId': attendanceId,
      'myStatus': myStatus,
    };
    await prefs.setString(key, jsonEncode(progressData));
  }

  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission != LocationPermission.denied &&
        permission != LocationPermission.deniedForever;
  }

  Future<bool> _validateGeofence(Position position) async {
    if (currentSite == null) {
      throw Exception('Site details are not loaded. Please try again.');
    }
    try {
      _ensureAccurateFreshPosition(position);

      if (currentSite!.siteId <= 0) {
        throw Exception(
            'The site is not configured correctly. Please contact your manager.');
      }

      final geofenceType =
          (currentSite!.geoFenceType ?? '').trim().toLowerCase();
      if (geofenceType.contains('polygon')) {
        final polygon = _parsePolygonCoordinates(currentSite!.geoCoordinates);
        if (polygon.length < 3) {
          throw Exception(
              'The site polygon geofence is not configured. Please contact your manager.');
        }

        final inPolygon = _isPointInPolygon(
          position.latitude,
          position.longitude,
          polygon,
        );
        debugPrint("Geofence Check: Polygon in range: $inPolygon");
        return inPolygon;
      }

      final siteLatStr = currentSite!.latitude ?? '';
      final siteLngStr = currentSite!.longitude ?? '';
      final siteLat = _parseCoordinate(siteLatStr);
      final siteLng = _parseCoordinate(siteLngStr);

      debugPrint(
          "Geofence Check: User Position: (${position.latitude}, ${position.longitude})");
      debugPrint(
          "Geofence Check: Site Position (ID: ${currentSite!.siteId}): ($siteLatStr, $siteLngStr)");

      if (siteLat == null || siteLng == null) {
        throw Exception(
            'The site coordinates are not configured. Please contact your manager.');
      }

      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        siteLat,
        siteLng,
      );

      final allowedRadius = currentSite!.radius;
      if (allowedRadius == null || allowedRadius <= 0) {
        throw Exception(
            'The site geofence radius is not configured. Please contact your manager.');
      }

      debugPrint(
          "Geofence Check: Distance: ${distance.toStringAsFixed(2)}m, Allowed Radius: ${allowedRadius}m");

      bool inRange = distance <= allowedRadius;
      debugPrint("Geofence Check: In Range: $inRange");

      return inRange;
    } catch (e) {
      debugPrint("Geofence Check Failed with error: $e");
      rethrow;
    }
  }

  Future<bool> _capturePhotos() async {
    _capturedPhotos.clear();
    bool done = false;

    while (!done && _capturedPhotos.length < 5) {
      final shouldAdd = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1C2230),
          title: Text("Add Photo (${_capturedPhotos.length}/5)",
              style: const TextStyle(color: Colors.white)),
          content: const Text("You must take at least one photo.",
              style: TextStyle(color: Colors.white70)),
          actions: [
            if (_capturedPhotos.isNotEmpty)
              TextButton(
                onPressed: () => Navigator.pop(ctx, false), // Done
                child: const Text("Done", style: TextStyle(color: Colors.blue)),
              ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () => Navigator.pop(ctx, true), // Add Photo
              child: const Text("Take Photo"),
            ),
          ],
        ),
      );

      if (shouldAdd == true) {
        final File? photo = await widget.imagePickerService.pickImage();
        if (photo != null) {
          setState(() {
            _capturedPhotos.add(File(photo.path));
          });
        }
      } else {
        done = true;
      }
    }
    return _capturedPhotos.isNotEmpty;
  }

  // --- CLOCK IN (Strict Geofence + GPS + Multi-Photo) ---
  Future<void> _handleClockIn() async {
    if (mounted) setState(() => isLoading = true);
    try {
      if (!await _checkLocationPermission()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Location permission is required.')));
          setState(() => isLoading = false);
        }
        return;
      }

      final position = await widget.locationService.getCurrentPosition(
        timeout: const Duration(seconds: 10),
      );

      //  STRICT CHECK: Validate Geofence BEFORE anything else
      bool inRange = await _validateGeofence(position);
      if (!inRange) {
        if (mounted) {
          setState(() => isLoading = false);
          // Show strict warning dialog
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1C2230),
              title: const Text("Out of Range",
                  style: TextStyle(color: Colors.redAccent)),
              content: const Text(
                "You are not within the allowed range of the site.\n\nYou cannot clock in or take photos until you are on site.",
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        }
        return;
      }

      //  TIME CHECK: Is it within the shift window?
      final now = DateTime.now();
      final scheduledStart = _getScheduledStartDateTime();
      final scheduledEnd = _getScheduledEndDateTime();

      // Allow clock-in up to 15 minutes before start
      final earliestAllowed =
          scheduledStart.subtract(const Duration(minutes: 15));

      if (now.isBefore(earliestAllowed)) {
        if (mounted) {
          setState(() => isLoading = false);
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1C2230),
              title: const Text("Too Early",
                  style: TextStyle(color: Colors.orangeAccent)),
              content: Text(
                "You cannot clock in yet.\n\nScheduled Start: ${DateFormat('hh:mm a').format(scheduledStart)}\nEarliest Clock-in: ${DateFormat('hh:mm a').format(earliestAllowed)}",
                style: const TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("OK")),
              ],
            ),
          );
        }
        return;
      }

      if (now.isAfter(scheduledEnd)) {
        if (mounted) {
          setState(() => isLoading = false);
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1C2230),
              title: const Text("Shift Ended",
                  style: TextStyle(color: Colors.redAccent)),
              content: Text(
                "The scheduled shift has already ended.\n\nScheduled End: ${DateFormat('hh:mm a').format(scheduledEnd)}",
                style: const TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("OK")),
              ],
            ),
          );
        }
        return;
      }

      // 1. Capture Photos (Only if in range)
      bool hasPhotos = await _capturePhotos();
      if (!hasPhotos) {
        if (mounted) {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('At least one photo is required.')));
        }
        return;
      }

      final result = await _attendanceService.clockIn(
        employeeId: widget.employeeId,
        shiftId: widget.shiftId,
        siteId: currentSite!.siteId,
        scheduledStartTime: widget.scheduledStartTime,
        photos: _capturedPhotos,
        clockInTime: now,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (result['success']) {
        final attendanceIdFromResponse = result['attendanceId'];

        if (mounted) {
          setState(() {
            clockInTime = now;
            attendanceId = attendanceIdFromResponse;
            if (result['data'] is Map<String, dynamic>) {
              _syncAttendanceEvidence(result['data'] as Map<String, dynamic>);
            }
            clockInPhoto =
                _capturedPhotos.isNotEmpty ? _capturedPhotos.first : null;
          });
        }
        await _saveShiftProgress();
        await _sendEmployeeLocation(position);
        await _syncActiveShiftMonitoring();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Clock-in successful!')));
        }
      } else {
        final message = result['error']?.toString() ??
            'Unable to clock in. Please try again.';
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
        }
      }
    } catch (e) {
      debugPrint('Clock-in error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_cleanErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _sendEmployeeLocation(Position position) async {
    try {
      await widget.locationService.sendLocation(position, widget.employeeId);
    } catch (e) {
      debugPrint(" Error sending employee location: $e");
    }
  }

  // --- CLOCK OUT (Early Warning & Multi-Photo) ---
  Future<void> _handleClockOut() async {
    if (attendanceId == null) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1C2230),
            title: const Text("Attendance Missing",
                style: TextStyle(color: Colors.orangeAccent)),
            content: const Text(
              "Unable to clock out because the attendance record could not be found.\n\nPlease refresh the shift or reopen it to sync your attendance data.",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
      return;
    }

    //  STRICT CHECK: Cannot Clock Out during an active break
    if (currentBreakStart != null) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1C2230),
            title: const Text("Active Break",
                style: TextStyle(color: Colors.orangeAccent)),
            content: const Text(
              "You cannot clock out while on a break.\n\nPlease end your break first.",
              style: TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
      return;
    }

    final now = DateTime.now();

    //  CHECK: Is it Early Departure?
    bool isEarly = _isBeforeScheduledEnd(now);

    String? earlyExitReason;

    if (isEarly) {
      bool? confirmEarly = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1C2230),
          title: const Text("Early Departure Warning",
              style: TextStyle(color: Colors.orangeAccent)),
          content: const Text(
            "You are attempting to clock out BEFORE your scheduled end time.\n\nAre you sure you want to proceed?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false), // No
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () => Navigator.pop(ctx, true), // Yes
              child: const Text("Yes, Clock Out Early"),
            ),
          ],
        ),
      );

      if (confirmEarly != true) return; // User cancelled

      // captures early exit reason
      final String? reason = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          final controller = TextEditingController();
          final formKey = GlobalKey<FormState>();
          return AlertDialog(
            backgroundColor: const Color(0xFF1C2230),
            title: const Text("Early Departure Reason",
                style: TextStyle(color: Colors.white)),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "You are clocking out early. Please provide a reason to proceed.",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: controller,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Reason for early exit",
                      hintStyle: const TextStyle(color: Colors.white30),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                            color: Colors.blueAccent.withValues(alpha: 0.3)),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Reason is required for early clock-out';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(ctx, controller.text);
                  }
                },
                child: const Text("Submit"),
              ),
            ],
          );
        },
      );

      if (reason == null) {
        if (mounted) setState(() => isLoading = false);
        return; // User cancelled or didn't provide reason
      }

      earlyExitReason = reason.trim();
    }

    if (mounted) setState(() => isLoading = true);

    try {
      // 1. Capture Photos
      bool hasPhotos = await _capturePhotos();
      if (!hasPhotos) {
        if (mounted) {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('At least one photo is required.')));
        }
        return;
      }

      Position position = await widget.locationService.getCurrentPosition(
        timeout: const Duration(seconds: 10),
      );

      // 2. Calculate Total Break Duration
      int totalBreakMinutes = 0;
      for (var b in breaks) {
        if (b['start'] != null && b['end'] != null) {
          totalBreakMinutes += b['end']!.difference(b['start']!).inMinutes;
        }
      }

      // 3. Call Service
      final result = await _attendanceService.clockOut(
        attendanceId: attendanceId!,
        shiftId: widget.shiftId,
        clockOutTime: now,
        photos: _capturedPhotos,
        latitude: position.latitude,
        longitude: position.longitude,
        clockInTime: clockInTime,
        totalBreakMinutes: totalBreakMinutes,
        earlyExitReason: earlyExitReason,
        timeout: networkTimeout,
      );

      if (result['success']) {
        if (mounted) {
          setState(() {
            clockOutTime = now;
            if (result['data'] is Map<String, dynamic>) {
              _syncAttendanceEvidence(result['data'] as Map<String, dynamic>);
            }
            if (isEarly && earlyExitReason != null) {
              this.earlyExitReason = earlyExitReason;
            } else if (!isEarly) {
              this.earlyExitReason = null;
            }
            _clearActiveLocalBreakState();
            clockOutPhoto =
                _capturedPhotos.isNotEmpty ? _capturedPhotos.first : null;
          });
        }
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final profile = userProvider.userProfile;
        final employeeName = profile.isNotEmpty
            ? "${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}"
                .trim()
            : "An employee";

        await NotificationService()
            .sendShiftCompletionNotification(employeeName, widget.shiftId, now);
        await _saveShiftProgress();
        await _syncActiveShiftMonitoring();

        if (mounted) {
          if (isEarly) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Colors.orange[800],
              content: const Text(
                  ' Early Departure Recorded. You clocked out early.'),
            ));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(' Clock-out successful!')));
          }
        }
      } else {
        final message = result['error']?.toString() ??
            'Unable to clock out. Please try again.';
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
        }
      }
    } catch (e) {
      debugPrint('Clock-out error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_cleanErrorMessage(e))));
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- UPDATED: Fix for Timezone Issue (Break Start) ---
  Future<void> _handleBreakStart() async {
    if (attendanceId == null) return;
    if (mounted) setState(() => isLoading = true);
    try {
      // 1. Capture Local Time
      final now = DateTime.now();

      // 2. Send 'now' to the service
      final result =
          await _attendanceService.breakStart(attendanceId!, startTime: now);

      if (result == true) {
        if (mounted) {
          setState(() {
            currentBreakStart = now;
            _activeBreakElapsed = Duration.zero;
          });
          _startBreakTicker();
        }
        await _saveShiftProgress();
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Break started!')));
        }
      }
    } catch (e) {
      debugPrint('Break start error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- UPDATED: Fix for Timezone Issue (Break End) ---
  Future<void> _handleBreakEnd() async {
    if (attendanceId == null) return;
    if (mounted) setState(() => isLoading = true);
    try {
      // 1. Capture Local Time
      final now = DateTime.now();

      // 2. Send 'now' to the service
      final result =
          await _attendanceService.endBreak(attendanceId!, endTime: now);

      if (result == true) {
        if (mounted) {
          setState(() {
            if (currentBreakStart != null) {
              breaks.add({'start': currentBreakStart!, 'end': now});
              currentBreakStart = null;
              _activeBreakElapsed = Duration.zero;
            }
          });
          _stopBreakTicker();
        }
        await _saveShiftProgress();
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Break ended!')));
        }
      }
    } catch (e) {
      debugPrint('Break end error: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: Background()),
        Scaffold(
          backgroundColor: Colors.transparent,
          drawer: const Sidenav(),
          appBar: const Uppernavbar(showBackButton: true),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Gradienthorizontal(
                    width: MediaQuery.of(context).size.width,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildShiftInfoCard(),
                          const SizedBox(height: 24),
                          _buildShiftActionArea(),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildShiftActionArea() {
    if (isActionLoading) {
      return const CircularProgressIndicator();
    }

    if (clockInTime != null && clockOutTime != null) {
      return _buildShiftSummary();
    }

    if (_isCompletedStatus()) {
      return _buildStatusMessage(
        "This shift is completed. Summary details are loading...",
        Colors.green,
      );
    }

    if (_isStatus("Pending")) {
      return _buildAcknowledgementCard();
    }

    if (_isStatus("Declined")) {
      return _buildStatusMessage(
        "You have declined this shift.${myRejectionReason != null && myRejectionReason!.isNotEmpty ? '\nReason: $myRejectionReason' : ''}",
        Colors.red,
      );
    }

    if (_isSwapPendingStatus) {
      return _buildStatusMessage(
        "Swap requested. Waiting for manager approval.",
        Colors.orange,
      );
    }

    if (_isSwapApprovedStatus) {
      return _buildStatusMessage(
        "Your shift swap request was approved.",
        Colors.green,
      );
    }

    if (_isSwapRejectedStatus) {
      return _buildStatusMessage(
        "Your shift swap request was rejected.",
        Colors.red,
      );
    }

    if (_isStatus("Accepted") || clockInTime != null) {
      return _buildTimeTrackingCard();
    }

    return _buildStatusMessage("Shift status: $myStatus", Colors.blueAccent);
  }

  Widget _buildLiveTrackingButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton.icon(
        onPressed: () {
          if (currentSite != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EmployeeTrackingScreen(
                  currentSite: currentSite!,
                  employeeId: widget.employeeId,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Site location not available.")),
            );
          }
        },
        icon: const Icon(Icons.map, color: Colors.white),
        label: const Text("View Live Location Map",
            style: TextStyle(color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildAcknowledgementCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          const Text(
            "Shift Acknowledgment",
            style: TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            "Please accept this shift to start tracking time.",
            style: TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _handleDecline,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent),
                  child: const Text("Decline"),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: ElevatedButton(
                  onPressed: _handleAccept,
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text("Accept"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: _handleSwapRequest,
            icon: const Icon(Icons.swap_horiz, color: Colors.orangeAccent),
            label: const Text("Request Swap",
                style: TextStyle(color: Colors.orangeAccent)),
          )
        ],
      ),
    );
  }

  Widget _buildStatusMessage(String msg, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color),
      ),
      child: Text(
        msg,
        style:
            TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildShiftInfoCard() {
    final date = shiftDetails?['Date'];
    final formattedDate = date != null
        ? DateFormat.yMMMMd().format(DateTime.parse(date))
        : 'Loading...';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.job.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          shiftDetails?['TaskName'] ?? 'Loading...',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Icon(Icons.calendar_month_outlined,
                color: Colors.white.withValues(alpha: 0.9), size: 18),
            const SizedBox(width: 8),
            Text(
              'Date: $formattedDate',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9), fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.schedule,
                color: Colors.white.withValues(alpha: 0.9), size: 18),
            const SizedBox(width: 8),
            Text(
              'Start: ${formatTime(widget.scheduledStartTime)}',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9), fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.schedule_outlined,
                color: Colors.white.withValues(alpha: 0.9), size: 18),
            const SizedBox(width: 8),
            Text(
              'End: ${formatTime(widget.scheduledEndTime)}',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9), fontSize: 16),
            ),
          ],
        ),
        if (currentSite != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on,
                  color: Colors.white.withValues(alpha: 0.9), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  currentSite!.siteName,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9), fontSize: 16),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTimeTrackingCard() {
    final canClockOut =
        clockInTime != null && clockOutTime == null && attendanceId != null;
    final needsAttendanceSync =
        clockInTime != null && clockOutTime == null && attendanceId == null;
    final isBreakEnabled = clockInTime != null && clockOutTime == null;

    bool isEarlyDeparture = false;
    if (clockOutTime != null) {
      isEarlyDeparture = _isBeforeScheduledEnd(clockOutTime!);
    }

    return Column(
      children: [
        const SizedBox(width: double.infinity),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              if (clockOutTime != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isEarlyDeparture
                        ? Colors.orange.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isEarlyDeparture
                          ? Colors.orange.withValues(alpha: 0.5)
                          : Colors.green.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        isEarlyDeparture
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle,
                        color: isEarlyDeparture ? Colors.orange : Colors.green,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEarlyDeparture
                                  ? 'Early Departure'
                                  : 'Shift Completed!',
                              style: TextStyle(
                                color: isEarlyDeparture
                                    ? Colors.orange
                                    : Colors.green,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isEarlyDeparture
                                  ? 'You clocked out at ${_formatDeviceLocalTime(clockOutTime!)} before the scheduled end time.'
                                  : 'You have successfully completed your shift at ${_formatDeviceLocalTime(clockOutTime!)}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (clockOutTime == null) ...[
                _buildTimeTrackingItem(
                  clockInTime == null ? "Clock In" : "Clock Out",
                  clockInTime,
                  clockInTime == null ? Icons.login : Icons.logout,
                  clockInTime == null ? "Clock In" : "Clock Out",
                  clockInTime == null
                      ? () => _handleClockIn()
                      : () => _handleClockOut(),
                  isEnabled: clockInTime == null ? true : canClockOut,
                  photo: clockInTime == null ? clockInPhoto : clockOutPhoto,
                ),
                if (needsAttendanceSync)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Attendance record is still syncing. Please refresh the shift or reopen it before trying to clock out.',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
              ] else
                _buildTimeTrackingItem(
                  "Clock Out",
                  clockOutTime,
                  Icons.logout,
                  "Shift Completed",
                  () {},
                  isEnabled: false,
                  photo: clockOutPhoto,
                ),
              const SizedBox(height: 16),
              if (clockInTime != null && clockOutTime == null) ...[
                if (currentBreakStart == null)
                  _buildTimeTrackingItem(
                    "Start Break",
                    null,
                    Icons.free_breakfast,
                    "Start Break",
                    _handleBreakStart,
                    isEnabled: isBreakEnabled,
                  )
                else
                  //  UPDATED: End Break Button with Distinct Color
                  _buildTimeTrackingItem(
                    "End Break",
                    currentBreakStart,
                    Icons.task_alt,
                    "End Break",
                    _handleBreakEnd,
                    isEnabled: isBreakEnabled,
                    customButtonColor: Colors.orangeAccent, // Changed color
                    customTextColor: Colors.black,
                    trailingText: _activeBreakTimeText(),
                  ),
                const SizedBox(height: 16),
                _buildLiveTrackingButton(),
                const SizedBox(height: 16),
              ],
              if (breaks.isNotEmpty) ...[
                _buildBreakHistory(),
                const SizedBox(height: 16),
              ],
              if (clockOutTime != null) ...[
                _buildShiftSummary(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShiftSummary() {
    if (clockInTime == null || clockOutTime == null) return SizedBox.shrink();

    final duration = clockOutTime!.difference(clockInTime!);
    if (duration.isNegative) {
      return const Text(
        ' Shift times are invalid (Clock-out before Clock-in)',
        style: TextStyle(color: Colors.redAccent, fontSize: 14),
      );
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final earlyExitReasonText = earlyExitReason?.trim();
    final showEarlyExitReason =
        _wasEarlyDeparture() && earlyExitReasonText?.isNotEmpty == true;
    final hasAttendanceEvidence = _hasAttendancePhoto(
          clockInPhoto,
          _clockInSignedPhotos,
        ) ||
        _hasAttendancePhoto(clockOutPhoto, _clockOutSignedPhotos);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(
                'Shift Summary',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.login, color: Colors.green, size: 16),
              const SizedBox(width: 8),
              Text(
                'Clock In: ${_formatDeviceLocalTime(clockInTime!)}',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.logout, color: Colors.red, size: 16),
              const SizedBox(width: 8),
              Text(
                'Clock Out: ${_formatDeviceLocalTime(clockOutTime!)}',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.blue, size: 16),
              const SizedBox(width: 8),
              Text(
                'Total Time: ${hours}h ${minutes}m',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.free_breakfast, color: Colors.orange, size: 16),
              const SizedBox(width: 8),
              Text(
                'Breaks Taken: ${breaks.length}',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          if (showEarlyExitReason) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.orangeAccent, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Early Exit Reason: $earlyExitReasonText',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.photo_library_outlined,
                  color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              const Text(
                'Attendance Photos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_isLoadingAttendancePhotos)
            const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white70,
                ),
              ),
            )
          else if (hasAttendanceEvidence)
            Column(
              children: [
                if (_hasAttendancePhoto(clockInPhoto, _clockInSignedPhotos))
                  _buildAttendancePhotoGroup(
                    'Clock In',
                    file: clockInPhoto,
                    photos: _clockInSignedPhotos,
                  ),
                if (_hasAttendancePhoto(clockInPhoto, _clockInSignedPhotos) &&
                    _hasAttendancePhoto(clockOutPhoto, _clockOutSignedPhotos))
                  const SizedBox(height: 12),
                if (_hasAttendancePhoto(clockOutPhoto, _clockOutSignedPhotos))
                  _buildAttendancePhotoGroup(
                    'Clock Out',
                    file: clockOutPhoto,
                    photos: _clockOutSignedPhotos,
                  ),
              ],
            )
          else
            const Text(
              'No attendance photos recorded for this shift.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
        ],
      ),
    );
  }

  bool _wasEarlyDeparture() {
    if (clockOutTime == null) return false;
    return _isBeforeScheduledEnd(clockOutTime!);
  }

  bool _hasAttendancePhoto(File? file, List<AttendancePhoto> photos) {
    return file != null || photos.isNotEmpty;
  }

  Widget _buildAttendancePhotoGroup(
    String label, {
    File? file,
    required List<AttendancePhoto> photos,
  }) {
    final photoItems = <Widget>[
      if (file != null)
        _buildAttendancePhotoPreview(
          label,
          file: file,
        ),
      for (var index = 0; index < photos.length; index++)
        _buildAttendancePhotoPreview(
          photos.length == 1 ? label : '$label ${index + 1}',
          url: photos[index].url,
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = photoItems.length == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: photoItems
              .map((item) => SizedBox(width: tileWidth, child: item))
              .toList(),
        );
      },
    );
  }

  Widget _buildAttendancePhotoPreview(
    String label, {
    File? file,
    String? url,
  }) {
    return GestureDetector(
      onTap: () => _showAttendancePhotoDialog(label, file: file, url: url),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 96,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _buildAttendanceImage(
                  file: file, url: url, fit: BoxFit.cover),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceImage({
    File? file,
    String? url,
    BoxFit fit = BoxFit.contain,
  }) {
    if (file != null) {
      return Image.file(file, fit: fit);
    }

    if (url != null && url.trim().isNotEmpty) {
      final bytes = _decodeImageBytes(url);
      if (bytes != null) {
        return Image.memory(
          bytes,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.broken_image_outlined, color: Colors.white38),
          ),
        );
      }

      return Image.network(
        url,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image_outlined, color: Colors.white38),
        ),
      );
    }

    return const Center(
      child: Icon(Icons.image_not_supported_outlined, color: Colors.white38),
    );
  }

  Uint8List? _decodeImageBytes(String value) {
    final trimmed = value.trim();
    final commaIndex = trimmed.indexOf(',');
    final base64Value =
        trimmed.toLowerCase().startsWith('data:image') && commaIndex != -1
            ? trimmed.substring(commaIndex + 1)
            : trimmed;

    if (base64Value.startsWith('http://') ||
        base64Value.startsWith('https://')) {
      return null;
    }

    try {
      return base64Decode(base64Value);
    } catch (_) {
      return null;
    }
  }

  void _showAttendancePhotoDialog(
    String label, {
    File? file,
    String? url,
  }) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1C2230),
        insetPadding: const EdgeInsets.all(18),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 520),
                child: InteractiveViewer(
                  child: _buildAttendanceImage(file: file, url: url),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeTrackingItem(
    String label,
    DateTime? time,
    IconData icon,
    String buttonText,
    VoidCallback onPressed, {
    bool? isEnabled,
    File? photo,
    Color? customButtonColor,
    Color? customTextColor,
    String? trailingText,
  }) {
    final isRecorded = time != null;
    final buttonEnabled = isEnabled ?? !isRecorded;

    // Use custom color if provided, else logic
    final isRedButton = buttonText.toLowerCase().contains("out") ||
        buttonText.toLowerCase().contains("end");

    final buttonColor = customButtonColor ?? (isRedButton ? Colors.red : green);
    final textColor = customTextColor ?? Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                trailingText ??
                    (time != null
                        ? _formatDeviceLocalTimeWithSeconds(time)
                        : "Time: 00:00:00"),
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: buttonEnabled ? onPressed : null,
              icon: Icon(
                buttonText == "Completed" ? Icons.check_circle : icon,
                size: 20,
                color: buttonEnabled ? textColor : null,
              ),
              label: Text(
                buttonText,
                style: TextStyle(
                  fontSize: 16,
                  color: buttonEnabled ? textColor : null,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonEnabled
                    ? buttonColor
                    : buttonColor.withValues(alpha: 0.4),
                foregroundColor: textColor,
                disabledForegroundColor: Colors.white.withValues(alpha: 0.6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakHistory() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(
                'Break History',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...breaks.map((breakItem) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(Icons.circle, color: Colors.white70, size: 8),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${DateFormat('hh:mm a').format(breakItem['start']!)} - ${DateFormat('hh:mm a').format(breakItem['end']!)}',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Used: ${_formatBreakDuration(
                        breakItem['end']!.difference(breakItem['start']!),
                      )}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
