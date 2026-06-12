import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:placement_portal_frontend/utils/token_manager.dart';
import 'package:fl_chart/fl_chart.dart';

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

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _activeTab = 0; // 0 = Stats, 1 = Recruiters, 2 = Students, 3 = Announcements, 4 = Profile
  String? _errorMessage;

  // Stats
  bool _isLoadingStats = true;
  int _totalStudents = 0;
  int _totalRecruiters = 0;
  int _totalJobs = 0;
  double _placementPercentage = 0.0;
  String _highestPackage = 'N/A';
  Map<String, dynamic> _branchWisePlacements = {};

  // Recruiters
  bool _isLoadingRecruiters = true;
  List<dynamic> _recruiters = [];
  final Set<int> _updatingRecruiterIds = {};

  // Students
  bool _isLoadingStudents = true;
  List<dynamic> _students = [];

  // Announcements
  bool _isLoadingAnnouncements = true;
  bool _isSubmittingAnnouncement = false;
  List<dynamic> _announcements = [];
  final _announcementTitleController = TextEditingController();
  final _announcementDescriptionController = TextEditingController();
  String _selectedAnnouncementType = 'Hackathon';
  final List<String> _announcementTypes = ['Hackathon', 'Seminar', 'Workshop', 'Notice'];

  // Admin Profile fields
  bool _isLoadingProfile = true;
  String _adminEmail = '';
  String _adminRole = '';
  bool _adminVerified = false;

  @override
  void initState() {
    super.initState();
    _loadTabDetails();
    _fetchAnnouncements();
  }

  @override
  void dispose() {
    _announcementTitleController.dispose();
    _announcementDescriptionController.dispose();
    super.dispose();
  }

  void _loadTabDetails() {
    setState(() {
      _errorMessage = null;
    });
    if (_activeTab == 0) {
      _fetchStats();
    } else if (_activeTab == 1) {
      _fetchRecruiters();
    } else if (_activeTab == 2) {
      _fetchStudents();
    } else if (_activeTab == 3) {
      _fetchAnnouncements();
    } else if (_activeTab == 4) {
      _fetchAdminProfile();
    }
  }

  Future<void> _fetchStats() async {
    setState(() {
      _isLoadingStats = true;
    });
    final url = Uri.parse('http://localhost:8080/admin/analytics');
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
          _totalStudents = data['totalStudents'] ?? 0;
          _totalRecruiters = data['totalRecruiters'] ?? 0;
          _totalJobs = data['totalJobs'] ?? 0;
          _placementPercentage = (data['placementPercentage'] as num?)?.toDouble() ?? 0.0;
          _highestPackage = data['highestPackage'] ?? 'N/A';
          _branchWisePlacements = Map<String, dynamic>.from(data['branchWisePlacements'] ?? {});
          _isLoadingStats = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load system statistics.';
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not connect to the server.';
        _isLoadingStats = false;
      });
    }
  }

  Future<void> _fetchRecruiters() async {
    setState(() {
      _isLoadingRecruiters = true;
    });
    final url = Uri.parse('http://localhost:8080/admin/recruiters');
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
          _recruiters = data;
          _isLoadingRecruiters = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load recruiters.';
          _isLoadingRecruiters = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not connect to the server.';
        _isLoadingRecruiters = false;
      });
    }
  }

  Future<void> _toggleRecruiterVerification(int id, bool verified) async {
    setState(() {
      _updatingRecruiterIds.add(id);
    });

    final url = Uri.parse('http://localhost:8080/admin/recruiters/$id/verify?verified=$verified');
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${TokenManager.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          final index = _recruiters.indexWhere((r) => r['id'] == id);
          if (index != -1) {
            _recruiters[index]['verified'] = verified;
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Recruiter verification status updated!', style: robotoStyle()),
              backgroundColor: Colors.greenAccent[700],
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update verification status.', style: robotoStyle()),
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
        _updatingRecruiterIds.remove(id);
      });
    }
  }

  Future<void> _fetchStudents() async {
    setState(() {
      _isLoadingStudents = true;
    });
    final url = Uri.parse('http://localhost:8080/admin/students');
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
          _students = data;
          _isLoadingStudents = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load student base.';
          _isLoadingStudents = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not connect to the server.';
        _isLoadingStudents = false;
      });
    }
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
          _announcements = data;
          _isLoadingAnnouncements = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch announcements.';
          _isLoadingAnnouncements = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not connect to the server.';
        _isLoadingAnnouncements = false;
      });
    }
  }

  Future<void> _createAnnouncement() async {
    final title = _announcementTitleController.text.trim();
    final description = _announcementDescriptionController.text.trim();

    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in both title and description.', style: robotoStyle()),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _isSubmittingAnnouncement = true;
    });

    final formattedTitle = '[$_selectedAnnouncementType] $title';
    final url = Uri.parse('http://localhost:8080/announcement');
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${TokenManager.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': formattedTitle,
          'description': description,
        }),
      );

      if (response.statusCode == 201) {
        _announcementTitleController.clear();
        _announcementDescriptionController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Announcement published globally!', style: robotoStyle()),
              backgroundColor: Colors.greenAccent[700],
            ),
          );
        }
        await _fetchAnnouncements();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to publish announcement.', style: robotoStyle()),
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
        _isSubmittingAnnouncement = false;
      });
    }
  }

  Future<void> _fetchAdminProfile() async {
    setState(() {
      _isLoadingProfile = true;
      _errorMessage = null;
    });
    final url = Uri.parse('http://localhost:8080/admin/profile');
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
          _adminEmail = data['email'] ?? 'admin@bmu.edu.in';
          _adminRole = data['role'] ?? 'ADMIN';
          _adminVerified = data['isVerified'] ?? true;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load admin profile details.';
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Profile Details',
                style: robotoStyle(color: const Color(0xFF14B8A6), fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              // Email
              Text(
                'Admin Email Address',
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
                      _adminEmail,
                      style: robotoStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Role
              Text(
                'Assigned System Role',
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
                    const Icon(Icons.security_outlined, color: Color(0xFF3B82F6), size: 18),
                    const SizedBox(width: 12),
                    Text(
                      _adminRole,
                      style: robotoStyle(color: const Color(0xFF3B82F6), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Status
              Text(
                'Account Verification Status',
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
                    const Icon(Icons.verified_user_outlined, color: Color(0xFF14B8A6), size: 18),
                    const SizedBox(width: 12),
                    Text(
                      _adminVerified ? 'System Verified' : 'Unverified',
                      style: robotoStyle(color: const Color(0xFF14B8A6), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
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
            _buildSidebar(isDesktop),
            Expanded(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _buildMainContent(isDesktop),
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
                    'BMU Admin',
                    style: robotoStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 48),
          _buildSidebarItem(0, Icons.bar_chart_outlined, 'System Stats', isDesktop),
          const SizedBox(height: 12),
          _buildSidebarItem(1, Icons.business_outlined, 'Verify Recruiters', isDesktop),
          const SizedBox(height: 12),
          _buildSidebarItem(2, Icons.people_outline, 'Student Database', isDesktop),
          const SizedBox(height: 12),
          _buildSidebarItem(3, Icons.campaign_outlined, 'Announcements', isDesktop),
          const SizedBox(height: 12),
          _buildSidebarItem(4, Icons.person_outline, 'My Profile', isDesktop),
          const Spacer(),
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
            _loadTabDetails();
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

  Widget _buildNotificationBell(List<dynamic> announcements) {
    final count = announcements.length;
    return PopupMenuButton<int>(
      tooltip: 'Announcements',
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_outlined, color: Colors.white70, size: 24),
          if (count > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      offset: const Offset(0, 40),
      color: const Color(0xFF111827),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      onSelected: (val) {
        if (val == -1) {
          setState(() {
            _activeTab = 3;
          });
          _loadTabDetails();
        }
      },
      itemBuilder: (context) {
        if (announcements.isEmpty) {
          return [
            PopupMenuItem<int>(
              enabled: false,
              child: Container(
                width: 280,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.notifications_off_outlined, color: Colors.white24, size: 36),
                    const SizedBox(height: 8),
                    Text(
                      'No new announcements',
                      style: robotoStyle(color: Colors.white38, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ];
        }

        final List<PopupMenuEntry<int>> items = [];
        
        items.add(
          PopupMenuItem<int>(
            enabled: false,
            child: Container(
              width: 320,
              padding: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Announcements',
                    style: robotoStyle(color: const Color(0xFF14B8A6), fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0x2214B8A6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count New',
                      style: robotoStyle(color: const Color(0xFF14B8A6), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        final recentAnnouncements = announcements.take(5).toList();
        for (var ann in recentAnnouncements) {
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

          Color badgeColor = Colors.tealAccent.withOpacity(0.15);
          Color badgeTextColor = Colors.tealAccent;
          if (displayType == 'Hackathon') {
            badgeColor = Colors.redAccent.withOpacity(0.15);
            badgeTextColor = Colors.redAccent;
          } else if (displayType == 'Seminar') {
            badgeColor = Colors.purpleAccent.withOpacity(0.15);
            badgeTextColor = Colors.purpleAccent;
          } else if (displayType == 'Workshop') {
            badgeColor = Colors.orangeAccent.withOpacity(0.15);
            badgeTextColor = Colors.orangeAccent;
          }

          items.add(
            PopupMenuItem<int>(
              value: -1,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            displayType,
                            style: robotoStyle(color: badgeTextColor, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          dateStr,
                          style: robotoStyle(color: Colors.white24, fontSize: 10),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: robotoStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: robotoStyle(color: Colors.white60, fontSize: 11, height: 1.3),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        items.add(
          PopupMenuItem<int>(
            value: -1,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
              ),
              alignment: Alignment.center,
              child: Text(
                'View All Announcements',
                style: robotoStyle(color: const Color(0xFF3B82F6), fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );

        return items;
      },
    );
  }

  Widget _buildHeader() {
    String titleText = 'System Statistics';
    if (_activeTab == 1) titleText = 'Verify Recruiters';
    if (_activeTab == 2) titleText = 'Student Database';
    if (_activeTab == 3) titleText = 'Announcement Panel';
    if (_activeTab == 4) titleText = 'My Admin Profile';

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
            titleText,
            style: robotoStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              _buildNotificationBell(_announcements),
              const SizedBox(width: 20),
              const Icon(Icons.account_circle_outlined, color: Color(0xFF3B82F6), size: 20),
              const SizedBox(width: 8),
              Text(
                TokenManager.email ?? 'admin@bmu.edu.in',
                style: robotoStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(bool isDesktop) {
    if (_errorMessage != null) {
      return Center(
        child: Text(_errorMessage!, style: robotoStyle(color: Colors.redAccent, fontSize: 14)),
      );
    }

    if (_activeTab == 0) {
      return _buildStatsView(isDesktop);
    } else if (_activeTab == 1) {
      return _buildRecruitersView(isDesktop);
    } else if (_activeTab == 2) {
      return _buildStudentsView(isDesktop);
    } else if (_activeTab == 3) {
      return _buildAnnouncementsView(isDesktop);
    } else {
      return _buildProfileView(isDesktop);
    }
  }

  Widget _buildStatsView(bool isDesktop) {
    if (_isLoadingStats) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF14B8A6)));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Portal Database Analytics',
            style: robotoStyle(color: const Color(0xFF14B8A6), fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          isDesktop
              ? Row(
                  children: [
                    Expanded(child: _buildStatCard('Total Students', _totalStudents.toString(), Icons.school, const Color(0xFF3B82F6))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard('Recruiters Registered', _totalRecruiters.toString(), Icons.business, const Color(0xFF14B8A6))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard('Opportunities Posted', _totalJobs.toString(), Icons.work, Colors.orangeAccent)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildStatCard('Placement Rate', '${_placementPercentage.toStringAsFixed(1)}%', Icons.analytics_outlined, Colors.purpleAccent)),
                  ],
                )
              : Column(
                  children: [
                    _buildStatCard('Total Students', _totalStudents.toString(), Icons.school, const Color(0xFF3B82F6)),
                    const SizedBox(height: 16),
                    _buildStatCard('Recruiters Registered', _totalRecruiters.toString(), Icons.business, const Color(0xFF14B8A6)),
                    const SizedBox(height: 16),
                    _buildStatCard('Opportunities Posted', _totalJobs.toString(), Icons.work, Colors.orangeAccent),
                    const SizedBox(height: 16),
                    _buildStatCard('Placement Rate', '${_placementPercentage.toStringAsFixed(1)}%', Icons.analytics_outlined, Colors.purpleAccent),
                  ],
                ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.04)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_outline, color: Colors.yellowAccent, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Highest Package Placed',
                      style: robotoStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  _highestPackage,
                  style: robotoStyle(color: const Color(0xFF14B8A6), fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: _buildPieChartCard()),
                    const SizedBox(width: 24),
                    Expanded(flex: 5, child: _buildBarChartCard()),
                  ],
                )
              : Column(
                  children: [
                    _buildPieChartCard(),
                    const SizedBox(height: 24),
                    _buildBarChartCard(),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: robotoStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  count,
                  style: robotoStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartCard() {
    return Container(
      height: 380,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Placement Distribution Ratio',
            style: robotoStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Ratio of placed vs unplaced students in the portal database.',
            style: robotoStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _buildPieChart(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: const Color(0xFF14B8A6), borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 8),
              Text('Placed', style: robotoStyle(color: Colors.white70, fontSize: 11)),
              const SizedBox(width: 24),
              Container(width: 12, height: 12, decoration: BoxDecoration(color: const Color(0xFF374151), borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 8),
              Text('Unplaced', style: robotoStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    final double placed = _placementPercentage;
    final double unplaced = 100.0 - placed;

    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            sectionsSpace: 4,
            centerSpaceRadius: 65,
            startDegreeOffset: -90,
            sections: [
              PieChartSectionData(
                color: const Color(0xFF14B8A6),
                value: placed > 0 ? placed : 0.001,
                title: placed > 0 ? '${placed.toStringAsFixed(1)}%' : '',
                radius: 24,
                titleStyle: robotoStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
              PieChartSectionData(
                color: const Color(0xFF374151),
                value: unplaced > 0 ? unplaced : 0.001,
                title: unplaced > 0 ? '${unplaced.toStringAsFixed(1)}%' : '',
                radius: 20,
                titleStyle: robotoStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${placed.toStringAsFixed(1)}%',
              style: robotoStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              'Placement Rate',
              style: robotoStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildBarChartCard() {
    return Container(
      height: 380,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Branch-wise Student Placements',
            style: robotoStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Number of placed students across different academic branches.',
            style: robotoStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _buildBarChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    if (_branchWisePlacements.isEmpty) {
      return Center(
        child: Text(
          'No branch placement data available.',
          style: robotoStyle(color: Colors.white24, fontSize: 13),
        ),
      );
    }

    final List<MapEntry<String, dynamic>> entries = _branchWisePlacements.entries.toList();
    
    double maxVal = 5.0;
    for (var entry in entries) {
      final val = (entry.value as num).toDouble();
      if (val > maxVal) {
        maxVal = val;
      }
    }
    maxVal = (maxVal + 2).ceilToDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => const Color(0xFF1F2937),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final branchName = entries[group.x.toInt()].key;
              return BarTooltipItem(
                '$branchName\n',
                robotoStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                children: <TextSpan>[
                  TextSpan(
                    text: '${rod.toY.toInt()} Placed',
                    style: robotoStyle(color: const Color(0xFF14B8A6), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final int idx = value.toInt();
                if (idx >= 0 && idx < entries.length) {
                  final String rawName = entries[idx].key;
                  String shortName = rawName;
                  if (rawName.toLowerCase().contains('computer science')) shortName = 'CSE';
                  else if (rawName.toLowerCase().contains('electronics')) shortName = 'ECE';
                  else if (rawName.toLowerCase().contains('mechanical')) shortName = 'ME';
                  else if (rawName.toLowerCase().contains('civil')) shortName = 'CE';
                  else if (rawName.length > 8) shortName = '${rawName.substring(0, 6)}...';

                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: Text(
                      shortName,
                      style: robotoStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 30,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8,
                  child: Text(
                    value.toInt().toString(),
                    style: robotoStyle(color: Colors.white38, fontSize: 10),
                  ),
                );
              },
              reservedSize: 28,
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.white.withOpacity(0.05),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(entries.length, (index) {
          final val = (entries[index].value as num).toDouble();
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: val,
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF14B8A6)],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(5),
                  topRight: Radius.circular(5),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxVal,
                  color: Colors.white.withOpacity(0.02),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildRecruitersView(bool isDesktop) {
    if (_isLoadingRecruiters) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF14B8A6)));
    }

    if (_recruiters.isEmpty) {
      return Center(
        child: Text('No recruiters registered in the system.', style: robotoStyle(color: Colors.white38)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _recruiters.length,
      itemBuilder: (context, index) {
        final recruiter = _recruiters[index];
        final int recId = recruiter['id'];
        final isVerified = recruiter['verified'] ?? false;
        final isUpdating = _updatingRecruiterIds.contains(recId);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recruiter['companyName'] ?? 'Company Name',
                      style: robotoStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recruiter['email'] ?? 'Email Not Specified',
                      style: robotoStyle(color: Colors.white38, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      recruiter['website'] ?? 'Website Not Specified',
                      style: robotoStyle(color: const Color(0xFF3B82F6), fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isVerified ? 'Verified' : 'Pending',
                    style: robotoStyle(
                      color: isVerified ? const Color(0xFF14B8A6) : Colors.orangeAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  isUpdating
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF14B8A6)),
                        )
                      : Switch(
                          value: isVerified,
                          activeColor: const Color(0xFF14B8A6),
                          inactiveThumbColor: Colors.white24,
                          inactiveTrackColor: Colors.white12,
                          onChanged: (val) => _toggleRecruiterVerification(recId, val),
                        ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStudentsView(bool isDesktop) {
    if (_isLoadingStudents) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF14B8A6)));
    }

    if (_students.isEmpty) {
      return Center(
        child: Text('No students registered in the database.', style: robotoStyle(color: Colors.white38)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];
        final name = student['name'] ?? 'Student';
        final email = student['email'] ?? 'N/A';
        final branch = student['branch'] ?? 'Not Specified';
        final semester = student['semester'] != null ? '${student['semester']} Sem' : 'N/A';
        final cgpa = student['cgpa'] != null ? '${student['cgpa']} CGPA' : 'N/A';
        final skills = student['skills'] ?? 'None';
        final resumeUrl = student['resumeUrl'] ?? '';

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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: robotoStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: robotoStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0x1114B8A6),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF14B8A6).withOpacity(0.3)),
                    ),
                    child: Text(
                      cgpa,
                      style: robotoStyle(color: const Color(0xFF14B8A6), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$branch | Semester $semester',
                    style: robotoStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                  resumeUrl.isNotEmpty
                      ? InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Opening resume URL: $resumeUrl', style: robotoStyle()),
                                backgroundColor: const Color(0xFF14B8A6),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.picture_as_pdf_outlined, color: Color(0xFF3B82F6), size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'Resume',
                                style: robotoStyle(color: const Color(0xFF3B82F6), fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        )
                      : Text('No Resume', style: robotoStyle(color: Colors.white24, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Skills: $skills',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: robotoStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnnouncementsView(bool isDesktop) {
    return isDesktop
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildAnnouncementList()),
              Container(width: 1, height: double.infinity, color: Colors.white10),
              Expanded(flex: 3, child: _buildAnnouncementForm()),
            ],
          )
        : Column(
            children: [
              _buildAnnouncementForm(),
              const Divider(color: Colors.white10, height: 32),
              Expanded(child: _buildAnnouncementList()),
            ],
          );
  }

  Widget _buildAnnouncementForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Publish Global Announcement',
              style: robotoStyle(color: const Color(0xFF14B8A6), fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _announcementTitleController,
              style: robotoStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Announcement Title',
                labelStyle: robotoStyle(color: Colors.white38, fontSize: 13),
                prefixIcon: const Icon(Icons.campaign_outlined, color: Color(0xFF14B8A6), size: 18),
                filled: true,
                fillColor: const Color(0xFF1F2937),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF14B8A6), width: 1.5)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _announcementDescriptionController,
              maxLines: 4,
              style: robotoStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Details / Description',
                labelStyle: robotoStyle(color: Colors.white38, fontSize: 13),
                prefixIcon: const Icon(Icons.description_outlined, color: Color(0xFF14B8A6), size: 18),
                filled: true,
                fillColor: const Color(0xFF1F2937),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF14B8A6), width: 1.5)),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButtonFormField<String>(
                  value: _selectedAnnouncementType,
                  dropdownColor: const Color(0xFF1F2937),
                  style: robotoStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    labelStyle: robotoStyle(color: Colors.white38),
                    labelText: 'Announcement Type',
                  ),
                  items: _announcementTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedAnnouncementType = val;
                      });
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmittingAnnouncement ? null : _createAnnouncement,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14B8A6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSubmittingAnnouncement
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Publish Announcement',
                        style: robotoStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementList() {
    if (_isLoadingAnnouncements) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF14B8A6)));
    }

    if (_announcements.isEmpty) {
      return Center(
        child: Text('No announcements posted yet.', style: robotoStyle(color: Colors.white38)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _announcements.length,
      itemBuilder: (context, index) {
        final ann = _announcements[index];
        final title = ann['title'] ?? 'Global Announcement';
        final description = ann['description'] ?? '';
        final dateStr = ann['date'] != null ? ann['date'].toString().substring(0, 10) : '';

        // Extract bracketed type from title e.g. [Hackathon] Google Challenge
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
}
