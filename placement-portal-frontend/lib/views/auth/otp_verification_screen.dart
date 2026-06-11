import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

TextStyle outfitTextStyle({
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
  double? height,
  double? letterSpacing,
}) {
  return TextStyle(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    letterSpacing: letterSpacing,
    fontFamily: 'Roboto',
  );
}

TextStyle interTextStyle({
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
  double? height,
  double? letterSpacing,
}) {
  return TextStyle(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    letterSpacing: letterSpacing,
    fontFamily: 'Roboto',
  );
}

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  String? _successMessage;

  int _secondsRemaining = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 30;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        setState(() {
          _timer?.cancel();
        });
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  Future<void> _handleVerify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'Please enter a valid 6-digit OTP code.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final url = Uri.parse('http://localhost:8080/auth/verify-otp');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'otp': otp,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _successMessage = 'Email verified successfully! Redirecting to login...';
        });
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
          }
        });
      } else {
        setState(() {
          _errorMessage = data['error'] ?? 'Invalid or expired OTP. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not connect to the server. Make sure the backend is running.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleResend() async {
    if (_secondsRemaining > 0) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final url = Uri.parse('http://localhost:8080/auth/send-otp');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _successMessage = 'A new OTP has been sent to your email address.';
        });
        _startTimer();
      } else {
        setState(() {
          _errorMessage = data['error'] ?? 'Failed to resend OTP. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to connect to the server. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F0C1B),
              Color(0xFF201A30),
              Color(0xFF140D24),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              decoration: BoxDecoration(
                color: const Color(0x33FFFFFF),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withAlpha(26),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(77),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  color: const Color(0xFF1B1425),
                  padding: const EdgeInsets.all(40.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Verify Email',
                        style: outfitTextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          style: interTextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                            height: 1.4,
                          ),
                          children: [
                            const TextSpan(text: 'We have sent a 6-digit OTP code to '),
                            TextSpan(
                              text: widget.email,
                              style: interTextStyle(
                                color: const Color(0xFF6366F1),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(text: '. Please enter it below to activate your account.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withAlpha(26),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.redAccent.withAlpha(77)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: interTextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (_successMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withAlpha(26),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.withAlpha(77)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _successMessage!,
                                  style: interTextStyle(
                                    color: Colors.green,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _otpController,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              textAlign: TextAlign.center,
                              style: outfitTextStyle(
                                color: const Color(0xFF8B5CF6),
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 8,
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                hintText: '000000',
                                hintStyle: interTextStyle(
                                  color: Colors.white12,
                                  letterSpacing: 8,
                                ),
                                filled: true,
                                fillColor: const Color(0xFF0F0C1B),
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.trim().length != 6) {
                                  return 'Enter a 6-digit code';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                  ),
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleVerify,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Text(
                                          'Verify OTP',
                                          style: interTextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: TextButton(
                          onPressed: (_secondsRemaining == 0 && !_isResending) ? _handleResend : null,
                          child: _isResending
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF6366F1),
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _secondsRemaining > 0
                                      ? 'Resend OTP in ${_secondsRemaining}s'
                                      : 'Resend OTP Code',
                                  style: interTextStyle(
                                    color: _secondsRemaining > 0 ? Colors.white30 : const Color(0xFF6366F1),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
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
      ),
    );
  }
}
