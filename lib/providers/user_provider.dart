import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  Map<String, dynamic> _userProfile = {};
  List<dynamic> _tenants = [];

  Map<String, dynamic> get userProfile => _userProfile;
  List<dynamic> get tenants => _tenants;

  void setUserProfile(Map<String, dynamic> profile) {
    print("UserProvider: Updating profile with: $profile");
    // Merge new profile data into existing profile to avoid losing fields like role
    _userProfile = {..._userProfile, ...profile}; 
    notifyListeners();
  }

  void setTenants(List<dynamic> tenants) {
    _tenants = tenants;
    notifyListeners();
  }

  void clearUserProfile() { 
    _userProfile = {}; 
    notifyListeners();
  }
}
