// lib/screens/login.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart'; // Biometric authentication
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Encrypted credential storage
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shiftsmart/providers/tenant_provider.dart';
import 'package:shiftsmart/providers/user_provider.dart';
import 'package:shiftsmart/screens/employee/emp_onboard.dart';
import 'package:shiftsmart/screens/forgot_password.dart';
import 'package:shiftsmart/screens/privacy_policy.dart';
import 'package:shiftsmart/services/auth_service.dart';
import 'package:shiftsmart/services/api_client.dart';
import 'package:shiftsmart/services/employee_service.dart';
import 'package:shiftsmart/services/notification_service.dart';
import 'package:shiftsmart/utils/fullscreen_helper.dart';
import 'package:shiftsmart/widgets/bottomnavbar.dart';
import 'package:shiftsmart/widgets/emp_bottomnavbar.dart';
import 'package:shiftsmart/widgets/login_background.dart';

class Login extends StatefulWidget {
  final bool promptBiometric; // Auto-trigger biometric prompt on load

  const Login({super.key, this.promptBiometric = false});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final AuthService _authService = AuthService();
  final ApiClient _apiClient = ApiClient();

  // Secure storage for encrypted credentials
  final _storage = const FlutterSecureStorage();
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Form controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // UI state variables
  bool _isLoading = false;
  bool _obscureText = true;
  bool _canCheckBiometrics = false; // Show/hide biometric button

  // Biometric type detection
  bool _hasFaceID = false;
  bool _hasFingerprint = false;
  String _biometricLabel = "Biometrics"; // Dynamic label based on device

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    disableFullScreen();
    _checkBiometricAvailability().then((_) {
      if (widget.promptBiometric && _canCheckBiometrics) {
        _performBiometricLogin();
      }
    }); // Check device biometric capabilities
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Check device biometric hardware and saved credentials
  Future<void> _checkBiometricAvailability() async {
    try {
      // Verify device supports biometrics
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        setState(() {
          _canCheckBiometrics = false;
        });
        return;
      }

      // Detect available biometric types (Face ID, Fingerprint)
      final List<BiometricType> availableBiometrics =
          await _localAuth.getAvailableBiometrics();

      // Check for previously saved credentials
      String? savedEmail = await _storage.read(key: 'login_email');
      String? savedPass = await _storage.read(key: 'login_pass');

      // Check user preference from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final bool biometricEnabled = prefs.getBool('biometric_enabled') ?? false;

      setState(() {
        // Identify Face ID availability
        _hasFaceID = availableBiometrics.contains(BiometricType.face);

        // Identify Fingerprint availability
        _hasFingerprint =
            availableBiometrics.contains(BiometricType.fingerprint);

        // Set dynamic label for UI display
        if (_hasFaceID && _hasFingerprint) {
          _biometricLabel = "Face ID / Fingerprint";
        } else if (_hasFaceID) {
          _biometricLabel = "Face ID";
        } else if (_hasFingerprint) {
          _biometricLabel = "Fingerprint";
        } else {
          _biometricLabel = "Biometrics";
        }

        // Show button only if hardware + enabled in settings + saved credentials exist
        _canCheckBiometrics = canAuthenticate &&
            biometricEnabled &&
            (_hasFaceID || _hasFingerprint) &&
            savedEmail != null &&
            savedPass != null;
      });

      print("Available biometrics: $availableBiometrics");
      print("Face ID: $_hasFaceID, Fingerprint: $_hasFingerprint");
    } catch (e) {
      print("Biometric check failed: $e");
      setState(() {
        _canCheckBiometrics = false;
      });
    }
  }

  // Return appropriate icon based on available biometric
  IconData _getBiometricIcon() {
    if (_hasFaceID && _hasFingerprint) {
      return Icons.fingerprint_rounded; // Default to fingerprint
    } else if (_hasFaceID) {
      return Icons.face_rounded;
    } else if (_hasFingerprint) {
      return Icons.fingerprint_rounded;
    } else {
      return Icons.lock_person_rounded; // Fallback
    }
  }

  // Show consent dialog before biometric authentication
  Future<void> _showBiometricConsentDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 16,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Biometric icon indicator
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2979FF).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getBiometricIcon(),
                    color: const Color(0xFF2979FF),
                    size: 50,
                  ),
                ),
                const SizedBox(height: 20),

                // Dialog title
                const Text(
                  "Enable Biometric Login?",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Dynamic message based on biometric type
                Text(
                  "Would you like to use $_biometricLabel to login quickly and securely?",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 25),

                // Yes/No action buttons
                Row(
                  children: [
                    // Decline button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Colors.grey,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          "No",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Accept and proceed button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          // Persist preference when user says YES
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('biometric_enabled', true);
                          _performBiometricLogin(); // Trigger biometric scan
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2979FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          "Yes",
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
              ],
            ),
          ),
        );
      },
    );
  }

  // Show consent dialog only if not yet enabled, otherwise proceed to scan
  Future<void> _handleBiometricLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final bool biometricEnabled = prefs.getBool('biometric_enabled') ?? false;

    if (biometricEnabled) {
      // If already enabled, just execute the scan
      _performBiometricLogin();
    } else {
      // If not yet enabled, ask for consent first
      await _showBiometricConsentDialog();
    }
  }

  // Perform biometric authentication and auto-login
  Future<void> _performBiometricLogin() async {
    try {
      // Verify biometric availability
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        _showStylishDialog(
          "Not Available",
          "Biometric authentication is not available on this device.",
        );
        return;
      }

      // Set dynamic authentication prompt message
      String authMessage = 'Please authenticate to login to ShiftSmart';
      if (_hasFaceID && !_hasFingerprint) {
        authMessage = 'Please use Face ID to login to ShiftSmart';
      } else if (_hasFingerprint && !_hasFaceID) {
        authMessage = 'Please use your fingerprint to login to ShiftSmart';
      }

      // Trigger biometric scanner (Face ID or Fingerprint)
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: authMessage,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (!didAuthenticate) {
        return; // User cancelled or failed
      }

      // Retrieve encrypted saved credentials
      String? savedEmail = await _storage.read(key: 'login_email');
      String? savedPass = await _storage.read(key: 'login_pass');

      if (savedEmail == null || savedPass == null) {
        _showStylishDialog(
          "No Saved Credentials",
          "Please login with email and password first.",
        );
        return;
      }

      // Auto-fill form fields for visual feedback
      _emailController.text = savedEmail;
      _passwordController.text = savedPass;

      // Execute login with saved credentials
      await _handleEmailPasswordLogin(isBiometric: true);
    } on PlatformException catch (e) {
      // Handle platform-specific errors
      String errorMsg = "Authentication error: ${e.message}";
      if (e.code == 'NotAvailable') {
        errorMsg = "Biometric authentication is not available.";
      } else if (e.code == 'NotEnrolled') {
        errorMsg =
            "No biometrics enrolled. Please set up $_biometricLabel in your device settings.";
      }
      _showStylishDialog("Authentication Failed", errorMsg);
    } catch (e) {
      _showStylishDialog(
        "Error",
        "An error occurred during biometric authentication: $e",
      );
    }
  }

  // Display styled alert dialog
  void _showStylishDialog(String title, String message, {bool isError = true}) {
    // Set icon and color based on dialog type
    IconData icon = isError ? Icons.error_outline : Icons.check_circle_outline;
    Color color = isError ? Colors.red : Colors.green;

    if (title == "Connection Error") {
      icon = Icons.wifi_off_rounded;
      color = Colors.orange;
    } else if (title == "Login Failed" || title == "Input Error") {
      icon = Icons.lock_person_outlined;
      color = Colors.redAccent;
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 16,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon indicator
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 40),
                ),
                const SizedBox(height: 20),
                // Dialog title
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                // Dialog message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 25),
                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
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
          ),
        );
      },
    );
  }

  // Main login function (email/password or biometric)
  Future<void> _handleEmailPasswordLogin({bool isBiometric = false}) async {
    // Skip form validation for biometric login
    if (!isBiometric) {
      if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
        _showStylishDialog("Input Error", "Please fix the errors in the form.");
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    try {
      // Authenticate with backend
      final loginResponse = await _authService.login(email, password);

      if (loginResponse == null) {
        _showStylishDialog(
          "Connection Error",
          "Unable to connect to server. Check internet.",
        );
        return;
      }

      // Check login success or onboarding requirement
      final String backendMsg =
          (loginResponse['message'] ?? loginResponse['Message'] ?? '')
              .toString();

      // Extract tenants list for deeper inspection
      final dynamic tenants = loginResponse['tenants'];
      dynamic targetTenant;
      if (tenants is List && tenants.isNotEmpty) {
        // Prefer the tenant that explicitly requires onboarding
        try {
          targetTenant = tenants.firstWhere(
            (t) => (t['onboardingRequired'] == true ||
                t['OnboardingRequired'] == true ||
                t['onboardingRequired'].toString().toLowerCase() == 'true'),
            orElse: () => tenants[0],
          );
        } catch (_) {
          targetTenant = tenants[0];
        }
      }

      final bool isSuccess =
          backendMsg.toLowerCase().contains('login successful') ||
              loginResponse['status'] == 1 ||
              loginResponse['isSuccess'] == true ||
              loginResponse['Success'] == true ||
              loginResponse['statusCode'] == 200;

      // Null-safe onboarding flag evaluation - checks top level and target tenant
      final dynamic onboardingFlag = loginResponse['onboardingRequired'] ??
          loginResponse['OnboardingRequired'] ??
          loginResponse['onboarding_required'] ??
          targetTenant?['onboardingRequired'] ??
          targetTenant?['OnboardingRequired'];

      final bool isOnboarding = onboardingFlag != null &&
          (onboardingFlag == true ||
              onboardingFlag.toString().toLowerCase() == 'true' ||
              onboardingFlag.toString() == '1');

      if (!isSuccess && !isOnboarding) {
        String msg = backendMsg.isNotEmpty
            ? backendMsg
            : "Incorrect email or password. Please try again.";
        _showStylishDialog("Login Failed", msg);
        return;
      }

      // Store user email and role in shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userEmail', email);
      if (targetTenant is Map) {
        await _saveTenantContext(prefs, targetTenant);
      }

      final String derivedRole = (loginResponse['userRole'] ??
              loginResponse['UserRole'] ??
              loginResponse['role'] ??
              loginResponse['Role'] ??
              'Employee')
          .toString();
      await prefs.setString('userRole', derivedRole);

      // Handle onboarding flow
      if (isOnboarding) {
        // Try all case variants the backend might return, prioritizing the identified tenant
        final int? idToPass = loginResponse["employeeId"] ??
            loginResponse["EmployeeId"] ??
            targetTenant?["employeeId"] ??
            targetTenant?["EmployeeId"] ??
            loginResponse['userId'] ??
            loginResponse['UserId'] ??
            targetTenant?['userId'] ??
            targetTenant?['UserId'];

        final String onboardingMode = (loginResponse["onboardingMode"] ??
                loginResponse["OnboardingMode"] ??
                targetTenant?["onboardingMode"] ??
                targetTenant?["OnboardingMode"] ??
                "none")
            .toString()
            .toLowerCase();
        final int? tenantIdToPass = int.tryParse(
          (targetTenant?["tenantId"] ??
                      targetTenant?["TenantId"] ??
                      loginResponse["tenantId"] ??
                      loginResponse["TenantId"] ??
                      loginResponse["lastUsedTenantId"] ??
                      loginResponse["LastUsedTenantId"])
                  ?.toString() ??
              '',
        );

        if (onboardingMode == "pending") {
          _showStylishDialog(
            "Review in Progress",
            "Your onboarding details have been submitted and are currently being reviewed by our team.",
          );
          return;
        }

        if (onboardingMode == "initial") {
          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Emponboard(
                email: email,
                employeeId: idToPass,
              ),
            ),
          );
          return;
        }

        if (onboardingMode == "resubmission") {
          if (idToPass == null) {
            _showStylishDialog(
              "Profile Error",
              "Employee ID is missing for resubmission.",
            );
            return;
          }

          final exchangeResponse = await _authService.exchangePasswordForToken(
            email,
            password,
            tenantId: tenantIdToPass,
          );

          final String? appToken =
              exchangeResponse?['appToken'] ?? exchangeResponse?['AppToken'];

          if (exchangeResponse == null || appToken == null) {
            _showStylishDialog(
              "Authentication Failed",
              "Could not verify your account for resubmission.",
            );
            return;
          }

          await _storage.write(key: 'login_email', value: email);
          await _storage.write(key: 'login_pass', value: password);
          await _checkBiometricAvailability();

          final existingProfile =
              await _authService.fetchRejectedProfileData(idToPass);

          if (existingProfile == null) {
            _showStylishDialog(
              "Resubmission Error",
              "Could not load rejected onboarding details.",
            );
            return;
          }

          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => Emponboard(
                email: email,
                existingProfile: existingProfile,
                employeeId: idToPass,
              ),
            ),
          );
          return;
        }
      }

      // Exchange credentials for app token
      final exchangeResponse = await _authService.exchangePasswordForToken(
        email,
        password,
      );

      final String? appToken =
          exchangeResponse?['appToken'] ?? exchangeResponse?['AppToken'];

      if (exchangeResponse == null || appToken == null) {
        print(" Exchange Response Failed: $exchangeResponse");
        _showStylishDialog(
          "Authentication Failed",
          "Could not verify credentials.",
        );
        return;
      }

      await _storage.write(key: 'login_email', value: email);
      await _storage.write(key: 'login_pass', value: password);
      await _checkBiometricAvailability();

      print(
          " Exchange Success. userId: ${exchangeResponse["userId"]}, role: ${exchangeResponse["userRole"]}");

      // Store user ID and role  fall back to loginResponse or JWT if exchange omits them
      final Map<String, dynamic>? jwtPayload = _apiClient.decodeJwt(appToken);

      int? userId = exchangeResponse["userId"] ??
          exchangeResponse["UserId"] ??
          exchangeResponse["employeeId"] ??
          exchangeResponse["EmployeeId"] ??
          loginResponse["userId"] ??
          loginResponse["UserId"] ??
          loginResponse["employeeId"] ??
          loginResponse["EmployeeId"] ??
          (jwtPayload?['sub'] != null
              ? int.tryParse(jwtPayload!['sub'].toString())
              : null) ??
          (jwtPayload?['userId'] != null
              ? int.tryParse(jwtPayload!['userId'].toString())
              : null);

      String role = (exchangeResponse["userRole"] ??
              exchangeResponse["UserRole"] ??
              loginResponse["userRole"] ??
              loginResponse["UserRole"] ??
              jwtPayload?['role'] ??
              jwtPayload?['UserRole'] ??
              jwtPayload?['userRole'] ??
              "Employee")
          .toString();

      if (userId == null) {
        print(
            " CRITICAL: userId NULL after all fallbacks (Exchange, Login, JWT).");
        _showStylishDialog("Profile Error",
            "User data is inconsistent. Please contact support.");
        return;
      }

      await prefs.setInt('userId', userId);
      await prefs.setString('userRole', role);

      // Fetch complete user profile
      final fullProfile = await _authService.fetchFullEmployeeProfile(email);
      print(" Full Profile Response: $fullProfile");

      if (fullProfile != null) {
        // Store employee details
        final int? empId =
            fullProfile['employeeId'] ?? fullProfile['EmployeeId'];
        if (empId == null) {
          _showStylishDialog("Profile Error", "Employee ID missing.");
          return;
        }

        await prefs.setInt('employeeId', empId);
        await prefs.setString(
          'userName',
          "${fullProfile["firstName"] ?? ''} ${fullProfile["lastName"] ?? ''}",
        );

        // Build user profile object
        final rawProfilePicture = fullProfile["profilePicture"] ??
            fullProfile["ProfilePicture"] ??
            "";
        final signedProfilePicture = empId > 0
            ? await EmployeeService().fetchProfilePictureDownloadUrl(empId)
            : null;

        final userProfile = {
          "userId": userId,
          "employeeId": empId,
          "firstName":
              fullProfile["firstName"] ?? fullProfile["FirstName"] ?? "",
          "middleName":
              fullProfile["middleName"] ?? fullProfile["MiddleName"] ?? "",
          "lastName": fullProfile["lastName"] ?? fullProfile["LastName"] ?? "",
          "gender": fullProfile["gender"] ?? fullProfile["Gender"] ?? "",
          "email": fullProfile["email"] ?? fullProfile["Email"] ?? "",
          "mobileNumber":
              fullProfile["mobileNumber"] ?? fullProfile["MobileNumber"] ?? "",
          "dateOfBirth":
              fullProfile["dateOfBirth"] ?? fullProfile["DateOfBirth"] ?? "",
          "street": fullProfile["street"] ?? fullProfile["Street"] ?? "",
          "city": fullProfile["city"] ?? fullProfile["City"] ?? "",
          "state": fullProfile["state"] ?? fullProfile["State"] ?? "",
          "postalCode":
              fullProfile["postalCode"] ?? fullProfile["PostalCode"] ?? "",
          "country": fullProfile["country"] ?? fullProfile["Country"] ?? "",
          "employmentStatus": fullProfile["employmentStatus"] ??
              fullProfile["EmploymentStatus"] ??
              "",
          "jobRole": fullProfile["jobRole"] ?? fullProfile["JobRole"] ?? "",
          "userRole": role,
          "profilePicture": signedProfilePicture ?? rawProfilePicture,
          "bankAccountName": fullProfile["bankAccountName"] ??
              fullProfile["BankAccountName"] ??
              "",
          "bankAccountNumber": fullProfile["bankAccountNumber"] ??
              fullProfile["BankAccountNumber"] ??
              "",
          "bankBSB": fullProfile["bankBSB"] ?? fullProfile["BankBSB"] ?? "",
          "bankName": fullProfile["bankName"] ?? fullProfile["BankName"] ?? "",
          "nextOfKins":
              (fullProfile["nextOfKins"] ?? fullProfile["NextOfKins"] ?? []),
        };

        // Update global user provider
        if (mounted) {
          final up = Provider.of<UserProvider>(context, listen: false);
          up.setUserProfile(userProfile);
          if (loginResponse['tenants'] != null) {
            up.setTenants(loginResponse['tenants']);
          }
          final tenantProvider = context.read<TenantProvider>();
          final tenantList = _tenantListFrom(loginResponse['tenants']);
          if (tenantList.isNotEmpty) {
            tenantProvider.setTenants(tenantList);
          }
          if (targetTenant is Map) {
            final tenantMap = Map<String, dynamic>.from(targetTenant);
            final tenantName = _tenantNameFrom(tenantMap);
            if (tenantName.isNotEmpty) {
              tenantProvider.initFromCurrentTenant(tenantName, tenantMap);
            }
          }
        }

        // Initialize push notifications
        try {
          final notificationService = NotificationService();
          await notificationService.initializeFCM(
            employeeId: empId,
            userTag: "user_$empId",
          );
        } catch (fcmError) {
          print("FCM Init Warning: $fcmError");
        }
      } else {
        _showStylishDialog("Profile Error", "Could not load user profile.");
        return;
      }

      // Navigate to appropriate dashboard based on role
      if (!mounted) return;
      print(" FINAL ROUTING CHECK: Evaluating role '$role'"); // DEBUG
      final String normalizedRole = role.trim().toLowerCase();

      if (normalizedRole.contains("manager") ||
          normalizedRole.contains("admin")) {
        print(" Routing to Manager/Admin Dashboard"); // DEBUG
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const Bottomnavbar(selectedIndex: 0),
          ),
        );
      } else {
        print(
            " Routing to Employee Dashboard (Fallback). Normalized string was: $normalizedRole"); // DEBUG
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const EmpBottomnavbar()),
        );
      }
    } catch (e) {
      // Handle login errors
      String errorStr = e.toString();
      if (errorStr.contains("Login failed") ||
          errorStr.contains("Unexpected character")) {
        _showStylishDialog("Login Failed", "Incorrect email or password.");
      } else {
        _showStylishDialog(
          "System Error",
          "An unexpected error occurred: $errorStr",
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveTenantContext(
    SharedPreferences prefs,
    Map<dynamic, dynamic> tenant,
  ) async {
    final tenantId = _tenantIdFrom(tenant);
    if (tenantId != null && tenantId != 0) {
      await prefs.setInt('selectedTenantId', tenantId);
      await prefs.setInt('currentTenantId', tenantId);
      await prefs.setInt('tenantId', tenantId);
    }

    final tenantName = _tenantNameFrom(tenant);
    if (tenantName.isNotEmpty) {
      await prefs.setString('selectedTenantName', tenantName);
    }
  }

  int? _tenantIdFrom(Map<dynamic, dynamic> tenant) {
    final raw = tenant['tenantId'] ??
        tenant['TenantId'] ??
        tenant['id'] ??
        tenant['ID'] ??
        tenant['tenantID'] ??
        tenant['TenantID'] ??
        tenant['tenant_id'];
    if (raw == null) return null;
    if (raw is int) return raw;
    return int.tryParse(raw.toString());
  }

  List<Map<String, dynamic>> _tenantListFrom(dynamic rawTenants) {
    if (rawTenants is! List) return [];

    return rawTenants
        .whereType<Map>()
        .map((tenant) => Map<String, dynamic>.from(tenant))
        .toList();
  }

  String _tenantNameFrom(Map<dynamic, dynamic> tenant) {
    return (tenant['name'] ??
            tenant['Name'] ??
            tenant['tenantName'] ??
            tenant['TenantName'] ??
            tenant['organizationName'] ??
            '')
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final logoSize = size.width * 0.5;
    final paddingUnit = size.width * 0.03;

    return Stack(
      children: [
        const Positioned.fill(child: LoginBackground()),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(paddingUnit * 2),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    children: [
                      // App logo
                      Image(
                        image: const AssetImage('assets/logo.png'),
                        width: logoSize,
                        height: logoSize,
                      ),
                      // Login form container with blur effect
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(
                                136,
                                42,
                                41,
                                41,
                              ).withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  spreadRadius: 2,
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Login header
                                const Text(
                                  "Login",
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Email input field
                                const Text(
                                  "Email",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  enabled: !_isLoading,
                                  style: const TextStyle(
                                    color: Color.fromARGB(255, 32, 32, 32),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "username@gmail.com",
                                    hintStyle: const TextStyle(
                                      color: Colors.grey,
                                    ),
                                    filled: true,
                                    fillColor: const Color.fromARGB(
                                      255,
                                      255,
                                      255,
                                      255,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  validator: (value) {
                                    // Email validation
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter an email';
                                    }
                                    const emailRegex =
                                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
                                    if (!RegExp(emailRegex).hasMatch(value)) {
                                      return 'Please enter a valid email address';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 15),

                                // Password input field
                                const Text(
                                  "Password",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscureText,
                                  enabled: !_isLoading,
                                  style: const TextStyle(
                                    color: Color.fromARGB(255, 17, 17, 17),
                                  ),
                                  decoration: InputDecoration(
                                    hintText: "Password",
                                    hintStyle: const TextStyle(
                                      color: Colors.grey,
                                    ),
                                    filled: true,
                                    fillColor: const Color.fromARGB(
                                      255,
                                      255,
                                      255,
                                      255,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    // Toggle password visibility
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureText
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscureText = !_obscureText,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    // Password validation
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your password';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 10),

                                // Forgot password link
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: TextButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const ForgotPasswordScreen(),
                                              ),
                                            );
                                          },
                                    child: const Text(
                                      "Forgot Password?",
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 15),

                                // Email/Password login button
                                Center(
                                  child: SizedBox(
                                    width: size.width * 0.7,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : _handleEmailPasswordLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFF2979FF,
                                        ),
                                        disabledBackgroundColor: const Color(
                                          0xFF2979FF,
                                        ).withOpacity(0.6),
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2.5,
                                              ),
                                            )
                                          : const Text(
                                              "Log In",
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.white,
                                              ),
                                            ),
                                    ),
                                  ),
                                ),

                                //Biometric login button (conditional display)
                                if (_canCheckBiometrics && !_isLoading) ...[
                                  const SizedBox(height: 20),
                                  Center(
                                    child: IconButton(
                                      iconSize: 45,
                                      onPressed: _handleBiometricLogin,
                                      icon: Icon(
                                        _getBiometricIcon(),
                                        color: Colors.white,
                                      ),
                                      tooltip: "Login with $_biometricLabel",
                                    ),
                                  ),
                                  // Biometric label text
                                  Center(
                                    child: Text(
                                      "Tap to use $_biometricLabel",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Center(
                                  child: TextButton.icon(
                                    onPressed: _isLoading
                                        ? null
                                        : () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const PrivacyPolicyScreen(),
                                              ),
                                            );
                                          },
                                    icon: const Icon(
                                      Icons.privacy_tip_outlined,
                                      size: 18,
                                    ),
                                    label: const Text('Privacy Policy'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
