import 'package:flutter/gestures.dart'; // ✅ Required for clickable text
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medical_simplified/features/auth/presentation/profile/privacy_policy/privacy_policy_screen.dart';
import 'package:medical_simplified/features/auth/presentation/profile/terms_and_condition/terms_and_condition_screen.dart';


import '../../../auth/data/auth_repository.dart';
import 'widgets/otp_bottom_sheet.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();

  bool _isSending = false;

  /// ✅ REQUIRED to verify OTP later
  String? _verificationId;
  int? _resendToken;
  String? _errorMessage; 

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  // ===============================
  // SEND OTP VIA FIREBASE
  // ===============================
  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      setState(() => _errorMessage = 'Please enter phone number');
      return;
    }

    // Clear previous error
    setState(() {
      _errorMessage = null;
      _isSending = true;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+91$phone',
        timeout: const Duration(seconds: 60),
        forceResendingToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          String message = 'OTP verification failed';
          if (e.code == 'invalid-phone-number') {
            message = 'Invalid mobile number';
          } else if (e.code == 'too-many-requests') {
            message = 'Too many requests. Please try again later.';
          }
          if (mounted) {
            setState(() {
              _errorMessage = message;
              _isSending = false;
            });
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          if (mounted) {
            setState(() => _isSending = false);
          }
          _verificationId = verificationId;
          _resendToken = resendToken; 
          _showOtpBottomSheet(phone);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          if (mounted) setState(() => _isSending = false);
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isSending = false;
      });
    }
  }

  // ===============================
  // SHOW OTP BOTTOM SHEET
  // ===============================
  void _showOtpBottomSheet(String phone) {
    if (_verificationId == null) {
      setState(() => _errorMessage = 'Verification failed. Try again.');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent, // Transparent to allow custom rounding
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -2))
          ],
        ),
        padding: EdgeInsets.only(
          left: 20, 
          right: 20, 
          top: 24, 
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar visual
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            OtpBottomSheet(
              phone: phone,
              verificationId: _verificationId!,
              authRepository: widget.authRepository,
              onResend: () {
                Navigator.pop(context);
                _sendOtp();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ===============================
  // NAVIGATION HELPERS
  // ===============================
  void _openTerms() {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => const TermsAndConditionsScreen())
    );
  }

  void _openPrivacy() {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen())
    );
  }

  // ===============================
  // UI COMPONENTS
  // ===============================
  @override
  Widget build(BuildContext context) {
    // Determine screen size for responsiveness
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                // 1. BRANDING / ILLUSTRATION SECTION
                Center(
                  child: Container(
                    height: 150,
                    width: 150,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.medical_services_outlined, // Updated to Medical Icon
                      size: 80,
                      color: primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // 2. WELCOME TEXT
                const Text(
                  'Medical Simplified',
                  style: TextStyle(
                    fontSize: 28, 
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your mobile number to login securely.',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),

                // 3. INPUT FIELD
                const Text(
                  'Mobile Number',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: Colors.grey[100],
                    prefixIcon: Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(right: 8),
                      child: const Text(
                        '+91',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                    hintText: '000 000 0000',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: primaryColor, width: 2),
                    ),
                    // Show error border if message exists
                    errorText: _errorMessage,
                  ),
                  onChanged: (_) {
                    if (_errorMessage != null) {
                      setState(() => _errorMessage = null);
                    }
                  },
                ),

                const SizedBox(height: 32),

                // 4. ACTION BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSending ? null : _sendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isSending
                        ? const SizedBox(
                            height: 24, 
                            width: 24, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                          )
                        : const Text(
                            'Send Verification Code',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                // 5. FOOTER / TERMS (Clickable)
                Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(color: Colors.grey[500], fontSize: 12, height: 1.5),
                      children: [
                        const TextSpan(text: 'By continuing, you agree to our '),
                        
                        // Clickable Terms
                        TextSpan(
                          text: 'Terms of Service',
                          style: TextStyle(
                            color: primaryColor, 
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()..onTap = _openTerms,
                        ),
                        
                        const TextSpan(text: ' & '),
                        
                        // Clickable Privacy
                        TextSpan(
                          text: 'Privacy Policy',
                          style: TextStyle(
                            color: primaryColor, 
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()..onTap = _openPrivacy,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}