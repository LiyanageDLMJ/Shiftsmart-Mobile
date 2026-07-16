import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shiftsmart/models/attendance.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_client.dart'; // Import ApiClient

class AttendanceReportService {
  final ApiClient _apiClient = ApiClient(); // Initialize ApiClient

  final String baseUrl = dotenv.env['ATTENDANCE_BASE_URL'] ?? "";
  String attendanceKey = dotenv.env['ATTENDANCE_GET_ALL_KEY'] ?? "";

  Future<List<Attendance>> fetchAttendanceData() async {
    final url = '$baseUrl/attendance/all?code=$attendanceKey';
    try {
      // FIX: Use ApiClient with useAuth: true
      final response = await _apiClient.get(url, useAuth: true);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((e) => Attendance.fromJson(e)).toList();
      } else {
        throw Exception(
            "Failed to fetch attendance data: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching attendance data: $e");
      rethrow;
    }
  }
}
