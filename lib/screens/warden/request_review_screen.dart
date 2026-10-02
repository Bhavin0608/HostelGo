import 'package:flutter/material.dart';
import '../../models/outing_request_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/status_badge.dart';

class RequestReviewScreen extends StatefulWidget {
  final String requestId;

  const RequestReviewScreen({
    super.key,
    required this.requestId,
  });

  @override
  State<RequestReviewScreen> createState() => _RequestReviewScreenState();
}

class _RequestReviewScreenState extends State<RequestReviewScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  bool _isProcessing = false;

  Future<void> _handleApprove(OutingRequestModel request) async {
    final warden = _authService.currentUser;
    if (warden == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Approve Request', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
          'Approve outing request for ${request.studentName} (${request.studentId})?\n\n'
          'The student will receive an approved digital gate pass immediately.',
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
              backgroundColor: AppColors.statusApproved,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await _firestoreService.approveRequest(
        requestId: request.id,
        wardenUid: warden.uid,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Outing request for ${request.studentName} APPROVED.'),
          backgroundColor: AppColors.statusApproved,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.statusRejected,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleReject(OutingRequestModel request) async {
    final warden = _authService.currentUser;
    if (warden == null) return;

    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reject Outing Request', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Provide the reason for rejecting ${request.studentName}\'s outing request:',
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: reasonController,
                maxLines: 3,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Rejection reason is required';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  hintText: 'e.g. Incomplete permissions / Late hours / Academic restriction',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusRejectedBg,
              foregroundColor: AppColors.statusRejected,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Reject Request', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await _firestoreService.rejectRequest(
        requestId: request.id,
        wardenUid: warden.uid,
        reason: reasonController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Outing request for ${request.studentName} REJECTED.'),
          backgroundColor: AppColors.statusRejected,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.statusRejected,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Review Request',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<OutingRequestModel?>(
        stream: _firestoreService.getRequestStream(widget.requestId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final request = snapshot.data;
          if (request == null) {
            return const Center(
              child: Text(
                'Request record not found.',
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
                    // Top Request Info Card
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
                                  request.studentName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${request.studentId} · ${request.displayRequestId}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StatusBadge(status: request.status, isLarge: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Student Details Panel
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
                        _buildKv('Submitted At', request.formattedCreatedAt),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Approval Action Buttons (from CSS .btn-row: .btn-reject + .btn-approve)
                    if (request.isPending) ...[
                      Row(
                        children: [
                          Expanded(
                            child: CustomButton(
                              text: 'Reject',
                              onPressed: _isProcessing ? null : () => _handleReject(request),
                              type: ButtonType.danger,
                              height: 48,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CustomButton(
                              text: 'Approve',
                              onPressed: _isProcessing ? null : () => _handleApprove(request),
                              type: ButtonType.approve,
                              height: 48,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSubtle,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.textMuted),
                            const SizedBox(width: 8),
                            Text(
                              'This request has been ${request.status.toUpperCase()}.',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
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
}
