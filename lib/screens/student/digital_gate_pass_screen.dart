import 'package:flutter/material.dart';
import '../../models/outing_request_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/status_badge.dart';

class DigitalGatePassScreen extends StatelessWidget {
  final String requestId;

  const DigitalGatePassScreen({
    super.key,
    required this.requestId,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Digital Gate Pass',
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
                'Gate pass record not found.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    // Digital Gate Pass Card
                    _buildGatePassCard(context, request),
                    const SizedBox(height: 20),

                    // Security Verification Notice
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF99F6E4)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            color: AppColors.primaryDark,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Hostel Gate Verification',
                                  style: TextStyle(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Present this digital pass to the security guard at the hostel main gate. Gate staff will verify your student ID and record departure/entry.',
                                  style: TextStyle(
                                    color: AppColors.secondary,
                                    fontSize: 12.5,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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

  Widget _buildGatePassCard(BuildContext context, OutingRequestModel request) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.shadow,
      ),
      child: Column(
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const AppLogo(
                  size: 38,
                  isDarkBackground: true,
                  borderRadius: 10,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.isMultiDay ? 'MULTI-DAY HOSTEL GATE PASS' : 'DIGITAL HOSTEL GATE PASS',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'PASS ID: ${request.displayRequestId}',
                        style: const TextStyle(
                          color: Color(0xFF99F6E4),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Main Pass Body
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Student Row
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        gradient: AppColors.avatarGradient,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          request.studentName.isNotEmpty ? request.studentName[0].toUpperCase() : 'S',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.studentName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${request.studentId} · ${request.hostel} (${request.roomNumber})',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Status row
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pass Status',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
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
                const SizedBox(height: 16),

                // Key-Value rows
                _buildKvRow('Destination', request.destination),
                _buildKvRow('Purpose', request.purpose),
                _buildKvRow('Leave Type', request.durationLabel),
                if (!request.isMultiDay) ...[
                  _buildKvRow('Date', request.formattedOutingDate),
                  _buildKvRow('Out Time', request.formattedLeavingTime),
                  _buildKvRow('In Time', request.formattedReturnTime),
                ] else ...[
                  _buildKvRow('Departure', request.formattedLeavingDateTime),
                  _buildKvRow('Expected Return', request.formattedReturnDateTime),
                ],
                if (request.remarks.isNotEmpty) _buildKvRow('Remarks / Contact', request.remarks),

                const SizedBox(height: 16),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 14),

                // Approval / Authority Verification
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: AppColors.statusApproved, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Verified by Hostel Warden',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.statusApproved,
                            ),
                          ),
                          Text(
                            'Approved: ${request.formattedApprovedAt}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                if (request.departureAt != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Gate Departure: ${request.formattedDepartureAt}',
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],

                if (request.returnedAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Gate Return: ${request.formattedReturnedAt}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.statusReturned),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKvRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13.5, color: AppColors.textMuted),
          ),
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
