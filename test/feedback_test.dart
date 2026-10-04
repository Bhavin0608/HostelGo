import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_gate_pass/models/feedback_model.dart';
import 'package:hostel_gate_pass/utils/constants.dart';

void main() {
  group('FeedbackModel Tests', () {
    final testDate = DateTime(2026, 9, 29, 14, 30);

    test('FeedbackModel initialization and properties work correctly', () {
      final feedback = FeedbackModel(
        id: 'fb_101',
        studentUid: 'student_99',
        studentName: 'Aman Patel',
        studentId: '23IT045',
        hostel: 'Boys Hostel B',
        roomNumber: '312',
        rating: 5,
        category: 'Outing & Gate Process',
        subject: 'Smooth gate exit experience',
        message: 'The QR code scanning was very fast and warden approval came within 5 minutes.',
        status: AppConstants.feedbackSubmitted,
        createdAt: testDate,
      );

      expect(feedback.id, 'fb_101');
      expect(feedback.studentUid, 'student_99');
      expect(feedback.studentName, 'Aman Patel');
      expect(feedback.rating, 5);
      expect(feedback.category, 'Outing & Gate Process');
      expect(feedback.isSubmitted, isTrue);
      expect(feedback.isReviewed, isFalse);
      expect(feedback.wardenReply, isNull);
      expect(feedback.reviewedAt, isNull);
    });

    test('Serialization toMap and copyWith work properly', () {
      final feedback = FeedbackModel(
        id: 'fb_102',
        studentUid: 'student_100',
        studentName: 'Priya Shah',
        studentId: '23CE012',
        hostel: 'Girls Hostel D',
        roomNumber: '105',
        rating: 4,
        category: 'Hostel Facilities & Rooms',
        subject: 'Wi-Fi connectivity in study room',
        message: 'Network speed is low after 10 PM.',
        status: AppConstants.feedbackSubmitted,
        createdAt: testDate,
      );

      final map = feedback.toMap();
      expect(map['studentUid'], 'student_100');
      expect(map['studentName'], 'Priya Shah');
      expect(map['rating'], 4);
      expect(map['category'], 'Hostel Facilities & Rooms');
      expect(map['status'], AppConstants.feedbackSubmitted);

      final reviewedFeedback = feedback.copyWith(
        status: AppConstants.feedbackReviewed,
        wardenReply: 'IT department has been notified to inspect router.',
        reviewedAt: DateTime(2026, 9, 29, 16, 0),
      );

      expect(reviewedFeedback.isReviewed, isTrue);
      expect(reviewedFeedback.isSubmitted, isFalse);
      expect(reviewedFeedback.wardenReply, 'IT department has been notified to inspect router.');
      expect(reviewedFeedback.id, feedback.id);
    });

    test('Formatted date getters return non-empty readable strings', () {
      final feedback = FeedbackModel(
        id: 'fb_103',
        studentUid: 'student_101',
        studentName: 'Devang Joshi',
        studentId: '23CS088',
        hostel: 'Boys Hostel A',
        roomNumber: '201',
        rating: 3,
        category: 'Gate Security & Timing',
        subject: 'Guard verification delay',
        message: 'Took longer than usual to verify pass.',
        status: AppConstants.feedbackReviewed,
        createdAt: testDate,
        reviewedAt: DateTime(2026, 9, 29, 15, 0),
      );

      expect(feedback.formattedDate, isNotEmpty);
      expect(feedback.formattedReviewedDate, isNotEmpty);
      expect(feedback.formattedCreatedAt, isNotEmpty);
      expect(feedback.formattedReviewedAt, isNotEmpty);
    });
  });

  group('Feedback Constants Tests', () {
    test('Feedback constants contain all expected categories and statuses', () {
      expect(AppConstants.collectionFeedbacks, 'student_feedbacks');
      expect(AppConstants.feedbackSubmitted, 'submitted');
      expect(AppConstants.feedbackReviewed, 'reviewed');

      expect(AppConstants.feedbackCategories, contains('Outing & Gate Process'));
      expect(AppConstants.feedbackCategories, contains('Gate Security & Timing'));
      expect(AppConstants.feedbackCategories, contains('Warden & Administration Support'));
      expect(AppConstants.feedbackCategories, contains('Hostel Facilities & Rooms'));
      expect(AppConstants.feedbackCategories, contains('App Experience & Technical'));
      expect(AppConstants.feedbackCategories, contains('General Suggestion / Grievance'));
      expect(AppConstants.feedbackCategories.length, 6);
    });
  });
}
