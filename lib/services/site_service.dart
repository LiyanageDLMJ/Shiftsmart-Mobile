import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shiftsmart/models/site.dart';
import 'package:shiftsmart/models/site_employee.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_client.dart';

class SiteService {
  final ApiClient _apiClient = ApiClient();

  //  PROD ENDPOINT CONFIGURATION (from func-projects)
  final String baseUrl =
      dotenv.env['PROJECT_BASE_URL'] ?? dotenv.env['BASE_URL'] ?? "";
  final String attendanceBaseUrl = dotenv.env['ATTENDANCE_BASE_URL'] ?? "";

  //  PROD ENDPOINT KEYS (from func-projects)
  final String siteCreateKey = dotenv.env['SITE_CREATE_KEY'] ?? "";
  final String siteUpdateKey = dotenv.env['SITE_UPDATE_KEY'] ?? "";
  final String siteGetAllKey = dotenv.env['SITE_GET_ALL_KEY'] ?? "";
  final String siteGetByIdKey = dotenv.env['SITE_GET_BY_ID_KEY'] ?? "";
  final String siteDeleteKey = dotenv.env['SITE_DELETE_KEY'] ?? "";
  final String siteEmployeeLocationsKey =
      dotenv.env['SITE_EMPLOYEE_LOCATIONS_KEY'] ?? "";
  final String activeLocationsBySiteKey =
      dotenv.env['ACTIVE_LOCATIONS_BY_SITE_KEY'] ?? "";

  SiteService() {
    if (baseUrl.isEmpty) {
      debugPrint(" SiteService: PROJECT_BASE_URL is missing");
    }
  }

  // --- ADD SITE ---
  // inside SiteService.dart

  Future<bool> addSite(Map<String, dynamic> siteData) async {
    final String url = '$baseUrl/site/create?code=$siteCreateKey';

    try {
      debugPrint("POST Request to: $url");
      debugPrint("Body: $siteData");

      final response = await _apiClient.post(
        url,
        body: siteData, // ApiClient handles jsonEncode
        useAuth: true,
      );

      debugPrint("Response Status: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        // Logic to show error message
        return false;
      }
    } catch (e) {
      debugPrint("Error adding site: $e");
      return false;
    }
  }

  // --- UPDATE SITE ---
  // --- UPDATE SITE ---
  Future<bool> updateSite(int id, Map<String, dynamic> siteData) async {
    final updateUrl = '$baseUrl/site/update/$id?code=$siteUpdateKey';

    // FIX 1: Send the exact capitalized key expected by your C# backend
    siteData['SiteId'] = id;

    try {
      final response = await _apiClient.put(
        updateUrl,
        body: siteData,
        // FIX 2: Set useAuth to true so AuthGuard won't reject the request
        useAuth: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        debugPrint(
            'Failed to update site: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint("Error updating site: $e");
      return false;
    }
  }

  // --- FETCH SITE BY ID (THE FIX) ---
  // Updated to return a Site object directly
  Future<Site?> fetchSiteById(int siteId) async {
    try {
      final url = '$baseUrl/site/$siteId?code=$siteGetByIdKey';

      final response = await _apiClient.get(url, useAuth: true);

      if (response.statusCode == 200) {
        final siteData = _extractMap(jsonDecode(response.body));
        return siteData == null ? null : Site.fromJson(siteData);
      } else {
        debugPrint("Failed to fetch site: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("Error fetching site: $e");
      return null;
    }
  }

  // --- FETCH ALL SITES (Restricted to Managers) ---
  Future<List<Site>> fetchAllSites() async {
    final url = '$baseUrl/site/all?code=$siteGetAllKey';
    debugPrint(" SiteService: Fetching all sites from $url");

    try {
      final response =
          await _apiClient.get(url, useAuth: true, showDialog: false);
      debugPrint(" SiteService Status: ${response.statusCode}");
      debugPrint(
          " SiteService Body Snippet: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = _extractList(jsonDecode(response.body));
        debugPrint(" SiteService: Found ${jsonData.length} sites.");
        return jsonData
            .whereType<Map>()
            .map((e) => Site.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      } else {
        debugPrint(
            " SiteService: Failed to load sites. Status: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint(" SiteService: Exception fetching sites: $e");
      return [];
    }
  }

  Map<String, dynamic>? _extractMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      for (final key in const ['site', 'Site', 'data', 'Data', 'value', 'Value']) {
        final nested = data[key];
        if (nested is Map<String, dynamic>) return nested;
        if (nested is Map) return Map<String, dynamic>.from(nested);
      }
      return data;
    }
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  List<dynamic> _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      for (final key in const [
        'sites',
        'Sites',
        'data',
        'Data',
        'items',
        'Items',
        'value',
        'Value',
      ]) {
        final nested = data[key];
        if (nested is List) return nested;
      }
    }
    return const [];
  }

  // --- FETCH EMPLOYEES IN SITE ---
  Future<List<SiteEmployee>> fetchEmployeesInSite(int siteId, Site site) async {
    // 1. Use ATTENDANCE_BASE_URL
    // 2. Use the endpoint "/active/locations" (matches Web Portal)
    final url =
        '$attendanceBaseUrl/site/$siteId/active/locations?code=$activeLocationsBySiteKey';

    debugPrint(" Fetching Active Locations: $url");

    try {
      final response = await _apiClient.get(url, useAuth: true);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);

        debugPrint(" Active Employees Data: $jsonData");

        return jsonData
            .map((e) => SiteEmployee.fromJson(e, site))
            .where((e) => e.clockInLat != null && e.clockInLng != null)
            .toList();
      } else {
        debugPrint(
            " Failed to load employees: ${response.statusCode} | Body: ${response.body}");
        return [];
      }
    } catch (e) {
      debugPrint(" Error fetching employees: $e");
      return [];
    }
  }

  // --- DELETE SITE ---
  Future<bool> deleteSite(int id) async {
    final url = '$baseUrl/site/delete/$id?code=$siteDeleteKey';
    try {
      final response = await _apiClient.delete(url, useAuth: true);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error deleting site: $e");
      return false;
    }
  }
}
