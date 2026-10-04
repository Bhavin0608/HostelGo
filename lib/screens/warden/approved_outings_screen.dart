import 'package:flutter/material.dart';
import '../../models/outing_request_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/outing_request_card.dart';
import '../student/request_details_screen.dart';

class ApprovedOutingsScreen extends StatefulWidget {
  const ApprovedOutingsScreen({super.key});

  @override
  State<ApprovedOutingsScreen> createState() => _ApprovedOutingsScreenState();
}

class _ApprovedOutingsScreenState extends State<ApprovedOutingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  Future<void> _handleMarkOutside(OutingRequestModel request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Departure', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
          'Mark student ${request.studentName} (${request.studentId}) as OUTSIDE?\n\n'
          'This records the gate exit timestamp and starts their active outing period.',
          style: const TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirm Departure', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firestoreService.markOutside(requestId: request.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${request.studentName} marked as OUTSIDE.'),
            backgroundColor: AppColors.statusOutside,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.statusRejected,
          ),
        );
      }
    }
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
          'Approved Gate Passes',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Input
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

          // Approved List Stream
          Expanded(
            child: StreamBuilder<List<OutingRequestModel>>(
              stream: _firestoreService.getApprovedRequestsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading approved requests: ${snapshot.error}',
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
                    icon: Icons.check_circle_outline_rounded,
                    title: 'No approved passes waiting',
                    message: 'Approved outing requests awaiting gate departure will appear here.',
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
                      trailingAction: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _handleMarkOutside(request),
                            icon: const Icon(Icons.directions_walk_rounded, size: 16),
                            label: const Text('Mark Gate Departure'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
