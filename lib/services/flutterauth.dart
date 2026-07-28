// auth_service.dart

import 'dart:convert';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class Flutterauth {
  static const _clientId = '0f3aac95-9559-4ea4-b818-afac42e981ff';
  static const _tenantId = '8a8547b1-9090-4c51-8823-499d27b0d7ec';
  static const _redirectUri = 'msauth://com.example.shiftsmart/w5G662mc4o81BUzLaFO2xjZlnHw=';
  static const _scopes = ['openid', 'profile', 'email'];

  final FlutterAppAuth _appAuth = FlutterAppAuth();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String? accessToken;
  String? idToken;
  Map<String, dynamic>? profile;

  String get _discoveryUrl {
    final value = dotenv.env['MICROSOFT_DISCOVERY_URL'] ?? '';
    if (value.isEmpty) {
      throw Exception('Missing MICROSOFT_DISCOVERY_URL');
    }
    return value;
  }

  String get _graphMeUrl {
    final value = dotenv.env['MICROSOFT_GRAPH_ME_URL'] ?? '';
    if (value.isEmpty) {
      throw Exception('Missing MICROSOFT_GRAPH_ME_URL');
    }
    return value;
  }

  Future<bool> signIn() async {
    try {
      final result = await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          _clientId,
          _redirectUri,
          discoveryUrl: _discoveryUrl,
          scopes: _scopes,
        ),
      );

      accessToken = result.accessToken;
      idToken = result.idToken;
      profile = _parseIdToken(idToken!);
      await _secureStorage.write(key: 'refresh_token', value: result.refreshToken);
      return true;
        } catch (e) {
      print('Login error: $e');
    }
    return false;
  }

  Future<void> signOut() async {
    await _secureStorage.deleteAll();
    accessToken = null;
    idToken = null;
    profile = null;
  }

  Map<String, dynamic> _parseIdToken(String token) {
    final parts = token.split('.');
    final payload = base64Url.normalize(parts[1]);
    final decoded = utf8.decode(base64Url.decode(payload));
    return json.decode(decoded);
  }

  Future<Map<String, dynamic>?> callMicrosoftGraph() async {
    if (accessToken == null) return null;

    final response = await http.get(
      Uri.parse(_graphMeUrl),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print('Graph API error: ${response.statusCode}');
      return null;
    }
  }
}
