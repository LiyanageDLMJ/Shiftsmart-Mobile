import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';

class AuthService {
  // Dependencies
  final ApiClient _apiClient = ApiClient();
  final _storage = const FlutterSecureStorage();

  // Environment Keys - Main Employee Service
  String baseUrl = dotenv.env['BASE_URL'] ?? '';
  String fallbackBaseUrl = dotenv.env['BASE_URL_FALLBACK'] ?? '';
  String loginKey = dotenv.env['LOGIN_KEY'] ?? '';
  String empProfileKey = dotenv.env['FETCH_PROFILE_KEY'] ?? '';
  String logOutKey = dotenv.env['LOGOUT_KEY'] ?? '';
  String updateProfileKey = dotenv.env['UPDATE_PROFILE_KEY'] ?? '';
  String updatePasswordKey = dotenv.env['UPDATE_PASS_KEY'] ?? '';
  String fetchRejectedKey = dotenv.env['FETCH_REJECTED_KEY'] ?? '';
  String resubmitKey = dotenv.env['RESUBMIT_KEY'] ?? '';
  String submitOnboardKey = dotenv.env['SUBMIT_ONBOARD_KEY'] ?? '';

  // Forgot Password Keys
  String forgotRequestKey = dotenv.env['FORGOT_PASS_REQUEST_KEY'] ?? '';
  String forgotVerifyKey = dotenv.env['FORGOT_PASS_VERIFY_KEY'] ?? '';
  String forgotResetKey = dotenv.env['FORGOT_PASS_RESET_KEY'] ?? '';

  /// STEP 1: Login
  Future<Map<String, dynamic>?> login(String email, String password) async {
    // Validate required environment variables
    if (baseUrl.isEmpty) {
      return {
        'Message':
            ' Configuration Error: BASE_URL is not configured. Please check .env.'
      };
    }

    if (loginKey.isEmpty) {
      print(
          "  Warning: LOGIN_KEY is empty in .env. Login endpoint will be called without function key.");
    }

    String loginUrl = '$baseUrl/employee/login';
    if (loginKey.isNotEmpty) {
      loginUrl += '?code=$loginKey';
    }

    // The API payload in the provided screenshot uses lowercase "email" and uppercase "Password".
    // Align with that format to reduce possible mismatch issues.
    final requestBody = {'email': email, 'Password': password};

    print(" Login URL: ${loginUrl.replaceAll(RegExp(r'code=.*'), 'code=***')}");
    print(" Attempting login for email: $email");

    try {
      final response = await _apiClient.post(
        loginUrl,
        body: requestBody,
        useAuth: false,
      );

      print(" Login Response (${response.statusCode}): ${response.body}");

      if (response.statusCode == 200) {
        try {
          final decodedBody = jsonDecode(response.body);
          final token = decodedBody['token'] ?? decodedBody['Token'];
          if (token != null) {
            await _storage.write(key: 'appToken', value: token);
            print(" Token saved successfully");
            return decodedBody;
          }
          return decodedBody;
        } catch (e) {
          print(" JSON Decode Error: $e. Body: ${response.body}");
          return {'Message': 'Server error: Invalid response format.'};
        }
      } else {
        try {
          final decodedBody = jsonDecode(response.body);
          return {
            'Message': decodedBody['Message'] ??
                decodedBody['message'] ??
                'Login failed (${response.statusCode})'
          };
        } catch (e) {
          return {
            'Message': 'Login failed (${response.statusCode}): ${response.body}'
          };
        }
      }
    } on SocketException catch (e) {
      // Network connectivity error
      print(" Network Error - SocketException: $e");
      return {
        'Message':
            ' Network Error: Failed to connect to server.\n\nChecklist:\n Check internet connection\n Verify WiFi/Mobile data is enabled\n Check firewall/proxy settings\n Try again or contact support\n\nDetails: $e'
      };
    } catch (e) {
      print(" Login error: $e");
      return {
        'Message':
            ' Login Error: ${e.toString()}\n\nIf this persists, please contact support.'
      };
    }
  }

  /// STEP 2: Exchange Password for Token
  Future<Map<String, dynamic>?> exchangePasswordForToken(
    String email,
    String password, {
    int? tenantId,
  }) async {
    final String exchangeUrl = '$baseUrl/auth/exchange-password';

    try {
      final requestBody = {
        'email': email,
        'Password': password,
        if (tenantId != null) 'tenantId': tenantId,
      };

      final response = await _apiClient.post(
        exchangeUrl,
        body: requestBody,
        useAuth: false,
      );

      print("Exchange Response (${response.statusCode}): ${response.body}");

      if (response.statusCode == 200) {
        try {
          final decodedResponse = jsonDecode(response.body);
          final String? token =
              decodedResponse['appToken'] ?? decodedResponse['AppToken'];
          if (token != null) {
            await _storage.write(key: 'appToken', value: token);
            print(" AppToken saved.");
          }
          return decodedResponse;
        } catch (e) {
          print(" JSON Decode Error in Exchange: $e. Body: ${response.body}");
          return {"Message": "Server error: Invalid response format."};
        }
      } else {
        return {
          "Message":
              "Exchange failed (${response.statusCode}): ${response.body}"
        };
      }
    } catch (e) {
      return {"Message": "Exchange error: ${e.toString()}"};
    }
  }

  /// Fetch Rejected Data (For Resubmission)
  ///  HEAVILY UPDATED with Debugging
  Future<Map<String, dynamic>?> fetchRejectedProfileData(int employeeId) async {
    print(
        " AuthService: Starting fetchRejectedProfileData for ID: $employeeId");

    // 1. Check Key
    if (fetchRejectedKey.isEmpty) {
      print(
          " CRITICAL ERROR: FETCH_REJECTED_KEY is missing in .env or AuthService!");
      return null;
    }

    // 2. Build URL
    final url =
        '$baseUrl/employee/rejected-info/$employeeId?code=$fetchRejectedKey';

    // Debug print (Hide actual key for logs)
    print(" Requesting URL: .../employee/rejected-info/$employeeId?code=***");

    try {
      // 3. Make Request with app token. Backend validates resubmission access.
      final response = await _apiClient.get(url, useAuth: true);

      print(" Rejected Data Response Status: ${response.statusCode}");
      print(" Rejected Data Response Body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print(" Failed to fetch data. Status: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print(" Exception in fetchRejectedProfileData: $e");
      return null;
    }
  }

  /// Fetch Full Profile (Requires Token)
  Future<Map<String, dynamic>?> fetchFullEmployeeProfile(String email) async {
    final encodedEmail = Uri.encodeComponent(email);
    final url = '$baseUrl/employee/profile/$encodedEmail?code=$empProfileKey';

    try {
      final response = await _apiClient.get(url, useAuth: true);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Fetch Profile Failed: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error fetching profile: $e");
      return null;
    }
  }

  /// STEP 1.5: Token Exchange
  Future<Map<String, dynamic>?> exchangeToken(String currentToken) async {
    final String exchangeUrl = '$baseUrl/auth/exchange-password';

    try {
      final response = await _apiClient.post(
        exchangeUrl,
        body: {},
        useAuth: true,
      );

      if (response.statusCode == 200) {
        final newData = jsonDecode(response.body);
        final newToken = newData['token'] ?? newData['Token'];
        if (newToken != null) {
          await _storage.write(key: 'appToken', value: newToken);
          return newData;
        }
        return newData;
      } else {
        return {"Message": "Exchange failed (${response.statusCode})"};
      }
    } catch (e) {
      return {"Message": "Exchange error: ${e.toString()}"};
    }
  }

  /// Logout
  Future<bool> logout(int? employeeId) async {
    final tokenBeforeDelete = await _storage.read(key: 'appToken');
    await _storage.delete(key: 'appToken');

    if (tokenBeforeDelete == null || employeeId == null) return true;

    String logoutUrl = '$baseUrl/employee/logout';
    if (logOutKey.isNotEmpty) {
      logoutUrl += '?code=$logOutKey';
    }

    try {
      await _apiClient.post(
        logoutUrl,
        body: {"employeeId": employeeId},
        useAuth: true,
      );
      return true;
    } catch (e) {
      return true;
    }
  }

  /// Change Password
  Future<bool> changePassword(
      String currentPassword, String newPassword) async {
    final url = '$baseUrl/employee/change-password?code=$updatePasswordKey';

    try {
      final response = await _apiClient.post(
        url,
        body: {"currentPassword": currentPassword, "newPassword": newPassword},
        useAuth: true,
      );

      print(' Change Password Status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print(' Change Password Error: $e');
      return false;
    }
  }

  /// Update Employee Profile
  Future<Map<String, dynamic>?> updateEmployeeProfile(
      int employeeId, Map<String, dynamic> profileData) async {
    final url = '$baseUrl/employee/update/$employeeId?code=$updateProfileKey';

    try {
      final response = await _apiClient.put(
        url,
        body: profileData,
        useAuth: false,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Update Profile Failed: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error updating profile: $e");
      return null;
    }
  }

  /// --- FORGOT PASSWORD (TOKEN-BASED FLOW) ---

  // 1. Request OTP (Returns the Reset Token ID)
  Future<String?> requestPasswordReset(String email) async {
    if (forgotRequestKey.isEmpty) {
      print(" CRITICAL: FORGOT_PASS_REQUEST_KEY is missing in .env!");
      return null;
    }

    final url =
        '$baseUrl/employee/forgot-password/request?code=$forgotRequestKey';
    print(" Requesting OTP for: $email");

    try {
      final response = await _apiClient.post(
        url,
        body: {"EmailOrPhone": email},
        useAuth: false,
      );

      print(" OTP Request Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['resetTokenId'];
        print(" Received Reset Token: $token");
        return token.toString();
      } else {
        print(" OTP Request Failed: ${response.body}");
        return null;
      }
    } catch (e) {
      print(" Request OTP Exception: $e");
      return null;
    }
  }

  // 2. Verify OTP (Uses ResetTokenId, not Email)
  Future<bool> verifyResetOtp(String resetTokenId, String otp) async {
    final url =
        '$baseUrl/employee/forgot-password/verify?code=$forgotVerifyKey';
    final body = {"ResetTokenId": resetTokenId, "Code": otp};

    print(" Verifying OTP...");
    print(" Body: $body");

    try {
      final response = await _apiClient.post(
        url,
        body: body,
        useAuth: false,
      );

      if (response.statusCode != 200) {
        print(" Verify Failed: ${response.body}");
      }
      return response.statusCode == 200;
    } catch (e) {
      print("Verify OTP Error: $e");
      return false;
    }
  }

  // 3. Reset Password (Uses ResetTokenId)
  Future<bool> resetPassword(
      String resetTokenId, String otp, String newPassword) async {
    final url = '$baseUrl/employee/forgot-password/reset?code=$forgotResetKey';
    final body = {
      "ResetTokenId": resetTokenId,
      "Code": otp,
      "NewPassword": newPassword
    };

    print(" Resetting Password...");

    try {
      final response = await _apiClient.post(
        url,
        body: body,
        useAuth: false,
      );

      if (response.statusCode != 200) {
        print(" Reset Failed: ${response.body}");
      }
      return response.statusCode == 200;
    } catch (e) {
      print("Reset Password Error: $e");
      return false;
    }
  }

  /// Ping the Auth Service
  Future<bool> ping() async {
    final url = '$baseUrl/auth/ping'; // No code needed as per user list
    try {
      final response = await _apiClient.get(url, useAuth: false);
      return response.statusCode == 200;
    } catch (e) {
      print(" Ping error: $e");
      return false;
    }
  }

  /// Get Current User Info (Me Endpoint)
  Future<Map<String, dynamic>?> getCurrentUserInfo() async {
    final url = '$baseUrl/me';

    try {
      final response =
          await _apiClient.get(url, useAuth: true, showDialog: false);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print("Get User Info Failed: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error getting user info: $e");
      return null;
    }
  }
}
