import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

TextStyle outfitTextStyle({
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
  double? height,
}) {
  return TextStyle(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    fontFamily: 'Roboto',
  );
}

TextStyle interTextStyle({
  Color? color,
  double? fontSize,
  FontWeight? fontWeight,
  double? height,
}) {
  return TextStyle(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    fontFamily: 'Roboto',
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final url = Uri.parse('http://localhost:8080/auth/login');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = data['token'];
        print('Logged in successfully. Token: $token');
        // In a real app, save token to local storage/shared preferences
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Login Successful! Token received.', style: interTextStyle()),
              backgroundColor: Colors.greenAccent[700],
            ),
          );
        }
      } else {
        final errorMsg = data['error'] ?? 'Login failed. Please try again.';
        setState(() {
          _errorMessage = errorMsg;
        });
        if (errorMsg.contains('Email not verified')) {
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) {
              Navigator.pushNamed(
                context,
                '/verify-otp',
                arguments: _emailController.text.trim(),
              );
            }
          });
        }
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

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
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 900 : 450,
              ),
              decoration: BoxDecoration(
                color: const Color(0x33FFFFFF), // Transparent glassmorphism base
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: isDesktop
                    ? Row(
                        children: [
                          Expanded(
                            child: _buildWelcomePanel(),
                          ),
                          Expanded(
                            child: _buildFormPanel(),
                          ),
                        ],
                      )
                    : _buildFormPanel(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomePanel() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'BMU Portal',
              style: outfitTextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Empowering\nYour Career Journey',
            style: outfitTextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 32,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Connect with top companies, manage your applications, and boost your professional profile.',
            style: interTextStyle(
              color: Colors.white70,
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormPanel() {
    return Container(
      color: const Color(0xFF1B1425),
      padding: const EdgeInsets.all(40.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Welcome Back',
              style: outfitTextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Login to your placement account',
              style: interTextStyle(
                color: Colors.white60,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
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
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: interTextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.email_outlined, color: Colors.white38),
                labelText: 'Email Address',
                labelStyle: interTextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF261D35),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6366F1)),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.redAccent),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.redAccent),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                final emailTrimmed = value.trim();
                if (!emailTrimmed.endsWith('@bmu.edu.in')) {
                  return 'Email must belong to the @bmu.edu.in domain';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailTrimmed)) {
                  return 'Please enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: interTextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outlined, color: Colors.white38),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: Colors.white38,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
                labelText: 'Password',
                labelStyle: interTextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF261D35),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF6366F1)),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.redAccent),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.redAccent),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/forgot-password');
                },
                child: Text(
                  'Forgot Password?',
                  style: interTextStyle(
                    color: const Color(0xFF8B5CF6),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Sign In',
                        style: outfitTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account?",
                  style: interTextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/signup');
                  },
                  child: Text(
                    'Sign Up',
                    style: interTextStyle(
                      color: const Color(0xFF6366F1),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
