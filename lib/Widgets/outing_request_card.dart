import 'package:flutter/material.dart';
import '../models/outing_request_model.dart';
import '../utils/app_colors.dart';
import 'status_badge.dart';

class OutingRequestCard extends StatelessWidget {
  final OutingRequestModel request;
  final VoidCallback onTap;
  final bool showStudentDetails;
  final Widget? trailingAction;

  const OutingRequestCard({
    super.key,
    required this.request,
    required this.onTap,
    this.showStudentDetails = false,
    this.trailingAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: request.isOverdue ? AppColors.statusOverdue.withAlpha((0.5 * 255).round()) : AppColors.border,
          width: request.isOverdue ? 1.5 : 1,
        ),
        boxShadow: AppColors.shadowSm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // If Warden, show student info row at the top
                if (showStudentDetails) ...[
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          gradient: AppColors.avatarGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            request.studentName.isNotEmpty ? request.studentName[0].toUpperCase() : 'S',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.studentName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${request.studentId} · ${request.hostel} (${request.roomNumber})',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(
                        status: request.status,
                        isOverdue: request.isOverdue,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 10),
                ],

                // Destination & Status badge (when student details not in header)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  request.destination,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                              if (request.isMultiDay) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySoft,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${request.durationDays}D LEAVE',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            request.purpose,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!showStudentDetails)
                      StatusBadge(
                        status: request.status,
                        isOverdue: request.isOverdue,
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                // Meta row: Date and Times
                if (!request.isMultiDay) ...[
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 5),
                      Text(
                        request.formattedOutingDate,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Text(' · ', style: TextStyle(color: AppColors.textMuted)),
                      const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        '${request.formattedLeavingTime} – ${request.formattedReturnTime}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      const Icon(Icons.date_range_rounded, size: 13, color: AppColors.primary),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          '${request.formattedLeavingDateTime} → ${request.formattedReturnDateTime}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],

                if (request.isRejected && request.rejectionReason != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Reason: ${request.rejectionReason}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.statusRejected,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],

                // Action button if present
                if (trailingAction != null) ...[
                  const SizedBox(height: 10),
                  trailingAction!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
