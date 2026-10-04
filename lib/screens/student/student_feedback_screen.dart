import 'package:flutter/material.dart';
import '../../models/feedback_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/validators.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/empty_state_view.dart';

class StudentFeedbackScreen extends StatefulWidget {
  final UserModel student;
  final int initialTabIndex;

  const StudentFeedbackScreen({
    super.key,
    required this.student,
    this.initialTabIndex = 0,
  });

  @override
  State<StudentFeedbackScreen> createState() => _StudentFeedbackScreenState();
}

class _StudentFeedbackScreenState extends State<StudentFeedbackScreen>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;

  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  int _rating = 5;
  String _selectedCategory = AppConstants.feedbackCategories.first;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 5:
        return 'Excellent ⭐⭐⭐⭐⭐';
      case 4:
        return 'Good ⭐⭐⭐⭐';
      case 3:
        return 'Average ⭐⭐⭐';
      case 2:
        return 'Poor ⭐⭐';
      case 1:
        return 'Very Bad ⭐';
      default:
        return '';
    }
  }

  Color _getRatingColor(int rating) {
    if (rating >= 4) return AppColors.statusApproved;
    if (rating == 3) return AppColors.statusPending;
    return AppColors.statusRejected;
  }

  Future<void> _handleSubmitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _firestoreService.submitFeedback(
        studentUid: widget.student.uid,
        studentName: widget.student.name,
        studentId: widget.student.studentId,
        hostel: widget.student.hostel,
        roomNumber: widget.student.roomNumber,
        category: _selectedCategory,
        rating: _rating,
        subject: _subjectController.text,
        message: _messageController.text,
      );

      if (!mounted) return;

      _subjectController.clear();
      _messageController.clear();
      setState(() {
        _rating = 5;
        _selectedCategory = AppConstants.feedbackCategories.first;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback submitted successfully! Thank you for helping us improve.'),
          backgroundColor: AppColors.statusApproved,
        ),
      );

      // Switch to history tab
      _tabController.animateTo(1);
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
          _isSubmitting = false;
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
          'Feedback & Grievances',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Submit Feedback'),
            Tab(text: 'My Feedbacks'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSubmitTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 1: SUBMIT FEEDBACK FORM
  // -------------------------------------------------------------
  Widget _buildSubmitTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info Callout
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF99F6E4)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Icon(Icons.feedback_outlined, color: AppColors.primaryDark, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Share your suggestions, grievances, or experiences with outing permissions, gate security, or hostel amenities. Wardens review submissions in real time.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.primaryDark,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Main Form Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppColors.shadowSm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Experience Rating'),
                      const SizedBox(height: 4),

                      // Interactive Star Selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final starNum = index + 1;
                          final isSelected = starNum <= _rating;
                          return IconButton(
                            iconSize: 36,
                            onPressed: () => setState(() => _rating = starNum),
                            icon: Icon(
                              isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                              color: isSelected ? const Color(0xFFF59E0B) : AppColors.border,
                            ),
                          );
                        }),
                      ),
                      Center(
                        child: Text(
                          _getRatingLabel(_rating),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _getRatingColor(_rating),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Divider(height: 1, color: AppColors.border),
                      const SizedBox(height: 16),

                      _buildFieldLabel('Category'),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border, width: 1.5),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
                            items: AppConstants.feedbackCategories.map((cat) {
                              return DropdownMenuItem<String>(
                                value: cat,
                                child: Text(
                                  cat,
                                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedCategory = val);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildFieldLabel('Subject / Title'),
                      TextFormField(
                        controller: _subjectController,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.next,
                        validator: (v) => Validators.validateRequired(v, 'Subject'),
                        decoration: const InputDecoration(
                          hintText: 'e.g. Quick gate pass verification, Water issue...',
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildFieldLabel('Detailed Feedback / Remarks'),
                      TextFormField(
                        controller: _messageController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: 4,
                        validator: (v) => Validators.validateRequired(v, 'Feedback message'),
                        decoration: const InputDecoration(
                          hintText: 'Describe your feedback, suggestion, or issue in detail...',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Submit Button
                CustomButton(
                  text: 'Submit Feedback',
                  icon: Icons.send_rounded,
                  onPressed: _handleSubmitFeedback,
                  isLoading: _isSubmitting,
                  type: ButtonType.primary,
                  height: 48,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 2: MY FEEDBACKS HISTORY
  // -------------------------------------------------------------
  Widget _buildHistoryTab() {
    return StreamBuilder<List<FeedbackModel>>(
      stream: _firestoreService.getStudentFeedbacksStream(widget.student.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final feedbacks = snapshot.data ?? [];

        if (feedbacks.isEmpty) {
          return EmptyStateView(
            icon: Icons.rate_review_outlined,
            title: 'No feedback submitted yet',
            message: 'Your suggestions and grievances will appear here once submitted.',
            buttonText: 'Submit Feedback',
            buttonIcon: Icons.add_rounded,
            onButtonPressed: () => _tabController.animateTo(0),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          itemCount: feedbacks.length,
          itemBuilder: (context, index) {
            final fb = feedbacks[index];
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
                  // Top Row: Category + Status Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          fb.category,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: fb.isReviewed ? AppColors.statusApprovedBg : AppColors.statusPendingBg,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              fb.isReviewed ? Icons.check_circle_rounded : Icons.access_time_rounded,
                              size: 12,
                              color: fb.isReviewed ? AppColors.statusApproved : AppColors.statusPending,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              fb.isReviewed ? 'REVIEWED' : 'SUBMITTED',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: fb.isReviewed ? AppColors.statusApproved : AppColors.statusPending,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Rating & Subject
                  Row(
                    children: [
                      Row(
                        children: List.generate(5, (starIdx) {
                          return Icon(
                            starIdx < fb.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 16,
                            color: starIdx < fb.rating ? const Color(0xFFF59E0B) : AppColors.border,
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '· ${fb.formattedCreatedAt}',
                        style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  Text(
                    fb.subject,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),

                  Text(
                    fb.message,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),

                  // Warden Response Box if Reviewed
                  if (fb.wardenReply != null && fb.wardenReply!.isNotEmpty) ...[
                    const SizedBox(height: 12),
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
                          Row(
                            children: const [
                              Icon(Icons.verified_user_rounded, size: 14, color: AppColors.primary),
                              SizedBox(width: 6),
                              Text(
                                'Warden Response',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fb.wardenReply!,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textPrimary,
                              height: 1.35,
                            ),
                          ),
                          if (fb.reviewedAt != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Reviewed on ${fb.formattedReviewedAt}',
                              style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
      ),
    );
  }
}
