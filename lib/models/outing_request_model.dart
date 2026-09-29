import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../utils/constants.dart';

class OutingRequestModel {
  final String id;
  final String requestId;
  final String studentUid;
  final String studentName;
  final String studentId;
  final String hostel;
  final String roomNumber;
  final DateTime outingDate;
  final DateTime leavingTime;
  final DateTime expectedReturnTime;
  final String destination;
  final String purpose;
  final String remarks;
  final String status;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final DateTime? departureAt;
  final DateTime? returnedAt;
  final String? processedBy;

  OutingRequestModel({
    required this.id,
    required this.requestId,
    required this.studentUid,
    required this.studentName,
    required this.studentId,
    required this.hostel,
    required this.roomNumber,
    required this.outingDate,
    required this.leavingTime,
    required this.expectedReturnTime,
    required this.destination,
    required this.purpose,
    this.remarks = '',
    required this.status,
    required this.createdAt,
    this.approvedAt,
    this.rejectedAt,
    this.rejectionReason,
    this.departureAt,
    this.returnedAt,
    this.processedBy,
  });

  // Status checks
  bool get isPending => status == AppConstants.statusPending;
  bool get isApproved => status == AppConstants.statusApproved;
  bool get isRejected => status == AppConstants.statusRejected;
  bool get isOutside => status == AppConstants.statusOutside;
  bool get isReturned => status == AppConstants.statusReturned;

  // Active check (for conflict prevention)
  bool get isActive => isPending || isApproved || isOutside;

  // Overdue check
  bool get isOverdue {
    if (!isOutside) return false;
    return DateTime.now().isAfter(expectedReturnTime);
  }

  // Multi-day Leave Helpers
  bool get isMultiDay {
    return leavingTime.year != expectedReturnTime.year ||
        leavingTime.month != expectedReturnTime.month ||
        leavingTime.day != expectedReturnTime.day;
  }

  int get durationDays {
    final start = DateTime(leavingTime.year, leavingTime.month, leavingTime.day);
    final end = DateTime(expectedReturnTime.year, expectedReturnTime.month, expectedReturnTime.day);
    final diff = end.difference(start).inDays;
    return diff <= 0 ? 1 : diff + 1;
  }

  String get durationLabel {
    if (!isMultiDay) return 'Same Day (Local)';
    final days = durationDays;
    return '$days Days (Home / Multi-Day)';
  }

  // Formatting helpers
  String get formattedOutingDate => DateFormat('dd MMM yyyy').format(outingDate);
  String get formattedReturnDate => DateFormat('dd MMM yyyy').format(expectedReturnTime);
  String get formattedLeavingTime => DateFormat('hh:mm a').format(leavingTime);
  String get formattedReturnTime => DateFormat('hh:mm a').format(expectedReturnTime);
  String get formattedLeavingDateTime => DateFormat('dd MMM yyyy, hh:mm a').format(leavingTime);
  String get formattedReturnDateTime => DateFormat('dd MMM yyyy, hh:mm a').format(expectedReturnTime);
  String get formattedCreatedAt => DateFormat('dd MMM yyyy, hh:mm a').format(createdAt);
  String get formattedApprovedAt => approvedAt != null ? DateFormat('dd MMM yyyy, hh:mm a').format(approvedAt!) : '-';
  String get formattedRejectedAt => rejectedAt != null ? DateFormat('dd MMM yyyy, hh:mm a').format(rejectedAt!) : '-';
  String get formattedDepartureAt => departureAt != null ? DateFormat('dd MMM yyyy, hh:mm a').format(departureAt!) : '-';
  String get formattedReturnedAt => returnedAt != null ? DateFormat('dd MMM yyyy, hh:mm a').format(returnedAt!) : '-';

  String get formattedTimeSummary {
    if (!isMultiDay) {
      return '$formattedLeavingTime – $formattedReturnTime';
    }
    return '${DateFormat('dd MMM, hh:mm a').format(leavingTime)} → ${DateFormat('dd MMM, hh:mm a').format(expectedReturnTime)} ($durationDays Days)';
  }

  String get displayRequestId => requestId.isNotEmpty ? requestId : 'REQ-${id.substring(0, id.length > 8 ? 8 : id.length).toUpperCase()}';

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

  factory OutingRequestModel.fromMap(Map<String, dynamic> map, String documentId) {
    return OutingRequestModel(
      id: documentId,
      requestId: map['requestId'] as String? ?? 'REQ-${documentId.substring(0, documentId.length > 8 ? 8 : documentId.length).toUpperCase()}',
      studentUid: map['studentUid'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      studentId: map['studentId'] as String? ?? '',
      hostel: map['hostel'] as String? ?? '',
      roomNumber: map['roomNumber'] as String? ?? '',
      outingDate: _parseDate(map['outingDate']),
      leavingTime: _parseDate(map['leavingTime']),
      expectedReturnTime: _parseDate(map['expectedReturnTime']),
      destination: map['destination'] as String? ?? '',
      purpose: map['purpose'] as String? ?? '',
      remarks: map['remarks'] as String? ?? '',
      status: map['status'] as String? ?? AppConstants.statusPending,
      createdAt: _parseDate(map['createdAt']),
      approvedAt: _parseNullableDate(map['approvedAt']),
      rejectedAt: _parseNullableDate(map['rejectedAt']),
      rejectionReason: map['rejectionReason'] as String?,
      departureAt: _parseNullableDate(map['departureAt']),
      returnedAt: _parseNullableDate(map['returnedAt']),
      processedBy: map['processedBy'] as String?,
    );
  }

  factory OutingRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return OutingRequestModel.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'studentUid': studentUid,
      'studentName': studentName,
      'studentId': studentId,
      'hostel': hostel,
      'roomNumber': roomNumber,
      'outingDate': Timestamp.fromDate(outingDate),
      'leavingTime': Timestamp.fromDate(leavingTime),
      'expectedReturnTime': Timestamp.fromDate(expectedReturnTime),
      'destination': destination,
      'purpose': purpose,
      'remarks': remarks,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      if (approvedAt != null) 'approvedAt': Timestamp.fromDate(approvedAt!),
      if (rejectedAt != null) 'rejectedAt': Timestamp.fromDate(rejectedAt!),
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (departureAt != null) 'departureAt': Timestamp.fromDate(departureAt!),
      if (returnedAt != null) 'returnedAt': Timestamp.fromDate(returnedAt!),
      if (processedBy != null) 'processedBy': processedBy,
    };
  }
}
