import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Kept only for image upload
import 'package:http_parser/http_parser.dart';
import 'package:shiftsmart/models/job.dart';
import 'package:shiftsmart/models/job_role.dart';
import 'package:shiftsmart/models/job_role_type.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_client.dart';

class JobService {
  // 1. Initialize ApiClient
  final ApiClient _apiClient = ApiClient();

  // Base URL may be from JOB_BASE_URL or a general base URL
  final String baseUrl =
      dotenv.env['JOB_BASE_URL'] ?? dotenv.env['BASE_URL'] ?? "";

  //  Endpoint keys (func-jobs)
  final String jobGetAllKey = dotenv.env['JOB_GET_ALL_KEY'] ?? "";
  final String jobCreateKey = dotenv.env['JOB_CREATE_KEY'] ?? "";
  final String jobUpdateKey = dotenv.env['JOB_UPDATE_KEY'] ?? "";
  final String jobDeleteKey = dotenv.env['JOB_DELETE_KEY'] ?? "";
  final String jobCompleteKey = dotenv.env['JOB_COMPLETE_KEY'] ?? "";
  final String jobImageKey = dotenv.env['JOB_IMAGE_UPLOAD_KEY'] ?? "";
  final String jobUpdateWithImageKey =
      dotenv.env['JOB_UPDATE_WITH_IMAGE_KEY'] ?? "";
  final String jobUploadWithImageKey =
      dotenv.env['JOB_UPLOAD_WITH_IMAGE_KEY'] ?? "";
  final String jobRoleTypeListKey = dotenv.env['JOBROLETYPE_LIST_KEY'] ?? "";
  final String jobRoleTypeCreateKey =
      dotenv.env['JOBROLETYPE_CREATE_KEY'] ?? "";
  final String jobRoleTypeDeleteKey =
      dotenv.env['JOBROLETYPE_DELETE_KEY'] ?? "";
  final String jobRoleBreakdownByJobKey =
      dotenv.env['JOBROLE_BREAKDOWN_KEY'] ?? "";

  JobService() {
    _debugEnv();
  }

  void _debugEnv() {
    if (baseUrl.isEmpty) debugPrint(" JobService: JOB_BASE_URL is missing");
    if (jobGetAllKey.isEmpty) {
      debugPrint(" JobService: JOB_GET_ALL_KEY is missing");
    }
    // ... adding more checks if needed, but the ?? "" is already safer
  }

  // --- FETCH ALL JOBS ---
  Future<List<Job>> fetchAllJobs() async {
    final geturl = '$baseUrl/job/list?code=$jobGetAllKey';
    try {
      // Re-enabling useAuth: true as per approved plan
      final response =
          await _apiClient.get(geturl, useAuth: true, showDialog: false);

      debugPrint("Job response status: ${response.statusCode}");
      debugPrint("Job response body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData is List) {
          if (jsonData.isNotEmpty) {
            return jsonData.map<Job>((data) => Job.fromJson(data)).toList();
          } else {
            debugPrint("Jobs list is empty from server.");
            return [];
          }
        } else {
          debugPrint("Unexpected data format: ${jsonData.runtimeType}");
          return [];
        }
      } else {
        debugPrint("Failed to load jobs. Status code: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error in fetchAllJobs: $e");
      return [];
    }
  }

  // --- ADD JOB (Data Only) ---
  Future<int?> addJob(Map<String, dynamic> jobData) async {
    if (jobCreateKey.isEmpty) {
      debugPrint(" JobService: JOB_CREATE_KEY is missing.");
      return null;
    }
    final url = '$baseUrl/job/create?code=$jobCreateKey';
    try {
      final response = await _apiClient.post(
        url,
        body: jobData,
        useAuth: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return 1;
      } else {
        // Change from 'return null;' to throw the actual error the backend sent
        final errorMessage = response.body.isNotEmpty
            ? response.body
            : "Status code: ${response.statusCode}";
        throw Exception(errorMessage);
      }
    } catch (e) {
      debugPrint("Error adding job data: $e");
      rethrow;
    }
  }

  // --- ADD JOB WITH IMAGE (Multipart Request) ---
  // Note: Multipart requests are special, so we manually add the token here.
  Future<bool> createJobWithImage(
      Map<String, dynamic> jobData, File image) async {
    final url =
        Uri.parse('$baseUrl/job/upload-with-image?code=$jobUploadWithImageKey');
    try {
      final validationError = ApiClient.validateUploadFiles(
        files: [image],
        maxFiles: 1,
        maxFileBytes: 10 * ApiClient.mb,
        maxRequestBytes: 15 * ApiClient.mb,
        allowPdf: false,
        fileLabel: 'Job image',
      );
      if (validationError != null) throw Exception(validationError);

      final request = http.MultipartRequest("POST", url);

      // FIX: Manually get token and add header
      final token = await _apiClient.getAppToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['job'] = jsonEncode(jobData);
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          image.path,
          contentType: MediaType.parse(
            ApiClient.uploadMimeType(image, allowPdf: false)!,
          ),
        ),
      );

      final response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        // Read the actual plain-text reason from the backend
        final respStr = await response.stream.bytesToString();
        final errorMessage = respStr.isNotEmpty
            ? respStr
            : "Status code: ${response.statusCode}";
        debugPrint("Failed to add job with image: $errorMessage");
        throw Exception(errorMessage); // Throw it so the UI catches it!
      }
    } catch (e) {
      debugPrint("Error occured while adding job with image $e");
      rethrow;
    }
  }

  // --- UPDATE JOB ---
  Future<bool> updateJob(int jobId, Map<String, dynamic> jobData) async {
    final url = '$baseUrl/job/update/$jobId?code=$jobUpdateKey';
    try {
      // FIX: Use ApiClient with useAuth: true
      final response = await _apiClient.put(
        url,
        body: jobData,
        useAuth: true,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint("Error updating job: $e");
      rethrow;
    }
  }

  // --- FETCH JOB ROLES ---
  Future<List<JobRole>> fetchJobRole(int jobId) async {
    final url = '$baseUrl/job/roles/$jobId?code=$jobRoleBreakdownByJobKey';
    try {
      // FIX: Use ApiClient with useAuth: true
      final response =
          await _apiClient.get(url, useAuth: true, showDialog: false);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final rolesData = _extractList(jsonData);
        return rolesData
            .whereType<Map<String, dynamic>>()
            .map((e) => JobRole.fromJson(e))
            .toList();
      } else {
        debugPrint("Failed to fetch job roles. Status: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error fetching job roles: $e");
      return [];
    }
  }

  // --- DELETE JOB ---
  Future<bool> deleteJob(int jobId) async {
    final url = '$baseUrl/job/delete/$jobId?code=$jobDeleteKey';
    try {
      final response = await _apiClient.delete(url, useAuth: true);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint("Error deleting job: $e");
      return false;
    }
  }

  // --- COMPLETE JOB ---
  Future<bool> completeJob(int jobId) async {
    final url = '$baseUrl/job/complete/$jobId?code=$jobCompleteKey';
    try {
      final response = await _apiClient.post(url, body: {}, useAuth: true);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint("Error completing job: $e");
      return false;
    }
  }

  // --- UPDATE JOB WITH IMAGE ---
  Future<bool> updateJobWithImage(
      int jobId, Map<String, dynamic> jobData, File image) async {
    if (jobUpdateWithImageKey.isEmpty) {
      throw Exception('JOB_UPDATE_WITH_IMAGE_KEY is missing.');
    }

    final payload = Map<String, dynamic>.from(jobData)
      ..['jobId'] = jobId
      ..['JobId'] = jobId;

    final endpoints = [
      Uri.parse(
        '$baseUrl/job/update-with-image/$jobId?code=$jobUpdateWithImageKey',
      ),
      Uri.parse(
        '$baseUrl/job/updatewithimage/$jobId?code=$jobUpdateWithImageKey',
      ),
    ];

    String lastError = '';

    for (final url in endpoints) {
      try {
        final validationError = ApiClient.validateUploadFiles(
          files: [image],
          maxFiles: 1,
          maxFileBytes: 10 * ApiClient.mb,
          maxRequestBytes: 15 * ApiClient.mb,
          allowPdf: false,
          fileLabel: 'Job image',
        );
        if (validationError != null) throw Exception(validationError);

        final request = http.MultipartRequest('PUT', url);

        final token = await _apiClient.getAppToken();
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }

        request.fields['job'] = jsonEncode(payload);
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            image.path,
            contentType: MediaType.parse(
              ApiClient.uploadMimeType(image, allowPdf: false)!,
            ),
          ),
        );

        final response = await request.send();
        final responseBody = await response.stream.bytesToString();

        if (response.statusCode == 200 ||
            response.statusCode == 201 ||
            response.statusCode == 204) {
          return true;
        }

        lastError = responseBody.isNotEmpty
            ? responseBody
            : 'Status code: ${response.statusCode}';
        debugPrint('Failed to update job with image: $lastError');

        if (response.statusCode != 404 && response.statusCode != 405) {
          break;
        }
      } catch (e) {
        lastError = e.toString();
        debugPrint('Error updating job with image: $e');
      }
    }

    throw Exception(
      lastError.isEmpty ? 'Failed to update job with image.' : lastError,
    );
  }

  // --- FETCH JOB ROLE TYPES ---
  Future<List<JobRoleType>> fetchJobRoleType() async {
    final url = '$baseUrl/jobroletype/list?code=$jobRoleTypeListKey';
    try {
      final response =
          await _apiClient.get(url, useAuth: true, showDialog: false);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final roleTypesData = _extractList(jsonData);
        return roleTypesData
            .whereType<Map<String, dynamic>>()
            .map((e) => JobRoleType.fromJson(e))
            .toList();
      } else {
        debugPrint(
            "Failed to fetch job role types. Status: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error fetching job role types: $e");
      return [];
    }
  }

  List<dynamic> _extractList(dynamic jsonData) {
    if (jsonData is List) return jsonData;
    if (jsonData is Map<String, dynamic>) {
      for (final key in ['data', 'items', 'results', 'value']) {
        final value = jsonData[key];
        if (value is List) return value;
      }
    }
    debugPrint("Unexpected list response format: ${jsonData.runtimeType}");
    return [];
  }

  // --- CREATE JOB ROLE TYPE ---
  Future<bool> createJobRoleType(Map<String, dynamic> data) async {
    final url = '$baseUrl/jobroletype/create?code=$jobRoleTypeCreateKey';
    try {
      final response = await _apiClient.post(url, body: data, useAuth: true);
      return response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204;
    } catch (e) {
      debugPrint("Error creating job role type: $e");
      return false;
    }
  }

  // --- DELETE JOB ROLE TYPE ---
  Future<bool> deleteJobRoleType(int id) async {
    final url = '$baseUrl/jobroletype/delete/$id?code=$jobRoleTypeDeleteKey';
    try {
      final response = await _apiClient.delete(url, useAuth: true);
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint("Error deleting job role type: $e");
      return false;
    }
  }
}
