import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shiftsmart/models/employee.dart';
import 'package:shiftsmart/models/empcert_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_client.dart';
import 'package:shiftsmart/utils/date_time_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmployeeService {
  final ApiClient _apiClient = ApiClient();

  // --- Environment Variables ---
  final String baseUrl = dotenv.env['BASE_URL'] ?? "";
  final String certBaseUrl = dotenv.env['CERT_BASE_URL'] ?? "";

  //  PROD ENDPOINT KEYS (from func-employees)
  final String fetchEmpKey = dotenv.env['FETCH_EMP_KEY'] ?? "";
  final String bankLookupKey = dotenv.env['BANK_LOOKUP_KEY'] ?? '';
  final String empNameMap =
      dotenv.env['FETCH_EMP_KEY'] ?? ""; // Map to FETCH_EMP_KEY as fallback
  final String fetchDocsKey = dotenv.env['EMPLOYEE_DOC_GET_BY_ID_KEY'] ??
      ''; // Updated to use specific key
  final String certificateAddKey = dotenv.env['CERTIFICATE_ADD_KEY'] ?? '';
  final String certificateDeleteKey =
      dotenv.env['CERTIFICATE_DELETE_KEY'] ?? '';
  final String certificateUpdateKey =
      dotenv.env['CERTIFICATE_UPDATE_KEY'] ?? '';
  final String certificateGetKey = dotenv.env['CERTIFICATE_GET_KEY'] ?? '';

  EmployeeService() {
    if (baseUrl.isEmpty) debugPrint(" EmployeeService: BASE_URL is missing");
  }

  // --- 1. Fetch All Employees ---
  Future<List<Employee>> fetchAllEmployees(
      {bool includeAdminsAndManagers = false}) async {
    final url = '$baseUrl/employee/all?code=$fetchEmpKey';
    debugPrint(" EmployeeService: Fetching all employees from $url");
    try {
      final response =
          await _apiClient.get(url, useAuth: true, showDialog: false);
      debugPrint(" EmployeeService Status: ${response.statusCode}");
      debugPrint(
          " EmployeeService Body: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        debugPrint(" EmployeeService: Found ${jsonData.length} employees.");

        if (!includeAdminsAndManagers) {
          final filtered = jsonData.where((e) {
            final role = (e['userRole'] ?? '').toString().toLowerCase();
            return role != 'manager' && role != 'admin';
          }).toList();
          return filtered.map((e) => Employee.fromJson(e)).toList();
        }

        return jsonData.map((e) => Employee.fromJson(e)).toList();
      } else {
        debugPrint("Failed to load employees: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint("Error fetching employees: $e");
      return [];
    }
  }

  // --- 2. Fetch Employee Name Map ---
  Future<Map<int, String>> fetchEmployeeNameMap() async {
    final url = '$baseUrl/employee/all?code=$empNameMap';
    try {
      final response =
          await _apiClient.get(url, useAuth: true, showDialog: false);
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        return {
          for (var e in jsonData)
            (e['employeeId'] as num).toInt():
                _buildFullName(e['firstName'], e['middleName'], e['lastName']),
        };
      } else {
        debugPrint("Failed to load employee name map: ${response.statusCode}");
        return {};
      }
    } catch (e) {
      debugPrint("Error fetching employee name map: $e");
      return {};
    }
  }

  String _buildFullName(dynamic first, dynamic middle, dynamic last) {
    final firstName = first?.toString().trim() ?? '';
    final middleName = middle?.toString().trim() ?? '';
    final lastName = last?.toString().trim() ?? '';
    return [firstName, middleName.isNotEmpty ? middleName : lastName]
        .where((part) => part.isNotEmpty)
        .join(' ');
  }

  // --- 3. Bank Lookup ---
  Future<Map<String, dynamic>> lookupBank(String bsb) async {
    final String url = '$baseUrl/utility/bank-lookup/$bsb?code=$bankLookupKey';
    debugPrint(" Calling Bank Lookup: $url");

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('appToken');

      Map<String, String> headers = {'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      } else {
        debugPrint(
            " Warning: No Auth Token found locally. Attempting request with API Key only.");
      }

      final response = await http.get(Uri.parse(url), headers: headers);

      debugPrint(" Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        return {
          'status': 'Error',
          'message': 'Unauthorized (401). API Key invalid or Token required.'
        };
      } else {
        return {
          'status': 'Error',
          'message': 'Lookup Failed: ${response.statusCode}'
        };
      }
    } catch (e) {
      debugPrint(" Exception: $e");
      return {'status': 'Error', 'message': "Connection error"};
    }
  }

  // --- 4. Fetch Employee Documents ---
  Future<List<EmployeeCertificate>> fetchEmployeeDocuments(int empId) async {
    // Official Endpoint: /api/employee/documents/{employeeId}?code=CERTIFICATE_GET_KEY
    final url = '$baseUrl/employee/documents/$empId?code=$fetchDocsKey';
    debugPrint(" Fetching Documents from: $url");

    try {
      final response = await _apiClient.get(url, useAuth: true);

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        debugPrint(
            " Documents Found (Raw Count): ${data is List ? data.length : 'Object'}");

        List<dynamic> rawDocs = [];

        // Handle both List and Map responses
        if (data is List) {
          rawDocs = data;
        } else if (data is Map<String, dynamic>) {
          if (data['Documents'] != null) rawDocs.addAll(data['Documents']);
          if (data['ApprovedDocuments'] != null) {
            rawDocs.addAll(data['ApprovedDocuments']);
          }
          if (data['Result'] != null) rawDocs.addAll(data['Result']);
        }

        return rawDocs.map<EmployeeCertificate>((doc) {
          return EmployeeCertificate(
            documentId: doc['DocumentId'] ?? doc['documentId'] ?? 0,
            employeeId: empId,
            fileName: doc['DocumentType'] ??
                doc['documentType'] ??
                doc['FileName'] ??
                doc['fileName'] ??
                'Document',
            fileType: doc['DocumentType'] ??
                doc['documentType'] ??
                doc['FileType'] ??
                doc['fileType'] ??
                'General',
            documentUrl: doc['DocumentUrl'] ?? doc['documentUrl'] ?? '',
            documentType:
                doc['DocumentType'] ?? doc['documentType'] ?? 'General',
            status: doc['Status'] ?? doc['status'] ?? 'Approved',
            uploadedAt: doc['UploadedAt'] ??
                doc['uploadedAt'] ??
                formatDateTimeForServer(DateTime.now()),
            remarks: doc['Remarks'] ?? doc['remarks'],
            updatedAt: doc['UpdatedAt'] ?? doc['updatedAt'],
          );
        }).toList();
      } else {
        debugPrint(" Failed to fetch docs. Status: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint(" Error fetching profile docs: $e");
      return [];
    }
  }

  // --- 5. Upload Certificate (Multipart) ---
  Future<String?> uploadCertificate({
    required File file,
    required int employeeId,
    required String certificateType,
    int? documentId, // If provided, it's an update
  }) async {
    if (documentId != null) {
      final updateAttempts = [
        _CertificateUploadAttempt(
          method: 'POST',
          url:
              '$baseUrl/certificates/update/$documentId?code=$certificateUpdateKey',
        ),
        _CertificateUploadAttempt(
          method: 'POST',
          url:
              '$baseUrl/certificates/update?code=$certificateUpdateKey&documentId=$documentId',
        ),
        _CertificateUploadAttempt(
          method: 'PUT',
          url:
              '$baseUrl/certificates/update/$documentId?code=$certificateUpdateKey',
        ),
        _CertificateUploadAttempt(
          method: 'PUT',
          url:
              '$baseUrl/certificates/update?code=$certificateUpdateKey&documentId=$documentId',
        ),
      ];

      String? lastError;
      for (final attempt in updateAttempts) {
        lastError = await _sendCertificateMultipart(
          method: attempt.method,
          url: attempt.url,
          file: file,
          employeeId: employeeId,
          certificateType: certificateType,
          documentId: documentId,
        );

        if (lastError == null) return null;
        if (!lastError.contains('Upload failed: 404')) return lastError;
      }

      return lastError ?? 'Upload failed: update route not found';
    }

    return _sendCertificateMultipart(
      method: 'POST',
      url: '$baseUrl/certificates/add?code=$certificateAddKey',
      file: file,
      employeeId: employeeId,
      certificateType: certificateType,
    );
  }

  Future<String?> _sendCertificateMultipart({
    required String method,
    required String url,
    required File file,
    required int employeeId,
    required String certificateType,
    int? documentId,
  }) async {
    debugPrint(" Uploading Document to: $url");

    try {
      final request = http.MultipartRequest(method, Uri.parse(url));

      final token = await _apiClient.getAppToken();
      if (token != null && token.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['employeeId'] = employeeId.toString();
      request.fields['certificateType'] = certificateType;
      request.fields['dateIssued'] =
          DateTime.now().toIso8601String().split('T').first;
      request.fields['expiryDate'] = DateTime.now()
          .add(const Duration(days: 365))
          .toIso8601String()
          .split('T')
          .first;

      if (documentId != null) {
        request.fields['documentId'] = documentId.toString();
        request.fields['id'] = documentId.toString(); // Some endpoints use 'id'
      }

      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: MediaType.parse(mimeType),
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return null; // Success
      } else {
        return "Upload failed: ${response.statusCode} - ${response.body}";
      }
    } catch (e) {
      return "Upload error: $e";
    }
  }

  // --- 6. Add Certificate (JSON - Kept for compatibility if needed) ---
  Future<Map<String, dynamic>?> addCertificate(
      Map<String, dynamic> certData) async {
    final url = '$baseUrl/certificates/add?code=$certificateAddKey';
    debugPrint(" Adding Certificate...");

    try {
      final response =
          await _apiClient.post(url, body: certData, useAuth: true);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint(" Failed to add certificate: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint(" Error adding certificate: $e");
      return null;
    }
  }

  // --- 6. Get All Certificates ---
  Future<List<EmployeeCertificate>> getAllCertificates() async {
    final url = '$baseUrl/certificates?code=$certificateGetKey';
    debugPrint(" Fetching all certificates...");

    try {
      final response = await _apiClient.get(url, useAuth: true);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map<EmployeeCertificate>((cert) {
          return EmployeeCertificate(
            documentId: cert['id'] ?? 0,
            employeeId: cert['employeeId'] ?? 0,
            fileName: cert['certificateName'] ?? 'Certificate',
            fileType: cert['certificateType'] ?? 'General',
            documentUrl: cert['certificateUrl'] ?? '',
            documentType: cert['certificateType'] ?? 'General',
            status: cert['status'] ?? 'Active',
            uploadedAt:
                cert['issuedDate'] ?? formatDateTimeForServer(DateTime.now()),
            remarks: cert['remarks'],
            updatedAt: cert['updatedAt'],
          );
        }).toList();
      } else {
        debugPrint(" Failed to fetch certificates: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint(" Error fetching certificates: $e");
      return [];
    }
  }

  // --- 7. Update Certificate ---
  Future<bool> updateCertificate(
      int certId, Map<String, dynamic> certData) async {
    final url =
        '$baseUrl/certificates/update/$certId?code=$certificateUpdateKey';
    debugPrint(" Updating Certificate ID: $certId");

    try {
      final response = await _apiClient.put(url, body: certData, useAuth: true);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint(" Error updating certificate: $e");
      return false;
    }
  }

  // --- 8. Delete Certificate ---
  Future<bool> deleteCertificate(int certId) async {
    final url =
        '$baseUrl/certificates/delete/$certId?code=$certificateDeleteKey';
    debugPrint(" Deleting Certificate ID: $certId");

    try {
      final response = await _apiClient.delete(url, useAuth: true);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint(" Error deleting certificate: $e");
      return false;
    }
  }
}

class _CertificateUploadAttempt {
  final String method;
  final String url;

  const _CertificateUploadAttempt({
    required this.method,
    required this.url,
  });
}
