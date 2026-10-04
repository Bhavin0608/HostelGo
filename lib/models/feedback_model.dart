import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';

class FeedbackModel {
  final String id;
  final String studentUid;
  final String studentName;
  final String studentId;
  final String hostel;
  final String roomNumber;
  final String category;
  final int rating; // 1 to 5 stars
  final String subject;
  final String message;
  final DateTime createdAt;
  final String status; // 'submitted', 'reviewed'
  final String? wardenReply;
  final DateTime? reviewedAt;

  FeedbackModel({
    required this.id,
    required this.studentUid,
    required this.studentName,
    required this.studentId,
    required this.hostel,
    required this.roomNumber,
    required this.category,
    required this.rating,
    required this.subject,
    required this.message,
    required this.createdAt,
    this.status = AppConstants.feedbackSubmitted,
    this.wardenReply,
    this.reviewedAt,
  });

  bool get isReviewed => status == AppConstants.feedbackReviewed;
  bool get isSubmitted => status == AppConstants.feedbackSubmitted;

  String get formattedCreatedAt => DateFormat('dd MMM yyyy, hh:mm a').format(createdAt);
  String get formattedReviewedAt => reviewedAt != null ? DateFormat('dd MMM yyyy, hh:mm a').format(reviewedAt!) : '-';
  String get formattedDate => formattedCreatedAt;
  String get formattedReviewedDate => formattedReviewedAt;

  FeedbackModel copyWith({
    String? id,
    String? studentUid,
    String? studentName,
    String? studentId,
    String? hostel,
    String? roomNumber,
    String? category,
    int? rating,
    String? subject,
    String? message,
    DateTime? createdAt,
    String? status,
    String? wardenReply,
    DateTime? reviewedAt,
  }) {
    return FeedbackModel(
      id: id ?? this.id,
      studentUid: studentUid ?? this.studentUid,
      studentName: studentName ?? this.studentName,
      studentId: studentId ?? this.studentId,
      hostel: hostel ?? this.hostel,
      roomNumber: roomNumber ?? this.roomNumber,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      wardenReply: wardenReply ?? this.wardenReply,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }

  static DateTime _parseDate(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    return DateTime.now();
  }

  static DateTime? _parseNullableDate(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val);
    return null;
  }

  factory FeedbackModel.fromMap(Map<String, dynamic> map, String documentId) {
    return FeedbackModel(
      id: documentId,
      studentUid: map['studentUid'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      hostel: map['hostel'] as String? ?? '',
      roomNumber: map['roomNumber'] as String? ?? '',
      category: map['category'] as String? ?? 'General Suggestion / Grievance',
      rating: (map['rating'] as num?)?.toInt() ?? 5,
      subject: map['subject'] as String? ?? '',
      message: map['message'] as String? ?? '',
      createdAt: _parseDate(map['createdAt']),
      status: map['status'] as String? ?? AppConstants.feedbackSubmitted,
      wardenReply: map['wardenReply'] as String?,
      reviewedAt: _parseNullableDate(map['reviewedAt']),
    );
  }

  factory FeedbackModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FeedbackModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'studentUid': studentUid,
      'studentName': studentName,
      'studentId': studentId,
      'hostel': hostel,
      'roomNumber': roomNumber,
      'category': category,
      'rating': rating,
      'subject': subject,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
      if (wardenReply != null) 'wardenReply': wardenReply,
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
    };
  }
}
