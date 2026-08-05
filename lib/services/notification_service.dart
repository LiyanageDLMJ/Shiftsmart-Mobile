import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftsmart/models/notification.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_client.dart';

class NotificationService {
  static const String _defaultRegisterDeviceKey =
      '';
  static const String _defaultFirebaseProjectId = 'shift-smart-a34cb';
  static const MethodChannel _nativePushChannel =
      MethodChannel('shiftsmart/native_push');

  FirebaseMessaging get _firebaseMessaging => FirebaseMessaging.instance;
  final ApiClient _apiClient = ApiClient();
  static bool _listenersConfigured = false;
  static bool _deferredRegistrationInProgress = false;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String get baseUrl {
    final value = dotenv.env['NOTIFICATION_BASE_URL'] ?? '';
    if (value.isEmpty) {
      throw Exception('Missing NOTIFICATION_BASE_URL');
    }
    return value;
  }

  String get mainKey => dotenv.env['GET_NOTIFICATIONS_KEY'] ?? '';
  String get registerKey =>
      dotenv.env['REGISTER_DEVICE_KEY'] ?? _defaultRegisterDeviceKey;
  String get markReadKey => dotenv.env['MARK_NOTIFICATIONS_READ_KEY'] ?? '';
  String get listInstallationsKey => dotenv.env['LIST_INSTALLATIONS_KEY'] ?? '';
  String get approvalKey => dotenv.env['SEND_APPROVAL_NOTIFICATION_KEY'] ?? '';
  String get geofenceAlertKey => dotenv.env['SEND_GEOFENCE_ALERT_KEY'] ?? '';
  String get eventRouterKey =>
      dotenv.env['NOTIFICATION_EVENT_ROUTER_KEY'] ?? '';
  String get leaveApprovalKey =>
      dotenv.env['SEND_LEAVE_APPROVAL_NOTIFICATION_KEY'] ?? '';
  String get leaveRequestKey =>
      dotenv.env['SEND_LEAVE_REQUEST_NOTIFICATION_KEY'] ?? '';
  String get shiftKey => dotenv.env['SEND_SHIFT_NOTIFICATION_KEY'] ?? '';
  String get shiftCompleteKey =>
      dotenv.env['SEND_SHIFT_COMPLETED_NOTIFICATION_KEY'] ?? '';
  String get expectedFirebaseProjectId =>
      dotenv.env['EXPECTED_FIREBASE_PROJECT_ID'] ?? _defaultFirebaseProjectId;

  Future<void> initializeFCM({
    required int employeeId,
    required String userTag,
    void Function(RemoteMessage)? onForegroundMessage,
    void Function(RemoteMessage)? onNotificationOpenedApp,
  }) async {
    try {
      if (Firebase.apps.isEmpty) {
        debugPrint("FCM initialization skipped: Firebase is not initialized.");
        return;
      }

      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      await _initializeLocalNotifications();

      debugPrint('User granted permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint(
          "RegisterDevice not called: notification permission is denied.",
        );
        return;
      }

      if (!_isFirebaseProjectAligned()) {
        return;
      }

      if (employeeId == 0) {
        debugPrint("Device registration skipped for guest session.");
      } else {
        await _registerCurrentDevice(
          employeeId: employeeId,
          tag: userTag,
          allowDeferredRetry: true,
        );
      }

      if (!_listenersConfigured) {
        _listenersConfigured = true;

        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint("Foreground Message Received: ${message.data}");

          String? title;
          String? body;

          if (message.notification != null) {
            title = message.notification?.title;
            body = message.notification?.body;
          } else if (message.data.containsKey('shiftDetails')) {
            title = "New Shift Assigned";
            body = message.data['shiftDetails'];
          } else if (message.data.containsKey('completionDetails')) {
            title = "Shift Completed";
            body = message.data['completionDetails'];
          } else if (message.data.containsKey('status') ||
              message.data.containsKey('Status')) {
            title = "Leave Update";
            body =
                "Your leave request is ${message.data['status'] ?? message.data['Status']}";
          } else if (message.data.containsKey('type')) {
  final type = message.data['type']?.toString();
  title = _titleForMessageType(type);

  if (type == 'shift_assignment') {
    body = message.data['body'] ??
        message.data['message'] ??
        message.data['details'] ??
        message.data['shiftDetails'] ??
        'You have been assigned a new shift.';
  } else {
    body = message.data['body'] ??
        message.data['message'] ??
        message.data['details'] ??
        message.data['shiftDetails'];
  }
}

          if (title != null && body != null) {
            _localNotifications.show(
              message.hashCode,
              title,
              body,
              const NotificationDetails(
                android: AndroidNotificationDetails(
                  'high_importance_channel',
                  'High Importance Notifications',
                  channelDescription: 'Used for important notifications',
                  importance: Importance.max,
                  priority: Priority.high,
                  icon: '@mipmap/ic_launcher',
                ),
              ),
            );
          }

          if (onForegroundMessage != null) onForegroundMessage(message);
        });

        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          debugPrint("Notification tapped (Opened from Background)");
          if (onNotificationOpenedApp != null) onNotificationOpenedApp(message);
        });
      }
    } catch (e) {
      debugPrint("FCM Initialization error: $e");
    }
  }

  Future<void> registerDeviceTokenToBackend({
    required String token,
    required int employeeId,
    required String tag,
  }) async {
    if (registerKey.isEmpty) {
      debugPrint("Missing REGISTER_DEVICE_KEY");
      return;
    }

    final url = _buildUrl('RegisterDevice', registerKey);
    final body = {
      "EmployeeId": employeeId,
      "DeviceToken": token,
      "Platform": _registrationPlatform,
      "Tag": tag,
    };

    try {
      debugPrint(
        "RegisterDevice payload: EmployeeId=$employeeId, "
        "Platform=$_registrationPlatform, Tag=$tag, DeviceTokenPresent=${token.isNotEmpty}",
      );
      final response = await _apiClient.post(url, body: body, useAuth: true);

      if (response.statusCode == 200) {
        debugPrint("Device registered successfully");
      } else {
        debugPrint(
            "Register failed: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      debugPrint("Device registration error: $e");
    }
  }

  Future<List<NotificationItem>> fetchNotificationsread(
    int employeeId, {
    int? tenantId,
  }) async {
    return _fetchNotifications(
      employeeId: employeeId,
      status: 'read',
      tenantId: tenantId,
    );
  }

  Future<List<NotificationItem>> fetchNotificationsUnread(
    int employeeId, {
    int? tenantId,
  }) async {
    return _fetchNotifications(
      employeeId: employeeId,
      status: 'unread',
      tenantId: tenantId,
    );
  }

  Future<List<NotificationItem>> _fetchNotifications({
    required int employeeId,
    required String status,
    int? tenantId,
  }) async {
    if (mainKey.isEmpty) throw Exception("Missing NOTIFI_MAIN_KEY");
    final resolvedTenantId = await resolveCurrentTenantId(tenantId: tenantId);

    final Map<String, String> queryParams = {
      'code': mainKey,
      'employeeId': employeeId.toString(),
      'status': status,
    };
    if (resolvedTenantId != null && resolvedTenantId != 0) {
      queryParams['tenantId'] = resolvedTenantId.toString();
    }

    final uri = Uri.parse('$baseUrl/notifications')
        .replace(queryParameters: queryParams);

    final response = await _apiClient.get(uri.toString(), useAuth: true);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final notifications =
          data['notifications'] ?? data['Notifications'] ?? [];
      final List<NotificationItem> items = [];
      for (var n in notifications) {
        if (n is Map<String, dynamic>) {
          items.add(NotificationItem.fromJson(n));
        } else if (n is Map) {
          items.add(NotificationItem.fromJson(Map<String, dynamic>.from(n)));
        }
      }
      if (resolvedTenantId != null && resolvedTenantId != 0) {
        items.removeWhere((item) =>
            item.tenantId != null &&
            item.tenantId != 0 &&
            item.tenantId != resolvedTenantId);
      }
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    } else {
      throw Exception('Failed to fetch notifications: ${response.statusCode}');
    }
  }

  Future<int?> resolveCurrentTenantId({int? tenantId}) async {
    if (tenantId != null && tenantId != 0) return tenantId;

    final prefs = await SharedPreferences.getInstance();
    final savedTenantId = prefs.getInt('selectedTenantId') ??
        prefs.getInt('currentTenantId') ??
        prefs.getInt('tenantId');
    if (savedTenantId != null && savedTenantId != 0) return savedTenantId;

    final token = await _apiClient.getAppToken();
    if (token == null || token.isEmpty) return null;

    final payload = _apiClient.decodeJwt(token);
    if (payload == null) return null;

    return _intFromAny(
      payload['tenantId'] ??
          payload['TenantId'] ??
          payload['tenantID'] ??
          payload['TenantID'] ??
          payload['tenant_id'],
    );
  }

  int? _intFromAny(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  Future<void> markAsRead(List<int> notificationIds) async {
    if (markReadKey.isEmpty) throw Exception("Missing NOTIFI_MARK_READ_KEY");

    final url = _buildUrl('notifications/mark-read', markReadKey);

    final response = await _apiClient.post(
      url,
      body: {"NotificationIds": notificationIds},
      useAuth: true,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark notifications as read');
    }
  }

  Future<void> sendShiftNotification(
      int employeeId, String shiftDetails) async {
    if (shiftKey.isEmpty) {
      debugPrint("Missing NOTIFI_SHIFT_KEY");
      return;
    }

    final url = _buildUrl('notifications/shift-assignment', shiftKey);

    final payload = {
      "userTag": "user_$employeeId",
      "shiftDetails": shiftDetails,
    };

    try {
      final response = await _apiClient.post(url, body: payload, useAuth: true);
      if (response.statusCode == 200) {
        debugPrint("Notification sent to user_$employeeId");
      } else if (response.statusCode == 404) {
        debugPrint(
            "Notification not sent: user_$employeeId has no registered device.");
      } else {
        debugPrint("Failed to send notification: ${response.body}");
      }
    } catch (e) {
      debugPrint("Notification sending error: $e");
    }
  }

  Future<void> sendLeaveRequeststoManager(int employeeId, String? leaveType,
      String startDate, String endDate, String reason) async {
    if (leaveRequestKey.isEmpty) {
      debugPrint("Missing NOTIFI_LEAVE_REQUEST_KEY");
      return;
    }

    final url = _buildUrl('notifications/leave-request', leaveRequestKey);

    final body = {
      "EmployeeId": employeeId,
      "LeaveType": leaveType,
      "StartDate": startDate,
      "EndDate": endDate,
      "Reason": reason,
    };

    try {
      final response = await _apiClient.post(url, body: body, useAuth: true);
      if (response.statusCode == 200) {
        debugPrint("Leave request notification sent");
      } else {
        debugPrint("Failed to send leave request: ${response.body}");
      }
    } catch (e) {
      debugPrint("Error sending leave request: $e");
    }
  }

  Future<void> leaveNotification(int id, String newStatus) async {
    if (leaveApprovalKey.isEmpty) {
      debugPrint("Missing NOTIFI_LEAVE_APPROVAL_KEY");
      return;
    }

    final url = _buildUrl('notifications/leave-status', leaveApprovalKey);
    final body = {"EmployeeId": id, "Status": newStatus};

    try {
      final response = await _apiClient.post(url, body: body, useAuth: true);
      if (response.statusCode == 200) {
        debugPrint("Leave $newStatus notification sent");
      } else if (response.statusCode == 404) {
        debugPrint("Notification not sent: Employee has no registered device.");
      } else {
        debugPrint(
            "Failed to send notification: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      debugPrint("Warning: Error sending leave notification: $e");
    }
  }

  Future<void> sendShiftCompletionNotification(
    String? employeeName,
    int shiftId,
    DateTime clockOutTime,
  ) async {
    if (shiftCompleteKey.isEmpty) {
      debugPrint("Missing NOTIFI_SHIFT_COMPLETE_KEY");
      return;
    }

    final url = _buildUrl('notifications/shift-completed', shiftCompleteKey);

    final formattedTime =
        DateFormat('h:mma').format(clockOutTime).toLowerCase();
    final message = "$employeeName completed shift #$shiftId at $formattedTime";
    final body = {"completionDetails": message};

    try {
      final response = await _apiClient.post(url, body: body, useAuth: true);
      if (response.statusCode == 200) {
        debugPrint("Notification sent: $message");
      } else {
        throw Exception("Failed to send notification: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error sending shift completion notification: $e");
    }
  }

  Future<void> sendEmergencyNotification(
    String? employeeName,
    int shiftId,
    String? reason,
    DateTime clockOutTime,
  ) async {
    if (geofenceAlertKey.isEmpty) {
      debugPrint("Missing SEND_GEOFENCE_ALERT_KEY");
      return;
    }

    final url = _buildUrl('alerts/geofence', geofenceAlertKey);

    final formattedTime =
        DateFormat('h:mma').format(clockOutTime).toLowerCase();
    final message =
        "EMERGENCY: $employeeName clocked out early from shift #$shiftId at $formattedTime. Reason: ${reason ?? 'Not provided'}";
    final prefs = await SharedPreferences.getInstance();
    final employeeId = prefs.getInt('employeeId') ?? prefs.getInt('userId');
    if (employeeId == null) {
      debugPrint("Geofence alert skipped: employeeId is not available.");
      return;
    }

    final body = {
      "EmployeeId": employeeId,
      "Status": "early_clockout",
      "Message": message,
    };

    try {
      final response = await _apiClient.post(url, body: body, useAuth: true);
      if (response.statusCode == 200) {
        debugPrint("Emergency notification sent: $message");
      } else {
        throw Exception("Failed to send notification: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error sending emergency notification: $e");
    }
  }

  Future<dynamic> listInstallations() async {
    if (listInstallationsKey.isEmpty) {
      throw Exception("Missing LIST_INSTALLATIONS_KEY");
    }

    final url = _buildUrl('installations/all', listInstallationsKey);
    final response = await _apiClient.get(url, useAuth: true);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }

    throw Exception('Failed to list installations: ${response.statusCode}');
  }

  Future<void> sendApprovalNotification({
    required int employeeId,
    required String status,
    String? message,
  }) async {
    if (approvalKey.isEmpty) {
      debugPrint("Missing SEND_APPROVAL_NOTIFICATION_KEY");
      return;
    }

    final url = _buildUrl('notifications/approval', approvalKey);
    final body = {
      "EmployeeId": employeeId,
      "Status": status,
      if (message != null && message.isNotEmpty) "Message": message,
    };

    final response = await _apiClient.post(url, body: body, useAuth: true);
    if (response.statusCode != 200) {
      throw Exception(
          'Failed to send approval notification: ${response.statusCode}');
    }
  }

  Future<void> routeNotificationEvent(Map<String, dynamic> payload) async {
    if (eventRouterKey.isEmpty) {
      debugPrint("Missing NOTIFICATION_EVENT_ROUTER_KEY");
      return;
    }

    final url = _buildUrl('notifications/route', eventRouterKey);
    final response = await _apiClient.post(url, body: payload, useAuth: true);
    if (response.statusCode != 200) {
      throw Exception('Failed to route notification: ${response.statusCode}');
    }
  }

  bool _isFirebaseProjectAligned() {
    final actualProjectId = Firebase.app().options.projectId;
    final actualSenderId = Firebase.app().options.messagingSenderId;

    debugPrint(
      "Firebase project: $actualProjectId, sender: $actualSenderId",
    );

    if (expectedFirebaseProjectId.isEmpty ||
        actualProjectId == expectedFirebaseProjectId) {
      return true;
    }

    debugPrint(
      "Firebase project mismatch. Expected $expectedFirebaseProjectId but "
      "mobile config loaded $actualProjectId. Device token registration skipped.",
    );
    return false;
  }

  String get _registrationPlatform => 'fcm';

  Future<void> _registerCurrentDevice({
    required int employeeId,
    required String tag,
    required bool allowDeferredRetry,
  }) async {
    final token = await _getDeviceTokenForRegistration();
    if (token == null) {
      if (allowDeferredRetry) {
        _scheduleDeferredDeviceRegistration(employeeId: employeeId, tag: tag);
      }
      return;
    }

    debugPrint(
      "Push token ready for $_registrationPlatform registration.",
    );
    await registerDeviceTokenToBackend(
      token: token,
      employeeId: employeeId,
      tag: tag,
    );
  }

  void _scheduleDeferredDeviceRegistration({
    required int employeeId,
    required String tag,
  }) {
    if (_deferredRegistrationInProgress) return;

    _deferredRegistrationInProgress = true;
    Future<void>(() async {
      for (var attempt = 1; attempt <= 12; attempt++) {
        await Future.delayed(const Duration(seconds: 5));
        debugPrint(
          "Retrying device registration... attempt $attempt/12",
        );

        final token = await _getDeviceTokenForRegistration(maxAttempts: 1);
        if (token == null) continue;

        await registerDeviceTokenToBackend(
          token: token,
          employeeId: employeeId,
          tag: tag,
        );
        _deferredRegistrationInProgress = false;
        return;
      }

      _deferredRegistrationInProgress = false;
      debugPrint(
        "Device registration skipped: push token was not ready after retry window.",
      );
    });
  }

  Future<String?> _getDeviceTokenForRegistration({int maxAttempts = 5}) async {
    if (Platform.isIOS || Platform.isMacOS) {
      final apnsToken =
          await _getApnsTokenForRegistration(maxAttempts: maxAttempts);
      if (apnsToken == null) return null;
    }

    return _getFcmTokenForRegistration();
  }

  Future<String?> _getFcmTokenForRegistration() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token == null || token.isEmpty) {
        debugPrint("RegisterDevice not called: FCM token is null.");
        return null;
      }
      return token;
    } on FirebaseException catch (e) {
      debugPrint(
        "RegisterDevice not called: FCM token error "
        "${e.plugin}/${e.code} - ${e.message}",
      );
      return null;
    } catch (e) {
      debugPrint("RegisterDevice not called: FCM token error $e");
      return null;
    }
  }

  Future<String?> _getApnsTokenForRegistration({int maxAttempts = 5}) async {
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final apnsToken = await _getApnsToken();
        if (apnsToken != null && apnsToken.isNotEmpty) {
          debugPrint("APNS token ready.");
          return apnsToken;
        }
      } on FirebaseException catch (e) {
        debugPrint(
          "APNS token error ${e.plugin}/${e.code} - ${e.message}",
        );
      } catch (e) {
        debugPrint("APNS token error $e");
      }

      debugPrint("Waiting for APNS token... attempt $attempt/$maxAttempts");
      await Future.delayed(const Duration(seconds: 1));
    }

    debugPrint("RegisterDevice not called: APNS token is not ready.");
    return null;
  }

  Future<String?> _getApnsToken() async {
    final nativeToken = await _getNativeApnsToken();
    if (nativeToken != null && nativeToken.isNotEmpty) {
      return nativeToken;
    }

    return _firebaseMessaging.getAPNSToken();
  }

  Future<String?> _getNativeApnsToken() async {
    try {
      final token = await _nativePushChannel.invokeMethod<String>(
        'getApnsToken',
      );
      if (token == null || token.isEmpty) return null;
      return token;
    } on MissingPluginException {
      return null;
    } catch (e) {
      debugPrint("Native APNS token lookup error: $e");
      return null;
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _localNotifications.initialize(settings);
  }

  String _titleForMessageType(String? type) {
    switch (type) {
      case 'shift_assignment':
        return 'Shift Assigned';
      case 'shift_completed':
        return 'Shift Completed';
      case 'leave_request':
        return 'New Leave Request';
      case 'leave_status':
        return 'Leave Request Status';
      case 'shift_response':
        return 'Shift Response';
      case 'shift_updated':
        return 'Shift Updated';
      case 'shift_incomplete':
        return 'Incomplete Shift Alert';
      case 'onboarding_complete':
        return 'Onboarding Complete';
      default:
        return 'Notification';
    }
  }

  String _buildUrl(String path, String key) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
    return '$normalizedBase/$normalizedPath?code=$key';
  }
}
