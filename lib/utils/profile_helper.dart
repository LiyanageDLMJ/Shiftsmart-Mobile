import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftsmart/providers/user_provider.dart';
import 'package:shiftsmart/services/auth_service.dart';

Future<void> refreshUserProfileFromBackend(
  BuildContext context, {
  AuthService? authService,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final email = prefs.getString('userEmail');

  if (email != null) {
    final service = authService ?? AuthService(); // Use provided or default
    final fullProfile = await service.fetchFullEmployeeProfile(email);

    if (fullProfile != null) {
      dynamic value(String key, String apiKey) {
        final normalValue = fullProfile[key];
        if (normalValue != null && normalValue.toString().trim().isNotEmpty) {
          return normalValue;
        }
        return fullProfile[apiKey];
      }

      int? intValue(String key, String apiKey) {
        final raw = value(key, apiKey);
        if (raw is int) return raw;
        return int.tryParse(raw?.toString() ?? '');
      }

      String text(String key, String apiKey) =>
          (value(key, apiKey) ?? '').toString().trim();

      final rawNextOfKins =
          value('nextOfKins', 'NextOfKins') as List<dynamic>? ?? [];

      final userProfile = {
        "userId": intValue("userId", "UserId") ?? prefs.getInt('userId'),
        "employeeId":
            intValue("employeeId", "EmployeeId") ?? prefs.getInt('employeeId'),
        "firstName": text("firstName", "FirstName"),
        "middleName": text("middleName", "MiddleName"),
        "lastName": text("lastName", "LastName"),
        "gender": text("gender", "Gender"),
        "email": text("email", "Email"),
        "mobileNumber": text("mobileNumber", "MobileNumber"),
        "dateOfBirth": text("dateOfBirth", "DateOfBirth"),
        "street": text("street", "Street"),
        "city": text("city", "City"),
        "state": text("state", "State"),
        "postalCode": text("postalCode", "PostalCode"),
        "country": text("country", "Country"),
        "employmentStatus": text("employmentStatus", "EmploymentStatus"),
        "jobRole": text("jobRole", "JobRole"),
        "userRole": text("userRole", "UserRole").isNotEmpty
            ? text("userRole", "UserRole")
            : prefs.getString('userRole') ?? "",
        "profilePicture": text("profilePicture", "ProfilePicture"),
        "bankAccountName": text("bankAccountName", "BankAccountName"),
        "bankAccountNumber": text("bankAccountNumber", "BankAccountNumber"),
        "bankBSB": text("bankBSB", "BankBSB"),
        "bankName": text("bankName", "BankName"),
        "nextOfKins": rawNextOfKins.map((nok) {
          final m = nok as Map<String, dynamic>;
          return {
            "nextOfKinId": m["nextOfKinId"] ?? m["NextOfKinId"],
            "employeeId": m["employeeId"] ?? m["EmployeeId"],
            "fullName": m["fullName"] ?? m["FullName"],
            "relationship": m["relationship"] ?? m["Relationship"],
            "mobileNumber": m["mobileNumber"] ?? m["MobileNumber"],
            "email": m["email"] ?? m["Email"],
            "address": m["address"] ?? m["Address"],
          };
        }).toList(),
      };

      if (!context.mounted) return;
      Provider.of<UserProvider>(context, listen: false)
          .setUserProfile(userProfile);
    }
  }
}
