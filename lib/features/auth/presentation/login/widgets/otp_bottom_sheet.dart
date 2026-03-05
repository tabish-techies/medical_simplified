import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

// Keep your existing imports
import '../../../data/auth_repository.dart';
import '../../registration/registration_screen.dart';
import '../../home/main_screen.dart';

class OtpBottomSheet extends StatefulWidget {
  const OtpBottomSheet({
    super.key,
    required this.phone,
    required this.verificationId,
    required this.authRepository,
    required this.onResend,
  });

  final String phone;
  final String verificationId;
  final AuthRepository authRepository;
  final VoidCallback onResend;

  @override
  State<OtpBottomSheet> createState() => _OtpBottomSheetState();
}

class _OtpBottomSheetState extends State<OtpBottomSheet> {
  final TextEditingController _otpController = TextEditingController();
  bool _isVerifying = false;
  String? _errorMessage;

  Timer? _timer;
  int _start = 30; // 30 seconds timer
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    setState(() {
      _start = 30;
      _canResend = false;
    });
    _timer?.cancel(); // Cancel existing if any
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _timer?.cancel();
          _canResend = true;
        });
      } else {
        setState(() => _start--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  // ===============================
  // VERIFY OTP (LOGIC PRESERVED)
  // ===============================
  Future<void> _onVerifyPressed() async {
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      setState(() => _errorMessage = 'Please enter a valid 6-digit OTP');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null; 
    });

    try {
      // 1️⃣ Create Firebase credential
      final credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId, 
        smsCode: otp
      );

      // 2️⃣ Sign in with Firebase
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Firebase authentication failed');
      }

      // 3️⃣ Get Firebase ID token
      final firebaseToken = await firebaseUser.getIdToken();
      if (firebaseToken == null) {
        throw Exception('Failed to obtain Firebase token');
      }

      // 🔥 Debug Logs
      debugPrint('🔥 Firebase ID Token: $firebaseToken');
      
      // 4️⃣ Call backend with Firebase token
      final user = await widget.authRepository.verifyFirebaseToken(firebaseToken: firebaseToken);

      if (!mounted) return;
      
      // Close bottom sheet BEFORE navigating
      Navigator.pop(context); 

      // 5️⃣ Check if new user & Navigate
      final isRegCompleted = user['isRegCompleted'] == 1;

      if (!isRegCompleted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => RegistrationScreen(authRepository: widget.authRepository)),
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => MainScreen(authRepository: widget.authRepository)),
          (_) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Invalid OTP';
      if (e.code == 'invalid-verification-code') {
        message = 'The code you entered is incorrect.';
      } else if (e.code == 'session-expired') {
        message = 'Session expired. Please resend OTP.';
      }
      if(mounted) setState(() => _errorMessage = message);
    } catch (e) {
      if(mounted) setState(() => _errorMessage = 'An error occurred: $e');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  void _handleResend() {
    widget.onResend();
    startTimer(); // Restart local timer
  }

  // ===============================
  // UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      // Ensure bottom sheet moves up with keyboard
      padding: EdgeInsets.only(bottom: keyboardHeight), 
      child: SingleChildScrollView(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Handle Bar (Visual cue)
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // 2. Icon Header (CHANGED TO BLUE)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1), // ✅ Changed from green to blue
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_read_outlined, color: Colors.blue, size: 32), // ✅ Changed from green to blue
              ),
              const SizedBox(height: 20),

              // 3. Title & Subtitle
              const Text(
                'Verification Code',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.5),
                  children: [
                    const TextSpan(text: 'We have sent the code verification to\n'),
                    TextSpan(
                      text: '+91 ${widget.phone}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold, 
                        color: Colors.black87
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 4. Styled OTP Input
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24, 
                  fontWeight: FontWeight.bold, 
                  letterSpacing: 12 // Spaced out look
                ),
                decoration: InputDecoration(
                  counterText: '', // Hide counter
                  hintText: '------',
                  hintStyle: TextStyle(color: Colors.grey[300], letterSpacing: 12),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  // Show error text if generic error exists
                  errorText: _errorMessage, 
                  errorMaxLines: 2,
                ),
                onChanged: (val) {
                  if (val.length == 6) FocusScope.of(context).unfocus();
                  if (_errorMessage != null) setState(() => _errorMessage = null);
                },
              ),

              const SizedBox(height: 24),

              // 5. Verify Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _onVerifyPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          height: 24, 
                          width: 24, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                        )
                      : const Text(
                          'Verify OTP', 
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // 6. Resend Timer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive code? ",
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  if (!_canResend)
                    Text(
                      'Resend in ${_start}s',
                      style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold),
                    )
                  else
                    GestureDetector(
                      onTap: _handleResend,
                      child: Text(
                        'Resend OTP',
                        style: TextStyle(
                          color: primaryColor, 
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}