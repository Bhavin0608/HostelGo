import 'package:flutter/material.dart';
import '../../models/outing_request_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/status_badge.dart';
import '../warden/request_review_screen.dart';
import 'digital_gate_pass_screen.dart';

class RequestDetailsScreen extends StatelessWidget {
  final String requestId;
  final bool isWarden;

  const RequestDetailsScreen({
    super.key,
    required this.requestId,
    this.isWarden = false,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Request Details',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<OutingRequestModel?>(
        stream: firestoreService.getRequestStream(requestId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final request = snapshot.data;
          if (request == null) {
            return const Center(
              child: Text(
                'Outing request not found.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header card with Destination, student and status badge
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppColors.shadowSm,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request.destination,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  request.displayRequestId,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StatusBadge(
                            status: request.status,
                            isOverdue: request.isOverdue,
                            isLarge: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Digital Gate Pass banner (if approved/outside/returned)
                    if (!isWarden && (request.isApproved || request.isOutside || request.isReturned)) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: AppColors.heroGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AppColors.heroShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha((0.2 * 255).round()),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.badge_rounded, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Approved Gate Pass Ready',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Show this pass at the gate',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => DigitalGatePassScreen(requestId: request.id),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primaryDark,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              child: const Text('View Pass', style: TextStyle(fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Outing Details Panel
                    _buildPanel(
                      title: 'OUTING & LEAVE DETAILS',
                      children: [
                        _buildKv('Leave Type', request.durationLabel),
                        _buildKv('Destination', request.destination),
                        _buildKv('Purpose', request.purpose),
                        if (!request.isMultiDay) ...[
                          _buildKv('Date', request.formattedOutingDate),
                          _buildKv('Out Time', request.formattedLeavingTime),
                          _buildKv('In Time', request.formattedReturnTime),
                        ] else ...[
                          _buildKv('Departure', request.formattedLeavingDateTime),
                          _buildKv('Return By', request.formattedReturnDateTime),
                        ],
                        if (request.remarks.isNotEmpty) _buildKv('Remarks / Contact', request.remarks),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Student Information Panel
                    _buildPanel(
                      title: 'STUDENT DETAILS',
                      children: [
                        _buildKv('Name', request.studentName),
                        _buildKv('Student ID', request.studentId),
                        _buildKv('Hostel', request.hostel),
                        _buildKv('Room', request.roomNumber),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Timeline Panel
                    _buildPanel(
                      title: 'TIMELINE',
                      children: [
                        _buildTimelineStep(
                          title: 'Request Submitted',
                          time: request.formattedCreatedAt,
                          status: 'done',
                          isLast: false,
                        ),
                        _buildTimelineStep(
                          title: request.isRejected ? 'Request Rejected' : 'Warden Approval',
                          time: request.isRejected
                              ? (request.rejectionReason != null
                                  ? '${request.formattedRejectedAt}\nReason: ${request.rejectionReason}'
                                  : request.formattedRejectedAt)
                              : (request.approvedAt != null ? request.formattedApprovedAt : 'Waiting for review'),
                          status: request.isRejected ? 'fail' : (request.approvedAt != null ? 'done' : 'wait'),
                          isLast: false,
                        ),
                        _buildTimelineStep(
                          title: 'Gate Departure (Outside)',
                          time: request.departureAt != null ? request.formattedDepartureAt : 'Not departed',
                          status: request.departureAt != null ? 'done' : 'pending',
                          isLast: false,
                        ),
                        _buildTimelineStep(
                          title: 'Gate Return (Completed)',
                          time: request.returnedAt != null ? request.formattedReturnedAt : 'Not returned',
                          status: request.returnedAt != null ? 'done' : 'pending',
                          isLast: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Warden Actions
                    if (isWarden) ...[
                      if (request.isPending) ...[
                        CustomButton(
                          text: 'Review & Process Request',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => RequestReviewScreen(requestId: request.id),
                              ),
                            );
                          },
                          type: ButtonType.primary,
                          height: 48,
                        ),
                      ] else if (request.isApproved) ...[
                        CustomButton(
                          text: 'Mark Gate Departure (Outside)',
                          onPressed: () => _confirmMarkOutside(context, request, firestoreService),
                          type: ButtonType.primary,
                          icon: Icons.directions_walk_rounded,
                          height: 48,
                        ),
                      ] else if (request.isOutside) ...[
                        CustomButton(
                          text: 'Mark Returned to Hostel',
                          onPressed: () => _confirmMarkReturned(context, request, firestoreService),
                          type: ButtonType.approve,
                          icon: Icons.check_circle_rounded,
                          height: 48,
                        ),
                      ],
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPanel({required String title, required List<Widget> children}) {
    return Container(
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildKv(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13.5, color: AppColors.textMuted)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String time,
    required String status,
    required bool isLast,
  }) {
    Color dotBg;
    Color dotFg;
    IconData dotIcon;

    switch (status) {
      case 'done':
        dotBg = AppColors.statusApproved;
        dotFg = Colors.white;
        dotIcon = Icons.check;
        break;
      case 'wait':
        dotBg = AppColors.statusPendingBg;
        dotFg = AppColors.statusPending;
        dotIcon = Icons.access_time_rounded;
        break;
      case 'fail':
        dotBg = AppColors.statusRejected;
        dotFg = Colors.white;
        dotIcon = Icons.close;
        break;
      case 'pending':
      default:
        dotBg = AppColors.border;
        dotFg = AppColors.textMuted;
        dotIcon = Icons.circle;
        break;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: dotBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(dotIcon, size: 12, color: dotFg),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    height: 1.3,
                  ),
                ),
                if (!isLast) const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _confirmMarkOutside(BuildContext context, OutingRequestModel request, FirestoreService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Departure', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Mark student ${request.studentName} (${request.studentId}) as OUTSIDE the hostel?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await service.markOutside(requestId: request.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Student departure recorded successfully.'),
                      backgroundColor: AppColors.statusOutside,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: AppColors.statusRejected),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Confirm Outside', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmMarkReturned(BuildContext context, OutingRequestModel request, FirestoreService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Return', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Mark student ${request.studentName} (${request.studentId}) as RETURNED to the hostel?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await service.markReturned(requestId: request.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Student marked as RETURNED to hostel.'),
                      backgroundColor: AppColors.statusReturned,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: AppColors.statusRejected),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusReturned, foregroundColor: Colors.white),
            child: const Text('Confirm Returned', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
