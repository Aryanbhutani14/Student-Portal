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

class RecruiterDashboardScreen extends StatefulWidget {
  const RecruiterDashboardScreen({super.key});

  @override
  State<RecruiterDashboardScreen> createState() => _RecruiterDashboardScreenState();
}

class _RecruiterDashboardScreenState extends State<RecruiterDashboardScreen> {
  int _activeTab = 0; // 0 = My Postings, 1 = Post Job, 2 = Applications, 3 = Announcements, 4 = Profile
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  List<dynamic> _recruiterJobs = [];

  List<dynamic> _applications = [];
  bool _isLoadingApplications = false;
  final Set<int> _updatingStatusIds = {};

  List<dynamic> _announcementsList = [];
  bool _isLoadingAnnouncements = false;

  // Post Job Form fields
  final _formKey = GlobalKey<FormState>();
  final _roleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _salaryController = TextEditingController();
  final _skillsController = TextEditingController();
  DateTime? _selectedDeadline;
  String _selectedType = 'Full-Time';

  final List<String> _jobTypes = ['Internship', 'Full-Time', 'Hackathon', 'Training'];

  // Recruiter Profile fields
  bool _isLoadingProfile = true;
  bool _isSavingProfile = false;
  bool _isEditProfileMode = false;
  final _companyNameController = TextEditingController();
  final _websiteController = TextEditingController();
  String _recruiterEmail = '';
  bool _recruiterVerified = false;
  final _profileFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fetchRecruiterJobs();
  }

  @override
  void dispose() {
    _roleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _salaryController.dispose();
    _skillsController.dispose();
    _companyNameController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _fetchAnnouncements() async {
    setState(() {
      _isLoadingAnnouncements = true;
    });
    final url = Uri.parse('http://localhost:8080/announcements');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${TokenManager.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _announcementsList = data;
        });
      }
    } catch (e) {
      print('Error loading announcements: $e');
    } finally {
      setState(() {
        _isLoadingAnnouncements = false;
      });
    }
  }

  Widget _buildAnnouncementsView(bool isDesktop) {
    if (_isLoadingAnnouncements) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF14B8A6)));
    }

    if (_announcementsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.campaign_outlined, size: 60, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              'No announcements posted yet.',
              style: robotoStyle(color: Colors.white38, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _announcementsList.length,
      itemBuilder: (context, index) {
        final ann = _announcementsList[index];
        final title = ann['title'] ?? 'Global Announcement';
        final description = ann['description'] ?? '';
        final dateStr = ann['date'] != null ? ann['date'].toString().substring(0, 10) : '';

        String displayType = 'Notice';
        String displayTitle = title;
        if (title.toString().startsWith('[')) {
          final closeIndex = title.toString().indexOf(']');
          if (closeIndex != -1) {
            displayType = title.toString().substring(1, closeIndex);
            displayTitle = title.toString().substring(closeIndex + 1).trim();
          }
        }

        Color badgeColor = Colors.white24;
        if (displayType == 'Hackathon') badgeColor = Colors.redAccent.withOpacity(0.2);
        if (displayType == 'Seminar') badgeColor = Colors.purpleAccent.withOpacity(0.2);
        if (displayType == 'Workshop') badgeColor = Colors.orangeAccent.withOpacity(0.2);
        if (displayType == 'Notice') badgeColor = Colors.tealAccent.withOpacity(0.2);

        Color badgeTextColor = Colors.white;
        if (displayType == 'Hackathon') badgeTextColor = Colors.redAccent;
        if (displayType == 'Seminar') badgeTextColor = Colors.purpleAccent;
        if (displayType == 'Workshop') badgeTextColor = Colors.orangeAccent;
        if (displayType == 'Notice') badgeTextColor = Colors.tealAccent;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      displayType,
                      style: robotoStyle(color: badgeTextColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    dateStr,
                    style: robotoStyle(color: Colors.white24, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                displayTitle,
                style: robotoStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: robotoStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _fetchApplications() async {
    setState(() {
      _isLoadingApplications = true;
      _errorMessage = null;
    });

    final url = Uri.parse('http://localhost:8080/recruiter/applications');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${TokenManager.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _applications = data;
          _isLoadingApplications = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch candidate applications.';
          _isLoadingApplications = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not connect to the server.';
        _isLoadingApplications = false;
      });
    }
  }

  Future<void> _updateApplicationStatus(int applicationId, String newStatus) async {
    setState(() {
      _updatingStatusIds.add(applicationId);
    });

    final url = Uri.parse('http://localhost:8080/application/status');
    try {
      final response = await http.patch(
        url,
        headers: {
          'Authorization': 'Bearer ${TokenManager.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'applicationId': applicationId,
          'status': newStatus,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          final index = _applications.indexWhere((app) => app['id'] == applicationId);
          if (index != -1) {
            _applications[index]['status'] = newStatus;
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Status updated to $newStatus successfully!', style: robotoStyle()),
              backgroundColor: Colors.greenAccent[700],
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else {
        final errorMsg = response.body;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg.isNotEmpty ? errorMsg : 'Failed to update status.', style: robotoStyle()),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error communicating with the server.', style: robotoStyle()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() {
        _updatingStatusIds.remove(applicationId);
      });
    }
  }

  Widget _buildApplicationsView(bool isDesktop) {
    if (_isLoadingApplications) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF14B8A6)));
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!, style: robotoStyle(color: Colors.redAccent)));
    }

    if (_applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 60, color: Colors.white24),
            const SizedBox(height: 16),
            Text('No candidate applications received yet.', style: robotoStyle(color: Colors.white38, fontSize: 15)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 2 : 1,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        mainAxisExtent: 310,
      ),
      itemCount: _applications.length,
      itemBuilder: (context, index) {
        final app = _applications[index];
        final int appId = app['id'];
        final currentStatus = app['status'] ?? 'APPLIED';
        final isUpdating = _updatingStatusIds.contains(appId);
        
        final studentName = app['studentName'] ?? 'Student';
        final studentEmail = app['studentEmail'] ?? 'N/A';
        final studentBranch = app['studentBranch'] ?? 'N/A';
        final studentSemester = app['studentSemester'] != null ? '${app['studentSemester']} Sem' : 'N/A';
        final studentCgpa = app['studentCgpa'] != null ? '${app['studentCgpa']} CGPA' : 'N/A';
        final studentSkills = app['studentSkills'] ?? '';
        final resumeUrl = app['studentResumeUrl'] ?? '';
        
        final role = app['role'] ?? 'Opportunity';
        final type = app['type'] ?? 'Full-Time';

        Color statusColor = const Color(0xFF3B82F6);
        if (currentStatus == 'SELECTED') statusColor = Colors.greenAccent[700]!;
        if (currentStatus == 'REJECTED') statusColor = Colors.redAccent;
        if (currentStatus == 'SHORTLISTED') statusColor = Colors.tealAccent[700]!;
        if (currentStatus == 'INTERVIEW') statusColor = Colors.orangeAccent;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          studentName,
                          style: robotoStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          studentEmail,
                          style: robotoStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      currentStatus,
                      style: robotoStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Applied Position',
                          style: robotoStyle(color: const Color(0xFF14B8A6), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$role ($type)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: robotoStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Academic Info',
                        style: robotoStyle(color: const Color(0xFF14B8A6), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$studentBranch | $studentSemester | $studentCgpa',
                        style: robotoStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Skills',
                style: robotoStyle(color: const Color(0xFF14B8A6), fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                studentSkills.isNotEmpty ? studentSkills : 'None specified',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: robotoStyle(color: Colors.white70, fontSize: 13),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  resumeUrl.isNotEmpty
                      ? OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Opening resume URL: $resumeUrl', style: robotoStyle()),
                                backgroundColor: const Color(0xFF14B8A6),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF3B82F6),
                            side: const BorderSide(color: Color(0x333B82F6)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.picture_as_pdf_outlined, size: 14),
                          label: Text('Resume', style: robotoStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        )
                      : Text('No Resume Uploaded', style: robotoStyle(color: Colors.white24, fontSize: 12)),
                  isUpdating
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF14B8A6)),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1F2937),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: currentStatus,
                              dropdownColor: const Color(0xFF1F2937),
                              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF14B8A6), size: 18),
                              style: robotoStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                              items: const [
                                DropdownMenuItem(value: 'APPLIED', child: Text('Applied')),
                                DropdownMenuItem(value: 'UNDER_REVIEW', child: Text('Under Review')),
                                DropdownMenuItem(value: 'SHORTLISTED', child: Text('Shortlisted')),
                                DropdownMenuItem(value: 'INTERVIEW', child: Text('Interview')),
                                DropdownMenuItem(value: 'SELECTED', child: Text('Selected')),
                                DropdownMenuItem(value: 'REJECTED', child: Text('Rejected')),
                              ],
                              onChanged: (newStatus) {
                                if (newStatus != null && newStatus != currentStatus) {
                                  _updateApplicationStatus(appId, newStatus);
                                }
                              },
                            ),
                          ),
                        ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _fetchRecruiterJobs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final url = Uri.parse('http://localhost:8080/jobs/recruiter');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${TokenManager.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _recruiterJobs = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch job postings.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not connect to the server.';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitJob() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDeadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an application deadline.', style: robotoStyle()),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final url = Uri.parse('http://localhost:8080/jobs/create');
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${TokenManager.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'role': _roleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'location': _locationController.text.trim(),
          'salary': _salaryController.text.trim(),
          'skillsRequired': _skillsController.text.trim(),
          'deadline': _selectedDeadline!.toIso8601String(),
          'type': _selectedType,
        }),
      );

      if (response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Opportunity posted successfully!', style: robotoStyle()),
              backgroundColor: Colors.greenAccent[700],
            ),
          );
        }
        _clearForm();
        setState(() {
          _activeTab = 0; // Redirect to postings
        });
        await _fetchRecruiterJobs();
      } else {
        final errorMsg = response.body;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg.isNotEmpty ? errorMsg : 'Failed to post opportunity.', style: robotoStyle()),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error communicating with the server.', style: robotoStyle()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _clearForm() {
    _roleController.clear();
    _descriptionController.clear();
    _locationController.clear();
    _salaryController.clear();
    _skillsController.clear();
    _selectedDeadline = null;
    _selectedType = 'Full-Time';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF14B8A6),
              onPrimary: Colors.white,
              surface: Color(0xFF111827),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDeadline = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      });
    }
  }

  Future<void> _fetchRecruiterProfile() async {
    setState(() {
      _isLoadingProfile = true;
      _errorMessage = null;
    });
    final url = Uri.parse('http://localhost:8080/recruiter/profile');
    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer ${TokenManager.token}',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _recruiterEmail = data['email'] ?? '';
          _companyNameController.text = data['companyName'] ?? '';
          _websiteController.text = data['website'] ?? '';
          _recruiterVerified = data['verified'] ?? false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load profile details.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error communicating with the server.';
      });
    } finally {
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _saveRecruiterProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;

    setState(() {
      _isSavingProfile = true;
    });
    final url = Uri.parse('http://localhost:8080/recruiter/profile');
    try {
      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer ${TokenManager.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'companyName': _companyNameController.text.trim(),
          'website': _websiteController.text.trim(),
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _companyNameController.text = data['companyName'] ?? '';
          _websiteController.text = data['website'] ?? '';
          _isEditProfileMode = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profile updated successfully!', style: robotoStyle()),
              backgroundColor: Colors.greenAccent[700],
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update profile.', style: robotoStyle()),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error communicating with the server.', style: robotoStyle()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() {
        _isSavingProfile = false;
      });
    }
  }

  Widget _buildProfileView(bool isDesktop) {
    if (_isLoadingProfile) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF14B8A6)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Form(
            key: _profileFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Profile Information',
                      style: robotoStyle(color: const Color(0xFF14B8A6), fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: Icon(
                        _isEditProfileMode ? Icons.close : Icons.edit,
                        color: const Color(0xFF14B8A6),
                      ),
                      onPressed: () {
                        setState(() {
                          _isEditProfileMode = !_isEditProfileMode;
                          if (!_isEditProfileMode) {
                            _fetchRecruiterProfile(); // reset fields
                          }
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Email
                Text(
                  'Email Address',
                  style: robotoStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2937).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.02)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.email_outlined, color: Colors.white38, size: 18),
                      const SizedBox(width: 12),
                      Text(
                        _recruiterEmail,
                        style: robotoStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Verification Status
                Text(
                  'Verification Status',
                  style: robotoStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2937).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.02)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _recruiterVerified ? Icons.verified : Icons.hourglass_empty,
                        color: _recruiterVerified ? const Color(0xFF14B8A6) : Colors.orangeAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _recruiterVerified ? 'Verified Recruiter' : 'Verification Pending',
                        style: robotoStyle(
                          color: _recruiterVerified ? const Color(0xFF14B8A6) : Colors.orangeAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Company Name
                Text(
                  'Company Name',
                  style: robotoStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _companyNameController,
                  enabled: _isEditProfileMode,
                  style: robotoStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.business_outlined, color: Color(0xFF14B8A6), size: 18),
                    filled: true,
                    fillColor: _isEditProfileMode ? const Color(0xFF1F2937) : const Color(0xFF1F2937).withOpacity(0.5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF14B8A6), width: 1.5),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Company name is required';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                // Website
                Text(
                  'Company Website',
                  style: robotoStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _websiteController,
                  enabled: _isEditProfileMode,
                  style: robotoStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.language_outlined, color: Color(0xFF14B8A6), size: 18),
                    filled: true,
                    fillColor: _isEditProfileMode ? const Color(0xFF1F2937) : const Color(0xFF1F2937).withOpacity(0.5),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF14B8A6), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (_isEditProfileMode)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSavingProfile ? null : _saveRecruiterProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF14B8A6),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isSavingProfile
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text('Save Profile Details', style: robotoStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0A0E17),
              Color(0xFF0F172A),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            // Sidebar Navigation (for desktop) / Left bar
            _buildSidebar(isDesktop),
            // Main Content Area
            Expanded(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _activeTab == 0
                        ? _buildPostingsView(isDesktop)
                        : _activeTab == 1
                            ? _buildPostJobForm()
                            : _activeTab == 2
                                ? _buildApplicationsView(isDesktop)
                                : _activeTab == 3
                                    ? _buildAnnouncementsView(isDesktop)
                                    : _buildProfileView(isDesktop),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(bool isDesktop) {
    return Container(
      width: isDesktop ? 240 : 80,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          // App Logo/Name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: isDesktop ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset(
                    'assets/images/bmu_logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                if (isDesktop) ...[
                  const SizedBox(width: 12),
                  Text(
                    'BMU Recruiter',
                    style: robotoStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 48),
          _buildSidebarItem(0, Icons.list_alt, 'My Postings', isDesktop),
          const SizedBox(height: 12),
          _buildSidebarItem(1, Icons.post_add_outlined, 'Post Opportunity', isDesktop),
          const SizedBox(height: 12),
          _buildSidebarItem(2, Icons.people_outline, 'Applications', isDesktop),
          const SizedBox(height: 12),
          _buildSidebarItem(3, Icons.campaign_outlined, 'Announcements', isDesktop),
          const SizedBox(height: 12),
          _buildSidebarItem(4, Icons.person_outline, 'My Profile', isDesktop),
          const Spacer(),
          // Logout button
          _buildSidebarItem(-1, Icons.logout_outlined, 'Sign Out', isDesktop),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String title, bool isDesktop) {
    final isSelected = _activeTab == index;
    final isLogout = index == -1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: InkWell(
        onTap: () {
          if (isLogout) {
            TokenManager.token = null;
            TokenManager.email = null;
            TokenManager.role = null;
            Navigator.pushReplacementNamed(context, '/login');
          } else {
            setState(() {
              _activeTab = index;
            });
            if (index == 0) {
              _fetchRecruiterJobs();
            } else if (index == 2) {
              _fetchApplications();
            } else if (index == 3) {
              _fetchAnnouncements();
            } else if (index == 4) {
              _fetchRecruiterProfile();
            }
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF14B8A6).withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF14B8A6).withOpacity(0.3) : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: isDesktop ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected 
                    ? const Color(0xFF14B8A6) 
                    : isLogout 
                        ? Colors.redAccent 
                        : Colors.white60,
                size: 20,
              ),
              if (isDesktop) ...[
                const SizedBox(width: 12),
                Text(
                  title,
                  style: robotoStyle(
                    color: isSelected 
                        ? Colors.white 
                        : isLogout 
                            ? Colors.redAccent 
                            : Colors.white70,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0x11FFFFFF),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _activeTab == 0
                ? 'My Posted Opportunities'
                : _activeTab == 1
                    ? 'Create New Opportunity'
                    : _activeTab == 2
                        ? 'Candidate Applications'
                        : _activeTab == 3
                            ? 'Global Announcements'
                            : 'My Recruiter Profile',
            style: robotoStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              const Icon(Icons.account_circle_outlined, color: Color(0xFF3B82F6), size: 20),
              const SizedBox(width: 8),
              Text(
                TokenManager.email ?? '',
                style: robotoStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostingsView(bool isDesktop) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF14B8A6)));
    }

    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!, style: robotoStyle(color: Colors.redAccent)));
    }

    if (_recruiterJobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.business_center_outlined, size: 60, color: Colors.white24),
            const SizedBox(height: 16),
            Text('You haven\'t posted any opportunities yet.', style: robotoStyle(color: Colors.white38, fontSize: 15)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _activeTab = 1;
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF14B8A6), foregroundColor: Colors.white),
              child: Text('Create Listing', style: robotoStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 3 : 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 220,
      ),
      itemCount: _recruiterJobs.length,
      itemBuilder: (context, index) {
        final job = _recruiterJobs[index];
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      job['role'] ?? 'Opportunity',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: robotoStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0x2214B8A6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      job['type'] ?? 'Full-Time',
                      style: robotoStyle(color: const Color(0xFF14B8A6), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 14, color: Colors.white38),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      job['location'] ?? 'Not Specified',
                      style: robotoStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.payments_outlined, size: 14, color: Colors.white38),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      job['salary'] ?? 'Not Specified',
                      style: robotoStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.psychology_outlined, size: 14, color: Colors.white38),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Skills: ${job['skillsRequired'] ?? "None"}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: robotoStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    job['deadline'] != null 
                        ? 'Deadline: ${job['deadline'].toString().substring(0, 10)}' 
                        : 'Deadline: N/A',
                    style: robotoStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPostJobForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Opportunity Parameters',
                style: robotoStyle(color: const Color(0xFF14B8A6), fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildFormTextField(_roleController, 'Role Name / Job Title', Icons.work_outline, validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter the role name';
                return null;
              }),
              const SizedBox(height: 16),
              _buildFormTextField(_descriptionController, 'Detailed Job Description', Icons.description_outlined, maxLines: 5, validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter a description';
                return null;
              }),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildFormTextField(_locationController, 'Location (e.g. Delhi, Remote)', Icons.place_outlined, validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter location';
                      return null;
                    }),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildFormTextField(_salaryController, 'Salary (e.g. 12 LPA, 25k/mo)', Icons.payments_outlined, validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter salary package';
                      return null;
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildFormTextField(_skillsController, 'Skills Required (comma-separated)', Icons.psychology_outlined, validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter required skills';
                return null;
              }),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F2937),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined, color: Color(0xFF14B8A6), size: 20),
                            const SizedBox(width: 12),
                            Text(
                              _selectedDeadline == null
                                  ? 'Select Deadline'
                                  : 'Deadline: ${_selectedDeadline!.toString().substring(0, 10)}',
                              style: robotoStyle(
                                color: _selectedDeadline == null ? Colors.white38 : Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F2937),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<String>(
                          value: _selectedType,
                          dropdownColor: const Color(0xFF1F2937),
                          style: robotoStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            labelStyle: robotoStyle(color: Colors.white38),
                            labelText: 'Opportunity Type',
                          ),
                          items: _jobTypes.map((type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedType = val;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitJob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF14B8A6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Post Opportunity', style: robotoStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
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
