import 'package:flutter/material.dart';
import '../../models/outing_request_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/outing_request_card.dart';
import '../student/request_details_screen.dart';

class WardenHistoryScreen extends StatefulWidget {
  const WardenHistoryScreen({super.key});

  @override
  State<WardenHistoryScreen> createState() => _WardenHistoryScreenState();
}

class _WardenHistoryScreenState extends State<WardenHistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Pending', 'Approved', 'Outside', 'Returned', 'Rejected'];

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
          'Outing Logs & History',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter & Search Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            color: AppColors.surface,
            child: Column(
              children: [
                // Search Field
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search student, ID, hostel, destination...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 18),
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

                // Status Filter Chips matching CSS .chips & .chip
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedFilter = filter),
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

          // Requests Stream List
          Expanded(
            child: StreamBuilder<List<OutingRequestModel>>(
              stream: _firestoreService.getAllRequestsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading history: ${snapshot.error}',
                        style: const TextStyle(color: AppColors.statusRejected)),
                  );
                }

                final allRequests = snapshot.data ?? [];
                final searchQuery = _searchController.text.trim().toLowerCase();

                final filtered = allRequests.where((req) {
                  // Filter by status
                  if (_selectedFilter == 'Pending' && req.status != AppConstants.statusPending) return false;
                  if (_selectedFilter == 'Approved' && req.status != AppConstants.statusApproved) return false;
                  if (_selectedFilter == 'Outside' && req.status != AppConstants.statusOutside) return false;
                  if (_selectedFilter == 'Returned' && req.status != AppConstants.statusReturned) return false;
                  if (_selectedFilter == 'Rejected' && req.status != AppConstants.statusRejected) return false;

                  // Search query filter
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
                    message: 'Try adjusting your search terms or filter selection.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final request = filtered[index];
                    return OutingRequestCard(
                      request: request,
                      showStudentDetails: true,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RequestDetailsScreen(
                              requestId: request.id,
                              isWarden: true,
                            ),
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
      ),
    );
  }
}
