import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:placement_portal_frontend/utils/token_manager.dart';

TextStyle robotoStyle({
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

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditMode = false;
  String? _errorMessage;
  String? _successMessage;

  // Form Controllers
  final _nameController = TextEditingController();
  final _branchController = TextEditingController();
  final _semesterController = TextEditingController();
  final _cgpaController = TextEditingController();
  final _skillsController = TextEditingController();
  final _certificationsController = TextEditingController();
  final _projectsController = TextEditingController();
  final _experienceController = TextEditingController();
  final _githubController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _resumeController = TextEditingController();
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _branchController.dispose();
    _semesterController.dispose();
    _cgpaController.dispose();
    _skillsController.dispose();
    _certificationsController.dispose();
    _projectsController.dispose();
    _experienceController.dispose();
    _githubController.dispose();
    _linkedinController.dispose();
    _resumeController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final url = Uri.parse('http://localhost:8080/student/profile');
    try {
      final token = TokenManager.token;
      if (token == null) {
        setState(() {
          _errorMessage = 'No authorization token found. Please log in again.';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _populateFields(data);
      } else {
        setState(() {
          _errorMessage = 'Failed to load profile. Error: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not connect to the server. Make sure the backend is running.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _populateFields(Map<String, dynamic> data) {
    _userEmail = data['email'] ?? '';
    _nameController.text = data['name'] ?? '';
    _branchController.text = data['branch'] ?? '';
    _semesterController.text = data['semester']?.toString() ?? '';
    _cgpaController.text = data['cgpa']?.toString() ?? '';
    _skillsController.text = data['skills'] ?? '';
    _certificationsController.text = data['certifications'] ?? '';
    _projectsController.text = data['projects'] ?? '';
    _experienceController.text = data['experience'] ?? '';
    _githubController.text = data['github'] ?? '';
    _linkedinController.text = data['linkedin'] ?? '';
    _resumeController.text = data['resumeUrl'] ?? '';
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    final url = Uri.parse('http://localhost:8080/student/profile');
    try {
      final token = TokenManager.token;
      if (token == null) {
        setState(() {
          _errorMessage = 'No authorization token found. Please log in.';
          _isSaving = false;
        });
        return;
      }

      final body = {
        'email': _userEmail,
        'name': _nameController.text.trim(),
        'branch': _branchController.text.trim(),
        'semester': int.tryParse(_semesterController.text.trim()),
        'cgpa': double.tryParse(_cgpaController.text.trim()),
        'skills': _skillsController.text.trim(),
        'certifications': _certificationsController.text.trim(),
        'projects': _projectsController.text.trim(),
        'experience': _experienceController.text.trim(),
        'github': _githubController.text.trim(),
        'linkedin': _linkedinController.text.trim(),
        'resumeUrl': _resumeController.text.trim(),
      };

      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _populateFields(data);
        setState(() {
          _successMessage = 'Profile updated successfully!';
          _isEditMode = false;
        });
      } else {
        final data = jsonDecode(response.body);
        setState(() {
          _errorMessage = data['error'] ?? 'Failed to update profile.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection failure. Failed to update profile.';
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _handleLogout() {
    TokenManager.token = null;
    TokenManager.email = null;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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
              Color(0xFF0A0E17),
              Color(0xFF1E293B),
              Color(0xFF0F172A),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF14B8A6),
                ),
              )
            : SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      decoration: BoxDecoration(
                        color: const Color(0x33FFFFFF), // frosted glass base
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
                          color: const Color(0xFF111827),
                          padding: const EdgeInsets.all(32.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeader(),
                                const Divider(color: Colors.white10, height: 40),
                                if (_errorMessage != null) ...[
                                  _buildBanner(_errorMessage!, Colors.redAccent, Icons.error_outline),
                                  const SizedBox(height: 20),
                                ],
                                if (_successMessage != null) ...[
                                  _buildBanner(_successMessage!, Colors.greenAccent, Icons.check_circle_outline),
                                  const SizedBox(height: 20),
                                ],
                                AnimatedCrossFade(
                                  firstChild: _buildReadPanel(),
                                  secondChild: _buildEditPanel(),
                                  crossFadeState: _isEditMode
                                      ? CrossFadeState.showSecond
                                      : CrossFadeState.showFirst,
                                  duration: const Duration(milliseconds: 300),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _nameController.text.isNotEmpty ? _nameController.text : 'Student Profile',
              style: robotoStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _userEmail,
              style: robotoStyle(
                color: Colors.white38,
                fontSize: 14,
              ),
            ),
          ],
        ),
        Row(
          children: [
            if (!_isEditMode) ...[
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isEditMode = true;
                    _errorMessage = null;
                    _successMessage = null;
                  });
                },
                icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                label: Text('Edit Profile', style: robotoStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14B8A6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout, size: 18, color: Colors.redAccent),
                label: Text('Log out', style: robotoStyle(color: Colors.redAccent)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.redAccent, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _handleSave,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.save, size: 18, color: Colors.white),
                label: Text(_isSaving ? 'Saving...' : 'Save', style: robotoStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14B8A6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _isSaving
                    ? null
                    : () {
                        setState(() {
                          _isEditMode = false;
                          _errorMessage = null;
                          _successMessage = null;
                          _fetchProfile(); // reload values
                        });
                      },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: Text('Cancel', style: robotoStyle(color: Colors.white70)),
              ),
            ],
          ],
        )
      ],
    );
  }

  Widget _buildBanner(String message, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: robotoStyle(
                color: color,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadPanel() {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return isDesktop
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildReadLeftColumn()),
              const SizedBox(width: 32),
              Expanded(flex: 3, child: _buildReadRightColumn()),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReadLeftColumn(),
              const SizedBox(height: 24),
              _buildReadRightColumn(),
            ],
          );
  }

  Widget _buildReadLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoCard(
          'Academic Information',
          [
            _buildInfoRow('Branch', _branchController.text.isNotEmpty ? _branchController.text : 'Not Specified'),
            _buildInfoRow('Semester', _semesterController.text.isNotEmpty ? _semesterController.text : 'Not Specified'),
            _buildInfoRow('CGPA', _cgpaController.text.isNotEmpty ? '${_cgpaController.text} / 10.0' : 'Not Specified'),
          ],
        ),
        const SizedBox(height: 24),
        _buildInfoCard(
          'Professional Links',
          [
            _buildLinkRow('GitHub', _githubController.text, Icons.code),
            _buildLinkRow('LinkedIn', _linkedinController.text, Icons.work_outline),
            _buildLinkRow('Resume URL', _resumeController.text, Icons.description_outlined),
          ],
        ),
      ],
    );
  }

  Widget _buildReadRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailSection('Skills', _skillsController.text, Icons.psychology_outlined),
        const SizedBox(height: 24),
        _buildDetailSection('Projects', _projectsController.text, Icons.assessment_outlined),
        const SizedBox(height: 24),
        _buildDetailSection('Experience', _experienceController.text, Icons.business_center_outlined),
        const SizedBox(height: 24),
        _buildDetailSection('Certifications', _certificationsController.text, Icons.verified_user_outlined),
      ],
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: robotoStyle(
                color: const Color(0xFF14B8A6),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: robotoStyle(color: Colors.white38, fontSize: 14)),
          Text(value, style: robotoStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildLinkRow(String label, String value, IconData icon) {
    final hasLink = value.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: hasLink ? const Color(0xFF3B82F6) : Colors.white24, size: 18),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: robotoStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 2),
              Text(
                hasLink ? value : 'Not provided',
                style: robotoStyle(
                  color: hasLink ? const Color(0xFF3B82F6) : Colors.white30,
                  fontSize: 13,
                  fontWeight: hasLink ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, String content, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF14B8A6), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: robotoStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content.isNotEmpty ? content : 'No details provided yet.',
            style: robotoStyle(
              color: content.isNotEmpty ? Colors.white70 : Colors.white24,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditPanel() {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return isDesktop
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildEditLeftColumn()),
              const SizedBox(width: 32),
              Expanded(flex: 3, child: _buildEditRightColumn()),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildEditLeftColumn(),
              const SizedBox(height: 24),
              _buildEditRightColumn(),
            ],
          );
  }

  Widget _buildEditLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Info',
          style: robotoStyle(color: const Color(0xFF14B8A6), fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildTextField(_nameController, 'Full Name', Icons.person_outlined, validator: (val) {
          if (val == null || val.trim().isEmpty) return 'Name is required';
          return null;
        }),
        const SizedBox(height: 16),
        _buildTextField(_branchController, 'Branch', Icons.school_outlined),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                _semesterController,
                'Semester',
                Icons.calendar_today_outlined,
                isNumber: true,
                validator: (val) {
                  if (val != null && val.trim().isNotEmpty) {
                    final sem = int.tryParse(val.trim());
                    if (sem == null || sem < 1 || sem > 10) return 'Enter 1-10';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                _cgpaController,
                'CGPA',
                Icons.grade_outlined,
                isDecimal: true,
                validator: (val) {
                  if (val != null && val.trim().isNotEmpty) {
                    final cg = double.tryParse(val.trim());
                    if (cg == null || cg < 0 || cg > 10.0) return 'Enter 0.0-10.0';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          'Links',
          style: robotoStyle(color: const Color(0xFF14B8A6), fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildTextField(_githubController, 'GitHub Link', Icons.code),
        const SizedBox(height: 16),
        _buildTextField(_linkedinController, 'LinkedIn Link', Icons.work_outline),
        const SizedBox(height: 16),
        _buildTextField(_resumeController, 'Resume URL', Icons.description_outlined),
      ],
    );
  }

  Widget _buildEditRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skills & Experience',
          style: robotoStyle(color: const Color(0xFF14B8A6), fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildTextField(_skillsController, 'Skills (comma-separated)', Icons.psychology_outlined, maxLines: 3),
        const SizedBox(height: 16),
        _buildTextField(_projectsController, 'Projects', Icons.assessment_outlined, maxLines: 5),
        const SizedBox(height: 16),
        _buildTextField(_experienceController, 'Work Experience', Icons.business_center_outlined, maxLines: 4),
        const SizedBox(height: 16),
        _buildTextField(_certificationsController, 'Certifications', Icons.verified_user_outlined, maxLines: 3),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    bool isNumber = false,
    bool isDecimal = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isDecimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : isNumber
              ? TextInputType.number
              : TextInputType.text,
      style: robotoStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: robotoStyle(color: Colors.white38, fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF14B8A6), size: 20),
        filled: true,
        fillColor: const Color(0xFF1F2937),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF14B8A6), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      validator: validator,
    );
  }
}
