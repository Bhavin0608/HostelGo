import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class DashboardStatCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData? icon;
  final Color? countColor;
  final bool isAccent;
  final VoidCallback? onTap;

  const DashboardStatCard({
    super.key,
    required this.title,
    required this.count,
    this.icon,
    this.countColor,
    this.isAccent = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isAccent ? AppColors.primary : AppColors.surface;
    final titleColor = isAccent ? Colors.white.withAlpha((0.85 * 255).round()) : AppColors.textMuted;
    final numberColor = isAccent ? Colors.white : (countColor ?? AppColors.textPrimary);
    final borderColor = isAccent ? Colors.transparent : AppColors.border;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: isAccent ? AppColors.heroShadow : AppColors.shadowSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (icon != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      icon,
                      color: isAccent ? Colors.white : (countColor ?? AppColors.primary),
                      size: 20,
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: isAccent ? Colors.white54 : AppColors.textMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
              Text(
                count,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: numberColor,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: titleColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
