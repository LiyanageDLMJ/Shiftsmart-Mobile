import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shiftsmart/models/project.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_client.dart';

class ProjectService {
  final ApiClient _apiClient = ApiClient();

  //  PROD ENDPOINT CONFIGURATION (from func-projects)
  final String baseUrl =
      dotenv.env['PROJECT_BASE_URL'] ?? dotenv.env['BASE_URL'] ?? "";

  //  PROD ENDPOINT KEYS (from func-projects)
  final String projectCreateKey = dotenv.env['PROJECT_CREATE_KEY'] ?? "";
  final String projectUpdateKey = dotenv.env['PROJECT_UPDATE_KEY'] ?? "";
  final String projectGetAllKey = dotenv.env['PROJECT_GET_ALL_KEY'] ?? "";
  final String projectDeleteKey = dotenv.env['PROJECT_DELETE_KEY'] ?? "";
  final String companyCreateKey = dotenv.env['COMPANY_CREATE_KEY'] ?? "";
  final String companyUpdateKey = dotenv.env['COMPANY_UPDATE_KEY'] ?? "";
  final String companyGetAllKey = dotenv.env['COMPANY_GET_ALL_KEY'] ?? "";
  final String companyDeleteKey = dotenv.env['COMPANY_DELETE_KEY'] ?? "";
  final String siteCreateKey = dotenv.env['SITE_CREATE_KEY'] ?? "";
  final String siteUpdateKey = dotenv.env['SITE_UPDATE_KEY'] ?? "";
  final String siteGetAllKey = dotenv.env['SITE_GET_ALL_KEY'] ?? "";
  final String siteGetByIdKey = dotenv.env['SITE_GET_BY_ID_KEY'] ?? "";
  final String siteDeleteKey = dotenv.env['SITE_DELETE_KEY'] ?? "";
  final String geofenceValidateKey = dotenv.env['GEOFENCE_VALIDATE_KEY'] ?? "";
  final String locationUpdateKey = dotenv.env['LOCATION_UPDATE_KEY'] ?? "";

  ProjectService() {
    if (baseUrl.isEmpty) {
      debugPrint(" ProjectService: PROJECT_BASE_URL is missing");
    }
  }

  // --- ADD PROJECT ---
  Future<bool> addProject(Map<String, dynamic> projectData) async {
    final String createUrl = '$baseUrl/project/create?code=$projectCreateKey';

    try {
      // FIX: Enable authentication for tenant context
      final response = await _apiClient.post(
        createUrl,
        body: projectData,
        useAuth: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        debugPrint('Failed to add project: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint("Error adding project: $e");
      return false;
    }
  }

  // --- UPDATE PROJECT ---
  Future<bool> updateProject(int id, Map<String, dynamic> projectData) async {
    final updateUrl = '$baseUrl/project/update/$id?code=$projectUpdateKey';
    projectData['ProjectId'] = id;

    try {
      // FIX: Enable authentication for tenant context
      final response = await _apiClient.put(
        updateUrl,
        body: projectData,
        useAuth: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        debugPrint(
            'Failed to update project: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint("Error updating project: $e");
      return false;
    }
  }

  // --- FETCH ALL PROJECTS ---
  Future<List<Project>> fetchAllProjects() async {
    final geturl = '$baseUrl/project/all?code=$projectGetAllKey';

    try {
      // FIX: Enable authentication for tenant context
      final response =
          await _apiClient.get(geturl, useAuth: true, showDialog: false);

      debugPrint("Project response: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData is List && jsonData.isNotEmpty) {
          return jsonData
              .map<Project>((data) => Project.fromJson(data))
              .toList();
        } else {
          debugPrint("Unexpected data format.");
          return [];
        }
      } else {
        debugPrint(
            "Failed to load projects. Status code: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error in fetchAllProjects: $e");
      return [];
    }
  }
}
