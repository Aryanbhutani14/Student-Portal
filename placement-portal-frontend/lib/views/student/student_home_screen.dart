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

      // 2. Fetch Jobs
      await _fetchJobs();
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not load data. Ensure the backend is running.';
        _isLoading = false;
      });
    }
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
    final url = Uri.parse('http://localhost:8080/jobs/$jobId/apply');
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
          _appliedJobIds.add(jobId);
        });
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
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white70),
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
        child: Column(
          children: [
            // Header bar
            _buildHeader(),
            // Main Content Area
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF14B8A6)),
                    )
                  : _errorMessage != null
                      ? Center(child: Text(_errorMessage!, style: robotoStyle(color: Colors.redAccent)))
                      : SingleChildScrollView(
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
                        ),
            ),
          ],
        ),
      ),
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
          Row(
            children: [
              Container(
                width: 10,
                height: 30,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF14B8A6), Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'BMU PLACEMENT PORTAL',
                style: robotoStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
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
