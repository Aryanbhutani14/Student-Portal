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

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _allJobs = [];
  List<dynamic> _recommendedJobs = [];
  Set<int> _appliedJobIds = {};

  int _activeTab = 0; // 0 = Explore, 1 = Bookmarks, 2 = Applications, 3 = Announcements
  List<dynamic> _appliedJobsList = [];
  bool _isLoadingApplications = false;

  List<dynamic> _savedJobsList = [];
  Set<int> _savedJobIds = {};
  bool _isLoadingSavedJobs = false;

  List<dynamic> _announcementsList = [];
  bool _isLoadingAnnouncements = false;

  // Profile info for recommendation matching
  String _studentSkills = "";

  // Search/Filter fields
  final _skillController = TextEditingController();
  final _locationController = TextEditingController();
  String _selectedType = 'All';

  final List<String> _jobTypes = ['All', 'Internship', 'Full-Time', 'Hackathon', 'Training'];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _skillController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Fetch Student Profile to get skills
      final profileUrl = Uri.parse('http://localhost:8080/student/profile');
      final profileResponse = await http.get(
        profileUrl,
        headers: {
          'Authorization': 'Bearer ${TokenManager.token}',
          'Content-Type': 'application/json',
        },
      );

      if (profileResponse.statusCode == 200) {
        final profileData = jsonDecode(profileResponse.body);
        _studentSkills = profileData['skills'] ?? "";
      }

      // 2. Fetch Applications to build _appliedJobIds
      await _fetchAppliedJobsOnStartup();

      // 3. Fetch Saved Jobs to build _savedJobIds
      await _fetchSavedJobsOnStartup();

      // 4. Fetch Jobs
      await _fetchJobs();
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not load data. Ensure the backend is running.';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchAppliedJobs() async {
    setState(() {
      _isLoadingApplications = true;
    });
    final url = Uri.parse('http://localhost:8080/student/applications');
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
          _appliedJobsList = data;
          _appliedJobIds = data.map<int>((app) => app['jobId'] as int).toSet();
        });
      }
    } catch (e) {
      print('Error loading applications: $e');
    } finally {
      setState(() {
        _isLoadingApplications = false;
      });
    }
  }

  Future<void> _fetchAppliedJobsOnStartup() async {
    final url = Uri.parse('http://localhost:8080/student/applications');
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
        _appliedJobsList = data;
        _appliedJobIds = data.map<int>((app) => app['jobId'] as int).toSet();
      }
    } catch (e) {
      print('Error loading applications on startup: $e');
    }
  }

  Future<void> _fetchSavedJobs() async {
    setState(() {
      _isLoadingSavedJobs = true;
    });
    final url = Uri.parse('http://localhost:8080/saved-jobs');
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
          _savedJobsList = data;
          _savedJobIds = data.map<int>((job) => job['id'] as int).toSet();
        });
      }
    } catch (e) {
      print('Error loading saved jobs: $e');
    } finally {
      setState(() {
        _isLoadingSavedJobs = false;
      });
    }
  }

  Future<void> _fetchSavedJobsOnStartup() async {
    final url = Uri.parse('http://localhost:8080/saved-jobs');
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
        _savedJobsList = data;
        _savedJobIds = data.map<int>((job) => job['id'] as int).toSet();
      }
    } catch (e) {
      print('Error loading saved jobs on startup: $e');
    }
  }

  Future<void> _toggleSavedJob(int jobId) async {
    final url = Uri.parse('http://localhost:8080/save-job');
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${TokenManager.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'jobId': jobId}),
      );

      if (response.statusCode == 200) {
        final msg = response.body;
        setState(() {
          if (_savedJobIds.contains(jobId)) {
            _savedJobIds.remove(jobId);
            _savedJobsList.removeWhere((job) => job['id'] == jobId);
          } else {
            _savedJobIds.add(jobId);
            final matchedJob = _allJobs.firstWhere((j) => j['id'] == jobId, orElse: () => null);
            if (matchedJob != null) {
              _savedJobsList.add(matchedJob);
            }
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg.isNotEmpty ? msg : 'Bookmark updated.', style: robotoStyle()),
              backgroundColor: const Color(0xFF14B8A6),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update bookmark.', style: robotoStyle()),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not connect to update bookmark.', style: robotoStyle()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildStatusTimeline(String currentStatus) {
    final steps = ['APPLIED', 'UNDER_REVIEW', 'SHORTLISTED', 'INTERVIEW', 'OUTCOME'];
    final labels = ['Applied', 'Review', 'Shortlist', 'Interview', 'Outcome'];
    
    int activeIndex = 0;
    bool isRejected = currentStatus == 'REJECTED';
    bool isSelected = currentStatus == 'SELECTED';
    
    if (currentStatus == 'APPLIED') {
      activeIndex = 0;
    } else if (currentStatus == 'UNDER_REVIEW') {
      activeIndex = 1;
    } else if (currentStatus == 'SHORTLISTED') {
      activeIndex = 2;
    } else if (currentStatus == 'INTERVIEW') {
      activeIndex = 3;
    } else if (isSelected || isRejected) {
      activeIndex = 4;
    }

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          final lineIndex = index ~/ 2;
          final isCompleted = lineIndex < activeIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: isCompleted
                  ? (isRejected && lineIndex == 3 ? Colors.redAccent : const Color(0xFF14B8A6))
                  : Colors.white12,
            ),
          );
        } else {
          final stepIndex = index ~/ 2;
          final isCompleted = stepIndex <= activeIndex;
          final isCurrent = stepIndex == activeIndex;
          
          Color nodeColor = Colors.white12;
          if (isCompleted) {
            if (stepIndex == 4) {
              nodeColor = isRejected ? Colors.redAccent : Colors.greenAccent[700]!;
            } else {
              nodeColor = const Color(0xFF14B8A6);
            }
          }

          String displayLabel = labels[stepIndex];
          if (stepIndex == 4) {
            if (isSelected) displayLabel = 'Selected';
            else if (isRejected) displayLabel = 'Rejected';
            else displayLabel = 'Outcome';
          }

          IconData? icon;
          if (stepIndex == 0) icon = Icons.send_outlined;
          else if (stepIndex == 1) icon = Icons.rate_review_outlined;
          else if (stepIndex == 2) icon = Icons.list_alt_outlined;
          else if (stepIndex == 3) icon = Icons.question_answer_outlined;
          else if (stepIndex == 4) {
            if (isRejected) icon = Icons.cancel_outlined;
            else if (isSelected) icon = Icons.check_circle_outline;
            else icon = Icons.emoji_events_outlined;
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isCurrent ? 28 : 22,
                height: isCurrent ? 28 : 22,
                decoration: BoxDecoration(
                  color: nodeColor.withOpacity(isCurrent ? 0.2 : 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: nodeColor,
                    width: isCurrent ? 2 : 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    icon,
                    size: isCurrent ? 14 : 11,
                    color: isCompleted ? nodeColor : Colors.white38,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                displayLabel,
                style: robotoStyle(
                  color: isCurrent 
                      ? Colors.white 
                      : isCompleted 
                          ? Colors.white70 
                          : Colors.white30,
                  fontSize: 9,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          );
        }
      }),
    );
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

  Future<void> _fetchJobs() async {
    // Build query params
    String query = "";
    List<String> params = [];
    if (_skillController.text.trim().isNotEmpty) {
      params.add("skill=${Uri.encodeComponent(_skillController.text.trim())}");
    }
    if (_locationController.text.trim().isNotEmpty) {
      params.add("location=${Uri.encodeComponent(_locationController.text.trim())}");
    }
    if (_selectedType != 'All') {
      params.add("type=${Uri.encodeComponent(_selectedType)}");
    }

    if (params.isNotEmpty) {
      query = "?${params.join('&')}";
    }

    final url = Uri.parse('http://localhost:8080/jobs$query');
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
          _allJobs = data;
          _computeRecommendations();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load jobs.';
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

  void _computeRecommendations() {
    if (_studentSkills.trim().isEmpty) {
      _recommendedJobs = [];
      return;
    }

    final skillsList = _studentSkills
        .toLowerCase()
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (skillsList.isEmpty) {
      _recommendedJobs = [];
      return;
    }

    _recommendedJobs = _allJobs.where((job) {
      final requiredSkills = (job['skillsRequired'] ?? "").toString().toLowerCase();
      return skillsList.any((skill) => requiredSkills.contains(skill));
    }).toList();
  }

  Future<void> _applyForJob(int jobId) async {
    final url = Uri.parse('http://localhost:8080/apply');
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer ${TokenManager.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'jobId': jobId}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _appliedJobIds.add(jobId);
        });
        await _fetchAppliedJobsOnStartup();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Application submitted successfully!', style: robotoStyle()),
              backgroundColor: Colors.greenAccent[700],
            ),
          );
        }
      } else {
        final errorMsg = response.body;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg.isNotEmpty ? errorMsg : 'Application failed.', style: robotoStyle()),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not submit application.', style: robotoStyle()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showJobDetails(dynamic job) {
    final int jobId = job['id'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isCurrentlyApplied = _appliedJobIds.contains(jobId);

            return Dialog(
              backgroundColor: const Color(0xFF111827),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
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
                                job['role'] ?? 'Opportunity',
                                style: robotoStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                job['company'] ?? 'Company Name',
                                style: robotoStyle(color: const Color(0xFF3B82F6), fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () async {
                                await _toggleSavedJob(jobId);
                                setDialogState(() {});
                              },
                              icon: Icon(
                                _savedJobIds.contains(jobId) ? Icons.bookmark : Icons.bookmark_border,
                                color: _savedJobIds.contains(jobId) ? const Color(0xFF14B8A6) : Colors.white70,
                                size: 24,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close, color: Colors.white70),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 24),
                    const SizedBox(height: 8),
                    _buildModalInfoRow(Icons.place_outlined, 'Location', job['location'] ?? 'Not Specified'),
                    const SizedBox(height: 8),
                    _buildModalInfoRow(Icons.payments_outlined, 'Salary', job['salary'] ?? 'Not Specified'),
                    const SizedBox(height: 8),
                    _buildModalInfoRow(Icons.work_history_outlined, 'Type', job['type'] ?? 'Not Specified'),
                    const SizedBox(height: 8),
                    _buildModalInfoRow(
                      Icons.calendar_month_outlined, 
                      'Deadline', 
                      job['deadline'] != null 
                          ? job['deadline'].toString().substring(0, 10) 
                          : 'Not Specified'
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Skills Required',
                      style: robotoStyle(color: const Color(0xFF14B8A6), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      job['skillsRequired'] ?? 'None',
                      style: robotoStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Description',
                      style: robotoStyle(color: const Color(0xFF14B8A6), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      child: SingleChildScrollView(
                        child: Text(
                          job['description'] ?? 'No description provided.',
                          style: robotoStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: isCurrentlyApplied
                            ? null
                            : () async {
                                await _applyForJob(jobId);
                                setDialogState(() {});
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF14B8A6),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.white10,
                          disabledForegroundColor: Colors.white30,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          isCurrentlyApplied ? 'Applied' : 'Apply Now',
                          style: robotoStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildModalInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white38, size: 18),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: robotoStyle(color: Colors.white38, fontSize: 13),
        ),
        Text(
          value,
          style: robotoStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
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
                    child: _activeTab == 0
                        ? _buildExploreView(isDesktop)
                        : _activeTab == 1
                            ? _buildBookmarksView(isDesktop)
                            : _activeTab == 2
                                ? _buildApplicationsView(isDesktop)
                                : _buildAnnouncementsView(isDesktop),
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
          // Logo/Name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: isDesktop ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF14B8A6), Color(0xFF3B82F6)]),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.school_outlined, color: Colors.white, size: 18),
                ),
                if (isDesktop) ...[
                  const SizedBox(width: 12),
                  Text(
                    'BMU Student',
                    style: robotoStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 48),
          _buildSidebarItem(0, Icons.explore_outlined, 'Explore', isDesktop),
          const SizedBox(height: 12),
          _buildSidebarItem(1, Icons.bookmark_border_outlined, 'Bookmarks', isDesktop),
          const SizedBox(height: 12),
          _buildSidebarItem(2, Icons.assignment_turned_in_outlined, 'Applications', isDesktop),
          const SizedBox(height: 12),
          _buildSidebarItem(3, Icons.campaign_outlined, 'Announcements', isDesktop),
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
            if (index == 1) {
              _fetchSavedJobs();
            } else if (index == 2) {
              _fetchAppliedJobs();
            } else if (index == 3) {
              _fetchAnnouncements();
            } else {
              _loadInitialData();
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

  Widget _buildBookmarksView(bool isDesktop) {
    if (_isLoadingSavedJobs) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF14B8A6)),
      );
    }

    if (_savedJobsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bookmark_border_outlined, size: 60, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              'You haven\'t saved any opportunities yet.',
              style: robotoStyle(color: Colors.white38, fontSize: 15),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _activeTab = 0;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14B8A6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Explore Opportunities', style: robotoStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bookmarks',
            style: robotoStyle(color: const Color(0xFF14B8A6), fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildJobGrid(_savedJobsList, isDesktop),
        ],
      ),
    );
  }

  Widget _buildExploreView(bool isDesktop) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF14B8A6)),
      );
    }
    if (_errorMessage != null) {
      return Center(
        child: Text(_errorMessage!, style: robotoStyle(color: Colors.redAccent)),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchPanel(isDesktop),
          const SizedBox(height: 24),
          if (_recommendedJobs.isNotEmpty) ...[
            Text(
              'Recommended Opportunities (Matching your profile skills)',
              style: robotoStyle(color: const Color(0xFF14B8A6), fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildJobGrid(_recommendedJobs, isDesktop),
            const SizedBox(height: 32),
          ],
          Text(
            'All Listings',
            style: robotoStyle(color: const Color(0xFF14B8A6), fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _allJobs.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      'No opportunities found.',
                      style: robotoStyle(color: Colors.white38, fontSize: 14),
                    ),
                  ),
                )
              : _buildJobGrid(_allJobs, isDesktop),
        ],
      ),
    );
  }

  Widget _buildApplicationsView(bool isDesktop) {
    if (_isLoadingApplications) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF14B8A6)),
      );
    }

    if (_appliedJobsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assignment_turned_in_outlined, size: 60, color: Colors.white24),
            const SizedBox(height: 16),
            Text(
              'You haven\'t applied to any opportunities yet.',
              style: robotoStyle(color: Colors.white38, fontSize: 15),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _activeTab = 0;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14B8A6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Explore Opportunities', style: robotoStyle(fontWeight: FontWeight.bold)),
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
        mainAxisExtent: 310,
      ),
      itemCount: _appliedJobsList.length,
      itemBuilder: (context, index) {
        final app = _appliedJobsList[index];
        final appliedDateStr = app['appliedDate'] != null
            ? app['appliedDate'].toString().substring(0, 10)
            : 'N/A';
        final status = app['status'] ?? 'APPLIED';
        
        Color statusColor = const Color(0xFF3B82F6); // blue for APPLIED / default
        if (status == 'SELECTED') statusColor = Colors.greenAccent[700]!;
        if (status == 'REJECTED') statusColor = Colors.redAccent;
        if (status == 'SHORTLISTED') statusColor = Colors.tealAccent[700]!;
        if (status == 'INTERVIEW') statusColor = Colors.orangeAccent;

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
                      app['role'] ?? 'Opportunity',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: robotoStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
                      status,
                      style: robotoStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                app['company'] ?? 'Company Name',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: robotoStyle(color: const Color(0xFF3B82F6), fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 14, color: Colors.white38),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      app['location'] ?? 'Not Specified',
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
                      app['salary'] ?? 'Not Specified',
                      style: robotoStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStatusTimeline(status),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Applied on: $appliedDateStr',
                    style: robotoStyle(color: Colors.white38, fontSize: 11),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      app['type'] ?? 'Full-Time',
                      style: robotoStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w600),
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0x11FFFFFF),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _activeTab == 0
                ? 'BMU Placement Portal'
                : _activeTab == 1
                    ? 'Saved Opportunities'
                    : _activeTab == 2
                        ? 'My Applications'
                        : 'Global Announcements',
            style: robotoStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/student/profile');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF111827),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: const Icon(Icons.person_outlined, size: 18, color: Color(0xFF3B82F6)),
            label: Text(
              'My Profile',
              style: robotoStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchPanel(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(15)),
      ),
      child: isDesktop
          ? Row(
              children: [
                Expanded(child: _buildSearchTextField(_skillController, 'Skill (e.g. Java, Python)', Icons.psychology_outlined)),
                const SizedBox(width: 16),
                Expanded(child: _buildSearchTextField(_locationController, 'Location (e.g. Delhi, Gurugram)', Icons.place_outlined)),
                const SizedBox(width: 16),
                _buildTypeDropdown(),
                const SizedBox(width: 16),
                _buildSearchButton(),
              ],
            )
          : Column(
              children: [
                _buildSearchTextField(_skillController, 'Skill (e.g. Java, Python)', Icons.psychology_outlined),
                const SizedBox(height: 12),
                _buildSearchTextField(_locationController, 'Location (e.g. Delhi, Gurugram)', Icons.place_outlined),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildTypeDropdown()),
                    const SizedBox(width: 12),
                    _buildSearchButton(),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildSearchTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      style: robotoStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: robotoStyle(color: Colors.white38, fontSize: 13),
        prefixIcon: Icon(icon, color: const Color(0xFF14B8A6), size: 18),
        filled: true,
        fillColor: const Color(0xFF1F2937),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF14B8A6), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedType,
          dropdownColor: const Color(0xFF1F2937),
          style: robotoStyle(color: Colors.white, fontSize: 14),
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF14B8A6)),
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
    );
  }

  Widget _buildSearchButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: _fetchJobs,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF14B8A6),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
        icon: const Icon(Icons.search, size: 18),
        label: Text('Search', style: robotoStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildJobGrid(List<dynamic> jobs, bool isDesktop) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isDesktop ? 3 : 1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        mainAxisExtent: 200,
      ),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        return _buildJobCard(job);
      },
    );
  }

  Widget _buildJobCard(dynamic job) {
    final int jobId = job['id'];
    final bool alreadyApplied = _appliedJobIds.contains(jobId);
    final bool isSaved = _savedJobIds.contains(jobId);

    return Container(
      padding: const EdgeInsets.all(18),
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _toggleSavedJob(jobId),
                    icon: Icon(
                      isSaved ? Icons.bookmark : Icons.bookmark_border,
                      color: isSaved ? const Color(0xFF14B8A6) : Colors.white60,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
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
            ],
          ),
          const SizedBox(height: 4),
          Text(
            job['company'] ?? 'Company Name',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: robotoStyle(color: const Color(0xFF3B82F6), fontSize: 13, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.place_outlined, size: 14, color: Colors.white38),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  job['location'] ?? 'Not Specified',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: robotoStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.payments_outlined, size: 14, color: Colors.white38),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  job['salary'] ?? 'Not Specified',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: robotoStyle(color: Colors.white70, fontSize: 12),
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
                    ? 'Apply by: ${job['deadline'].toString().substring(0, 10)}' 
                    : 'Apply by: N/A',
                style: robotoStyle(color: Colors.white38, fontSize: 11),
              ),
              ElevatedButton(
                onPressed: () => _showJobDetails(job),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14B8A6),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                child: Text(
                  alreadyApplied ? 'Applied' : 'View',
                  style: robotoStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
