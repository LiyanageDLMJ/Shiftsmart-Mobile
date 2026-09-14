import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shiftsmart/providers/user_provider.dart';
import 'package:shiftsmart/services/profile_service.dart';
import 'package:shiftsmart/theme.dart';
import 'package:shiftsmart/utils/fullscreen_helper.dart';
import 'package:shiftsmart/widgets/background.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shiftsmart/widgets/bottomnavbar.dart';
import 'package:shiftsmart/widgets/build_profile_avatar.dart';
import 'package:shiftsmart/widgets/gradienthorizontal.dart';
import 'package:shiftsmart/widgets/sidenav.dart';
import 'package:shiftsmart/widgets/uppernavbar.dart';
import 'package:shiftsmart/widgets/success_dialog.dart'; //  Import Success Dialog
import 'package:shiftsmart/screens/privacy_policy.dart';

class ManagerSettings extends StatefulWidget {
  const ManagerSettings({super.key});

  @override
  State<ManagerSettings> createState() => _ManagerSettingsState();
}

class _ManagerSettingsState extends State<ManagerSettings> {
  // Controllers
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // State
  bool _currentPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _isLoading = false;

  // Biometrics state
  bool _isBiometricEnabled = false;
  bool _canCheckBiometrics = false;
  bool _hasFaceID = false;
  bool _hasFingerprint = false;
  String _biometricLabel = "Biometrics";
  final LocalAuthentication _localAuth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();

  final ProfileService _profileService = ProfileService();

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

  // --- Biometric Authentication Methods ---

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

  // --- Password Validation Getters ---

  bool get _hasMinLength => _newPasswordController.text.length >= 6;
  bool get _hasUpperCase =>
      _newPasswordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasLowerCase =>
      _newPasswordController.text.contains(RegExp(r'[a-z]'));
  bool get _hasSpecialChar =>
      _newPasswordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  bool get _isDifferentFromCurrent =>
      _currentPasswordController.text.isNotEmpty &&
      _newPasswordController.text.isNotEmpty &&
      _currentPasswordController.text != _newPasswordController.text;

  // --- Update Password Logic ---
  Future<void> _updatePassword() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // 1. Validation
    if (newPassword.isEmpty ||
        currentPassword.isEmpty ||
        confirmPassword.isEmpty) {
      _showSnackBar("Please fill in all fields", isError: true);
      return;
    }

    if (newPassword != confirmPassword) {
      _showSnackBar("Passwords do not match", isError: true);
      return;
    }

    if (currentPassword == newPassword) {
      _showSnackBar("New password must be different from current password",
          isError: true);
      return;
    }

    if (newPassword.length < 6) {
      _showSnackBar("Password must be at least 6 characters long",
          isError: true);
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

    setState(() => _isLoading = true);

    try {
      // 2. Get User Data
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userProfile = userProvider.userProfile;

      // DEBUG LOG: Check if email exists
      debugPrint("Manager Profile Data: $userProfile");

      // Fallback: Check 'email' key, if not found check 'Email' (case sensitive)
      final userEmail = userProfile["email"] ?? userProfile["Email"];

      if (userEmail == null || userEmail.toString().isEmpty) {
        setState(() => _isLoading = false);
        _showSnackBar("Error: Manager email not found in profile.",
            isError: true);
        return;
      }

      debugPrint("Attempting to update password for: $userEmail");

      // 3. API Call
      final success = await _profileService.updatePassword(
          userEmail, currentPassword, newPassword);

      setState(() => _isLoading = false);

      if (success != null && success) {
        // SYNC: Update secure storage with new password
        await _storage.write(key: 'login_pass', value: newPassword);

        if (mounted) {
          // --- Show Success Dialog ---
          SuccessDialog.show(
            context,
            title: "Password Updated",
            message: "Your password has been changed successfully.",
            buttonText: "OK",
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const Bottomnavbar(selectedIndex: 0),
                ),
              );
            },
          );
        }
      } else {
        _showSnackBar("Failed to update password. Check current password.",
            isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("Exception: $e");
      _showSnackBar("Something went wrong: $e", isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: Background()),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: const Uppernavbar(
            showBackButton: false,
          ),
          drawer: const Sidenav(
            currentScreen: 'ManagerSettings',
          ),
          body: Padding(
            padding: const EdgeInsets.only(bottom: 70),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Gradienthorizontal(
                width: double.infinity,
                height: 600,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    // Added ScrollView to prevent overflow
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),
                        const Text(
                          'Settings',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                        const SizedBox(height: 10),
                        const Center(
                          child: ProfileAvatar(
                            editable: false,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildPasswordFields(),
                        const SizedBox(height: 15),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_isLoading)
          const Center(
              child: CircularProgressIndicator(color: Color(0xFF724584))),
      ],
    );
  }

  Widget _buildPasswordFields() {
    return Column(
      children: [
        _buildPasswordInputField(
          controller: _currentPasswordController,
          hintText: "Current Password",
          isVisible: _currentPasswordVisible,
          toggleVisibility: () => setState(
              () => _currentPasswordVisible = !_currentPasswordVisible),
        ),
        const SizedBox(height: 16),
        _buildPasswordInputField(
          controller: _newPasswordController,
          hintText: "New Password",
          isVisible: _newPasswordVisible,
          toggleVisibility: () =>
              setState(() => _newPasswordVisible = !_newPasswordVisible),
        ),

        // Password Validation Requirements
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
                if (_currentPasswordController.text.isNotEmpty)
                  _buildValidationItem(
                    "Different from current password",
                    _isDifferentFromCurrent,
                  ),
              ],
            ),
          ),

        const SizedBox(height: 16),
        _buildPasswordInputField(
          controller: _confirmPasswordController,
          hintText: "Confirm Password",
          isVisible: _confirmPasswordVisible,
          toggleVisibility: () => setState(
              () => _confirmPasswordVisible = !_confirmPasswordVisible),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: MediaQuery.of(context).size.width * 0.5,
          child: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.gradientBlueButton,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ElevatedButton(
              onPressed:
                  _isLoading ? null : _updatePassword, // Disable when loading
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                _isLoading ? 'Updating...' : 'Update',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Biometric Authentication Toggle
        _buildBiometricToggle(),
        const SizedBox(height: 24),
        _buildPrivacyPolicyLink(),
        const SizedBox(height: 8),
      ],
    );
  }

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

  Widget _buildPrivacyPolicyLink() {
    return Column(
      children: [
        const Divider(color: Colors.white24),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.privacy_tip_outlined, color: Colors.white),
          title: const Text(
            'Privacy Policy',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          trailing: const Icon(Icons.chevron_right, color: Colors.white70),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PrivacyPolicyScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Build biometric authentication toggle section
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
}
