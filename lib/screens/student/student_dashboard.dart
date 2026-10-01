import 'package:flutter/material.dart';
import '../../models/outing_request_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/dashboard_stat_card.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/outing_request_card.dart';
import '../auth/login_screen.dart';
import 'apply_outing_screen.dart';
import 'digital_gate_pass_screen.dart';
import 'request_details_screen.dart';
import 'student_feedback_screen.dart';

class StudentDashboard extends StatefulWidget {
  final int initialTabIndex;

  const StudentDashboard({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  UserModel? _currentUser;
  bool _isLoadingUser = true;
  late int _currentNavIndex;

  // Requests Tab state
  int _selectedRequestsChip = 0;
  final TextEditingController _searchController = TextEditingController();
  final List<String> _requestChips = ['All', 'Pending', 'Active', 'Past'];

  // Profile Tab state
  final _profileFormKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _roomNumberController;
  late TextEditingController _phoneController;
  String _selectedHostel = AppConstants.hostelBlocks.first;
  bool _isSavingProfile = false;
  String? _profileMessage;
  bool _isProfileSuccess = false;

  @override
  void initState() {
    super.initState();
    _currentNavIndex = widget.initialTabIndex;
    _nameController = TextEditingController();
    _roomNumberController = TextEditingController();
    _phoneController = TextEditingController();
    _loadUser();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _roomNumberController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getCurrentUserModel();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _isLoadingUser = false;
        if (user != null) {
          _nameController.text = user.name;
          _roomNumberController.text = user.roomNumber;
          _phoneController.text = user.phone ?? '';
          if (AppConstants.hostelBlocks.contains(user.hostel)) {
            _selectedHostel = user.hostel;
          }
        }
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getFirstName(String fullName) {
    if (fullName.isEmpty) return 'Student';
    return fullName.split(' ').first;
  }

  void _switchTab(int tabIndex, {int? requestsChipIndex}) {
    setState(() {
      _currentNavIndex = tabIndex;
      if (requestsChipIndex != null) {
        _selectedRequestsChip = requestsChipIndex;
      }
    });
  }

  Future<void> _handleSaveProfile() async {
    if (!_profileFormKey.currentState!.validate() || _currentUser == null) return;

    setState(() {
      _isSavingProfile = true;
      _profileMessage = null;
    });

    try {
      await _authService.updateStudentProfile(
        uid: _currentUser!.uid,
        name: _nameController.text,
        hostel: _selectedHostel,
        roomNumber: _roomNumberController.text,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      );

      await _loadUser();

      if (mounted) {
        setState(() {
          _isProfileSuccess = true;
          _profileMessage = 'Profile updated successfully!';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProfileSuccess = false;
          _profileMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSavingProfile = false;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
          'Are you sure you want to sign out of your account?',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusRejectedBg,
              foregroundColor: AppColors.statusRejected,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingUser) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (_currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Session expired or user not found.'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text('Return to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: IndexedStack(
          index: _currentNavIndex,
          children: [
            _buildHomeTab(),
            _buildRequestsTab(),
            _buildProfileTab(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 64,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
          boxShadow: AppColors.shadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavButton(
              label: 'Home',
              icon: Icons.home_rounded,
              isActive: _currentNavIndex == 0,
              onTap: () => setState(() => _currentNavIndex = 0),
            ),
            _buildNavButton(
              label: 'Requests',
              icon: Icons.assignment_outlined,
              isActive: _currentNavIndex == 1,
              onTap: () => setState(() => _currentNavIndex = 1),
            ),
            _buildNavButton(
              label: 'Profile',
              icon: Icons.person_rounded,
              isActive: _currentNavIndex == 2,
              onTap: () => setState(() => _currentNavIndex = 2),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------
  // TAB 0: HOME
  // -------------------------
  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _loadUser,
      color: AppColors.primary,
      child: StreamBuilder<List<OutingRequestModel>>(
        stream: _firestoreService.getStudentRequestsStream(_currentUser!.uid),
        builder: (context, snapshot) {
          final allRequests = snapshot.data ?? [];
          final pendingCount = allRequests.where((r) => r.status == AppConstants.statusPending).length;
          final approvedCount = allRequests.where((r) => r.status == AppConstants.statusApproved || r.status == AppConstants.statusOutside).length;
          final rejectedCount = allRequests.where((r) => r.status == AppConstants.statusRejected).length;
          final totalCount = allRequests.length;
          final recentRequests = allRequests.take(3).toList();

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Topbar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_getGreeting()}, ${_getFirstName(_currentUser!.name)} 👋',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Plan your outing and request permission.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => _switchTab(2),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          gradient: AppColors.avatarGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _currentUser!.name.isNotEmpty ? _currentUser!.name[0].toUpperCase() : 'S',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Hero Card (Teal Card from CSS)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.heroGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppColors.heroShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Going somewhere?',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Submit an outing request or multi-day leave for warden review.',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: Colors.white.withAlpha((0.9 * 255).round()),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ApplyOutingScreen(student: _currentUser!),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.primaryDark,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Create Request',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Request Overview Header
                const Text(
                  'Request Overview',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 10),

                // Stats 2x2 Grid
                Row(
                  children: [
                    Expanded(
                      child: DashboardStatCard(
                        title: 'Pending',
                        count: '$pendingCount',
                        countColor: AppColors.statusPending,
                        onTap: () => _switchTab(1, requestsChipIndex: 1),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DashboardStatCard(
                        title: 'Approved',
                        count: '$approvedCount',
                        countColor: AppColors.statusApproved,
                        onTap: () => _switchTab(1, requestsChipIndex: 2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DashboardStatCard(
                        title: 'Rejected',
                        count: '$rejectedCount',
                        countColor: AppColors.statusRejected,
                        onTap: () => _switchTab(1, requestsChipIndex: 3),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DashboardStatCard(
                        title: 'Total',
                        count: '$totalCount',
                        countColor: AppColors.textPrimary,
                        onTap: () => _switchTab(1, requestsChipIndex: 0),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Recent Requests Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Requests',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _switchTab(1, requestsChipIndex: 0),
                      child: const Text(
                        'See all',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Recent Requests List or Empty
                if (recentRequests.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                      boxShadow: AppColors.shadowSm,
                    ),
                    child: Column(
                      children: const [
                        Icon(Icons.inbox_outlined, size: 36, color: AppColors.textMuted),
                        SizedBox(height: 8),
                        Text(
                          'No outing requests yet.',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Tap "Create Request" above to apply.',
                          style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: recentRequests.map((req) {
                      return OutingRequestCard(
                        request: req,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RequestDetailsScreen(
                                requestId: req.id,
                                isWarden: false,
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  // -------------------------
  // TAB 1: REQUESTS
  // -------------------------
  Widget _buildRequestsTab() {
    return Column(
      children: [
        // Search & Chip Filters Header
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Requests',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 28),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ApplyOutingScreen(student: _currentUser!),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search destination, purpose, ID...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 10),

              // Chip row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_requestChips.length, (index) {
                    final isSelected = _selectedRequestsChip == index;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedRequestsChip = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : AppColors.surface,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                          ),
                          child: Text(
                            _requestChips[index],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),

        // Stream List
        Expanded(
          child: StreamBuilder<List<OutingRequestModel>>(
            stream: _firestoreService.getStudentRequestsStream(_currentUser!.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }

              final allRequests = snapshot.data ?? [];
              final query = _searchController.text.trim().toLowerCase();

              final filtered = allRequests.where((req) {
                // Filter by chip
                if (_selectedRequestsChip == 1 && req.status != AppConstants.statusPending) {
                  return false;
                }
                if (_selectedRequestsChip == 2 &&
                    !(req.status == AppConstants.statusApproved || req.status == AppConstants.statusOutside)) {
                  return false;
                }
                if (_selectedRequestsChip == 3 &&
                    !(req.status == AppConstants.statusReturned || req.status == AppConstants.statusRejected)) {
                  return false;
                }

                // Filter by query
                if (query.isNotEmpty) {
                  final matchDest = req.destination.toLowerCase().contains(query);
                  final matchPurpose = req.purpose.toLowerCase().contains(query);
                  final matchId = req.displayRequestId.toLowerCase().contains(query);
                  return matchDest || matchPurpose || matchId;
                }

                return true;
              }).toList();

              if (filtered.isEmpty) {
                return EmptyStateView(
                  icon: Icons.inbox_outlined,
                  title: 'No requests found.',
                  message: 'Submit a new outing request to get approval from your warden.',
                  buttonText: 'Create Request',
                  buttonIcon: Icons.add_rounded,
                  onButtonPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ApplyOutingScreen(student: _currentUser!),
                      ),
                    );
                  },
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final request = filtered[index];
                  return OutingRequestCard(
                    request: request,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RequestDetailsScreen(
                            requestId: request.id,
                            isWarden: false,
                          ),
                        ),
                      );
                    },
                    trailingAction: (request.isApproved || request.isOutside)
                        ? SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => DigitalGatePassScreen(requestId: request.id),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.badge_outlined, size: 16),
                              label: const Text('Open Digital Gate Pass'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryDark,
                                side: const BorderSide(color: Color(0xFF99F6E4)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          )
                        : null,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // -------------------------
  // TAB 2: PROFILE
  // -------------------------
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Form(
            key: _profileFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Profile Hero
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          gradient: AppColors.avatarGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _currentUser!.name.isNotEmpty ? _currentUser!.name[0].toUpperCase() : 'S',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _currentUser!.name,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentUser!.studentId,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'STUDENT',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Status Message Banner
                if (_profileMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isProfileSuccess ? AppColors.statusApprovedBg : AppColors.statusRejectedBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _profileMessage!,
                      style: TextStyle(
                        color: _isProfileSuccess ? AppColors.statusApproved : AppColors.statusRejected,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Institutional Details Panel
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppColors.shadowSm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'STUDENT DETAILS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildKv('Email', _currentUser!.email),
                      _buildKv('Student ID', _currentUser!.studentId),
                      _buildKv('Role', 'Student'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Editable Information Panel
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppColors.shadowSm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'EDIT PROFILE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildFieldLabel('Full Name'),
                      TextFormField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        validator: (v) => Validators.validateRequired(v, 'Full Name'),
                      ),
                      const SizedBox(height: 12),

                      _buildFieldLabel('Hostel'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border, width: 1.5),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedHostel,
                            isExpanded: true,
                            items: AppConstants.hostelBlocks.map((hostel) {
                              return DropdownMenuItem<String>(
                                value: hostel,
                                child: Text(
                                  hostel,
                                  style: const TextStyle(fontSize: 14.5, color: AppColors.textPrimary),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedHostel = val;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildFieldLabel('Room Number'),
                      TextFormField(
                        controller: _roomNumberController,
                        validator: Validators.validateRoomNumber,
                      ),
                      const SizedBox(height: 12),

                      _buildFieldLabel('Phone Number'),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Feedback & Grievance Portal Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppColors.shadowSm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'FEEDBACK & GRIEVANCES',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Have suggestions, complaints, or feedback about the outing process or hostel services?',
                        style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.35),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => StudentFeedbackScreen(student: _currentUser!),
                              ),
                            );
                          },
                          icon: const Icon(Icons.rate_review_outlined, size: 18),
                          label: const Text('Give Feedback / Grievance', style: TextStyle(fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Save Button
                CustomButton(
                  text: 'Save Changes',
                  onPressed: _handleSaveProfile,
                  isLoading: _isSavingProfile,
                  type: ButtonType.primary,
                  height: 48,
                ),
                const SizedBox(height: 12),

                // Sign Out Button
                CustomButton(
                  text: 'Log Out',
                  onPressed: _handleLogout,
                  type: ButtonType.danger,
                  height: 48,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildKv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13.5, color: AppColors.textMuted)),
          Text(
            value,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primarySoft : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? AppColors.primaryDark : AppColors.textMuted,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isActive ? AppColors.primaryDark : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
