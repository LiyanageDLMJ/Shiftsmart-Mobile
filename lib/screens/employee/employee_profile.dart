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
import 'package:shiftsmart/widgets/emp_slidenav.dart';
import 'package:shiftsmart/widgets/gradient_button.dart';
import 'package:shiftsmart/widgets/uppernavbar.dart';
import 'package:shiftsmart/widgets/success_dialog.dart';
import 'package:shiftsmart/screens/employee/employee_next_of_kin.dart';

class EmployeeProfile extends StatefulWidget {
  const EmployeeProfile({super.key});

  @override
  State<EmployeeProfile> createState() => _EmployeeProfileState();
}

class _EmployeeProfileState extends State<EmployeeProfile> {
  // Navigation State
  int _currentStep = 1;
  bool _isInitialized = false;
  final bool _isLoading = false;
  final FocusNode _countryFocusNode = FocusNode();

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
    "Male",
    "Female",
  ];

  static const Map<String, List<String>> _countryStates = {
    "Australia": [
      "ACT",
      "NSW",
      "NT",
      "QLD",
      "SA",
      "TAS",
      "VIC",
      "WA",
    ],
    "Sri Lanka": [
      "Central",
      "Eastern",
      "North Central",
      "Northern",
      "North Western",
      "Sabaragamuwa",
      "Southern",
      "Uva",
      "Western",
    ],
    "United States": [
      "Alabama",
      "Alaska",
      "Arizona",
      "Arkansas",
      "California",
      "Colorado",
      "Connecticut",
      "Delaware",
      "Florida",
      "Georgia",
      "Hawaii",
      "Idaho",
      "Illinois",
      "Indiana",
      "Iowa",
      "Kansas",
      "Kentucky",
      "Louisiana",
      "Maine",
      "Maryland",
      "Massachusetts",
      "Michigan",
      "Minnesota",
      "Mississippi",
      "Missouri",
      "Montana",
      "Nebraska",
      "Nevada",
      "New Hampshire",
      "New Jersey",
      "New Mexico",
      "New York",
      "North Carolina",
      "North Dakota",
      "Ohio",
      "Oklahoma",
      "Oregon",
      "Pennsylvania",
      "Rhode Island",
      "South Carolina",
      "South Dakota",
      "Tennessee",
      "Texas",
      "Utah",
      "Vermont",
      "Virginia",
      "Washington",
      "West Virginia",
      "Wisconsin",
      "Wyoming",
    ],
    "India": [
      "Andhra Pradesh",
      "Arunachal Pradesh",
      "Assam",
      "Bihar",
      "Chhattisgarh",
      "Goa",
      "Gujarat",
      "Haryana",
      "Himachal Pradesh",
      "Jharkhand",
      "Karnataka",
      "Kerala",
      "Madhya Pradesh",
      "Maharashtra",
      "Manipur",
      "Meghalaya",
      "Mizoram",
      "Nagaland",
      "Odisha",
      "Punjab",
      "Rajasthan",
      "Sikkim",
      "Tamil Nadu",
      "Telangana",
      "Tripura",
      "Uttar Pradesh",
      "Uttarakhand",
      "West Bengal",
    ],
    "New Zealand": [
      "Auckland",
      "Bay of Plenty",
      "Canterbury",
      "Gisborne",
      "Hawke's Bay",
      "Manawatu-Wanganui",
      "Marlborough",
      "Nelson",
      "Northland",
      "Otago",
      "Southland",
      "Taranaki",
      "Tasman",
      "Waikato",
      "Wellington",
      "West Coast",
    ],
    "Canada": [
      "Alberta",
      "British Columbia",
      "Manitoba",
      "New Brunswick",
      "Newfoundland and Labrador",
      "Northwest Territories",
      "Nova Scotia",
      "Nunavut",
      "Ontario",
      "Prince Edward Island",
      "Quebec",
      "Saskatchewan",
      "Yukon",
    ],
  };

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

  @override
  void dispose() {
    _countryFocusNode.dispose();
    _firstNameController.dispose();
    _midNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _dateController.dispose();
    _streetController.dispose();
    _suburbController.dispose();
    _stateController.dispose();
    _postalController.dispose();
    _countryController.dispose();
    _genderController.dispose();
    _accountNameController.dispose();
    _bsbController.dispose();
    _accountNumberController.dispose();
    _bankNameController.dispose();
    _jobroleController.dispose();
    super.dispose();
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

  String? get _selectedCountryName {
    final selectedCountry = _countryController.text.trim().toLowerCase();
    if (selectedCountry.isEmpty) return null;

    for (final countryName in _countryStates.keys) {
      if (countryName.toLowerCase() == selectedCountry) return countryName;
    }
    return null;
  }

  List<String> get _selectedCountryStates {
    final countryName = _selectedCountryName;
    return countryName == null ? const [] : _countryStates[countryName]!;
  }

  bool get _hasKnownCountry {
    final country = _countryController.text.trim().toLowerCase();
    if (country.isEmpty) return false;
    return countryDialCodes.any((item) => item.name.toLowerCase() == country);
  }

  void _handleCountryChanged(String countryName) {
    final nextStates = _countryStates[countryName] ?? const <String>[];
    final shouldClearState =
        nextStates.isNotEmpty && !nextStates.contains(_stateController.text);

    setState(() {
      _countryController.text = countryName;
      _fieldErrors.remove('country');
      if (shouldClearState) {
        _stateController.clear();
        _fieldErrors.remove('state');
      }
    });
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
      if (phone.isEmpty) {
        errors['phone'] = 'Phone Number is required.';
      } else if (!RegExp(r'^\+?[1-9]\d{6,14}$').hasMatch(phone))
        errors['phone'] = 'Use international format, e.g. +94771234567';

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
        errors['suburb'] = 'City is required.';
      }

      final state = _stateController.text.trim();
      if (state.isEmpty) {
        errors['state'] = 'State is required.';
      } else if (_selectedCountryStates.isNotEmpty &&
          !_selectedCountryStates.contains(state)) {
        errors['state'] = 'Select a valid state.';
      }

      if (_countryController.text.trim().isEmpty) {
        errors['country'] = 'Country is required.';
      } else if (!_hasKnownCountry) {
        errors['country'] = 'Select a valid country.';
      }

      final postal = _postalController.text.trim();
      if (postal.isEmpty) {
        errors['postal'] = 'Postal Code is required.';
      } else if (!RegExp(r'^[A-Za-z0-9\s\-]{2,10}$').hasMatch(postal)) {
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

  // Sends updated data to the backend
  // Returns true if successful, false otherwise
  Future<bool> _updateProfile(File? profilePictureFile) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final employeeId = userProvider.userProfile['employeeId'] ??
        userProvider.userProfile['EmployeeId'];

    if (employeeId == null) {
      debugPrint('Error: employeeId missing from userProfile');
      return false;
    }

    // Construct the profile object
    final profile = {
      "firstName": _firstNameController.text,
      "middleName": _midNameController.text,
      "lastName": _lastNameController.text,
      "gender": _genderForBackend(),
      "email": _emailController.text,
      "mobileNumber": _phoneController.text,
      "dateOfBirth": _dateController.text,
      "street": _streetController.text,
      "city": _suburbController.text,
      "state": _stateController.text,
      "postalCode": _postalController.text,
      "country": _countryController.text,
      "bankAccountName": _optionalBankValue(_accountNameController.text),
      "bankBSB": _optionalBankValue(_bsbController.text),
      "bankAccountNumber": _optionalBankValue(_accountNumberController.text),
      "bankName": _optionalBankValue(_bankNameController.text),
      "profilePicture": _currentProfilePicture(),
      "employmentStatus": "Active",
      "jobRole": _jobroleController.text
    };

    final error = await ProfileService().updateProfile(
      employeeId: employeeId,
      profile: profile,
      nextOfKins: const [],
      profilePicture: profilePictureFile,
    );

    return error == null;
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
          drawer: const EmpSidenav(currentScreen: 'Profile'),
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
                                      builder: (_) => EmployeeNextOfKinScreen(
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
            errorKey: 'firstName', readOnly: true),
        _buildTextField("Middle Name", _midNameController, readOnly: true),
        _buildTextField("Last Name", _lastNameController,
            errorKey: 'lastName', readOnly: true),
        _buildDropdownField("Gender", _genderController, _genderOptions,
            errorKey: 'gender'),
        CountryCodePhoneField(
          label: "Phone Number",
          controller: _phoneController,
          errorText: _fieldErrors['phone'],
          onChanged: (_) {
            if (_fieldErrors.containsKey('phone')) {
              setState(() => _fieldErrors.remove('phone'));
            }
          },
        ),
        _buildTextField("Date of birth", _dateController,
            errorKey: 'dob', readOnly: true),
        const Text("Address",
            style: TextStyle(color: Colors.white70, fontSize: 16)),
        const SizedBox(height: 12),
        _buildCountryAutocomplete(),
        if (_selectedCountryStates.isNotEmpty)
          _buildSubDropdownField(
            "State",
            _stateController,
            _selectedCountryStates,
            errorKey: 'state',
          )
        else
          _buildSubTextField("State", _stateController, errorKey: 'state'),
        _buildSubTextField("City", _suburbController, errorKey: 'suburb'),
        _buildSubTextField("Street", _streetController, errorKey: 'street'),
        _buildSubTextField("Postal Code", _postalController,
            errorKey: 'postal', keyboardType: TextInputType.number),
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
        _buildTextField("Job Role", _jobroleController,
            errorKey: 'jobRole', readOnly: true),
      ],
    );
  }

  String? _genderDropdownValue() {
    final gender = _genderController.text.trim();
    if (_genderOptions.contains(gender)) return gender;
    if (gender.toLowerCase() == 'man') return 'Male';
    if (gender.toLowerCase() == 'woman') return 'Female';
    return null;
  }

  String _genderForBackend() {
    return _genderDropdownValue() ?? _genderController.text.trim();
  }

  Widget _buildInlineError(String error) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(children: [
        const SizedBox(width: 4),
        const Icon(Icons.error_outline, color: Colors.redAccent, size: 14),
        const SizedBox(width: 4),
        Expanded(
            child: Text(error,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
      ]),
    );
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

  Widget _buildCountryAutocomplete() {
    final error = _fieldErrors['country'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RawAutocomplete<CountryDialCode>(
            textEditingController: _countryController,
            focusNode: _countryFocusNode,
            displayStringForOption: (country) => country.name,
            optionsBuilder: (textEditingValue) {
              final query = textEditingValue.text.trim().toLowerCase();
              if (query.isEmpty) return const Iterable<CountryDialCode>.empty();

              return countryDialCodes
                  .where((country) =>
                      country.name.toLowerCase().startsWith(query) ||
                      country.name.toLowerCase().contains(query))
                  .take(12);
            },
            onSelected: (country) => _handleCountryChanged(country.name),
            fieldViewBuilder:
                (context, textEditingController, focusNode, onFieldSubmitted) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: error != null ? Colors.redAccent : Colors.white),
                ),
                child: TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  onSubmitted: (_) => onFieldSubmitted(),
                  onChanged: (value) {
                    final matchedCountry = countryDialCodes.where((country) =>
                        country.name.toLowerCase() ==
                        value.trim().toLowerCase());
                    if (matchedCountry.isEmpty) {
                      setState(() {
                        _fieldErrors.remove('country');
                      });
                      return;
                    }

                    _handleCountryChanged(matchedCountry.first.name);
                  },
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: InputBorder.none,
                    hintText: ' Country',
                    hintStyle: TextStyle(color: Colors.white70),
                    suffixIcon: Icon(Icons.arrow_drop_down,
                        color: Colors.white70, size: 24),
                  ),
                ),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: const Color(0xFF111D35),
                  elevation: 8,
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxHeight: 260, maxWidth: 600),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final country = options.elementAt(index);
                        return InkWell(
                          onTap: () => onSelected(country),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            child: Row(
                              children: [
                                Text(country.flag,
                                    style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    country.name,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          if (error != null) _buildInlineError(error),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSubDropdownField(
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
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: error != null ? Colors.redAccent : Colors.white),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: items.contains(controller.text) ? controller.text : null,
                hint: Text(' $label',
                    style: const TextStyle(color: Colors.white70)),
                dropdownColor: const Color(0xFF2A3240),
                icon: const Icon(Icons.keyboard_arrow_down,
                    color: Colors.white70),
                isExpanded: true,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                style: const TextStyle(color: Colors.white, fontSize: 16),
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
          if (error != null) _buildInlineError(error),
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
