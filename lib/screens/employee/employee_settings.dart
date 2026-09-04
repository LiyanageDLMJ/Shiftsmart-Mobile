import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shiftsmart/providers/user_provider.dart';
import 'package:shiftsmart/responsive.dart';
import 'package:shiftsmart/services/profile_service.dart';
import 'package:shiftsmart/theme.dart';
import 'package:shiftsmart/utils/fullscreen_helper.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:shiftsmart/widgets/build_profile_avatar.dart';
import 'package:shiftsmart/widgets/emp_bottomnavbar.dart';
import 'package:shiftsmart/widgets/emp_slidenav.dart';
import 'package:shiftsmart/widgets/uppernavbar.dart';
import 'package:shiftsmart/widgets/success_dialog.dart';
import 'package:shiftsmart/screens/employee/employee_profile.dart';

/// Employee Settings Screen

/// This screen allows employees to:
/// - Change their password with real-time validation
/// - Enable/disable biometric authentication (Face ID/Fingerprint)
/// - View and edit their profile information
class EmployeeSettings extends StatefulWidget {
  const EmployeeSettings({super.key});

  @override
  State<EmployeeSettings> createState() => _EmployeeSettingsState();
}

class _EmployeeSettingsState extends State<EmployeeSettings> {
  // SERVICES & DEPENDENCIES

  final ProfileService _profileService = ProfileService();
  final LocalAuthentication _localAuth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();

  // TEXT EDITING CONTROLLERS

  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // STATE VARIABLES - Password Visibility

  bool _currentPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  // STATE VARIABLES - Loading & Biometrics

  bool _isLoading = false;
  bool _isBiometricEnabled = false;
  bool _canCheckBiometrics = false;
  bool _hasFaceID = false;
  bool _hasFingerprint = false;
  String _biometricLabel = "Biometrics";

  // LIFECYCLE METHODS

  @override
  void initState() {
    super.initState();
    enableFullScreen();

    // Add listener to rebuild UI when password changes for real-time validation
    _newPasswordController.addListener(() {
      setState(() {});
    });

    // Check if biometrics are available on this device
    _checkBiometrics();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // PASSWORD VALIDATION GETTERS

  /// Check if password has minimum length requirement
  bool get _hasMinLength => _newPasswordController.text.length >= 6;

  /// Check if password contains uppercase letter
  bool get _hasUpperCase =>
      _newPasswordController.text.contains(RegExp(r'[A-Z]'));

  /// Check if password contains lowercase letter
  bool get _hasLowerCase =>
      _newPasswordController.text.contains(RegExp(r'[a-z]'));

  /// Check if password contains special character
  bool get _hasSpecialChar =>
      _newPasswordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  /// Check if new password is different from current password
  bool get _isDifferentFromCurrent =>
      _currentPasswordController.text.isNotEmpty &&
      _newPasswordController.text.isNotEmpty &&
      _currentPasswordController.text != _newPasswordController.text;

  // BIOMETRIC AUTHENTICATION METHODS

  /// Check if device supports biometrics and load user preference
  Future<void> _checkBiometrics() async {
    bool canCheck = false;

    try {
      canCheck = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
    } catch (e) {
      debugPrint("Biometric check failed: $e");
    }

    // Load available biometrics
    final List<BiometricType> availableBiometrics =
        await _localAuth.getAvailableBiometrics();

    // Load user's biometric preference from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool('biometric_enabled') ?? false;

    if (mounted) {
      setState(() {
        _canCheckBiometrics = canCheck;
        _isBiometricEnabled = isEnabled;
        _hasFaceID = availableBiometrics.contains(BiometricType.face);
        _hasFingerprint =
            availableBiometrics.contains(BiometricType.fingerprint);

        // Set dynamic label
        if (_hasFaceID && _hasFingerprint) {
          _biometricLabel = "Face ID / Fingerprint";
        } else if (_hasFaceID) {
          _biometricLabel = "Face ID";
        } else if (_hasFingerprint) {
          _biometricLabel = "Fingerprint";
        } else {
          _biometricLabel = "Biometrics";
        }
      });
    }
  }

  /// Toggle biometric authentication on/off
  Future<void> _toggleBiometrics(bool value) async {
    final prefs = await SharedPreferences.getInstance();

    if (value) {
      try {
        // Biometric Challenge before enabling
        final String authMessage = _hasFaceID
            ? 'Please authenticate using Face ID to enable biometric login'
            : (_hasFingerprint
                ? 'Please authenticate using Fingerprint to enable biometric login'
                : 'Please authenticate to enable biometric login');

        final bool didAuthenticate = await _localAuth.authenticate(
          localizedReason: authMessage,
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );

        if (!didAuthenticate) {
          return; // Auth failed or cancelled, do not enable
        }
      } catch (e) {
        debugPrint("Biometric Authentication Error: $e");
        _showSnackBar("Biometric authentication failed", isError: true);
        return;
      }

      // Synchronize SecureStorage check
      String? savedEmail = await _storage.read(key: 'login_email');
      String? savedPass = await _storage.read(key: 'login_pass');

      if (savedEmail == null || savedPass == null) {
        _showSnackBar("Please log in again to link biometrics securely.",
            isError: true);
        return;
      }
    }

    await prefs.setBool('biometric_enabled', value);

    setState(() {
      _isBiometricEnabled = value;
    });

    _showSnackBar(
      value ? "Biometric login enabled" : "Biometric login disabled",
      isError: false,
    );
  }

  // PASSWORD UPDATE LOGIC

  /// Validate and update user password
  Future<void> _updatePassword() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validation: Check if all fields are filled
    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      _showSnackBar("Please fill in all fields", isError: true);
      return;
    }

    // Validation: Check if passwords match
    if (newPassword != confirmPassword) {
      _showSnackBar("Passwords do not match", isError: true);
      return;
    }

    // Validation: Check if new password is different from current
    if (currentPassword == newPassword) {
      _showSnackBar(
        "New password must be different from current password",
        isError: true,
      );
      return;
    }

    // Validation: Check minimum length
    if (newPassword.length < 6) {
      _showSnackBar(
        "Password must be at least 6 characters long",
        isError: true,
      );
      return;
    }

    if (!RegExp(r'[A-Z]').hasMatch(newPassword)) {
      _showSnackBar("Password must contain at least one uppercase letter",
          isError: true);
      return;
    }

    if (!RegExp(r'[a-z]').hasMatch(newPassword)) {
      _showSnackBar("Password must contain at least one lowercase letter",
          isError: true);
      return;
    }

    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(newPassword)) {
      _showSnackBar("Password must contain at least one special character",
          isError: true);
      return;
    }

    // Start loading state
    setState(() => _isLoading = true);

    try {
      // Get user email from provider
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userEmail = userProvider.userProfile["email"];

      // Call API to update password
      final success = await _profileService.updatePassword(
        userEmail,
        currentPassword,
        newPassword,
      );

      setState(() => _isLoading = false);

      // Handle success
      if (success != null && success) {
        // SYNC: Update secure storage with new password
        await _storage.write(key: 'login_pass', value: newPassword);

        if (mounted) {
          SuccessDialog.show(
            context,
            title: "Password Updated",
            message: "Your password has been changed successfully.",
            buttonText: "OK",
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmpBottomnavbar(),
                ),
              );
            },
          );
        }
      } else {
        _showSnackBar(
          "Failed to update password. Check current password.",
          isError: true,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Exception during password update: $e");
      _showSnackBar("Something went wrong: $e", isError: true);
    }
  }

  // UI HELPER METHODS

  /// Show snackbar with message
  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.redAccent : Colors.green,
        ),
      );
    }
  }

  // BUILD METHOD

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: Background()),
        Scaffold(
          backgroundColor: Colors.transparent,
          drawer: const EmpSidenav(
            currentScreen: 'EmployeeSettings',
          ),
          appBar: const Uppernavbar(
            showBackButton: false,
          ),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    Responsive.isDesktop(context)
                        ? 100
                        : (Responsive.isTablet(context) ? 40 : 20),
                    10,
                    Responsive.isDesktop(context)
                        ? 100
                        : (Responsive.isTablet(context) ? 40 : 20),
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppTheme.borderRadiusL),
                          gradient: AppTheme.backgroundGradient,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Page title
                            const Text(
                              'Settings',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Profile header with avatar
                            _buildProfileHeader(),
                            const SizedBox(height: 30),

                            // Password change fields and biometric toggle
                            _buildPasswordFields(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_isLoading)
          const Center(
            child: CircularProgressIndicator(
              color: Color(0xFF724584),
            ),
          ),
      ],
    );
  }

  // UI COMPONENT BUILDERS

  /// Build profile header section with avatar
  Widget _buildProfileHeader() {
    void navigateToProfile() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const EmployeeProfile(),
        ),
      );
    }

    return Center(
      child: ProfileAvatar(
        editable: true,
        onEditTap: navigateToProfile,
        onTap: navigateToProfile,
      ),
    );
  }

  /// Build all password-related fields and controls
  Widget _buildPasswordFields() {
    return Column(
      children: [
        // Current Password Field
        _buildPasswordInputField(
          controller: _currentPasswordController,
          hintText: "Current Password",
          isVisible: _currentPasswordVisible,
          toggleVisibility: () {
            setState(() {
              _currentPasswordVisible = !_currentPasswordVisible;
            });
          },
        ),
        const SizedBox(height: 16),

        // New Password Field
        _buildPasswordInputField(
          controller: _newPasswordController,
          hintText: "New Password",
          isVisible: _newPasswordVisible,
          toggleVisibility: () {
            setState(() {
              _newPasswordVisible = !_newPasswordVisible;
            });
          },
        ),

        // Password Validation Requirements
        // Shows real-time feedback when user starts typing
        if (_newPasswordController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12, left: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildValidationItem(
                  "At least 6 characters",
                  _hasMinLength,
                ),
                _buildValidationItem(
                  "Contains uppercase letter (A-Z)",
                  _hasUpperCase,
                ),
                _buildValidationItem(
                  "Contains lowercase letter (a-z)",
                  _hasLowerCase,
                ),
                _buildValidationItem(
                  "Contains special character (!@#\$%^&*)",
                  _hasSpecialChar,
                ),
                // Only show "different from current" if current password is entered
                if (_currentPasswordController.text.isNotEmpty)
                  _buildValidationItem(
                    "Different from current password",
                    _isDifferentFromCurrent,
                  ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // Confirm Password Field
        _buildPasswordInputField(
          controller: _confirmPasswordController,
          hintText: "Confirm Password",
          isVisible: _confirmPasswordVisible,
          toggleVisibility: () {
            setState(() {
              _confirmPasswordVisible = !_confirmPasswordVisible;
            });
          },
        ),
        const SizedBox(height: 24),

        // Update Password Button
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.5,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.gradientBlueButton,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _updatePassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _isLoading ? 'Updating...' : 'Update',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Biometric Authentication Toggle
        _buildBiometricToggle(),
        const SizedBox(height: 24),
      ],
    );
  }

  /// Build individual password validation requirement indicator

  /// Shows a checkmark if requirement is met, X if not met
  Widget _buildValidationItem(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.cancel,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build password input field with visibility toggle
  Widget _buildPasswordInputField({
    required TextEditingController controller,
    required String hintText,
    required bool isVisible,
    required VoidCallback toggleVisibility,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        obscureText: !isVisible,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          suffixIcon: IconButton(
            icon: Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.grey.shade400,
            ),
            onPressed: toggleVisibility,
          ),
        ),
      ),
    );
  }

  /// Build biometric authentication toggle section

  /// Shows a toggle switch if biometrics are available on the device,
  /// otherwise shows a disabled state with explanation
  Widget _buildBiometricToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: _canCheckBiometrics
          ? SwitchListTile(
              title: Text(
                "Enable $_biometricLabel",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                "Use $_biometricLabel for faster login",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              secondary: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_hasFaceID)
                    const Icon(
                      Icons.face,
                      color: Colors.white,
                      size: 24,
                    ),
                  if (_hasFaceID && _hasFingerprint) const SizedBox(width: 8),
                  if (_hasFingerprint)
                    const Icon(
                      Icons.fingerprint,
                      color: Colors.white,
                      size: 24,
                    ),
                  if (!_hasFaceID && !_hasFingerprint)
                    const Icon(
                      Icons.lock_person_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                ],
              ),
              activeThumbColor: const Color(0xFF2979FF),
              value: _isBiometricEnabled,
              onChanged: _toggleBiometrics,
            )
          : const ListTile(
              leading: Icon(
                Icons.lock_clock_outlined,
                color: Colors.grey,
              ),
              title: Text(
                "Biometrics Not Available",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                "Your device does not support biometric authentication.",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
    );
  }
}
