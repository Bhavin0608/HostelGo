import 'package:flutter/material.dart';
import '../../models/outing_request_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/outing_request_card.dart';
import 'request_details_screen.dart';

class StudentHistoryScreen extends StatefulWidget {
  final UserModel student;

  const StudentHistoryScreen({
    super.key,
    required this.student,
  });

  @override
  State<StudentHistoryScreen> createState() => _StudentHistoryScreenState();
}

class _StudentHistoryScreenState extends State<StudentHistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All'; // All, Completed, Rejected

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
          'Outing History',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: AppColors.surface,
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by destination or purpose...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.surfaceSubtle,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),

                // Filter Chips
                Row(
                  children: [
                    _buildFilterChip('All'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Completed', status: AppConstants.statusReturned),
                    const SizedBox(width: 8),
                    _buildFilterChip('Rejected', status: AppConstants.statusRejected),
                  ],
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
                  return const Center(child: CircularProgressIndicator());
                }

                final allRequests = snapshot.data ?? [];
                final searchQuery = _searchController.text.trim().toLowerCase();

                final filtered = allRequests.where((req) {
                  // Filter by status tab
                  if (_selectedFilter == 'Completed' && req.status != AppConstants.statusReturned) {
                    return false;
                  }
                  if (_selectedFilter == 'Rejected' && req.status != AppConstants.statusRejected) {
                    return false;
                  }

                  // Search query filter
                  if (searchQuery.isNotEmpty) {
                    final matchDest = req.destination.toLowerCase().contains(searchQuery);
                    final matchPurpose = req.purpose.toLowerCase().contains(searchQuery);
                    final matchId = req.displayRequestId.toLowerCase().contains(searchQuery);
                    return matchDest || matchPurpose || matchId;
                  }

                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.history_rounded,
                    title: 'No history records found',
                    message: 'Past completed or rejected outings will be archived here.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
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

  Widget _buildFilterChip(String label, {String? status}) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceSubtle,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = label;
          });
        }
      },
    );
  }
}
