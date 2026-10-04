import 'package:flutter/material.dart';
import '../../models/feedback_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/empty_state_view.dart';

class WardenFeedbacksScreen extends StatefulWidget {
  const WardenFeedbacksScreen({super.key});

  @override
  State<WardenFeedbacksScreen> createState() => _WardenFeedbacksScreenState();
}

class _WardenFeedbacksScreenState extends State<WardenFeedbacksScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showReplyDialog(FeedbackModel feedback) {
    final replyController = TextEditingController(text: feedback.wardenReply ?? '');
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalSheetContext) => StatefulBuilder(
        builder: (dialogContext, setModalState) {
          return Container(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(dialogContext).viewInsets.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Review & Reply Feedback',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                        onPressed: () => Navigator.pop(modalSheetContext),
                      ),
                    ],
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: 14),

                  // Feedback context snapshot
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${feedback.studentName} (${feedback.studentId}) · ${feedback.hostel} (${feedback.roomNumber})',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          feedback.subject,
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          feedback.message,
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Warden Response / Administrative Remarks',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: replyController,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Enter official reply or action taken for the student...',
                    ),
                  ),
                  const SizedBox(height: 20),

                  CustomButton(
                    text: feedback.isReviewed ? 'Update Response' : 'Mark as Reviewed & Send Reply',
                    icon: Icons.check_circle_outline_rounded,
                    isLoading: isSaving,
                    type: ButtonType.approve,
                    height: 46,
                    onPressed: () async {
                      setModalState(() => isSaving = true);
                      try {
                        await _firestoreService.markFeedbackReviewed(
                          feedbackId: feedback.id,
                          wardenReply: replyController.text,
                        );
                        if (modalSheetContext.mounted) {
                          Navigator.pop(modalSheetContext);
                        }
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Feedback acknowledged and response saved.'),
                              backgroundColor: AppColors.statusApproved,
                            ),
                          );
                        }
                      } catch (e) {
                        setModalState(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString()), backgroundColor: AppColors.statusRejected),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['All', ...AppConstants.feedbackCategories];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Student Feedbacks',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<FeedbackModel>>(
        stream: _firestoreService.getAllFeedbacksStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final allFeedbacks = snapshot.data ?? [];
          final query = _searchController.text.trim().toLowerCase();

          // Metrics calculation
          final totalCount = allFeedbacks.length;
          final reviewedCount = allFeedbacks.where((f) => f.isReviewed).length;
          final pendingCount = totalCount - reviewedCount;
          final avgRating = totalCount > 0
              ? (allFeedbacks.map((f) => f.rating).reduce((a, b) => a + b) / totalCount)
              : 0.0;

          // Filter by category and search
          final filtered = allFeedbacks.where((fb) {
            if (_selectedCategory != 'All' && fb.category != _selectedCategory) {
              return false;
            }
            if (query.isNotEmpty) {
              final matchName = fb.studentName.toLowerCase().contains(query);
              final matchId = fb.studentId.toLowerCase().contains(query);
              final matchHostel = fb.hostel.toLowerCase().contains(query);
              final matchSubj = fb.subject.toLowerCase().contains(query);
              final matchMsg = fb.message.toLowerCase().contains(query);
              return matchName || matchId || matchHostel || matchSubj || matchMsg;
            }
            return true;
          }).toList();

          return Column(
            children: [
              // Metrics & Filter Bar
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  children: [
                    // Summary Stats Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Avg Rating',
                            value: totalCount > 0 ? '${avgRating.toStringAsFixed(1)} ★' : 'N/A',
                            color: const Color(0xFFF59E0B),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Total Feedbacks',
                            value: '$totalCount',
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildMetricCard(
                            title: 'Need Reply',
                            value: '$pendingCount',
                            color: pendingCount > 0 ? AppColors.statusPending : AppColors.statusApproved,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Search field
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search student, ID, subject, keyword...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
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
                    const SizedBox(height: 10),

                    // Category chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categories.map((cat) {
                          final isSelected = _selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedCategory = cat),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary : AppColors.surface,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : AppColors.border,
                                  ),
                                ),
                                child: Text(
                                  cat,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected ? Colors.white : AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),

              // Feedback list
              Expanded(
                child: filtered.isEmpty
                    ? const EmptyStateView(
                        icon: Icons.rate_review_outlined,
                        title: 'No feedbacks found',
                        message: 'No student feedbacks match the selected filter criteria.',
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final fb = filtered[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
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
                                // Student Identity + Status Pill
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
                                          fb.studentName.isNotEmpty ? fb.studentName[0].toUpperCase() : 'S',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            fb.studentName,
                                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.textPrimary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '${fb.studentId} · ${fb.hostel} (${fb.roomNumber})',
                                            style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                      decoration: BoxDecoration(
                                        color: fb.isReviewed ? AppColors.statusApprovedBg : AppColors.statusPendingBg,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        fb.isReviewed ? 'REVIEWED' : 'NEEDS REPLY',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: fb.isReviewed ? AppColors.statusApproved : AppColors.statusPending,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                const Divider(height: 1, color: AppColors.border),
                                const SizedBox(height: 10),

                                // Category & Rating Stars
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.primarySoft,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        fb.category,
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primaryDark),
                                      ),
                                    ),
                                    Row(
                                      children: List.generate(5, (starIdx) {
                                        return Icon(
                                          starIdx < fb.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                                          size: 15,
                                          color: starIdx < fb.rating ? const Color(0xFFF59E0B) : AppColors.border,
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),

                                Text(
                                  fb.subject,
                                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  fb.message,
                                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.35),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  fb.formattedCreatedAt,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                ),

                                // Warden response if any
                                if (fb.wardenReply != null && fb.wardenReply!.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceSubtle,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: const [
                                            Icon(Icons.reply_rounded, size: 13, color: AppColors.primary),
                                            SizedBox(width: 4),
                                            Text('Warden Response', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primaryDark)),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(fb.wardenReply!, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 10),
                                // Reply / Acknowledge Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 36,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showReplyDialog(fb),
                                    icon: Icon(fb.isReviewed ? Icons.edit_note_rounded : Icons.reply_rounded, size: 16),
                                    label: Text(fb.isReviewed ? 'Edit Warden Response' : 'Reply / Acknowledge Feedback'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primaryDark,
                                      side: const BorderSide(color: Color(0xFF99F6E4)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 1),
          Text(title, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textMuted), maxLines: 1),
        ],
      ),
    );
  }
}
