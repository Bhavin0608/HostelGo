import 'package:flutter/material.dart';
import '../../models/outing_request_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/dashboard_stat_card.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/outing_request_card.dart';
import '../auth/login_screen.dart';
import 'approved_outings_screen.dart';
import 'currently_outside_screen.dart';
import 'request_review_screen.dart';

class WardenDashboard extends StatefulWidget {
  final int initialTabIndex;

  const WardenDashboard({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<WardenDashboard> createState() => _WardenDashboardState();
}

class _WardenDashboardState extends State<WardenDashboard> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  UserModel? _currentUser;
  bool _isLoadingUser = true;
  late int _currentNavIndex;

  // Pending Tab state
  final TextEditingController _pendingSearchController = TextEditingController();

  // History / Logs Tab state
  final TextEditingController _historySearchController = TextEditingController();
  String _selectedHistoryFilter = 'All';
  final List<String> _historyFilters = ['All', 'Pending', 'Approved', 'Outside', 'Returned', 'Rejected'];

  @override
  void initState() {
    super.initState();
    _currentNavIndex = widget.initialTabIndex;
    _loadUser();
  }

  @override
  void dispose() {
    _pendingSearchController.dispose();
    _historySearchController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await _authService.getCurrentUserModel();
    if (mounted) {
      setState(() {
        _currentUser = user;
        _isLoadingUser = false;
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
    if (fullName.isEmpty) return 'Warden';
    return fullName.split(' ').first;
  }

  void _switchTab(int index, {String? historyFilter}) {
    setState(() {
      _currentNavIndex = index;
      if (historyFilter != null) {
        _selectedHistoryFilter = historyFilter;
      }
    });
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text(
          'Are you sure you want to sign out of the Warden management console?',
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
              const Text('Session expired or unauthorized.'),
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
            _buildPendingTab(),
            _buildLogsTab(),
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
              label: 'Logs',
              icon: Icons.history_rounded,
              isActive: _currentNavIndex == 2,
              onTap: () => setState(() => _currentNavIndex = 2),
            ),
            _buildNavButton(
              label: 'Profile',
              icon: Icons.person_rounded,
              isActive: _currentNavIndex == 3,
              onTap: () => setState(() => _currentNavIndex = 3),
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
    return StreamBuilder<List<OutingRequestModel>>(
      stream: _firestoreService.getAllRequestsStream(),
      builder: (context, snapshot) {
        final allRequests = snapshot.data ?? [];
        final pendingRequests = allRequests.where((r) => r.status == AppConstants.statusPending).toList();
        final approvedCount = allRequests.where((r) => r.status == AppConstants.statusApproved || r.status == AppConstants.statusOutside).length;
        final rejectedCount = allRequests.where((r) => r.status == AppConstants.statusRejected).length;
        final totalCount = allRequests.length;
        final topPending = pendingRequests.take(4).toList();

        return RefreshIndicator(
          onRefresh: _loadUser,
          color: AppColors.primary,
          child: SingleChildScrollView(
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
                            'Review hostel outing requests.',
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
                      onTap: () => _switchTab(3),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          gradient: AppColors.avatarGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _currentUser!.name.isNotEmpty ? _currentUser!.name[0].toUpperCase() : 'W',
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

                // Warden Stats 2x2 Grid
                Row(
                  children: [
                    Expanded(
                      child: DashboardStatCard(
                        title: 'Pending',
                        count: '${pendingRequests.length}',
                        isAccent: true,
                        onTap: () => _switchTab(1),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DashboardStatCard(
                        title: 'Approved Today',
                        count: '$approvedCount',
                        countColor: AppColors.statusApproved,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ApprovedOutingsScreen()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DashboardStatCard(
                        title: 'Rejected Today',
                        count: '$rejectedCount',
                        countColor: AppColors.statusRejected,
                        onTap: () => _switchTab(2, historyFilter: 'Rejected'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DashboardStatCard(
                        title: 'Total Requests',
                        count: '$totalCount',
                        countColor: AppColors.textPrimary,
                        onTap: () => _switchTab(2, historyFilter: 'All'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Management Portals
                const Text(
                  'Management Portals',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildPortalButton(
                        title: 'Gate Pass',
                        icon: Icons.vpn_key_rounded,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ApprovedOutingsScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildPortalButton(
                        title: 'Outside',
                        icon: Icons.directions_walk_rounded,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CurrentlyOutsideScreen()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildPortalButton(
                        title: 'Logs',
                        icon: Icons.history_rounded,
                        onTap: () => _switchTab(2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Needs Your Attention Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Needs Your Attention',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _switchTab(1),
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

                if (topPending.isEmpty)
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
                        Icon(Icons.done_all_rounded, size: 36, color: AppColors.statusApproved),
                        SizedBox(height: 8),
                        Text(
                          'No pending requests.',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "You're all caught up.",
                          style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: topPending.map((req) {
                      return OutingRequestCard(
                        request: req,
                        showStudentDetails: true,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RequestReviewScreen(requestId: req.id),
                            ),
                          );
                        },
                        trailingAction: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => RequestReviewScreen(requestId: req.id),
                                  ),
                                );
                              },
                              child: const Text(
                                'Review Request →',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // -------------------------
  // TAB 1: PENDING REQUESTS
  // -------------------------
  Widget _buildPendingTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          color: AppColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pending Requests',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _pendingSearchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search by student name, ID, hostel...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 18),
                  suffixIcon: _pendingSearchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _pendingSearchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),

        Expanded(
          child: StreamBuilder<List<OutingRequestModel>>(
            stream: _firestoreService.getPendingRequestsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }

              final requests = snapshot.data ?? [];
              final query = _pendingSearchController.text.trim().toLowerCase();

              final filtered = requests.where((req) {
                if (query.isEmpty) return true;
                final matchName = req.studentName.toLowerCase().contains(query);
                final matchId = req.studentId.toLowerCase().contains(query);
                final matchHostel = req.hostel.toLowerCase().contains(query);
                final matchDest = req.destination.toLowerCase().contains(query);
                return matchName || matchId || matchHostel || matchDest;
              }).toList();

              if (filtered.isEmpty) {
                return const EmptyStateView(
                  icon: Icons.done_all_rounded,
                  title: 'No pending requests',
                  message: "You're all caught up! New requests from hostel students appear in real time.",
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final request = filtered[index];
                  return OutingRequestCard(
                    request: request,
                    showStudentDetails: true,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RequestReviewScreen(requestId: request.id),
                        ),
                      );
                    },
                    trailingAction: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => RequestReviewScreen(requestId: request.id),
                              ),
                            );
                          },
                          child: const Text(
                            'Review Request →',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
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
  // TAB 2: LOGS & HISTORY
  // -------------------------
  Widget _buildLogsTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          color: AppColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Outing Logs & History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _historySearchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search student, ID, hostel, destination...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 18),
                  suffixIcon: _historySearchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _historySearchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 10),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _historyFilters.map((filter) {
                    final isSelected = _selectedHistoryFilter == filter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedHistoryFilter = filter),
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
                            filter,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),

        Expanded(
          child: StreamBuilder<List<OutingRequestModel>>(
            stream: _firestoreService.getAllRequestsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              }

              final allRequests = snapshot.data ?? [];
              final searchQuery = _historySearchController.text.trim().toLowerCase();

              final filtered = allRequests.where((req) {
                if (_selectedHistoryFilter == 'Pending' && req.status != AppConstants.statusPending) return false;
                if (_selectedHistoryFilter == 'Approved' && req.status != AppConstants.statusApproved) return false;
                if (_selectedHistoryFilter == 'Outside' && req.status != AppConstants.statusOutside) return false;
                if (_selectedHistoryFilter == 'Returned' && req.status != AppConstants.statusReturned) return false;
                if (_selectedHistoryFilter == 'Rejected' && req.status != AppConstants.statusRejected) return false;

                if (searchQuery.isNotEmpty) {
                  final matchName = req.studentName.toLowerCase().contains(searchQuery);
                  final matchId = req.studentId.toLowerCase().contains(searchQuery);
                  final matchHostel = req.hostel.toLowerCase().contains(searchQuery);
                  final matchRoom = req.roomNumber.toLowerCase().contains(searchQuery);
                  final matchDest = req.destination.toLowerCase().contains(searchQuery);
                  final matchPurpose = req.purpose.toLowerCase().contains(searchQuery);
                  final matchReqId = req.displayRequestId.toLowerCase().contains(searchQuery);
                  return matchName || matchId || matchHostel || matchRoom || matchDest || matchPurpose || matchReqId;
                }

                return true;
              }).toList();

              if (filtered.isEmpty) {
                return const EmptyStateView(
                  icon: Icons.search_off_rounded,
                  title: 'No matching records found',
                  message: 'Try adjusting your search terms or status filter selection.',
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final request = filtered[index];
                  return OutingRequestCard(
                    request: request,
                    showStudentDetails: true,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RequestReviewScreen(requestId: request.id),
                        ),
                      );
                    },
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
  // TAB 3: PROFILE
  // -------------------------
  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                          _currentUser!.name.isNotEmpty ? _currentUser!.name[0].toUpperCase() : 'W',
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
                      _currentUser!.hostel,
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
                        'WARDEN',
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
                      'WARDEN DETAILS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildKv('Email', _currentUser!.email),
                    _buildKv('Hostel', _currentUser!.hostel),
                    _buildKv('Role', 'Warden (Administrator)'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

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
                      'ADMINISTRATIVE POLICIES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildPolicyItem(
                      icon: Icons.gavel_rounded,
                      title: 'Warden Discretionary Authority',
                      desc: 'The Warden evaluates all single-day outings, late-night permissions, and extended festival or vacation leaves based on student purpose and remarks.',
                    ),
                    const SizedBox(height: 10),
                    _buildPolicyItem(
                      icon: Icons.verified_user_outlined,
                      title: 'Digital Gate Pass Verification',
                      desc: 'Approved passes are verified at hostel gates before recording student departures and return movements.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

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
    );
  }

  Widget _buildPortalButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
            boxShadow: AppColors.shadowSm,
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPolicyItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
