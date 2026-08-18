import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shiftsmart/providers/user_provider.dart';
import 'package:shiftsmart/services/profile_service.dart';
import 'package:shiftsmart/utils/country_dial_codes.dart';
import 'package:shiftsmart/utils/fullscreen_helper.dart';
import 'package:shiftsmart/utils/profile_helper.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/build_profile_avatar.dart';
import 'package:shiftsmart/widgets/country_code_phone_field.dart';
import 'package:shiftsmart/widgets/sidenav.dart';
import 'package:shiftsmart/widgets/gradient_button.dart';
import 'package:shiftsmart/widgets/uppernavbar.dart';
import 'package:shiftsmart/screens/manager/manager_next_of_kin.dart';

class ManagerProfile extends StatefulWidget {
  const ManagerProfile({super.key});

  @override
  State<ManagerProfile> createState() => _ManagerProfileState();
}

class _ManagerProfileState extends State<ManagerProfile> {
  // Navigation State
  int _currentStep = 1;
  bool _isInitialized = false;

  // Per-field inline validation errors
  final Map<String, String> _fieldErrors = {};

  // Data State
  File? _selectedProfilePicture;

  // --- Controllers: Step 1 (Personal Info) ---
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _midNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _suburbController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _postalController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  static const List<String> _genderOptions = [
    "Man",
    "Woman",
    "Non-binary",
    "I use a different term",
    "Prefer not to say",
  ];

  // --- Controllers: Step 2 (Bank & Job) ---
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _bsbController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _jobroleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    enableFullScreen();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLatestProfile();
    });
  }

  Future<void> _loadLatestProfile() async {
    await refreshUserProfileFromBackend(context);
    if (!mounted) return;
    _populateFieldsFromUserProvider();
    _isInitialized = true;
  }

  // Load initial data from UserProvider when screen opens
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isInitialized) {
        _populateFieldsFromUserProvider();
        _isInitialized = true;
      }
    });
  }

  // Helper to fill text controllers with existing user data
  void _populateFieldsFromUserProvider() {
    final userProfile =
        Provider.of<UserProvider>(context, listen: false).userProfile;

    setState(() {
      _firstNameController.text =
          _profileText(userProfile, 'firstName', 'FirstName');
      _midNameController.text =
          _profileText(userProfile, 'middleName', 'MiddleName');
      _lastNameController.text =
          _profileText(userProfile, 'lastName', 'LastName');
      _genderController.text = _profileText(userProfile, 'gender', 'Gender');
      _phoneController.text =
          _profileText(userProfile, 'mobileNumber', 'MobileNumber');
      _emailController.text = _profileText(userProfile, 'email', 'Email');
      _dateController.text =
          _profileDate(userProfile, 'dateOfBirth', 'DateOfBirth');
      _streetController.text = _profileText(userProfile, 'street', 'Street');
      _suburbController.text = _profileText(userProfile, 'city', 'City');
      _stateController.text = _profileText(userProfile, 'state', 'State');
      _postalController.text =
          _profileText(userProfile, 'postalCode', 'PostalCode');
      _countryController.text = _profileText(userProfile, 'country', 'Country');

      _accountNameController.text = _optionalBankValue(
          _profileText(userProfile, 'bankAccountName', 'BankAccountName'));
      _bsbController.text =
          _optionalBankValue(_profileText(userProfile, 'bankBSB', 'BankBSB'));
      _accountNumberController.text = _optionalBankValue(
          _profileText(userProfile, 'bankAccountNumber', 'BankAccountNumber'));
      _bankNameController.text =
          _optionalBankValue(_profileText(userProfile, 'bankName', 'BankName'));
      _jobroleController.text = _profileText(userProfile, 'jobRole', 'JobRole');
    });
  }

  String _profileText(Map<String, dynamic> profile, String key, String apiKey) {
    final normalValue = profile[key];
    if (normalValue != null && normalValue.toString().trim().isNotEmpty) {
      return normalValue.toString().trim();
    }
    return (profile[apiKey] ?? '').toString().trim();
  }

  String _profileDate(Map<String, dynamic> profile, String key, String apiKey) {
    final value = _profileText(profile, key, apiKey);
    return value.contains('T') ? value.split('T').first : value;
  }

  String _optionalBankValue(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.toUpperCase() == 'N/A' ? '' : text;
  }

  String _currentProfilePicture() {
    final userProfile =
        Provider.of<UserProvider>(context, listen: false).userProfile;
    return _profileText(userProfile, 'profilePicture', 'ProfilePicture');
  }

  //  INLINE VALIDATION
  /// Returns true if all fields in the current step are valid.
  bool _validateStep() {
    final errors = <String, String>{};

    if (_currentStep == 1) {
      final first = _firstNameController.text.trim();
      if (first.isEmpty) {
        errors['firstName'] = 'First Name is required.';
      } else if (!RegExp(r"^[a-zA-Z-\s.'-]{2,50}$").hasMatch(first))
        errors['firstName'] = '250 letters only.';

      final last = _lastNameController.text.trim();
      if (last.isEmpty) {
        errors['lastName'] = 'Last Name is required.';
      } else if (!RegExp(r"^[a-zA-Z-\s.'-]{1,50}$").hasMatch(last))
        errors['lastName'] = 'Letters only.';

      if (_genderController.text.trim().isEmpty) {
        errors['gender'] = 'Gender is required.';
      }

      final phone =
          _phoneController.text.trim().replaceAll(RegExp(r'[\s\-()]'), '');
      final phoneError = validateInternationalPhoneNumber(
        phone,
        requiredMessage: 'Phone Number is required.',
        invalidMessage: 'Please enter a valid mobile number.',
      );
      if (phoneError != null) {
        errors['phone'] = phoneError;
      }

      final email = _emailController.text.trim();
      if (email.isEmpty) {
        errors['email'] = 'Email is required.';
      } else if (!RegExp(r'^[\w._%+\-]+@[\w.\-]+\.[a-zA-Z]{2,}$')
          .hasMatch(email)) errors['email'] = 'Enter a valid email address.';

      final dob = _dateController.text.trim();
      if (dob.isEmpty) {
        errors['dob'] = 'Date of Birth is required.';
      } else {
        try {
          final dobDate = DateTime.parse(dob);
          final age = DateTime.now().difference(dobDate).inDays ~/ 365;
          if (age < 16) errors['dob'] = 'Must be at least 16 years old.';
        } catch (_) {
          errors['dob'] = 'Use format YYYY-MM-DD.';
        }
      }

      if (_streetController.text.trim().isEmpty) {
        errors['street'] = 'Street Address is required.';
      }
      if (_suburbController.text.trim().isEmpty) {
        errors['suburb'] = 'City/Suburb is required.';
      }
      if (_countryController.text.trim().isEmpty) {
        errors['country'] = 'Country is required.';
      }
      final postal = _postalController.text.trim();
      if (postal.isNotEmpty &&
          !RegExp(r'^[A-Za-z0-9\s\-]{2,10}$').hasMatch(postal)) {
        errors['postal'] = 'Enter a valid Postal/ZIP code.';
      }
    }

    if (_currentStep == 2) {
      final accNo = _optionalBankValue(_accountNumberController.text);
      if (accNo.isNotEmpty &&
          !RegExp(r'^[0-9A-Za-z\-]{4,34}$').hasMatch(accNo)) {
        errors['accountNumber'] = 'Enter a valid account number (4-34 chars).';
      }
      if (_jobroleController.text.trim().isEmpty) {
        errors['jobRole'] = 'Job Role is required.';
      }
    }

    setState(() {
      _fieldErrors.clear();
      _fieldErrors.addAll(errors);
    });
    return errors.isEmpty;
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E2E), // Match app background
              onSurface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateController.text = picked.toString().split(' ')[0];
        if (_fieldErrors.containsKey('dob')) _fieldErrors.remove('dob');
      });
    }
  }

  // Builds the profile map from current form fields
  Map<String, dynamic> _buildProfileMap() {
    return {
      "firstName": _firstNameController.text.trim(),
      "middleName": _midNameController.text.trim(),
      "lastName": _lastNameController.text.trim(),
      "gender": _genderForBackend(),
      "email": _emailController.text.trim(),
      "mobileNumber": _phoneController.text.trim(),
      "dateOfBirth": _dateController.text.trim(),
      "street": _streetController.text.trim(),
      "city": _suburbController.text.trim(),
      "state": _stateController.text.trim(),
      "postalCode": _postalController.text.trim(),
      "country": _countryController.text.trim(),
      "bankAccountName": _optionalBankValue(_accountNameController.text),
      "bankBSB": _optionalBankValue(_bsbController.text),
      "bankAccountNumber": _optionalBankValue(_accountNumberController.text),
      "bankName": _optionalBankValue(_bankNameController.text),
      "profilePicture": _currentProfilePicture(),
      "employmentStatus": "Active",
      "jobRole": _jobroleController.text.trim(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: Background()),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: const Uppernavbar(showBackButton: true),
          drawer: const Sidenav(),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    height: constraints.maxHeight,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Scrollable Form Content
                        Expanded(
                          child: SingleChildScrollView(
                            child: Form(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_currentStep == 1) _buildProfileForm(),
                                  if (_currentStep == 2) _buildBankAndJobForm(),
                                  const SizedBox(height: 30),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Bottom Navigation Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Back Button logic
                            if (_currentStep == 1)
                              GradientButton(
                                text: "Back",
                                isCancel: true,
                                onPressed: () => Navigator.pop(context),
                              ),
                            if (_currentStep > 1)
                              GradientButton(
                                text: "Back",
                                isCancel: true,
                                onPressed: () => setState(() => _currentStep--),
                              ),

                            // Next button logic
                            GradientButton(
                              text: 'Next',
                              onPressed: () {
                                if (!_validateStep()) return;
                                if (_currentStep < 2) {
                                  setState(() => _currentStep++);
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ManagerNextOfKinScreen(
                                        profileData: _buildProfileMap(),
                                        profilePicture: _selectedProfilePicture,
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Step 1: Personal Information ---
  Widget _buildProfileForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Center(
            child: ProfileAvatar(
          editable: true,
          initialImage: _selectedProfilePicture,
          onImageSelected: (File image) {
            setState(() {
              _selectedProfilePicture = image;
            });
          },
        )),
        const SizedBox(height: 20),
        _buildTextField("First Name", _firstNameController,
            errorKey: 'firstName'),
        _buildTextField("Middle Name", _midNameController),
        _buildTextField("Last Name", _lastNameController, errorKey: 'lastName'),
        _buildDropdownField("Gender", _genderController, _genderOptions,
            errorKey: 'gender'),
        CountryCodePhoneField(
          label: "Phone Number",
          controller: _phoneController,
          errorText: _fieldErrors['phone'],
          validator: (value) => validateInternationalPhoneNumber(
            value,
            requiredMessage: 'Phone Number is required.',
            invalidMessage: 'Please enter a valid mobile number.',
          ),
          onChanged: (_) {
            if (_fieldErrors.containsKey('phone')) {
              setState(() => _fieldErrors.remove('phone'));
            }
          },
        ),
        _buildTextField("Email", _emailController, errorKey: 'email'),
        _buildTextField("Date of birth", _dateController,
            errorKey: 'dob', readOnly: true, onTap: _selectDate),
        const Text("Address",
            style: TextStyle(color: Colors.white70, fontSize: 16)),
        const SizedBox(height: 12),
        _buildSubTextField("Street Address", _streetController,
            errorKey: 'street'),
        _buildSubTextField("Suburb", _suburbController, errorKey: 'suburb'),
        _buildSubTextField("State/Territory", _stateController),
        _buildSubTextField("Postal Code", _postalController,
            errorKey: 'postal', keyboardType: TextInputType.number),
        _buildSubTextField("Country", _countryController, errorKey: 'country'),
      ],
    );
  }

  // --- Step 2: Bank & Job ---
  Widget _buildBankAndJobForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        const Text("Bank Details (Optional)",
            style: TextStyle(color: Colors.white70, fontSize: 16)),
        const SizedBox(height: 12),
        _buildSubTextField("Account Name", _accountNameController,
            errorKey: 'accountName'),
        _buildSubTextField("BSB Number", _bsbController,
            keyboardType: TextInputType.number),
        _buildSubTextField("Account Number", _accountNumberController,
            keyboardType: TextInputType.number, errorKey: 'accountNumber'),
        _buildSubTextField("Bank Name", _bankNameController,
            errorKey: 'bankName'),
        const SizedBox(height: 20),
        _buildTextField("Job Role", _jobroleController, errorKey: 'jobRole'),
      ],
    );
  }

  String? _genderDropdownValue() {
    final gender = _genderController.text.trim();
    if (_genderOptions.contains(gender)) return gender;
    if (gender.toLowerCase() == 'male') return 'Man';
    if (gender.toLowerCase() == 'female') return 'Woman';
    return null;
  }

  String _genderForBackend() {
    final gender = _genderController.text.trim();
    if (gender == 'Man') return 'Male';
    if (gender == 'Woman') return 'Female';
    return gender;
  }

  // --- UI Helper: Main Text Fields ---
  Widget _buildTextField(String label, TextEditingController controller,
      {String? errorKey, bool readOnly = false, VoidCallback? onTap}) {
    final error = errorKey != null ? _fieldErrors[errorKey] : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: error != null ? Colors.redAccent : Colors.white),
            ),
            child: TextField(
              controller: controller,
              readOnly: readOnly,
              onTap: onTap,
              style: const TextStyle(color: Colors.white70),
              onChanged: (_) {
                if (errorKey != null && _fieldErrors.containsKey(errorKey)) {
                  setState(() => _fieldErrors.remove(errorKey));
                }
              },
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: InputBorder.none,
                hintText: ' $label',
                hintStyle: const TextStyle(color: Colors.white70),
                suffixIcon: onTap != null
                    ? const Icon(Icons.calendar_today,
                        color: Colors.white70, size: 20)
                    : null,
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.error_outline,
                  color: Colors.redAccent, size: 14),
              const SizedBox(width: 4),
              Expanded(
                  child: Text(error,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 12))),
            ]),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    TextEditingController controller,
    List<String> items, {
    String? errorKey,
  }) {
    final error = errorKey != null ? _fieldErrors[errorKey] : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: error != null ? Colors.redAccent : Colors.white),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _genderDropdownValue(),
                hint: Text(' $label',
                    style: const TextStyle(color: Colors.white70)),
                dropdownColor: const Color(0xFF2A3240),
                icon: const Icon(Icons.keyboard_arrow_down,
                    color: Colors.white70),
                isExpanded: true,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                items: items
                    .map((item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    controller.text = value;
                    if (errorKey != null) _fieldErrors.remove(errorKey);
                  });
                },
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.error_outline,
                  color: Colors.redAccent, size: 14),
              const SizedBox(width: 4),
              Expanded(
                  child: Text(error,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 12))),
            ]),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // --- UI Helper: Sub Text Fields ---
  Widget _buildSubTextField(
    String label,
    TextEditingController controller, {
    String? errorKey,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final error = errorKey != null ? _fieldErrors[errorKey] : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: error != null ? Colors.redAccent : Colors.white),
            ),
            child: TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              keyboardType: keyboardType,
              onChanged: (_) {
                if (errorKey != null && _fieldErrors.containsKey(errorKey))
                  setState(() => _fieldErrors.remove(errorKey));
              },
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: InputBorder.none,
                hintText: ' $label',
                hintStyle: const TextStyle(color: Colors.white70),
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 4),
            Row(children: [
              const SizedBox(width: 4),
              const Icon(Icons.error_outline,
                  color: Colors.redAccent, size: 14),
              const SizedBox(width: 4),
              Expanded(
                  child: Text(error,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 12))),
            ]),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
