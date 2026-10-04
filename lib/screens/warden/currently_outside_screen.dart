import 'package:flutter/material.dart';
import '../../models/outing_request_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/outing_request_card.dart';
import '../student/request_details_screen.dart';

class CurrentlyOutsideScreen extends StatefulWidget {
  const CurrentlyOutsideScreen({super.key});

  @override
  State<CurrentlyOutsideScreen> createState() => _CurrentlyOutsideScreenState();
}

class _CurrentlyOutsideScreenState extends State<CurrentlyOutsideScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  Future<void> _handleMarkReturned(OutingRequestModel request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Return', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
          'Mark student ${request.studentName} (${request.studentId}) as RETURNED?\n\n'
          'This will record their gate return timestamp and complete the outing lifecycle.',
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
              backgroundColor: AppColors.statusReturned,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirm Return', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _firestoreService.markReturned(requestId: request.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${request.studentName} marked as RETURNED to hostel.'),
            backgroundColor: AppColors.statusReturned,
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
          'Currently Outside',
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

          // Outside List Stream
          Expanded(
            child: StreamBuilder<List<OutingRequestModel>>(
              stream: _firestoreService.getOutsideRequestsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error loading outside students: ${snapshot.error}',
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
                    icon: Icons.meeting_room_rounded,
                    title: 'No students currently outside',
                    message: 'All hostel residents with approved gate passes have either returned or are in campus.',
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (request.departureAt != null)
                            Text(
                              'Left gate: ${request.formattedDepartureAt}',
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                            )
                          else
                            const SizedBox(),
                          ElevatedButton.icon(
                            onPressed: () => _handleMarkReturned(request),
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                            label: const Text('Mark Returned'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.statusReturned,
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
