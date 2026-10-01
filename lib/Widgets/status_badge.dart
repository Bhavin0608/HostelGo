import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/constants.dart';

class StatusBadge extends StatelessWidget {
  final String status;
  final bool isOverdue;
  final bool isLarge;

  const StatusBadge({
    super.key,
    required this.status,
    this.isOverdue = false,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor;
    Color bgColor;
    IconData icon;
    String label;

    if (isOverdue && status == AppConstants.statusOutside) {
      textColor = AppColors.statusOverdue;
      bgColor = AppColors.statusOverdueBg;
      icon = Icons.warning_amber_rounded;
      label = 'OVERDUE';
    } else {
      switch (status.toLowerCase()) {
        case AppConstants.statusApproved:
          textColor = AppColors.statusApproved;
          bgColor = AppColors.statusApprovedBg;
          icon = Icons.check_circle_rounded;
          label = 'APPROVED';
          break;
        case AppConstants.statusRejected:
          textColor = AppColors.statusRejected;
          bgColor = AppColors.statusRejectedBg;
          icon = Icons.cancel_rounded;
          label = 'REJECTED';
          break;
        case AppConstants.statusOutside:
          textColor = AppColors.statusOutside;
          bgColor = AppColors.statusOutsideBg;
          icon = Icons.directions_walk_rounded;
          label = 'OUTSIDE';
          break;
        case AppConstants.statusReturned:
          textColor = AppColors.statusReturned;
          bgColor = AppColors.statusReturnedBg;
          icon = Icons.check_circle_rounded;
          label = 'RETURNED';
          break;
        case AppConstants.statusPending:
        default:
          textColor = AppColors.statusPending;
          bgColor = AppColors.statusPendingBg;
          icon = Icons.schedule_rounded;
          label = 'PENDING';
          break;
      }
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 12 : 9,
        vertical: isLarge ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999), // Pill badge
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: isLarge ? 15 : 12,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w800,
              fontSize: isLarge ? 12 : 10.5,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
