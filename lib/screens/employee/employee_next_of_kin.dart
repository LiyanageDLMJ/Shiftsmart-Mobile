import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shiftsmart/models/emergency_contact_model.dart';
import 'package:shiftsmart/providers/user_provider.dart';
import 'package:shiftsmart/services/emergency_contact_service.dart';
import 'package:shiftsmart/services/profile_service.dart';
import 'package:shiftsmart/utils/fullscreen_helper.dart';
import 'package:shiftsmart/utils/profile_helper.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/country_code_phone_field.dart';
import 'package:shiftsmart/widgets/emp_bottomnavbar.dart';
import 'package:shiftsmart/widgets/emp_slidenav.dart';
import 'package:shiftsmart/widgets/gradient_button.dart';
import 'package:shiftsmart/widgets/success_dialog.dart';
import 'package:shiftsmart/widgets/uppernavbar.dart';

class EmployeeNextOfKinScreen extends StatefulWidget {
  final Map<String, dynamic>? profileData;
  final File? profilePicture;

  const EmployeeNextOfKinScreen({
    super.key,
    this.profileData,
    this.profilePicture,
  });

  @override
  State<EmployeeNextOfKinScreen> createState() =>
      _EmployeeNextOfKinScreenState();
}

class _EmployeeNextOfKinScreenState extends State<EmployeeNextOfKinScreen> {
  final EmergencyContactService _contactService = EmergencyContactService();
  final ProfileService _profileService = ProfileService();

  bool _isLoading = true;
  bool _isSaving = false;

  List<KinControllers> _kinControllers = [];

  @override
  void initState() {
    super.initState();
    enableFullScreen();
    _loadNextOfKin();
  }

  @override
  void dispose() {
    for (var c in _kinControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadNextOfKin() async {
    setState(() => _isLoading = true);
    try {
      // First try loading from UserProvider (already fetched at login)
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final rawNoks = userProvider.userProfile['nextOfKins'] as List<dynamic>?;

      if (rawNoks != null && rawNoks.isNotEmpty) {
        debugPrint(' Loaded ${rawNoks.length} NoK(s) from UserProvider');
        setState(() {
          _kinControllers = rawNoks.map((nok) {
            final m = nok as Map<String, dynamic>;
            return KinControllers(
              id: m['nextOfKinId'] ?? m['NextOfKinId'],
              name: m['fullName'] ?? m['FullName'] ?? '',
              relationship: m['relationship'] ?? m['Relationship'] ?? '',
              phone: m['mobileNumber'] ?? m['MobileNumber'] ?? '',
              email: m['email'] ?? m['Email'] ?? '',
              address: m['address'] ?? m['Address'] ?? '',
            );
          }).toList();
        });
      } else {
        // Fallback: fetch from API directly
        debugPrint(' UserProvider has no NoK  fetching from API...');
        final contacts = await _contactService.getContacts();
        debugPrint(' API returned ${contacts.length} NoK(s)');
        setState(() {
          _kinControllers =
              contacts.map((kin) => KinControllers.fromModel(kin)).toList();
        });
      }

      if (_kinControllers.isEmpty) {
        debugPrint(' No NoK found  adding empty entry');
        _addEmptyKin();
      }
    } catch (e) {
      debugPrint(' Error loading next of kin: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading Next of Kin: $e')),
        );
      }
      if (_kinControllers.isEmpty) _addEmptyKin();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addEmptyKin() {
    setState(() => _kinControllers.add(KinControllers()));
  }

  void _removeKin(int index) {
    if (_kinControllers.length > 1) {
      setState(() {
        final removed = _kinControllers.removeAt(index);
        removed.dispose();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one Next of Kin is required.')),
      );
    }
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.error_outline, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(
              child:
                  Text(message, style: const TextStyle(color: Colors.white))),
        ]),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  String? _validateNoK() {
    for (int i = 0; i < _kinControllers.length; i++) {
      final label = 'Next of Kin ${i + 1}';
      final c = _kinControllers[i];

      // Full Name required, letters/spaces only, 2-80 chars
      final name = c.nameController.text.trim();
      if (name.isEmpty) return '$label: Full Name is required.';
      if (!RegExp(r"^[a-zA-Z-\s.'-]{2,80}$").hasMatch(name)) {
        return '$label: Full Name must be 2-80 letters only.';
      }

      // Relationship required
      if (c.relationshipController.text.trim().isEmpty) {
        return '$label: Relationship is required.';
      }

      // Mobile required, international format from the country code selector.
      final phone =
          c.phoneController.text.trim().replaceAll(RegExp(r'[\s\-()]'), '');
      if (phone.isEmpty) {
        return '$label: Mobile Number is required.';
      }
      if (!RegExp(r'^\+?[1-9]\d{6,14}$').hasMatch(phone)) {
        return '$label: Enter a valid mobile number (e.g. +94771234567).';
      }

      // Email required, valid format
      final email = c.emailController.text.trim();
      if (email.isEmpty) {
        return '$label: Email is required.';
      }
      if (!RegExp(r'^[\w._%+\-]+@[\w.\-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
        return '$label: Enter a valid email address.';
      }

      // Address required
      if (c.addressController.text.trim().isEmpty) {
        return '$label: Address is required.';
      }
    }
    return null;
  }

  Map<String, dynamic> _profilePayloadFrom(
    Map<String, dynamic> userProfile,
    int employeeId,
  ) {
    final editedProfile = widget.profileData ?? const <String, dynamic>{};

    String value(String key, [String? apiKey]) {
      final editedValue = editedProfile[key] ?? editedProfile[apiKey];
      if (editedValue != null && editedValue.toString().trim().isNotEmpty) {
        return editedValue.toString().trim();
      }
      final profileValue = userProfile[key];
      if (profileValue != null && profileValue.toString().trim().isNotEmpty) {
        return profileValue.toString().trim();
      }
      return (userProfile[apiKey] ?? '').toString().trim();
    }

    return {
      'employeeId': employeeId,
      'firstName': value('firstName', 'FirstName'),
      'middleName': value('middleName', 'MiddleName'),
      'lastName': value('lastName', 'LastName'),
      'gender': value('gender', 'Gender'),
      'email': value('email', 'Email'),
      'mobileNumber': value('mobileNumber', 'MobileNumber'),
      'dateOfBirth': _dateOnly(value('dateOfBirth', 'DateOfBirth')),
      'street': value('street', 'Street'),
      'city': value('city', 'City'),
      'state': value('state', 'State'),
      'postalCode': value('postalCode', 'PostalCode'),
      'country': value('country', 'Country'),
      'bankAccountName': value('bankAccountName', 'BankAccountName'),
      'bankBSB': value('bankBSB', 'BankBSB'),
      'bankAccountNumber': value('bankAccountNumber', 'BankAccountNumber'),
      'bankName': value('bankName', 'BankName'),
      'profilePicture': value('profilePicture', 'ProfilePicture'),
      'employmentStatus': value('employmentStatus', 'EmploymentStatus').isEmpty
          ? 'Active'
          : value('employmentStatus', 'EmploymentStatus'),
      'jobRole': value('jobRole', 'JobRole'),
    };
  }

  String _dateOnly(String value) {
    final text = value.trim();
    return text.contains('T') ? text.split('T').first : text;
  }

  String? _validateRequiredProfile(Map<String, dynamic> profile) {
    final requiredFields = <String, String>{
      'firstName': 'First Name',
      'lastName': 'Last Name',
      'gender': 'Gender',
      'email': 'Email',
      'mobileNumber': 'Phone Number',
      'dateOfBirth': 'Date of Birth',
      'street': 'Street Address',
      'city': 'City/Suburb',
      'country': 'Country',
      'jobRole': 'Job Role',
    };

    for (final entry in requiredFields.entries) {
      if ((profile[entry.key] ?? '').toString().trim().isEmpty) {
        return '${entry.value} is required. Please complete your profile first.';
      }
    }

    return null;
  }

  List<Map<String, dynamic>> _nextOfKinPayload(int employeeId) {
    return _kinControllers.asMap().entries.map((entry) {
      final controller = entry.value;
      final payload = <String, dynamic>{
        'employeeId': employeeId,
        'fullName': controller.nameController.text.trim(),
        'relationship': controller.relationshipController.text.trim(),
        'mobileNumber': controller.phoneController.text.trim(),
        'email': controller.emailController.text.trim(),
        'address': controller.addressController.text.trim(),
        'isPrimary': entry.key == 0,
      };

      final id = controller.id;
      if (id != null && id > 0) {
        payload['nextOfKinId'] = id;
      }

      return payload;
    }).toList();
  }

  Future<void> _save() async {
    final validationError = _validateNoK();
    if (validationError != null) {
      _showValidationError(validationError);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final rawEmployeeId = userProvider.userProfile['EmployeeId'] ??
          userProvider.userProfile['employeeId'];
      final employeeId = int.tryParse(rawEmployeeId?.toString() ?? '');

      debugPrint(' Saving all profile data for employeeId: $employeeId');
      if (employeeId == null) {
        throw Exception('User ID not found in userProfile');
      }

      final profileData =
          _profilePayloadFrom(userProvider.userProfile, employeeId);
      final profileValidationError = _validateRequiredProfile(profileData);
      if (profileValidationError != null) {
        _showValidationError(profileValidationError);
        return;
      }

      final nextOfKins = _nextOfKinPayload(employeeId);
      debugPrint(' Sending profile: $profileData');
      debugPrint(' Sending nextOfKins: $nextOfKins');

      final error = await _profileService.updateProfile(
        employeeId: employeeId,
        profile: profileData,
        nextOfKins: nextOfKins,
        profilePicture: widget.profilePicture,
      );

      debugPrint(' updateProfile result: $error');

      if (error == null && mounted) {
        // Refresh local UserProvider with latest data from backend
        await refreshUserProfileFromBackend(context);

        if (mounted) {
          SuccessDialog.show(
            context,
            title: 'Saved',
            message: 'Profile updated successfully.',
            buttonText: 'OK',
            onPressed: () {
              // Navigate to employee dashboard, clearing all previous screens
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => EmpBottomnavbar()),
                (route) => false,
              );
            },
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $error')),
        );
      }
    } catch (e) {
      debugPrint(' Exception saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: Background()),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: const Uppernavbar(showBackButton: true),
          drawer: const EmpSidenav(currentScreen: 'Emergency'),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: LayoutBuilder(builder: (context, constraints) {
                return Container(
                  height: constraints.maxHeight,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white))
                      : Column(
                          children: [
                            // Header row with title + add button
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Next of Kin',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  onPressed: _addEmptyKin,
                                  icon: const Icon(
                                    Icons.add_circle_outline,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white24),
                            const SizedBox(height: 8),

                            // Scrollable list of kin entries
                            Expanded(
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    ...List.generate(
                                      _kinControllers.length,
                                      (i) => _buildKinSection(i),
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                              ),
                            ),

                            // Bottom buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GradientButton(
                                  text: 'Back',
                                  isCancel: true,
                                  onPressed: () => Navigator.pop(context),
                                ),
                                GradientButton(
                                  text: _isSaving ? 'Saving...' : 'Update',
                                  onPressed: _isSaving ? () {} : _save,
                                ),
                              ],
                            ),
                          ],
                        ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKinSection(int index) {
    final c = _kinControllers[index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Next of Kin ${index + 1}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_kinControllers.length > 1)
              GestureDetector(
                onTap: () => _removeKin(index),
                child: const Icon(Icons.delete_outline,
                    color: Colors.redAccent, size: 22),
              ),
          ],
        ),
        const SizedBox(height: 10),
        _buildField('Full Name', c.nameController),
        _buildField('Relationship', c.relationshipController),
        CountryCodePhoneField(
          label: 'Mobile Number',
          controller: c.phoneController,
          labelFontSize: 14,
          fillColor: Colors.white.withValues(alpha: 0.15),
        ),
        _buildField('Email', c.emailController,
            keyboardType: TextInputType.emailAddress),
        _buildField('Address', c.addressController),
        const SizedBox(height: 12),
        if (index < _kinControllers.length - 1)
          const Divider(color: Colors.white24),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white),
            ),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: InputBorder.none,
                hintText: ' $label',
                hintStyle: const TextStyle(color: Colors.white54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class KinControllers {
  final int? id;
  final TextEditingController nameController;
  final TextEditingController relationshipController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final TextEditingController addressController;

  KinControllers({
    this.id,
    String name = '',
    String relationship = '',
    String phone = '',
    String email = '',
    String address = '',
  })  : nameController = TextEditingController(text: name),
        relationshipController = TextEditingController(text: relationship),
        phoneController = TextEditingController(text: phone),
        emailController = TextEditingController(text: email),
        addressController = TextEditingController(text: address);

  factory KinControllers.fromModel(NextOfKin kin) {
    return KinControllers(
      id: kin.nextOfKinId,
      name: kin.fullName,
      relationship: kin.relationship,
      phone: kin.mobileNumber,
      email: kin.email,
      address: kin.address,
    );
  }

  void dispose() {
    nameController.dispose();
    relationshipController.dispose();
    phoneController.dispose();
    emailController.dispose();
    addressController.dispose();
  }
}
