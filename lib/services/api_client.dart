import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:shiftsmart/main.dart';
import 'package:shiftsmart/providers/tenant_provider.dart';
import 'package:shiftsmart/widgets/premium_feature_gate.dart';

class ApiClient {
  // Use FlutterSecureStorage (consistent with AuthService)
  final _storage = const FlutterSecureStorage();

  // Helper to get the saved token
  Future<String?> getAppToken() async {
    return await _storage.read(key: 'appToken');
  }

  /// Decodes a JWT token without external dependencies
  Map<String, dynamic>? decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];
      final String normalized = base64Url.normalize(payload);
      final String decoded = utf8.decode(base64Url.decode(normalized));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (e) {
      debugPrint(" Error decoding JWT: $e");
      return null;
    }
  }

  /// Extracts the role from the saved token
  Future<String?> getRoleFromToken() async {
    final token = await getAppToken();
    if (token == null) return null;
    final payload = decodeJwt(token);
    return payload?['role'] ?? payload?['UserRole'] ?? payload?['userRole'];
  }

  // Helper to build the correct headers
  Future<Map<String, String>> _getHeaders(bool useAuth) async {
    Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    if (useAuth) {
      final token = await getAppToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  /// Handles 403 Forbidden errors globally
  void _handleForbidden(http.Response response, {bool showDialog = true}) {
    if (response.statusCode == 403) {
      debugPrint(" ApiClient: 403 Forbidden detected. showDialog: $showDialog");
      
      final context = navigatorKey.currentContext;
      if (context != null) {
        // Record the blocked endpoint in TenantProvider so the bottom nav
        // can show a crown icon on the corresponding tab.
        final endpointPath = response.request?.url.path;
        if (endpointPath != null && endpointPath.isNotEmpty) {
          try {
            Provider.of<TenantProvider>(context, listen: false)
                .addBlockedEndpoint(endpointPath);
          } catch (_) {}
        }

        // Try to parse the feature name from response if possible, 
        // otherwise default to 'This feature'.
        String featureName = 'This feature';
        try {
          final body = jsonDecode(response.body);
          featureName = body['featureName'] ?? body['FeatureName'] ?? 'This feature';
        } catch (_) {}

        // Only show the dialog if we have a specific feature name from the backend.
        // This prevents generic "This feature" popups on background calls.
        if (showDialog && featureName != 'This feature') {
          PremiumFeatureGate.showDialog(
            context,
            featureName: featureName,
            blockedEndpoint: endpointPath,
          );
        }
      }
    }
  }

  /// Performs a GET request
  Future<http.Response> get(String url,
      {bool useAuth = false, bool handleForbidden = true, bool showDialog = true}) async {
    final headers = await _getHeaders(useAuth);
    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );
    if (handleForbidden) {
      _handleForbidden(response, showDialog: showDialog);
    }
    return response;
  }

  /// Performs a POST request
  Future<http.Response> post(String url,
      {dynamic body, bool useAuth = false, bool handleForbidden = true, bool showDialog = true}) async {
    final headers = await _getHeaders(useAuth);
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    if (handleForbidden) {
      _handleForbidden(response, showDialog: showDialog);
    }
    return response;
  }

  /// Performs a PUT request
  Future<http.Response> put(String url,
      {dynamic body, bool useAuth = false, bool handleForbidden = true, bool showDialog = true}) async {
    final headers = await _getHeaders(useAuth);
    final response = await http.put(
      Uri.parse(url),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    if (handleForbidden) {
      _handleForbidden(response, showDialog: showDialog);
    }
    return response;
  }

  /// Performs a DELETE request
  Future<http.Response> delete(String url,
      {bool useAuth = false, bool handleForbidden = true, bool showDialog = true}) async {
    final headers = await _getHeaders(useAuth);
    final response = await http.delete(
      Uri.parse(url),
      headers: headers,
    );
    if (handleForbidden) {
      _handleForbidden(response, showDialog: showDialog);
    }
    return response;
  }

  /// Performs a PATCH request
  Future<http.Response> patch(String url,
      {dynamic body, bool useAuth = false, bool handleForbidden = true, bool showDialog = true}) async {
    final headers = await _getHeaders(useAuth);
    final response = await http.patch(
      Uri.parse(url),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    if (handleForbidden) {
      _handleForbidden(response, showDialog: showDialog);
    }
    return response;
  }
}
