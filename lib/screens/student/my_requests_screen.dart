import 'package:flutter/material.dart';
import '../../models/outing_request_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/outing_request_card.dart';
import 'apply_outing_screen.dart';
import 'digital_gate_pass_screen.dart';
import 'request_details_screen.dart';

class MyRequestsScreen extends StatefulWidget {
  final UserModel student;
  final int initialTabIndex;

  const MyRequestsScreen({
    super.key,
    required this.student,
    this.initialTabIndex = 0,
  });

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  late int _selectedChipIndex;
  final TextEditingController _searchController = TextEditingController();

  final List<String> _chips = ['All', 'Pending', 'Active', 'Past'];

  @override
  void initState() {
    super.initState();
    _selectedChipIndex = widget.initialTabIndex;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My Requests',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search & Chip Filters Header
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by destination or purpose...',
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
                    children: List.generate(_chips.length, (index) {
                      final isSelected = _selectedChipIndex == index;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedChipIndex = index),
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
                              _chips[index],
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

          // Requests Stream List
          Expanded(
            child: StreamBuilder<List<OutingRequestModel>>(
              stream: _firestoreService.getStudentRequestsStream(widget.student.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading requests: ${snapshot.error}',
                      style: const TextStyle(color: AppColors.statusRejected),
                    ),
                  );
                }

                final allRequests = snapshot.data ?? [];
                final query = _searchController.text.trim().toLowerCase();

                final filtered = allRequests.where((req) {
                  // Filter by chip
                  if (_selectedChipIndex == 1 && req.status != AppConstants.statusPending) {
                    return false;
                  }
                  if (_selectedChipIndex == 2 &&
                      !(req.status == AppConstants.statusApproved || req.status == AppConstants.statusOutside)) {
                    return false;
                  }
                  if (_selectedChipIndex == 3 &&
                      !(req.status == AppConstants.statusReturned || req.status == AppConstants.statusRejected)) {
                    return false;
                  }

                  // Filter by search query
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
                          builder: (_) => ApplyOutingScreen(student: widget.student),
                        ),
                      );
                    },
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 80),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ApplyOutingScreen(student: widget.student),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Create Request', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
    );
  }
}
