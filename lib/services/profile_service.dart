import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mime/mime.dart';
import 'api_client.dart';

class ProfileService {
  final ApiClient _apiClient = ApiClient();

  final String baseUrl = dotenv.env['BASE_URL'] ?? '';

  //  Removed '!' and added '?? ""' to prevent App Crash
  final String updateProfileKey = dotenv.env['UPDATE_PROFILE_KEY'] ?? '';
  final String updatePassKey = dotenv.env['UPDATE_PASS_KEY'] ?? '';

  String _text(dynamic value) => (value ?? '').toString().trim();

  dynamic _firstNonEmpty(dynamic first, dynamic second) {
    if (first != null && first.toString().trim().isNotEmpty) {
      return first;
    }
    return second;
  }

  String _optionalBankText(dynamic value) {
    final text = _text(value);
    return text.isEmpty ? 'N/A' : text;
  }

  String _phone(dynamic value) =>
      _text(value).replaceAll(RegExp(r'[\s\-()]'), '');

  String _dateOnly(dynamic value) {
    final text = _text(value);
    return text.contains('T') ? text.split('T').first : text;
  }

  Map<String, dynamic> _employeePayload(
    Map<String, dynamic> profile,
    int employeeId,
  ) {
    return {
      'EmployeeId': employeeId,
      'FirstName':
          _text(_firstNonEmpty(profile['firstName'], profile['FirstName'])),
      'MiddleName':
          _text(_firstNonEmpty(profile['middleName'], profile['MiddleName'])),
      'LastName':
          _text(_firstNonEmpty(profile['lastName'], profile['LastName'])),
      'Gender': _text(_firstNonEmpty(profile['gender'], profile['Gender'])),
      'Email': _text(_firstNonEmpty(profile['email'], profile['Email'])),
      'MobileNumber': _phone(
          _firstNonEmpty(profile['mobileNumber'], profile['MobileNumber'])),
      'DateOfBirth': _dateOnly(
          _firstNonEmpty(profile['dateOfBirth'], profile['DateOfBirth'])),
      'Street': _text(_firstNonEmpty(profile['street'], profile['Street'])),
      'City': _text(_firstNonEmpty(profile['city'], profile['City'])),
      'State': _text(_firstNonEmpty(profile['state'], profile['State'])),
      'PostalCode':
          _text(_firstNonEmpty(profile['postalCode'], profile['PostalCode'])),
      'Country': _text(_firstNonEmpty(profile['country'], profile['Country'])),
      'BankAccountName': _optionalBankText(_firstNonEmpty(
          profile['bankAccountName'], profile['BankAccountName'])),
      'BankBSB': _optionalBankText(
          _firstNonEmpty(profile['bankBSB'], profile['BankBSB'])),
      'BankAccountNumber': _optionalBankText(_firstNonEmpty(
          profile['bankAccountNumber'], profile['BankAccountNumber'])),
      'BankName': _optionalBankText(
          _firstNonEmpty(profile['bankName'], profile['BankName'])),
      'ProfilePicture': _text(
          _firstNonEmpty(profile['profilePicture'], profile['ProfilePicture'])),
      'EmploymentStatus': _text(_firstNonEmpty(
                  profile['employmentStatus'], profile['EmploymentStatus']))
              .isEmpty
          ? 'Active'
          : _text(_firstNonEmpty(
              profile['employmentStatus'], profile['EmploymentStatus'])),
      'JobRole': _text(_firstNonEmpty(profile['jobRole'], profile['JobRole'])),
    };
  }

  List<Map<String, dynamic>> _nextOfKinPayload(
    List<Map<String, dynamic>> nextOfKins,
    int employeeId,
  ) {
    return nextOfKins.map((kin) {
      final id = int.tryParse(
            _text(kin['nextOfKinId'] ?? kin['NextOfKinId']),
          ) ??
          0;

      final payload = <String, dynamic>{
        'EmployeeId': employeeId,
        'FullName': _text(kin['fullName'] ?? kin['FullName']),
        'Relationship': _text(kin['relationship'] ?? kin['Relationship']),
        'MobileNumber': _phone(kin['mobileNumber'] ?? kin['MobileNumber']),
        'Email': _text(kin['email'] ?? kin['Email']),
        'Address': _text(kin['address'] ?? kin['Address']),
        'IsPrimary': kin['isPrimary'] ?? kin['IsPrimary'] ?? false,
      };

      if (id > 0) {
        payload['NextOfKinId'] = id;
      }

      return payload;
    }).toList();
  }

  // --- UPDATE PROFILE ---
  Future<String?> updateProfile({
    required int employeeId,
    required Map<String, dynamic> profile,
    required List<Map<String, dynamic>> nextOfKins,
    File? profilePicture,
  }) async {
    // Check if key exists
    if (updateProfileKey.isEmpty) {
      return "Error: Missing UPDATE_PROFILE_KEY in .env";
    }

    final url = '$baseUrl/employee/update/$employeeId?code=$updateProfileKey';

    final profilePayload = _employeePayload(profile, employeeId);
    final missingRequiredField = _missingRequiredProfileField(profilePayload);
    if (missingRequiredField != null) {
      return '$missingRequiredField is required.';
    }

    final nextOfKinPayload = _nextOfKinPayload(nextOfKins, employeeId);
    final profileUpdateBody = {
      ...profilePayload,
      'employeeId': employeeId,
      'NextOfKins': nextOfKinPayload,
      'nextOfKins': nextOfKinPayload,
      'NextOfKin': nextOfKinPayload,
      'ApprovedNextOfKin': nextOfKinPayload,
    };

    Future<http.Response> sendJsonRequest() {
      return _apiClient.put(
        url,
        body: profileUpdateBody,
        useAuth: true,
      );
    }

    Future<http.Response> sendMultipartRequest(String method) async {
      final uri = Uri.parse(url);
      final request = http.MultipartRequest(method, uri);

      final token = await _apiClient.getAppToken();
      if (token == null || token.isEmpty) {
        return http.Response('Missing saved login token.', 401);
      }
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['profile'] = jsonEncode(profilePayload);
      request.fields['Profile'] = jsonEncode(profilePayload);
      request.fields['nextOfKins'] = jsonEncode(nextOfKinPayload);
      request.fields['NextOfKins'] = jsonEncode(nextOfKinPayload);
      request.fields['NextOfKin'] = jsonEncode(nextOfKinPayload);
      request.fields['ApprovedNextOfKin'] = jsonEncode(nextOfKinPayload);
      request.fields['employeeId'] = employeeId.toString();
      request.fields['EmployeeId'] = employeeId.toString();
      for (final entry in profilePayload.entries) {
        request.fields[entry.key] = entry.value.toString();
      }

      if (profilePicture != null && profilePicture.existsSync()) {
        final mimeType = lookupMimeType(profilePicture.path) ?? 'image/jpeg';
        request.files.add(await http.MultipartFile.fromPath(
          'profilePicture',
          profilePicture.path,
          contentType: MediaType.parse(mimeType),
        ));
      }

      final streamedResponse = await request.send();
      return await http.Response.fromStream(streamedResponse);
    }

    try {
      var response = profilePicture == null
          ? await sendJsonRequest()
          : await sendMultipartRequest('PUT');

      if (profilePicture == null &&
          (response.statusCode == 400 ||
              response.statusCode == 415 ||
              response.statusCode == 500)) {
        response = await sendMultipartRequest('PUT');
      }

      if (response.statusCode == 200) {
        return null; // Success
      }

      // Azure Functions sometimes parse multipart PUT poorly; retry as POST
      // for server/model-binding errors from the first attempts.
      if (response.statusCode == 400 ||
          response.statusCode == 415 ||
          response.statusCode == 500) {
        final retryResponse = await sendMultipartRequest('POST');
        if (retryResponse.statusCode == 200) {
          return null;
        }
        return 'Failed : ${retryResponse.statusCode} ${retryResponse.body}';
      }

      return 'Failed : ${response.statusCode} ${response.body}';
    } catch (e) {
      return 'Error: $e';
    }
  }

  String? _missingRequiredProfileField(Map<String, dynamic> profilePayload) {
    final requiredFields = <String, String>{
      'FirstName': 'First Name',
      'LastName': 'Last Name',
      'Gender': 'Gender',
      'Email': 'Email',
      'MobileNumber': 'Phone Number',
      'DateOfBirth': 'Date of Birth',
      'Street': 'Street Address',
      'City': 'City/Suburb',
      'Country': 'Country',
      'JobRole': 'Job Role',
    };

    for (final entry in requiredFields.entries) {
      if (_text(profilePayload[entry.key]).isEmpty) {
        return entry.value;
      }
    }

    return null;
  }

  // --- UPDATE PASSWORD ---
  Future<bool?> updatePassword(
      String userEmail, String currentPassword, String newPassword) async {
    // Check if key exists
    if (updatePassKey.isEmpty) {
      debugPrint(" Error: Missing UPDATE_PASS_KEY in .env");
      return false;
    }

    final url = '$baseUrl/employee/change-password?code=$updatePassKey';

    try {
      final response = await _apiClient.post(
        url,
        body: {
          "email": userEmail,
          "currentPassword": currentPassword,
          "newPassword": newPassword,
        },
        useAuth: true,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint("Failed to update password: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      debugPrint("Error updating password: $e");
      return null;
    }
  }
}
