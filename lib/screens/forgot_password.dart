import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shiftsmart/services/auth_service.dart';
import 'package:shiftsmart/widgets/login_background.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthService _authService = AuthService();

  // Controllers
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  // OTP Controllers & FocusNodes (For 6-digit input)
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  // State Variables
  int _step = 1; // 1: Email, 2: OTP, 3: New Password
  bool _isLoading = false;
  String? _resetTokenId; // Stores the token from Backend
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _otpFocusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _showMessage(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Helper to get the full OTP string from the 6 boxes
  String get _otpCode => _otpControllers.map((e) => e.text).join();

  Future<void> _handleNext() async {
    setState(() => _isLoading = true);

    try {
      // --- STEP 1: REQUEST OTP ---
      if (_step == 1) {
        final email = _emailCtrl.text.trim();
        if (email.isEmpty) {
          _showMessage("Please enter your email", isError: true);
          setState(() => _isLoading = false);
          return;
        }

        if (!RegExp(r'^[\w._%+\-]+@[\w.\-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
          _showMessage("Please enter a valid email address", isError: true);
          setState(() => _isLoading = false);
          return;
        }

        // Call Request Endpoint
        final result = await _authService.requestPasswordReset(email);

        if (result.success && result.resetTokenId != null) {
          setState(() {
            _resetTokenId = result.resetTokenId; //  Capture the Token!
            _step = 2;
          });
          _showMessage(result.message);
        } else {
          _showMessage(result.message, isError: true);
        }
      }

      // --- STEP 2: VERIFY OTP ---
      else if (_step == 2) {
        final otp = _otpCode;
        if (otp.length < 6) {
          _showMessage("Please enter the full 6-digit code", isError: true);
          setState(() => _isLoading = false);
          return;
        }

        // Verify using Token + OTP
        bool success = await _authService.verifyResetOtp(_resetTokenId!, otp);

        if (success) {
          setState(() => _step = 3);
          _showMessage("OTP Verified Successfully");
        } else {
          _showMessage("Invalid Code. Please try again.", isError: true);
        }
      }

      // --- STEP 3: RESET PASSWORD ---
      else if (_step == 3) {
        if (_passCtrl.text.length < 6) {
          _showMessage("Password must be at least 6 chars", isError: true);
          setState(() => _isLoading = false);
          return;
        }
        if (_passCtrl.text != _confirmPassCtrl.text) {
          _showMessage("Passwords do not match", isError: true);
          setState(() => _isLoading = false);
          return;
        }

        // Reset using Token + OTP + New Password
        bool success = await _authService.resetPassword(
            _resetTokenId!,
            _otpCode, // Send the OTP again as proof
            _passCtrl.text.trim());

        if (success) {
          _showMessage("Password Reset Successful! Please Login.");
          if (mounted) Navigator.pop(context);
        } else {
          _showMessage("Failed to reset password", isError: true);
        }
      }
    } catch (e) {
      _showMessage("An error occurred: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: LoginBackground()),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    // Optional: Add Logo here if needed
                    const Icon(Icons.lock_reset, size: 60, color: Colors.white),
                    const SizedBox(height: 20),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(136, 42, 41, 41)
                                .withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildHeader(),
                              const SizedBox(height: 25),
                              if (_step == 1) _buildStep1Email(),
                              if (_step == 2) _buildStep2Otp(),
                              if (_step == 3) _buildStep3Password(),
                              const SizedBox(height: 25),
                              _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: _handleNext,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xFF2979FF),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12)),
                                          elevation: 5,
                                        ),
                                        child: Text(
                                          _step == 3
                                              ? "Reset Password"
                                              : "Next",
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white),
                                        ),
                                      ),
                                    ),
                              const SizedBox(height: 15),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Cancel",
                                    style: TextStyle(color: Colors.white70)),
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
      ],
    );
  }

  Widget _buildHeader() {
    String title = "Forgot Password";
    String subtitle = "Enter your email to receive a reset code.";

    if (_step == 2) {
      title = "Enter OTP";
      subtitle = "We sent a 6-digit code to ${_emailCtrl.text}";
    } else if (_step == 3) {
      title = "New Password";
      subtitle = "Create a strong password for your account.";
    }

    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildStep1Email() {
    return _buildTextField("Email Address", _emailCtrl,
        icon: Icons.email_outlined);
  }

  Widget _buildStep2Otp() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return Container(
          width: 45,
          height: 55,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: _otpFocusNodes[index].hasFocus
                    ? const Color(0xFF2979FF)
                    : Colors.white24,
                width: _otpFocusNodes[index].hasFocus ? 2 : 1),
          ),
          child: TextFormField(
            controller: _otpControllers[index],
            focusNode: _otpFocusNodes[index],
            style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            inputFormatters: [
              LengthLimitingTextInputFormatter(1),
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                // Auto-focus next field
                FocusScope.of(context).requestFocus(_otpFocusNodes[index + 1]);
              } else if (value.isEmpty && index > 0) {
                // Auto-focus previous field on delete
                FocusScope.of(context).requestFocus(_otpFocusNodes[index - 1]);
              }
            },
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStep3Password() {
    return Column(
      children: [
        _buildTextField("New Password", _passCtrl,
            icon: Icons.lock_outline,
            obscure: _obscurePass,
            onToggleVis: () => setState(() => _obscurePass = !_obscurePass)),
        const SizedBox(height: 15),
        _buildTextField("Confirm Password", _confirmPassCtrl,
            icon: Icons.lock_outline,
            obscure: _obscureConfirm,
            onToggleVis: () =>
                setState(() => _obscureConfirm = !_obscureConfirm)),
      ],
    );
  }

  Widget _buildTextField(String hint, TextEditingController ctrl,
      {required IconData icon,
      bool obscure = false,
      VoidCallback? onToggleVis}) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: onToggleVis != null
            ? IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.white54),
                onPressed: onToggleVis,
              )
            : null,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2979FF), width: 1.5),
        ),
      ),
    );
  }
}
