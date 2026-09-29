import 'package:flutter/material.dart';

class AppColors {
  // Brand Palette from Design
  static const Color primary = Color(0xFF0F766E); // Teal-700
  static const Color primaryDark = Color(0xFF115E59); // Teal-800
  static const Color primarySoft = Color(0xFFCCFBF1); // Teal-100 / Mint Soft
  static const Color secondary = Color(0xFF134E4A); // Teal-900

  // Neutral & Surfaces
  static const Color background = Color(0xFFF3F4F6); // Gray-100
  static const Color surface = Color(0xFFFFFFFF); // Pure White
  static const Color surfaceSubtle = Color(0xFFF9FAFB); // Gray-50
  static const Color textPrimary = Color(0xFF111827); // Gray-900
  static const Color textSecondary = Color(0xFF4B5563); // Gray-600
  static const Color textMuted = Color(0xFF6B7280); // Gray-500
  static const Color border = Color(0xFFE5E7EB); // Gray-200

  // Status Colors (Soft Backgrounds + Strong Labels)
  static const Color statusPending = Color(0xFFB45309); // Amber-700
  static const Color statusPendingBg = Color(0xFFFEF3C7); // Amber-100

  static const Color statusApproved = Color(0xFF047857); // Emerald-700
  static const Color statusApprovedBg = Color(0xFFD1FAE5); // Emerald-100

  static const Color statusRejected = Color(0xFFB91C1C); // Red-700
  static const Color statusRejectedBg = Color(0xFFFEE2E2); // Red-100

  static const Color statusOutside = Color(0xFF1D4ED8); // Blue-700
  static const Color statusOutsideBg = Color(0xFFDBEAFE); // Blue-100

  static const Color statusReturned = Color(0xFF047857); // Emerald-700
  static const Color statusReturnedBg = Color(0xFFD1FAE5); // Emerald-100

  static const Color statusOverdue = Color(0xFFB91C1C); // Red-700
  static const Color statusOverdueBg = Color(0xFFFEE2E2); // Red-100

  static const Color statusCancelled = Color(0xFF4B5563); // Gray-600
  static const Color statusCancelledBg = Color(0xFFE5E7EB); // Gray-200

  // Soft Shadows
  static const List<BoxShadow> shadow = [
    BoxShadow(
      color: Color(0x14111827), // rgba(17, 24, 39, 0.08)
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Color(0x0F111827), // rgba(17, 24, 39, 0.06)
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> heroShadow = [
    BoxShadow(
      color: Color(0x380F766E), // rgba(15, 118, 110, 0.22)
      blurRadius: 28,
      offset: Offset(0, 12),
    ),
  ];

  // Gradients
  static const LinearGradient avatarGradient = LinearGradient(
    colors: [Color(0xFF14B8A6), Color(0xFF0F766E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF0F766E), Color(0xFF115E59)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gatePassGradient = LinearGradient(
    colors: [Color(0xFF111827), Color(0xFF1F2937), Color(0xFF115E59)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
