import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shiftsmart/models/report_employee.dart';
import 'package:shiftsmart/models/weekly_report_employee.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_client.dart';

class PerformanceReportService {
  final ApiClient _apiClient = ApiClient();
  final String baseUrl = dotenv.env['REPORT_BASE_URL'] ?? "";

  // Load Keys safely
  String get weeklyKey => dotenv.env['REPORT_GENERATE_WEEKLY_KEY'] ?? '';
  String get dateRangeKey => dotenv.env['REPORT_GENERATE_DATERANGE_KEY'] ?? '';
  String get overallKey => dotenv.env['REPORT_GENERATE_KEY'] ?? '';

  // === 1. OVERALL REPORT (By Employee ID) ===
  Future<ReportEmployee> generateReport({required int employeeId}) async {
    // Endpoint: /report/by-employee/{id}
    final url = '$baseUrl/report/by-employee/$employeeId?code=$overallKey';

    debugPrint("Attempting to GET Overall Report: $url");

    try {
      // Use ApiClient to send Bearer Token
      final response = await _apiClient.get(url, useAuth: true);

      if (response.statusCode == 200) {
        if (response.body.isEmpty) throw Exception("Empty response");

        return ReportEmployee.fromJson(jsonDecode(response.body));
      } else {
        debugPrint("Report failed: ${response.statusCode} - ${response.body}");
        throw Exception("Failed to load report");
      }
    } catch (e) {
      debugPrint("Error generating overall report: $e");
      rethrow;
    }
  }

  // === 2. WEEKLY REPORT ===
  Future<WeeklyReportEmployee> generateWeeklyReport(
      {required int employeeId}) async {
    // Endpoint: /report/weekly/{id}
    final url = '$baseUrl/report/weekly/$employeeId?code=$weeklyKey';

    debugPrint("Attempting to GET Weekly Report: $url");

    try {
      final response = await _apiClient.get(url, useAuth: true);

      if (response.statusCode == 200) {
        if (response.body.isEmpty || response.body == "null") {
          throw Exception("No weekly data found.");
        }
        return WeeklyReportEmployee.fromJson(jsonDecode(response.body));
      } else {
        debugPrint("Weekly report failed: ${response.statusCode}");
        throw Exception("Failed to fetch weekly report");
      }
    } catch (e) {
      debugPrint("Error generating weekly report: $e");
      rethrow;
    }
  }

  // === 3. DATE RANGE REPORT ===
  Future<WeeklyReportEmployee> generateDateRangeReport({
    required int employeeId,
    required String startDate,
    required String endDate,
  }) async {
    // Endpoint: /report/daterange/{id}/{start}/{end}
    // Note: We use dateRangeKey (mASW...) here, not the generic fetch key
    final url =
        '$baseUrl/report/daterange/$employeeId/$startDate/$endDate?code=$dateRangeKey';

    debugPrint("Attempting to GET Date Range Report: $url");

    try {
      final response = await _apiClient.get(url, useAuth: true);

      if (response.statusCode == 200) {
        if (response.body.isEmpty || response.body == "null") {
          throw Exception("No data found for date range.");
        }
        return WeeklyReportEmployee.fromJson(jsonDecode(response.body));
      } else {
        debugPrint("Date range report failed: ${response.statusCode}");
        throw Exception("Failed to fetch date range report");
      }
    } catch (e) {
      debugPrint("Error generating date range report: $e");
      rethrow;
    }
  }
}
