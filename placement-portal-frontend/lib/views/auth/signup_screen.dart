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

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();

  String _selectedRole = 'STUDENT'; // Default role
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final url = Uri.parse('http://localhost:8080/auth/register');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'role': _selectedRole,
          'name': _nameController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Registration Successful! Please verify your email with the OTP sent.', style: interTextStyle()),
              backgroundColor: Colors.greenAccent[700],
            ),
          );
          Navigator.pushReplacementNamed(
            context,
            '/verify-otp',
            arguments: _emailController.text.trim(),
          );
        }
      } else {
        setState(() {
          _errorMessage = data['error'] ?? 'Registration failed. Please check details.';
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
                color: const Color(0x33FFFFFF),
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
                            child: _buildInfoPanel(),
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

  Widget _buildInfoPanel() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF8B5CF6),
            Color(0xFFEC4899),
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
              'Join Us',
              style: outfitTextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Create Your\nPlacement Account',
            style: outfitTextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 32,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Create a profile as a Student to explore jobs, or as a Recruiter to hire top-tier talent from BMU.',
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
              'Sign Up',
              style: outfitTextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get started on the placement portal',
              style: interTextStyle(
                color: Colors.white60,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
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
            // Role Selection Cards
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedRole = 'STUDENT'),
                    child: _buildRoleCard('Student', Icons.school_outlined, _selectedRole == 'STUDENT'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedRole = 'RECRUITER'),
                    child: _buildRoleCard('Recruiter', Icons.business_outlined, _selectedRole == 'RECRUITER'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              style: interTextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  _selectedRole == 'STUDENT' ? Icons.person_outline : Icons.business_outlined,
                  color: Colors.white38,
                ),
                labelText: _selectedRole == 'STUDENT' ? 'Full Name' : 'Company Name',
                labelStyle: interTextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF261D35),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
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
                if (value == null || value.trim().isEmpty) {
                  return _selectedRole == 'STUDENT' ? 'Please enter your name' : 'Please enter company name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
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
                  borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
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
            const SizedBox(height: 16),
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
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
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
                  borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
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
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              style: interTextStyle(color: Colors.white),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_clock_outlined, color: Colors.white38),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: Colors.white38,
                  ),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
                labelText: 'Confirm Password',
                labelStyle: interTextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF261D35),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF8B5CF6)),
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
                  return 'Please confirm your password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleSignup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
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
                        'Create Account',
                        style: outfitTextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account?',
                  style: interTextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: Text(
                    'Sign In',
                    style: interTextStyle(
                      color: const Color(0xFF8B5CF6),
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

  Widget _buildRoleCard(String title, IconData icon, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0x1F8B5CF6) : const Color(0xFF261D35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF8B5CF6) : Colors.white.withOpacity(0.05),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF8B5CF6) : Colors.white38,
            size: 28,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: outfitTextStyle(
              color: isSelected ? Colors.white : Colors.white60,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
