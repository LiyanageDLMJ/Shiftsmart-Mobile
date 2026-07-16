import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:http/http.dart' as http; // Kept for MultipartRequest
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shiftsmart/models/empcert_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_client.dart'; // Import ApiClient

class CertificateService {
  final ApiClient _apiClient = ApiClient(); // Initialize ApiClient

  // Use keys from .env to prevent 401 errors
  final String baseUrl = dotenv.env['BASE_URL'] ?? "";
  final String certBaseUrl = dotenv.env['CERT_BASE_URL'] ?? "";

  CertificateService() {
    if (baseUrl.isEmpty) debugPrint(" CertificateService: BASE_URL is missing");
  }

  // Safe getters for keys
  String get uploadKey => dotenv.env['CERT_UPLOAD_KEY'] ?? '';
  String get fetchKey => dotenv.env['FETCH_DOCUMENTS1_KEY'] ?? '';

  // --- UPLOAD CERTIFICATE (Multipart) ---
  Future<String?> uploadCertificate({
    required File file,
    required int employeeId,
    required String certificateType,
    required String dateIssued,
    required String expiryDate,
  }) async {
    // 1. Construct URL with the correct Key
    final Uri uploadUrl = Uri.parse(
      '$certBaseUrl/cert/upload?code=$uploadKey',
    );

    try {
      final request = http.MultipartRequest('POST', uploadUrl);

      // 2. FIX: Manually Add Authorization Header for Multipart
      final token = await _apiClient.getAppToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      // 3. Add File
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType.parse(
            lookupMimeType(file.path) ?? 'application/octet-stream',
          ),
        ),
      );

      // 4. Add Fields
      request.fields['employeeId'] = employeeId.toString();
      request.fields['certificateType'] = certificateType;
      request.fields['dateIssued'] = dateIssued;
      request.fields['expiryDate'] = expiryDate;

      // 5. Send
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return null; // Success
      } else {
        return "Upload failed: ${response.statusCode} - $responseBody";
      }
    } catch (e) {
      return "Upload error: $e";
    }
  }

  // --- FETCH CERTIFICATES ---
  Future<List<EmployeeCertificate>> fetchCertificates(int employeeId) async {
    final url = '$baseUrl/employee/documents1/$employeeId?code=$fetchKey';
    debugPrint(" CertificateService: Fetching certificates from $url");

    try {
      final response = await _apiClient.get(url, useAuth: true);
      debugPrint(" CertificateService Status: ${response.statusCode}");
      debugPrint(" CertificateService Body snippet: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        debugPrint(" CertificateService: Found ${jsonData.length} documents.");
        return jsonData.map((e) => EmployeeCertificate.fromJson(e)).toList();
      } else {
        debugPrint(" CertificateService: Failed to fetch documents. Status: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      debugPrint(" CertificateService: Exception fetching documents: $e");
      return [];
    }
  }
}
