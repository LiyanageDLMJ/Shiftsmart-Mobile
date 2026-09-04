import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_client.dart';

abstract class LocationService {
  Future<Position> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 10),
  });

  Future<bool> sendLocation(Position position, int employeeId);

  Future<void> startContinuousTracking({
    required int employeeId,
    Duration heartbeatInterval = const Duration(seconds: 45),
    void Function(Object error)? onError,
  });

  Future<void> stopTracking();
}

class RealLocationService implements LocationService {
  final ApiClient _apiClient = ApiClient();
  StreamSubscription<Position>? _positionSubscription;
  Timer? _heartbeatTimer;
  Position? _lastKnownPosition;
  bool _sendInProgress = false;

  @override
  Future<Position> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    // Added permission check safe-guard inside the service as well
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        timeLimit: timeout,
      ),
    );
  }

  @override
  Future<void> startContinuousTracking({
    required int employeeId,
    Duration heartbeatInterval = const Duration(seconds: 45),
    void Function(Object error)? onError,
  }) async {
    await stopTracking();

    try {
      final initialPosition = await getCurrentPosition();
      _lastKnownPosition = initialPosition;
      await _sendHeartbeat(employeeId, initialPosition);
    } catch (e) {
      debugPrint("Initial tracking location failed: $e");
      onError?.call(e);
    }

    final locationSettings = _trackingLocationSettings();

    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (position) async {
        _lastKnownPosition = position;
        await _sendHeartbeat(employeeId, position);
      },
      onError: (Object error) {
        debugPrint("Location tracking stream error: $error");
        onError?.call(error);
      },
    );

    _heartbeatTimer = Timer.periodic(heartbeatInterval, (_) async {
      try {
        final position = _lastKnownPosition ?? await getCurrentPosition();
        _lastKnownPosition = position;
        await _sendHeartbeat(employeeId, position);
      } catch (e) {
        debugPrint("Location heartbeat failed: $e");
        onError?.call(e);
      }
    });
  }

  @override
  Future<void> stopTracking() async {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _lastKnownPosition = null;
    _sendInProgress = false;
  }

  LocationSettings _trackingLocationSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        intervalDuration: const Duration(seconds: 30),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'ShiftSmart',
          notificationText: 'Shift location tracking is active',
          notificationChannelName: 'Shift Location Tracking',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    }

    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
  }

  Future<void> _sendHeartbeat(int employeeId, Position position) async {
    if (_sendInProgress) return;
    _sendInProgress = true;
    try {
      await sendLocation(position, employeeId);
    } finally {
      _sendInProgress = false;
    }
  }

  @override
  Future<bool> sendLocation(Position position, int employeeId) async {
    //  FIX: Use ATTENDANCE_BASE_URL because LOCATION_KEY belongs to the Attendance Function App
    final String baseUrl = dotenv.env['ATTENDANCE_BASE_URL'] ?? "";
    final String locationKey =
        dotenv.env['ATTENDANCE_LOCATION_UPDATE_KEY'] ?? "";

    final url = '$baseUrl/employee/location/update?code=$locationKey';

    try {
      final body = {
        "employeeId": employeeId,
        "latitude": position.latitude,
        "longitude": position.longitude,
        // "siteId": 0 // Optional: Backend handles it if missing
      };

      // Use ApiClient with Auth to send the Token
      final response = await _apiClient.post(
        url,
        body: body,
        useAuth: true,
      );

      if (response.statusCode == 200) {
        debugPrint(
            " Employee location updated: ${position.latitude}, ${position.longitude}");
        return true;
      } else {
        debugPrint(
            " Failed to update employee location: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Error sending location: $e");
      return false;
    }
  }
}
