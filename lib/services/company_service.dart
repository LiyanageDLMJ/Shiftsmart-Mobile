import 'dart:convert';
import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http; // Removed: We use ApiClient now
import 'package:shiftsmart/models/company.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_client.dart'; // Import ApiClient

class CompanyService {
  final ApiClient _apiClient = ApiClient(); // 1. Initialize ApiClient

  //  PROD Endpoints from func-projects
  final String baseUrl = dotenv.env['PROJECT_BASE_URL'] ?? dotenv.env['BASE_URL'] ?? "";
  final String addCompanyKey = dotenv.env['COMPANY_CREATE_KEY'] ?? "";
  final String updateCompanyKey = dotenv.env['COMPANY_UPDATE_KEY'] ?? "";
  final String fetchCompanyKey = dotenv.env['COMPANY_GET_ALL_KEY'] ?? "";
  final String deleteCompanyKey = dotenv.env['COMPANY_DELETE_KEY'] ?? "";

  CompanyService() {
    if (baseUrl.isEmpty) debugPrint(" CompanyService: PROJECT_BASE_URL is missing");
  }

  // --- ADD COMPANY ---
  Future<bool> addCompany(Map<String, dynamic> companyData) async {
    final String url = '$baseUrl/company/create?code=$addCompanyKey';

    try {
      // FIX: Use ApiClient with useAuth: false (JWT crashes on backend)
      final response = await _apiClient.post(
        url,
        body: companyData,
        useAuth: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        debugPrint('Failed to add company: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint("Error adding company: $e");
      return false;
    }
  }

  // --- UPDATE COMPANY ---
  Future<bool> updateCompany(int id, Map<String, dynamic> companyData) async {
    final String updateUrl =
        '$baseUrl/company/update/$id?code=$updateCompanyKey';

    // Ensure ID is in the body if required by backend
    companyData['CompanyId'] = id;

    try {
      // FIX: Use ApiClient with useAuth: false
      final response = await _apiClient.put(
        updateUrl,
        body: companyData,
        useAuth: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        debugPrint('Failed to update company: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error updating company: $e');
      return false;
    }
  }

  // --- FETCH COMPANIES ---
  Future<List<Company>> fetchCompanies() async {
    final String url = '$baseUrl/company/all?code=$fetchCompanyKey';

    try {
      final response = await _apiClient.get(url, useAuth: true, showDialog: false);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return jsonData.map((e) => Company.fromJson(e)).toList();
      } else {
        // Log the actual error from the server
        debugPrint(
            "Failed to fetch companies: ${response.statusCode} - ${response.body}");
        throw Exception("Failed to fetch companies");
      }
    } catch (e) {
      debugPrint("Error fetching company data: $e");
      // Return empty list instead of crashing app
      return [];
    }
  }

  // --- DELETE COMPANY ---
  Future<bool> deleteCompany(int id) async {
    final String url = '$baseUrl/company/delete/$id?code=$deleteCompanyKey';
    try {
      final response = await _apiClient.delete(url, useAuth: true);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Error deleting company: $e");
      return false;
    }
  }
}
