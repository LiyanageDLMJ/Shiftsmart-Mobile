import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_client.dart';

abstract class LocationService {
  Future<Position> getCurrentPosition();
  Future<bool> sendLocation(Position position, int employeeId);
}

class RealLocationService implements LocationService {
  final ApiClient _apiClient = ApiClient();

  @override
  Future<Position> getCurrentPosition() async {
    // Added permission check safe-guard inside the service as well
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10), // Prevent freezing
    );
  }

  @override
  Future<bool> sendLocation(Position position, int employeeId) async {
    //  FIX: Use ATTENDANCE_BASE_URL because LOCATION_KEY belongs to the Attendance Function App
    final String baseUrl = dotenv.env['ATTENDANCE_BASE_URL'] ?? "";
    final String locationKey = dotenv.env['ATTENDANCE_LOCATION_UPDATE_KEY'] ?? "";

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
