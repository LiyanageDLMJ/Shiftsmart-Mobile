import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftsmart/models/emergency_contact_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'api_client.dart'; // Import ApiClient

class EmergencyContactService {
  final ApiClient _apiClient = ApiClient(); // Initialize ApiClient

  final String baseUrl = dotenv.env['BASE_URL'] ?? "";
  // Use getter for safety
  String get fetchProfileKey => dotenv.env['FETCH_PROFILE_KEY'] ?? '';

  String? _userEmail;

  EmergencyContactService({String? userEmail}) {
    _userEmail = userEmail;
  }

  void setUserEmail(String email) {
    _userEmail = email;
  }

  Future<String?> _getUserEmail() async {
    if (_userEmail != null) return _userEmail;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userEmail');
  }

  // --- GET CONTACTS (Next Of Kin) ---
  Future<List<NextOfKin>> getContacts() async {
    try {
      final email = await _getUserEmail();
      if (email == null) throw Exception('User email not found');

      // Construct the URL directly (Decoupled from AuthService)
      final url = '$baseUrl/employee/profile/$email?code=$fetchProfileKey';

      // FIX: Use ApiClient with useAuth: true
      final response = await _apiClient.get(url, useAuth: true);

      if (response.statusCode == 200) {
        final Map<String, dynamic> contactJson = jsonDecode(response.body);

        // Parse the profile to get contacts
        final contact = Contact.fromJson(contactJson);
        return contact.nextOfKins;
      } else {
        debugPrint(
            "Failed to load profile: ${response.statusCode} - ${response.body}");
        throw Exception('Failed to load employee profile');
      }
    } catch (e) {
      debugPrint("Error getting contacts: $e");
      throw Exception('Error getting contacts: $e');
    }
  }

  // --- GET NUMBERS ---
  Future<List<String>> getEmergencyPhoneNumbers() async {
    try {
      final contacts = await getContacts();
      return contacts.map((kin) => kin.mobileNumber).toList();
    } catch (e) {
      debugPrint("Error getting phone numbers: $e");
      return [];
    }
  }
}
