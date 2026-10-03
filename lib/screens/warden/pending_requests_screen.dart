import 'package:flutter/material.dart';
import '../../models/outing_request_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/outing_request_card.dart';
import 'request_review_screen.dart';

class PendingRequestsScreen extends StatefulWidget {
  const PendingRequestsScreen({super.key});

  @override
  State<PendingRequestsScreen> createState() => _PendingRequestsScreenState();
}

class _PendingRequestsScreenState extends State<PendingRequestsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

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
          'Pending Requests',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.surface,
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search by student name or ID...',
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
          ),
          const Divider(height: 1, color: AppColors.border),

          // Pending List Stream
          Expanded(
            child: StreamBuilder<List<OutingRequestModel>>(
              stream: _firestoreService.getPendingRequestsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading requests: ${snapshot.error}',
                        style: const TextStyle(color: AppColors.statusRejected)),
                  );
                }

                final requests = snapshot.data ?? [];
                final query = _searchController.text.trim().toLowerCase();

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
                    message: "You're all caught up! New outing requests from students will appear here in real time.",
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
      ),
    );
  }
}
