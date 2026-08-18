import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shiftsmart/services/employee_service.dart';
import 'package:shiftsmart/services/job_service.dart';
import 'package:shiftsmart/models/job_role_type.dart';
import 'package:shiftsmart/services/onboarding_service.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/build_profile_avatar.dart';
import 'package:shiftsmart/widgets/gradient_button.dart';
import 'package:shiftsmart/screens/login.dart';
import 'package:shiftsmart/utils/country_dial_codes.dart';

class _DialCountry {
  final String name;
  final String code;
  final String flag;

  const _DialCountry({
    required this.name,
    required this.code,
    required this.flag,
  });
}

class Emponboard extends StatefulWidget {
  final String email;
  final Map<String, dynamic>? existingProfile;
  final int? employeeId;
  final String? rejectionReason;

  const Emponboard({
    super.key,
    required this.email,
    this.existingProfile,
    this.employeeId,
    this.rejectionReason,
  });

  @override
  State<Emponboard> createState() => _EmponboardState();
}

class _EmponboardState extends State<Emponboard> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final OnboardingService _service = OnboardingService();

  int _currentStep = 1;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isResubmission = false;

  bool _isLoadingBank = false;
  bool _isBankNameReadOnly = false;
  final FocusNode _bsbFocusNode = FocusNode();
  final FocusNode _countryFocusNode = FocusNode();

  Key _avatarKey = UniqueKey();

  // Controllers
  final _firstNameCtrl = TextEditingController();
  final _midNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();

  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();

  final _tfnCtrl = TextEditingController();
  final _abnCtrl = TextEditingController();

  final _accNameCtrl = TextEditingController();
  final _bsbCtrl = TextEditingController();
  final _accNumCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();

  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final _nokNameCtrl = TextEditingController();
  final _nokRelCtrl = TextEditingController();
  final _nokPhoneCtrl = TextEditingController();
  final _nokEmailCtrl = TextEditingController();
  final _nokAddressCtrl = TextEditingController();
  bool _forceNokFieldValidation = false;

  String _jobRole = "";
  String _empType = "";
  String? _invitationToken;
  int? _invitationId;
  List<String> _requiredDocs = [];
  List<String> _rejectedKeys = [];

  File? _profilePic;
  bool _profileImageError = false;
  final Map<String, List<File>> _uploadedDocs = {};
  final Map<String, int> _requiredDocIds = {};
  final Set<String> _resubmittedDocs = {};
  String? _updatingDocName;

  String? _gender;

  final List<String> _genderOptions = [
    "Male",
    "Female",
  ];

  final Map<String, List<String>> _countryStates = const {
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

  final List<Map<String, dynamic>> _nokList = [];

  static final List<_DialCountry> _dialCountries = countryDialCodes
      .map((country) => _DialCountry(
            name: country.name,
            code: country.dialCode,
            flag: country.flag,
          ))
      .toList(growable: false);

  _DialCountry _selectedProfileCountry = _dialCountries.first;
  _DialCountry _selectedNokCountry = _dialCountries.first;

  final List<String> _allAvailableDocTypes = [
    "National ID",
    "Resume",
    "Electrical License",
    "White Card",
    "Driver's License",
    "RSA",
    "Police Check",
    "Passport",
    "Visa",
    "Other Certificate",
  ];

  @override
  void initState() {
    super.initState();
    _profilePic = null;

    if (widget.rejectionReason != null && widget.rejectionReason!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showRejectionReasonDialog(widget.rejectionReason!);
      });
    }

    _initData();
    _bsbFocusNode.addListener(() {
      if (!_bsbFocusNode.hasFocus) {
        String clean = _bsbCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
        if (clean.length == 6) _handleBsbLookup();
      }
    });
  }

  @override
  void dispose() {
    _bsbFocusNode.dispose();
    _countryFocusNode.dispose();
    _firstNameCtrl.dispose();
    _midNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _zipCtrl.dispose();
    _countryCtrl.dispose();
    _tfnCtrl.dispose();
    _abnCtrl.dispose();
    _accNameCtrl.dispose();
    _bsbCtrl.dispose();
    _accNumCtrl.dispose();
    _bankNameCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _nokNameCtrl.dispose();
    _nokRelCtrl.dispose();
    _nokPhoneCtrl.dispose();
    _nokEmailCtrl.dispose();
    _nokAddressCtrl.dispose();
    super.dispose();
  }

  void _setPhoneFromInternational(
    TextEditingController controller,
    String? rawValue,
    ValueChanged<_DialCountry> onCountryChanged,
  ) {
    final value = (rawValue ?? '').trim();
    if (value.isEmpty) {
      controller.clear();
      return;
    }

    final cleanValue = value.replaceAll(RegExp(r'\s|-|\(|\)'), '');
    final country = _dialCountries
        .where((country) => cleanValue.startsWith(country.code))
        .fold<_DialCountry?>(null, (best, country) {
      if (best == null || country.code.length > best.code.length) {
        return country;
      }
      return best;
    });

    if (country == null) {
      controller.text = value.replaceAll(RegExp(r'[^0-9]'), '');
      return;
    }

    onCountryChanged(country);
    controller.text = cleanValue
        .substring(country.code.length)
        .replaceAll(RegExp(r'[^0-9]'), '');
  }

  String _buildFullPhoneNumber(
    TextEditingController controller,
    _DialCountry country,
  ) {
    var localNumber = controller.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (localNumber.startsWith('0')) {
      localNumber = localNumber.substring(1);
    }
    if (localNumber.isEmpty) return '';
    return '${country.code}$localNumber';
  }

  String? _validatePhoneNumber(
    String? value, {
    required String label,
    String? countryName,
    bool optional = false,
  }) {
    return validateNationalPhoneNumber(
      value,
      countryName: countryName,
      optional: optional,
      requiredMessage: '$label is required',
      invalidMessage: 'Please enter a valid $label',
    );
  }

  String? _validateAge(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "Date of Birth is required";

    final date = DateTime.tryParse(dateStr.split('T').first);
    if (date == null) return "Enter a valid date of birth";

    final today = DateTime.now();
    var age = today.year - date.year;
    if (today.month < date.month ||
        (today.month == date.month && today.day < date.day)) {
      age--;
    }

    return age >= 16 ? null : "You must be at least 16 years old";
  }

  String? _validatePostcode(String? value) {
    final postcode = (value ?? '').trim();
    if (postcode.isEmpty) return "Postcode is required";
    return RegExp(r'^\d{4}$').hasMatch(postcode)
        ? null
        : "Postcode must be exactly 4 digits";
  }

  String? _validateTfn(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return "TFN is required";
    return RegExp(r'^\d{8,9}$').hasMatch(digits)
        ? null
        : "TFN must be 8 or 9 digits";
  }

  String? _validateBsb(String? value) {
    final bsb = (value ?? '').trim();
    if (bsb.isEmpty) return "BSB is required";
    return RegExp(r'^\d{3}-\d{3}$').hasMatch(bsb)
        ? null
        : "BSB must match XXX-XXX";
  }

  String? _validateAccountNumber(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return "Account Number is required";
    return RegExp(r'^\d{6,10}$').hasMatch(digits)
        ? null
        : "Account number must be 6-10 digits";
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return "New Password is required";
    if (password.length < 8) return "Password must be at least 8 characters";
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return "Password needs one uppercase letter";
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      return "Password needs one number";
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return "Confirm Password is required";
    return value == _passCtrl.text ? null : "Passwords do not match";
  }

  String? _validateEmail(String? value, {bool optional = false}) {
    final email = (value ?? '').trim();
    if (email.isEmpty) return optional ? null : "Email is required";
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email) ? null : "Enter a valid email address";
  }

  String? get _selectedCountryName {
    final selectedCountry = _countryCtrl.text.trim().toLowerCase();
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

  void _handleCountryChanged(String countryName) {
    final nextStates = _countryStates[countryName] ?? const <String>[];
    final shouldClearState =
        nextStates.isNotEmpty && !nextStates.contains(_stateCtrl.text);

    setState(() {
      _countryCtrl.text = countryName;
      if (shouldClearState) _stateCtrl.clear();
    });
  }

  bool _validateCurrentStep() {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    var isStepValid = isFormValid;

    if (_currentStep == 1 && _shouldShow("FullName")) {
      final needsProfileImage = !_isResubmission;
      final hasProfileImage = _profilePic != null;
      setState(
          () => _profileImageError = needsProfileImage && !hasProfileImage);
      if (needsProfileImage && !hasProfileImage) {
        isStepValid = false;
      }
    }

    return isStepValid;
  }

  bool get _hasNokDraft {
    return _nokNameCtrl.text.trim().isNotEmpty ||
        _nokRelCtrl.text.trim().isNotEmpty ||
        _nokPhoneCtrl.text.trim().isNotEmpty ||
        _nokEmailCtrl.text.trim().isNotEmpty ||
        _nokAddressCtrl.text.trim().isNotEmpty;
  }

  bool get _shouldValidateNokFields {
    if (!_isEditable("NextOfKin")) return false;
    return _forceNokFieldValidation || _nokList.isEmpty || _hasNokDraft;
  }

  String _readDocumentType(dynamic doc) {
    if (doc is String) return doc.trim();
    if (doc is! Map) return '';
    final value = doc['DocumentType'] ??
        doc['documentType'] ??
        doc['FileType'] ??
        doc['fileType'] ??
        doc['Name'] ??
        doc['name'];
    return value?.toString().trim() ?? '';
  }

  int? _readDocumentId(dynamic doc) {
    if (doc is! Map) return null;
    final value = doc['DocumentId'] ??
        doc['documentId'] ??
        doc['Id'] ??
        doc['id'] ??
        doc['CertificateId'] ??
        doc['certificateId'];
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  String? _readFirstStringByKeys(dynamic source, List<String> keys) {
    if (source is Map) {
      for (final key in keys) {
        final value = source[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString().trim();
        }
      }

      for (final value in source.values) {
        final nested = _readFirstStringByKeys(value, keys);
        if (nested != null && nested.isNotEmpty) return nested;
      }
    } else if (source is List) {
      for (final value in source) {
        final nested = _readFirstStringByKeys(value, keys);
        if (nested != null && nested.isNotEmpty) return nested;
      }
    }
    return null;
  }

  int? _readInvitationId(dynamic source) {
    final value = _readFirstStringByKeys(source, const [
      'invitationId',
      'InvitationId',
      'InvitationID',
    ]);
    return int.tryParse(value ?? '');
  }

  void _applyInvitationAuthData(Map<String, dynamic> data) {
    _invitationToken = _readFirstStringByKeys(data, const [
      'token',
      'Token',
      'invitationToken',
      'InvitationToken',
      'onboardingToken',
      'OnboardingToken',
    ]);
    _invitationId = _readInvitationId(data);
  }

  bool _stepHasContent(int step) {
    if (!_isResubmission) return true;
    if (step == 4) return _requiredDocs.isNotEmpty;
    return step >= 1 && step <= 3;
  }

  int? _getNextStep(int current) {
    for (int i = current + 1; i <= 4; i++) {
      if (_stepHasContent(i)) return i;
    }
    return null;
  }

  int? _getPrevStep(int current) {
    for (int i = current - 1; i >= 1; i--) {
      if (_stepHasContent(i)) return i;
    }
    return null;
  }

  bool _shouldShow(String key) => true;

  bool _isEditable(String key) {
    if (!_isResubmission) return true;
    return _rejectedKeys.contains(key);
  }

  Future<void> _initData() async {
    if (widget.existingProfile != null) {
      _mapResubmissionData(widget.existingProfile!);
    } else {
      final data = await _service.fetchInvitation(widget.email);
      if (data != null) {
        _mapInvitationData(data);
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleBsbLookup() async {
    String bsb = _bsbCtrl.text.trim();
    String cleanBsb = bsb.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanBsb.length != 6) return;

    setState(() => _isLoadingBank = true);
    try {
      final result = await EmployeeService().lookupBank(cleanBsb);
      if (result['status'] == 'Found') {
        setState(() {
          _bankNameCtrl.text = result['bankName'].toString();
          _isBankNameReadOnly = true;
        });
      } else {
        setState(() {
          _bankNameCtrl.clear();
          _isBankNameReadOnly = false;
        });
      }
    } catch (e) {
      setState(() => _isBankNameReadOnly = false);
    } finally {
      if (mounted) setState(() => _isLoadingBank = false);
    }
  }

  void _mapResubmissionData(Map<String, dynamic> data) {
    setState(() {
      _isResubmission = true;
      final rejectedFieldsRaw =
          data['rejectedFields'] ?? data['RejectedFields'] ?? [];

      _rejectedKeys = List<String>.from(rejectedFieldsRaw);

      final rejectedDocsList = (data['rejectedDocuments'] ??
          data['RejectedDocuments'] ??
          []) as List<dynamic>;
      _requiredDocs = [];
      _requiredDocIds.clear();
      _resubmittedDocs.clear();
      if (rejectedDocsList.isNotEmpty) {
        for (final doc in rejectedDocsList) {
          final docType = _readDocumentType(doc);
          if (docType.isEmpty) continue;

          _requiredDocs.add(docType);
          final docId = _readDocumentId(doc);
          if (docId != null && docId > 0) {
            _requiredDocIds[docType] = docId;
          }
        }
      }

      final profile = data['profile'] ?? data['Profile'] ?? {};
      String fullName =
          (profile['fullName'] ?? profile['FullName'] ?? '').toString().trim();
      List<String> nameParts = fullName.split(RegExp(r'\s+'));

      if (nameParts.isNotEmpty) {
        _firstNameCtrl.text = nameParts.first;
        if (nameParts.length == 2) {
          _lastNameCtrl.text = nameParts.last;
        } else if (nameParts.length > 2) {
          _midNameCtrl.text =
              nameParts.sublist(1, nameParts.length - 1).join(' ');
          _lastNameCtrl.text = nameParts.last;
        }
      }

      _dobCtrl.text = (profile['dateOfBirth'] ?? profile['DateOfBirth'] ?? '')
          .toString()
          .split('T')
          .first;
      _setPhoneFromInternational(
        _phoneCtrl,
        (profile['mobileNumber'] ?? profile['MobileNumber'])?.toString(),
        (country) => _selectedProfileCountry = country,
      );

      String? incomingGender =
          (profile['gender'] ?? profile['Gender'])?.toString();
      if (incomingGender != null) {
        if (_genderOptions.contains(incomingGender)) {
          _gender = incomingGender;
        } else if (incomingGender.toLowerCase() == "male" ||
            incomingGender.toLowerCase() == "man") {
          _gender = "Male";
        } else if (incomingGender.toLowerCase() == "female" ||
            incomingGender.toLowerCase() == "woman") {
          _gender = "Female";
        } else {
          _gender = null;
        }
      }

      final address = profile['address'] ?? profile['Address'] ?? {};
      if (address is Map) {
        _streetCtrl.text =
            (address['street'] ?? address['Street'] ?? '').toString();
        _cityCtrl.text = (address['city'] ?? address['City'] ?? '').toString();
        _stateCtrl.text =
            (address['state'] ?? address['State'] ?? '').toString();
        _zipCtrl.text =
            (address['postalCode'] ?? address['PostalCode'] ?? '').toString();
        _countryCtrl.text =
            (address['country'] ?? address['Country'] ?? '').toString();
      } else {
        final rawAddress = address.toString();
        final addrParts = rawAddress.split(',').map((s) => s.trim()).toList();
        if (addrParts.isNotEmpty) _streetCtrl.text = addrParts[0];
        if (addrParts.length > 1) _cityCtrl.text = addrParts[1];
        if (addrParts.length > 2) _stateCtrl.text = addrParts[2];
        if (addrParts.length > 3) _zipCtrl.text = addrParts[3];
        if (addrParts.length > 4) _countryCtrl.text = addrParts[4];
      }

      final bank = profile['bank'] ?? profile['Bank'] ?? {};
      if (bank is Map) {
        _bankNameCtrl.text =
            (bank['bankName'] ?? bank['BankName'] ?? bank['Name'] ?? '')
                .toString();
        _bsbCtrl.text =
            (bank['bsb'] ?? bank['BSB'] ?? bank['bankBSB'] ?? '').toString();
        _accNumCtrl.text =
            (bank['accountNumber'] ?? bank['AccountNumber'] ?? '').toString();
        _accNameCtrl.text =
            (bank['accountName'] ?? bank['AccountName'] ?? '').toString();
      }

      final tax = profile['taxInfo'] ?? profile['TaxInfo'] ?? {};
      if (tax is Map) {
        _empType =
            (tax['employmentType'] ?? tax['EmploymentType'] ?? 'PAYG Employee')
                .toString();
        _tfnCtrl.text = (tax['tfn'] ?? tax['Tfn'] ?? '').toString();
        _abnCtrl.text = (tax['abn'] ?? tax['Abn'] ?? '').toString();
      }

      _jobRole = (profile['jobRole'] ?? profile['JobRole'] ?? 'Standard Role')
          .toString();

      final noksRaw = profile['nextOfKins'] ?? profile['NextOfKins'] ?? [];
      final noks = noksRaw is List ? noksRaw : <dynamic>[];
      _nokList.clear();
      for (var nok in noks) {
        _nokList.add({
          "nextOfKinId": nok['nextOfKinId'] ?? nok['NextOfKinId'],
          "fullName": nok['fullName'] ?? nok['FullName'] ?? '',
          "relationship": nok['relationship'] ?? nok['Relationship'] ?? '',
          "mobileNumber": nok['mobileNumber'] ?? nok['MobileNumber'] ?? '',
          "email": nok['email'] ?? nok['Email'] ?? '',
          "address": nok['address'] ?? nok['Address'] ?? '',
        });
      }
      if (_nokList.isNotEmpty) {
        final firstNok = _nokList.first;
        _nokNameCtrl.text = firstNok["fullName"]?.toString() ?? "";
        _nokRelCtrl.text = firstNok["relationship"]?.toString() ?? "";
        _setPhoneFromInternational(
          _nokPhoneCtrl,
          firstNok["mobileNumber"]?.toString(),
          (country) => _selectedNokCountry = country,
        );
        _nokEmailCtrl.text = firstNok["email"]?.toString() ?? "";
        _nokAddressCtrl.text = firstNok["address"]?.toString() ?? "";
      }
      _isLoading = false;
    });
  }

  void _mapInvitationData(Map<String, dynamic> data) {
    setState(() {
      _isResubmission = false;
      String fullName = (data['name'] ?? data['Name'] ?? '').trim();
      List<String> nameParts = fullName.split(RegExp(r'\s+'));

      if (nameParts.isNotEmpty) {
        _firstNameCtrl.text = nameParts.first;
        if (nameParts.length == 2) {
          _lastNameCtrl.text = nameParts.last;
        } else if (nameParts.length > 2) {
          _midNameCtrl.text =
              nameParts.sublist(1, nameParts.length - 1).join(' ');
          _lastNameCtrl.text = nameParts.last;
        }
      }

      _setPhoneFromInternational(
        _phoneCtrl,
        (data['phone'] ?? data['Phone'])?.toString(),
        (country) => _selectedProfileCountry = country,
      );
      _applyInvitationAuthData(data);
      _jobRole = data['jobRole'] ?? data['JobRole'] ?? '';
      _empType = data['employmentType'] ?? data['EmploymentType'] ?? '';

      dynamic docsRaw = data['requiredCertificates'] ??
          data['RequiredDocuments'] ??
          data['RequiredCertificates'] ??
          data['Certificates'] ??
          data['Documents'] ??
          data['required_documents'];

      if (docsRaw != null) {
        if (docsRaw is List) {
          _requiredDocs = docsRaw
              .map(_readDocumentType)
              .where((e) => e.isNotEmpty)
              .toList();
        } else if (docsRaw is String) {
          _requiredDocs = docsRaw
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      }

      if (_requiredDocs.isEmpty && _jobRole.isNotEmpty) {
        _fetchRoleRequirements();
      }
      _isLoading = false;
    });
  }

  Future<void> _fetchRoleRequirements() async {
    try {
      final List<JobRoleType> roles = await JobService().fetchJobRoleType();
      final target = roles.firstWhere(
        (r) => r.name.toLowerCase() == _jobRole.toLowerCase(),
        orElse: () => JobRoleType.unKnown(),
      );

      if (target.id != 0 && target.requiredDocuments.isNotEmpty) {
        setState(() {
          _requiredDocs = target.requiredDocuments;
        });
      }
    } catch (e) {
      debugPrint(" Error fetching role requirements: $e");
    }
  }

  void _pickProfileImage() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (ctx) => Wrap(children: [
        ListTile(
          leading: const Icon(Icons.camera_alt, color: Colors.white),
          title:
              const Text('Take Photo', style: TextStyle(color: Colors.white)),
          onTap: () async {
            Navigator.pop(ctx);
            final XFile? img = await ImagePicker()
                .pickImage(source: ImageSource.camera, imageQuality: 80);
            if (img != null) {
              setState(() {
                _profilePic = File(img.path);
                _profileImageError = false;
                _avatarKey = UniqueKey();
              });
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.photo_library, color: Colors.white),
          title:
              const Text('From Gallery', style: TextStyle(color: Colors.white)),
          onTap: () async {
            Navigator.pop(ctx);
            final XFile? img = await ImagePicker()
                .pickImage(source: ImageSource.gallery, imageQuality: 80);
            if (img != null) {
              setState(() {
                _profilePic = File(img.path);
                _profileImageError = false;
                _avatarKey = UniqueKey();
              });
            }
          },
        ),
      ]),
    );
  }

  Future<List<File>> _selectDocumentFiles({bool directCamera = false}) async {
    if (directCamera) {
      final file = await _openCamera();
      return file == null ? [] : [file];
    }

    return await showModalBottomSheet<List<File>>(
          context: context,
          backgroundColor: Colors.grey[900],
          builder: (ctx) => Wrap(children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white),
              title: const Text('Take Photo',
                  style: TextStyle(color: Colors.white)),
              onTap: () async {
                final file = await _openCamera();
                if (ctx.mounted) Navigator.pop(ctx, file == null ? [] : [file]);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white),
              title: const Text('From Gallery',
                  style: TextStyle(color: Colors.white)),
              onTap: () async {
                final images =
                    await ImagePicker().pickMultiImage(imageQuality: 80);
                if (ctx.mounted) {
                  Navigator.pop(
                    ctx,
                    images.map((image) => File(image.path)).toList(),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file, color: Colors.white),
              title: const Text('Pick Files',
                  style: TextStyle(color: Colors.white)),
              onTap: () async {
                FilePickerResult? result = await FilePicker.pickFiles(
                  type: FileType.custom,
                  allowMultiple: true,
                  allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                );
                final files = result?.files
                        .where((file) => file.path != null)
                        .map((file) => File(file.path!))
                        .toList() ??
                    [];
                if (ctx.mounted) {
                  Navigator.pop(ctx, files);
                }
              },
            ),
          ]),
        ) ??
        [];
  }

  Future<File?> _openCamera() async {
    final XFile? img = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 80);
    if (img == null) {
      return null;
    }
    return File(img.path);
  }

  Future<void> _updateRequiredDocument(
    String docName, {
    bool directCamera = false,
  }) async {
    final files = await _selectDocumentFiles(directCamera: directCamera);
    if (files.isEmpty) return;

    final documentId = _requiredDocIds[docName];
    if (documentId == null || documentId <= 0) {
      setState(() {
        _uploadedDocs.putIfAbsent(docName, () => []).addAll(files);
      });
      return;
    }

    setState(() => _updatingDocName = docName);
    String? error;
    for (final file in files) {
      error = await _service.resubmitDocument(
        documentId: documentId,
        file: file,
        documentType: docName,
      );
      if (error != null) break;
    }

    if (!mounted) return;

    setState(() {
      _updatingDocName = null;
      if (error == null) {
        _uploadedDocs.putIfAbsent(docName, () => []).addAll(files);
        _resubmittedDocs.add(docName);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? "Document updated successfully."),
        backgroundColor: error == null ? Colors.green : Colors.redAccent,
      ),
    );
  }

  Future<void> _selectDob(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
              primary: Colors.blueAccent, onPrimary: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      String formatted =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      setState(() => _dobCtrl.text = formatted);
    }
  }

  void _showRejectionReasonDialog(String reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2F45),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline,
                    color: Colors.red, size: 60),
              ),
              const SizedBox(height: 20),
              const Text(
                "Profile Error",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                reason,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Okay",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessDialog() {
    final title =
        _isResubmission ? "Review in Progress" : "Submission Successful!";
    final message = _isResubmission
        ? "Your corrected details have been resubmitted for review."
        : "Your details have been submitted for review. You can now login.";
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A2F45),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle,
                    color: Colors.green, size: 60),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  text: "Go to Login",
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const Login()),
                        (route) => false);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitForm() async {
    setState(() => _isSubmitting = true);
    Map<String, dynamic> payload = {};

    String finalGender = _gender ?? "";

    if (_isResubmission) {
      payload["EmployeeId"] = widget.employeeId ?? 0;
      payload["Email"] = widget.email;

      if (_rejectedKeys.contains("FullName")) {
        String middleName =
            _midNameCtrl.text.trim().isEmpty ? "N/A" : _midNameCtrl.text.trim();
        payload["FullName"] =
            "${_firstNameCtrl.text.trim()} $middleName ${_lastNameCtrl.text.trim()}"
                .trim();
      }
      if (_rejectedKeys.contains("Gender")) {
        payload["Gender"] = finalGender;
      }
      if (_rejectedKeys.contains("DateOfBirth")) {
        payload["DateOfBirth"] = _dobCtrl.text.contains("T")
            ? _dobCtrl.text
            : "${_dobCtrl.text}T00:00:00";
      }
      if (_rejectedKeys.contains("MobileNumber")) {
        payload["MobileNumber"] =
            _buildFullPhoneNumber(_phoneCtrl, _selectedProfileCountry);
      }
      if (_rejectedKeys.contains("Address")) {
        payload["Street"] =
            _streetCtrl.text.trim().isEmpty ? "N/A" : _streetCtrl.text.trim();
        payload["City"] = _cityCtrl.text;
        payload["State"] =
            _stateCtrl.text.trim().isEmpty ? "N/A" : _stateCtrl.text.trim();
        payload["PostalCode"] =
            _zipCtrl.text.trim().isEmpty ? "N/A" : _zipCtrl.text.trim();
        payload["Country"] =
            _countryCtrl.text.isNotEmpty ? _countryCtrl.text : "Australia";
      }
      if (_rejectedKeys.contains("Bank")) {
        payload["BankBSB"] =
            _bsbCtrl.text.trim().isEmpty ? "N/A" : _bsbCtrl.text.trim();
        payload["BankAccountNumber"] =
            _accNumCtrl.text.trim().isEmpty ? "N/A" : _accNumCtrl.text.trim();
        payload["BankAccountName"] =
            _accNameCtrl.text.trim().isEmpty ? "N/A" : _accNameCtrl.text.trim();
        payload["BankName"] = _bankNameCtrl.text.trim().isEmpty
            ? "N/A"
            : _bankNameCtrl.text.trim();
      }
      if (_rejectedKeys.contains("TaxInfo")) {
        payload["EmploymentType"] = _empType;
        if (_empType.contains("Contractor")) {
          payload["Abn"] =
              _abnCtrl.text.trim().isEmpty ? "N/A" : _abnCtrl.text.trim();
        }
        if (_empType.contains("Employee")) {
          payload["Tfn"] =
              _tfnCtrl.text.trim().isEmpty ? "N/A" : _tfnCtrl.text.trim();
        }
      }
      if (_rejectedKeys.contains("NextOfKin")) {
        final firstNok =
            _nokList.isNotEmpty ? _nokList.first : <String, dynamic>{};
        final nextOfKinId =
            int.tryParse((firstNok["nextOfKinId"] ?? "").toString()) ?? 0;
        if (nextOfKinId <= 0) {
          if (mounted) {
            setState(() => _isSubmitting = false);
            _showErrorWithRetry(
                "Next of Kin ID is missing. Please refresh and try again.");
          }
          return;
        }
        final nokMobile = _nokPhoneCtrl.text.trim().isNotEmpty
            ? _buildFullPhoneNumber(_nokPhoneCtrl, _selectedNokCountry)
            : (firstNok["mobileNumber"] ?? "N/A").toString();
        payload["NextOfKin"] = {
          "NextOfKinId": nextOfKinId,
          "FullName": _nokNameCtrl.text.trim().isEmpty
              ? (firstNok["fullName"] ?? "N/A").toString()
              : _nokNameCtrl.text.trim(),
          "MobileNumber": nokMobile,
          "Email": _nokEmailCtrl.text.trim().isEmpty
              ? (firstNok["email"] ?? "N/A").toString()
              : _nokEmailCtrl.text.trim(),
          "Relationship": _nokRelCtrl.text.trim().isEmpty
              ? (firstNok["relationship"] ?? "N/A").toString()
              : _nokRelCtrl.text.trim(),
          "Address": _nokAddressCtrl.text.trim().isEmpty
              ? (firstNok["address"] ?? "N/A").toString()
              : _nokAddressCtrl.text.trim(),
          "IsPrimary": true
        };
      }

      if (_uploadedDocs.isNotEmpty) {
        List<Map<String, dynamic>> documentsList = [];
        _uploadedDocs.forEach((key, files) {
          for (final _ in files) {
            documentsList.add({
              "DocumentId": _requiredDocIds[key] ?? 0,
              "DocumentType": key,
              "DocumentUrl": ""
            });
          }
        });
        payload["Documents"] = documentsList;
      }
    } else {
      String middleName =
          _midNameCtrl.text.trim().isEmpty ? "N/A" : _midNameCtrl.text.trim();
      String street =
          _streetCtrl.text.trim().isEmpty ? "N/A" : _streetCtrl.text.trim();
      String state =
          _stateCtrl.text.trim().isEmpty ? "N/A" : _stateCtrl.text.trim();
      String postcode =
          _zipCtrl.text.trim().isEmpty ? "N/A" : _zipCtrl.text.trim();
      String bsb = _bsbCtrl.text.trim().isEmpty ? "N/A" : _bsbCtrl.text.trim();
      String accountNum =
          _accNumCtrl.text.trim().isEmpty ? "N/A" : _accNumCtrl.text.trim();
      String accountName =
          _accNameCtrl.text.trim().isEmpty ? "N/A" : _accNameCtrl.text.trim();
      String bankName =
          _bankNameCtrl.text.trim().isEmpty ? "N/A" : _bankNameCtrl.text.trim();
      String tfn = _tfnCtrl.text.trim().isEmpty ? "N/A" : _tfnCtrl.text.trim();
      String abn = _abnCtrl.text.trim().isEmpty ? "N/A" : _abnCtrl.text.trim();

      payload = {
        "FirstName": _firstNameCtrl.text,
        "MiddleName": middleName,
        "LastName": _lastNameCtrl.text,
        "Email": widget.email,
        "MobileNumber":
            _buildFullPhoneNumber(_phoneCtrl, _selectedProfileCountry),
        "Gender": finalGender,
        "DateOfBirth": _dobCtrl.text.isNotEmpty
            ? (_dobCtrl.text.contains("T")
                ? _dobCtrl.text
                : "${_dobCtrl.text}T00:00:00")
            : "1990-01-01T00:00:00",
        "Street": street,
        "City": _cityCtrl.text,
        "State": state,
        "PostalCode": postcode,
        "Country":
            _countryCtrl.text.isNotEmpty ? _countryCtrl.text : "Australia",
        "BankBSB": bsb,
        "BankAccountNumber": accountNum,
        "BankAccountName": accountName,
        "BankName": bankName,
        "EmploymentType": _empType,
        "JobRole": _jobRole,
      };
      if (_invitationId != null) payload["InvitationId"] = _invitationId;
      if (_invitationToken != null && _invitationToken!.isNotEmpty) {
        payload["InvitationToken"] = _invitationToken;
        payload["Token"] = _invitationToken;
      }
      if (_empType.contains("Contractor")) payload["Abn"] = abn;
      if (_empType.contains("Employee")) payload["Tfn"] = tfn;

      if (_uploadedDocs.isNotEmpty) {
        List<Map<String, dynamic>> documentsList = [];
        _uploadedDocs.forEach((key, files) {
          for (final _ in files) {
            documentsList
                .add({"DocumentId": 0, "DocumentType": key, "DocumentUrl": ""});
          }
        });
        payload["Certificates"] = documentsList;
      }
    }

    try {
      if (!_isResubmission &&
          (_invitationToken == null || _invitationToken!.isEmpty)) {
        final invitationData = await _service.fetchInvitation(widget.email);
        if (invitationData != null) {
          _applyInvitationAuthData(invitationData);
          if (_invitationId != null) payload["InvitationId"] = _invitationId;
          if (_invitationToken != null && _invitationToken!.isNotEmpty) {
            payload["InvitationToken"] = _invitationToken;
            payload["Token"] = _invitationToken;
          }
        }
      }

      if (!_isResubmission &&
          (_invitationToken == null || _invitationToken!.isEmpty)) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          _showErrorWithRetry(
              "Invitation token is missing. Please reopen the onboarding link or login again.");
        }
        return;
      }

      final docsToSubmit = Map<String, List<File>>.from(_uploadedDocs);
      if (_isResubmission) {
        for (final docName in _resubmittedDocs) {
          docsToSubmit.remove(docName);
        }
      }

      if (_isResubmission) {
        final hasProfilePayload = payload.keys.any((key) =>
            key != "EmployeeId" && key != "Email" && key != "Documents");
        if (!hasProfilePayload) {
          if (mounted) {
            _showSuccessDialog();
          }
          return;
        }
      }

      final response = _isResubmission
          ? await _service.submitEmployeeResubmission(payload)
          : await _service.submitOnboardingForm(
              profilePicture: _profilePic ?? File(''),
              uploadedCertificates: docsToSubmit,
              profile: payload,
              nextOfKins: _nokList,
              password: _passCtrl.text.trim(),
              isResubmission: false,
              invitationToken: _invitationToken,
            );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          _showSuccessDialog();
        }
      } else {
        if (mounted) {
          setState(() => _isSubmitting = false);
          _showErrorWithRetry("Status Code: ${response.statusCode}");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        _showErrorWithRetry(e.toString());
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
          backgroundColor: Color(0xFF2F3846),
          body: Center(child: CircularProgressIndicator()));
    }

    int? nextStep = _getNextStep(_currentStep);
    int? prevStep = _getPrevStep(_currentStep);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          const Positioned.fill(child: Background()),
          SafeArea(
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
                        Expanded(
                          child: SingleChildScrollView(
                            child: Form(
                              key: _formKey,
                              autovalidateMode:
                                  AutovalidateMode.onUserInteraction,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_currentStep == 1) _buildStep1Profile(),
                                  if (_currentStep == 2)
                                    _buildStep2BankAndAuth(),
                                  if (_currentStep == 3) _buildStep3NextOfKin(),
                                  if (_currentStep == 4) _buildStep4Documents(),
                                  const SizedBox(height: 30),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (prevStep == null)
                              GradientButton(
                                text: "Back",
                                isCancel: true,
                                onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const Login())),
                              )
                            else
                              GradientButton(
                                text: "Back",
                                isCancel: true,
                                onPressed: () =>
                                    setState(() => _currentStep = prevStep),
                              ),
                            GradientButton(
                              text: nextStep == null
                                  ? (_isSubmitting ? "Submitting..." : "Submit")
                                  : "Next",
                              onPressed: () {
                                if (nextStep != null) {
                                  if (_validateCurrentStep()) {
                                    setState(() => _currentStep = nextStep);
                                  }
                                } else {
                                  // Final Step Validation (Documents & Submit)
                                  bool isStepValid = true;

                                  if (_currentStep == 3 &&
                                      _shouldShow("NextOfKin") &&
                                      _isEditable("NextOfKin")) {
                                    isStepValid = _nokList.isNotEmpty;
                                  } else if (_currentStep == 4) {
                                    isStepValid = _requiredDocs.isEmpty ||
                                        _requiredDocs.every((doc) =>
                                            (_uploadedDocs[doc]?.isNotEmpty ??
                                                false) ||
                                            _resubmittedDocs.contains(doc));
                                  }

                                  if (_isResubmission &&
                                      !_stepHasContent(_currentStep)) {
                                    isStepValid = true;
                                  }

                                  if (isStepValid && !_isSubmitting) {
                                    _submitForm();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Text(_currentStep == 3
                                            ? "Please add at least one Next of Kin."
                                            : "Please upload required documents."),
                                        backgroundColor: Colors.redAccent));
                                  }
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
        ],
      ),
    );
  }

  Widget _buildStep1Profile() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Center(
        child: ProfileAvatar(
          key: _avatarKey,
          editable: !_isResubmission,
          initialImage: _profilePic,
          useProviderImage: false,
          placeholderIcon: Icons.person,
          onTap: _pickProfileImage,
          onEditTap: _pickProfileImage,
          onImageSelected: (File image) {
            setState(() {
              _profilePic = image;
              _profileImageError = false;
            });
          },
        ),
      ),
      Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            "Profile Picture",
            style: TextStyle(
              color: _profileImageError ? Colors.redAccent : Colors.white54,
              fontSize: 12,
            ),
          ),
        ),
      ),
      if (_profileImageError)
        const Center(
          child: Padding(
            padding: EdgeInsets.only(top: 4.0),
            child: Text(
              "Profile picture is required",
              style: TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        ),
      const SizedBox(height: 20),
      if (_shouldShow("FullName")) ...[
        _buildTextField("First Name", _firstNameCtrl,
            readOnly: !_isEditable("FullName")),
        _buildTextField("Middle Name", _midNameCtrl,
            readOnly: !_isEditable("FullName")),
        _buildTextField("Last Name", _lastNameCtrl,
            readOnly: !_isEditable("FullName")),
      ],
      if (_shouldShow("Gender"))
        _buildDropdown("Gender", _genderOptions, _gender,
            (v) => setState(() => _gender = v),
            enabled: _isEditable("Gender")),
      if (_shouldShow("MobileNumber"))
        _buildPhoneNumberField(
          label: "Mobile Number",
          controller: _phoneCtrl,
          selectedCountry: _selectedProfileCountry,
          onCountryChanged: (country) =>
              setState(() => _selectedProfileCountry = country),
          readOnly: !_isEditable("MobileNumber"),
        ),
      if (_shouldShow("DateOfBirth"))
        _buildDatePicker("Date of Birth", _dobCtrl,
            validator: _validateAge, enabled: _isEditable("DateOfBirth")),
      if (_shouldShow("Address")) ...[
        if (_isEditable("Address"))
          _buildCountryAutocomplete()
        else
          _buildTextField("Country", _countryCtrl, readOnly: true),
        if (_selectedCountryStates.isNotEmpty)
          _buildDropdown(
            "State",
            _selectedCountryStates,
            _stateCtrl.text,
            (v) => setState(() => _stateCtrl.text = v ?? ''),
            enabled: _isEditable("Address"),
          )
        else
          _buildTextField("State", _stateCtrl,
              readOnly: !_isEditable("Address")),
        _buildTextField("City", _cityCtrl, readOnly: !_isEditable("Address")),
        _buildTextField("Street", _streetCtrl,
            readOnly: !_isEditable("Address")),
        _buildTextField("Postcode", _zipCtrl,
            readOnly: !_isEditable("Address"),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: _validatePostcode),
      ],
      const SizedBox(height: 20),
      const Text("Employment Details",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      const SizedBox(height: 10),
      _buildReadOnlyField("Job Role", _jobRole),
      _buildReadOnlyField("Employment Type", _empType),
      if (_shouldShow("TaxInfo")) ...[
        if (_empType.contains("Contractor"))
          _buildTextField("ABN", _abnCtrl, readOnly: !_isEditable("TaxInfo")),
        if (_empType.contains("Employee"))
          _buildTextField("TFN", _tfnCtrl,
              readOnly: !_isEditable("TaxInfo"),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: _validateTfn),
      ]
    ]);
  }

  Widget _buildStep2BankAndAuth() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_shouldShow("Bank")) ...[
        const Text("Bank Details",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        const SizedBox(height: 10),
        _buildTextField("Account Name", _accNameCtrl,
            readOnly: !_isEditable("Bank")),
        _buildTextField("BSB", _bsbCtrl,
            readOnly: !_isEditable("Bank"),
            focusNode: _bsbFocusNode,
            keyboardType: TextInputType.text,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9-]'))
            ],
            validator: _validateBsb,
            onChanged: (val) {
              String clean = val.replaceAll(RegExp(r'[^0-9]'), '');
              if (clean.length == 6) {
                _handleBsbLookup();
              } else {
                if (_isBankNameReadOnly) {
                  setState(() {
                    _bankNameCtrl.clear();
                    _isBankNameReadOnly = false;
                  });
                }
              }
            },
            onFieldSubmitted: (_) => _handleBsbLookup(),
            suffixIcon: _isLoadingBank
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : null),
        _buildTextField("Account Number", _accNumCtrl,
            readOnly: !_isEditable("Bank"),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: _validateAccountNumber),
        _buildTextField("Bank Name", _bankNameCtrl,
            readOnly: !_isEditable("Bank") ||
                (_isBankNameReadOnly && _bankNameCtrl.text.isNotEmpty)),
      ],
      if (!_isResubmission) ...[
        const SizedBox(height: 20),
        const Text("Set Password",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        const SizedBox(height: 10),
        _buildTextField("New Password", _passCtrl,
            obscure: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                color: Colors.white70,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: _validatePassword),
        _buildTextField("Confirm Password", _confirmPassCtrl,
            obscure: _obscureConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.white70,
              ),
              onPressed: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
            validator: _validateConfirmPassword),
      ]
    ]);
  }

  Widget _buildStep3NextOfKin() {
    final canEditNok = _isEditable("NextOfKin");
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_shouldShow("NextOfKin")) ...[
        const Text("Next of Kin",
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        const SizedBox(height: 10),
        _buildTextField("Full Name", _nokNameCtrl, readOnly: !canEditNok,
            validator: (v) {
          if (!_shouldValidateNokFields) return null;
          return (v == null || v.trim().isEmpty)
              ? "Full Name is required"
              : null;
        }),
        _buildTextField("Relationship", _nokRelCtrl, readOnly: !canEditNok,
            validator: (v) {
          if (!_shouldValidateNokFields) return null;
          return (v == null || v.trim().isEmpty)
              ? "Relationship is required"
              : null;
        }),
        _buildPhoneNumberField(
          label: "Mobile",
          controller: _nokPhoneCtrl,
          selectedCountry: _selectedNokCountry,
          onCountryChanged: (country) =>
              setState(() => _selectedNokCountry = country),
          validator: (v) => _validatePhoneNumber(
            v,
            label: 'Mobile',
            countryName: _selectedNokCountry.name,
            optional: !_shouldValidateNokFields,
          ),
          readOnly: !canEditNok,
        ),
        _buildTextField("Email", _nokEmailCtrl,
            readOnly: !canEditNok,
            keyboardType: TextInputType.emailAddress, validator: (v) {
          if (!_shouldValidateNokFields) return null;
          return _validateEmail(v);
        }),
        _buildTextField("Address", _nokAddressCtrl, readOnly: !canEditNok,
            validator: (v) {
          if (!_shouldValidateNokFields) return null;
          return (v == null || v.trim().isEmpty) ? "Address is required" : null;
        }),
        if (canEditNok)
          Align(
            alignment: Alignment.centerRight,
            child: GradientButton(
                text: _isResubmission ? "Update NoK" : "Add NoK",
                onPressed: () {
                  setState(() => _forceNokFieldValidation = true);
                  if (!(_formKey.currentState?.validate() ?? false)) return;

                  final name = _nokNameCtrl.text.trim();
                  final rel = _nokRelCtrl.text.trim();
                  final mobile =
                      _buildFullPhoneNumber(_nokPhoneCtrl, _selectedNokCountry);
                  final email = _nokEmailCtrl.text.trim();
                  final address = _nokAddressCtrl.text.trim();

                  if (name.isEmpty ||
                      rel.isEmpty ||
                      mobile.isEmpty ||
                      email.isEmpty ||
                      address.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Please fill in all Next of Kin fields."),
                        backgroundColor: Colors.redAccent));
                    return;
                  }

                  if (_validatePhoneNumber(
                        _nokPhoneCtrl.text,
                        label: 'Mobile',
                        countryName: _selectedNokCountry.name,
                      ) !=
                      null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Please enter a valid mobile number."),
                        backgroundColor: Colors.redAccent));
                    return;
                  }

                  if (_validateEmail(email) != null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text("Please enter a valid email address."),
                        backgroundColor: Colors.redAccent));
                    return;
                  }

                  setState(() {
                    final updatedNok = <String, dynamic>{
                      "fullName": name,
                      "relationship": rel,
                      "mobileNumber": mobile,
                      "email": email,
                      "address": address,
                    };
                    if (_isResubmission && _nokList.isNotEmpty) {
                      updatedNok["nextOfKinId"] = _nokList.first["nextOfKinId"];
                    }
                    if (_isResubmission && _nokList.isNotEmpty) {
                      _nokList[0] = updatedNok;
                    } else {
                      _nokList.add(updatedNok);
                    }
                    _nokNameCtrl.clear();
                    _nokRelCtrl.clear();
                    _nokPhoneCtrl.clear();
                    _selectedNokCountry = _dialCountries.first;
                    _nokEmailCtrl.clear();
                    _nokAddressCtrl.clear();
                    _forceNokFieldValidation = false;
                  });
                }),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _nokList.map((nok) {
            return Chip(
              label: Text(nok['fullName']),
              backgroundColor: Colors.blueAccent,
              deleteIcon:
                  const Icon(Icons.close, size: 18, color: Colors.white),
              onDeleted: canEditNok
                  ? () => setState(() => _nokList.remove(nok))
                  : null,
            );
          }).toList(),
        ),
      ],
    ]);
  }

  Widget _buildStep4Documents() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("Required Documents",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      const SizedBox(height: 10),
      if (_requiredDocs.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Text("No documents required yet. Add them above.",
                style: TextStyle(color: Colors.white54)),
          ),
        ),
      ..._requiredDocs.map((docName) {
        final files = _uploadedDocs[docName] ?? const <File>[];
        bool isUploaded =
            files.isNotEmpty || _resubmittedDocs.contains(docName);
        bool isUpdating = _updatingDocName == docName;
        final actionLabel = isUploaded ? "Update" : "Add";

        return Card(
          color: Colors.white.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _updateRequiredDocument(docName),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(docName,
                            style: const TextStyle(color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(
                          _resubmittedDocs.contains(docName)
                              ? files.length > 1
                                  ? "Updated (${files.length} files)"
                                  : "Updated"
                              : files.isNotEmpty
                                  ? files.length > 1
                                      ? "Ready to submit (${files.length} files)"
                                      : "Ready to submit"
                                  : "Required",
                          style: TextStyle(
                            color: isUploaded
                                ? Colors.greenAccent
                                : Colors.redAccent,
                          ),
                        ),
                        if (files.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 52,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: files.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final file = files[index];
                                return _buildDocumentPreview(
                                  file,
                                  onRemove: () {
                                    setState(() {
                                      _uploadedDocs[docName]?.remove(file);
                                      if (_uploadedDocs[docName]?.isEmpty ??
                                          false) {
                                        _uploadedDocs.remove(docName);
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: isUpdating
                      ? null
                      : () => _updateRequiredDocument(docName),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: const Color(0xFF3E5BFF),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isUpdating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          actionLabel,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        );
      }),
    ]);
  }

  Widget _buildDocumentPreview(File file, {required VoidCallback onRemove}) {
    final isImage = _isImageFile(file);

    return GestureDetector(
      onTap: isImage ? () => _showImagePreview(file) : null,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isImage
                  ? Image.file(file, fit: BoxFit.cover)
                  : const Icon(Icons.insert_drive_file,
                      color: Colors.white70, size: 24),
            ),
          ),
          Positioned(
            right: -7,
            top: -7,
            child: InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isImageFile(File file) {
    final path = file.path.toLowerCase();
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png');
  }

  void _showAddDocModal() {
    String searchQuery = "";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1F2B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          final filtered = _allAvailableDocTypes
              .where((doc) =>
                  doc.toLowerCase().contains(searchQuery.toLowerCase()) &&
                  !_requiredDocs.contains(doc))
              .toList();

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Add Required Document",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  style: const TextStyle(color: Colors.white),
                  onChanged: (v) => setModalState(() => searchQuery = v),
                  decoration: InputDecoration(
                    hintText: "Search document...",
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 15),
                ConstrainedBox(
                  constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final doc = filtered[index];
                      return ListTile(
                        title: Text(doc,
                            style: const TextStyle(color: Colors.white)),
                        trailing:
                            const Icon(Icons.add, color: Colors.blueAccent),
                        onTap: () {
                          setState(() => _requiredDocs.add(doc));
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
                if (searchQuery.isNotEmpty && !filtered.contains(searchQuery))
                  ListTile(
                    title: Text("Add '$searchQuery'...",
                        style: const TextStyle(color: Colors.blueAccent)),
                    leading: const Icon(Icons.create, color: Colors.blueAccent),
                    onTap: () {
                      setState(() => _requiredDocs.add(searchQuery));
                      Navigator.pop(context);
                    },
                  ),
                const SizedBox(height: 20),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _buildPhoneNumberField({
    required String label,
    required TextEditingController controller,
    required _DialCountry selectedCountry,
    required ValueChanged<_DialCountry> onCountryChanged,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              SizedBox(
                width: 110,
                height: 56,
                child: Material(
                  color: const Color(0xFF233565),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: readOnly
                        ? null
                        : () => _showCountryPicker(
                              selectedCountry: selectedCountry,
                              onSelected: onCountryChanged,
                            ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFF5B86FF), width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            selectedCountry.flag,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              selectedCountry.code,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: TextFormField(
                    controller: controller,
                    readOnly: readOnly,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    validator: readOnly
                        ? null
                        : validator ??
                            (v) => _validatePhoneNumber(
                                  v,
                                  label: label,
                                  countryName: selectedCountry.name,
                                ),
                    decoration: InputDecoration(
                      hintText: "Phone number",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: readOnly
                          ? Colors.white10
                          : Colors.white.withValues(alpha: 0.1),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.white38),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: Color(0xFF6A4DE8), width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.redAccent),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: Colors.redAccent, width: 2),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showCountryPicker({
    required _DialCountry selectedCountry,
    required ValueChanged<_DialCountry> onSelected,
  }) {
    String query = '';

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0F1A31),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredCountries = _dialCountries.where((country) {
              final normalizedQuery = query.toLowerCase().trim();
              if (normalizedQuery.isEmpty) return true;
              return country.name.toLowerCase().contains(normalizedQuery) ||
                  country.code.contains(normalizedQuery);
            }).toList();

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.62,
                  child: Column(
                    children: [
                      TextField(
                        autofocus: true,
                        style: const TextStyle(color: Colors.white),
                        onChanged: (value) =>
                            setModalState(() => query = value),
                        decoration: InputDecoration(
                          hintText: "Search country...",
                          hintStyle: const TextStyle(color: Colors.white54),
                          prefixIcon:
                              const Icon(Icons.search, color: Colors.white54),
                          filled: true,
                          fillColor: const Color(0xFF111D35),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.white30),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xFF5B86FF)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: filteredCountries.length,
                          itemBuilder: (context, index) {
                            final country = filteredCountries[index];
                            final isSelected =
                                country.name == selectedCountry.name &&
                                    country.code == selectedCountry.code;

                            return InkWell(
                              onTap: () {
                                onSelected(country);
                                Navigator.of(sheetContext).pop();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF3368F5)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Text(country.flag,
                                        style: const TextStyle(fontSize: 22)),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            country.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            "Dial code ${country.code}",
                                            style: const TextStyle(
                                                color: Colors.white60),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      country.code,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController ctrl, {
    bool obscure = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool readOnly = false,
    Widget? suffixIcon,
    FocusNode? focusNode,
    Function(String)? onFieldSubmitted,
    Function(String)? onChanged,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: ctrl,
        obscureText: obscure,
        keyboardType: keyboardType,
        readOnly: readOnly,
        focusNode: focusNode,
        onFieldSubmitted: onFieldSubmitted,
        onChanged: readOnly ? null : onChanged,
        inputFormatters: inputFormatters,
        style: const TextStyle(color: Colors.white),
        validator: readOnly
            ? (_) => null
            : validator ??
                (v) => (v == null || v.isEmpty) ? "$label is required" : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor:
              readOnly ? Colors.white10 : Colors.white.withValues(alpha: 0.1),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon: suffixIcon,
          helperText: (readOnly && ctrl.text.isNotEmpty) ? "Saved" : null,
          helperStyle: const TextStyle(color: Colors.greenAccent),
        ),
      ),
    );
  }

  Widget _buildCountryAutocomplete() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: RawAutocomplete<CountryDialCode>(
        textEditingController: _countryCtrl,
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
          return TextFormField(
            controller: textEditingController,
            focusNode: focusNode,
            onChanged: (value) {
              final matchedCountry = countryDialCodes.where((country) =>
                  country.name.toLowerCase() == value.trim().toLowerCase());
              if (matchedCountry.isEmpty) {
                setState(() {});
                return;
              }

              _handleCountryChanged(matchedCountry.first.name);
            },
            onFieldSubmitted: (_) => onFieldSubmitted(),
            style: const TextStyle(color: Colors.white),
            validator: (value) {
              final country = (value ?? '').trim();
              if (country.isEmpty) return "Country is required";
              final isKnownCountry = countryDialCodes.any(
                  (item) => item.name.toLowerCase() == country.toLowerCase());
              return isKnownCountry ? null : "Select a valid country";
            },
            decoration: InputDecoration(
              labelText: "Country",
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.1),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              suffixIcon:
                  const Icon(Icons.arrow_drop_down, color: Colors.white70),
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
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        initialValue: value,
        readOnly: true,
        style: const TextStyle(color: Colors.white60),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38),
          filled: true,
          fillColor: Colors.black26,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> items, String? value,
      Function(String?) onChanged,
      {bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        initialValue: items.contains(value) ? value : null,
        hint: Text("Select $label",
            style: const TextStyle(color: Colors.white70)),
        dropdownColor: Colors.grey[900],
        isExpanded: true,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        onChanged: enabled ? onChanged : null,
        validator:
            enabled ? (v) => v == null ? "$label is required" : null : null,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          filled: true,
          fillColor:
              enabled ? Colors.white.withValues(alpha: 0.1) : Colors.white10,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white38),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF6A4DE8), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
          ),
        ),
        items: items
            .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: const TextStyle(color: Colors.white))))
            .toList(),
      ),
    );
  }

  Widget _buildDatePicker(String label, TextEditingController controller,
      {String? Function(String?)? validator, bool enabled = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        style: const TextStyle(color: Colors.white),
        validator: enabled
            ? validator ??
                (v) => (v == null || v.isEmpty) ? "$label is required" : null
            : null,
        onTap: enabled ? () => _selectDob(context) : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor:
              enabled ? Colors.white.withValues(alpha: 0.1) : Colors.white10,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon: const Icon(Icons.calendar_today, color: Colors.white70),
          errorStyle: const TextStyle(color: Colors.redAccent),
        ),
      ),
    );
  }

  void _showImagePreview(File file) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(
                child: Image.file(file),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorWithRetry(String error) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A2F45),
        title: const Text("Submission Error",
            style: TextStyle(color: Colors.white)),
        content: Text("Failed to submit: $error",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _submitForm();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text("Retry", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
