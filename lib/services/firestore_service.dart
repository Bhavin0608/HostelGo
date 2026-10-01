import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/outing_request_model.dart';
import '../utils/constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _requestsRef =>
      _firestore.collection(AppConstants.collectionRequests);

  // Generate readable Request ID (e.g., REQ-20260825-4821)
  String _generateRequestId(DateTime date) {
    final dateStr = DateFormat('yyyyMMdd').format(date);
    final randomNum = (1000 + Random().nextInt(9000)).toString();
    return 'REQ-$dateStr-$randomNum';
  }

  // Check if student already has an active request (pending, approved, or outside)
  Future<bool> hasActiveOutingRequest(String studentUid) async {
    try {
      final querySnapshot = await _requestsRef
          .where('studentUid', isEqualTo: studentUid)
          .where('status', whereIn: [
            AppConstants.statusPending,
            AppConstants.statusApproved,
            AppConstants.statusOutside,
          ])
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      // Fallback query if composite index is building or in basic mode
      final querySnapshot = await _requestsRef
          .where('studentUid', isEqualTo: studentUid)
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] as String?;
        if (status == AppConstants.statusPending ||
            status == AppConstants.statusApproved ||
            status == AppConstants.statusOutside) {
          return true;
        }
      }
      return false;
    }
  }

  // Get current active request for a student if any
  Stream<OutingRequestModel?> getActiveRequestStream(String studentUid) {
    return _requestsRef
        .where('studentUid', isEqualTo: studentUid)
        .snapshots()
        .map((snapshot) {
      for (var doc in snapshot.docs) {
        final request = OutingRequestModel.fromFirestore(doc);
        if (request.isActive) {
          return request;
        }
      }
      return null;
    });
  }

  // Create a new outing request with duplicate conflict check
  Future<OutingRequestModel> createOutingRequest({
    required String studentUid,
    required String studentName,
    required String studentId,
    required String hostel,
    required String roomNumber,
    required DateTime outingDate,
    required DateTime leavingTime,
    required DateTime expectedReturnTime,
    required String destination,
    required String purpose,
    String remarks = '',
  }) async {
    try {
      // 1. Conflict / Duplicate check
      final hasActive = await hasActiveOutingRequest(studentUid);
      if (hasActive) {
        throw 'You already have an active outing request in progress. You cannot apply for a new one until the current outing is completed or rejected.';
      }

      // 2. Generate unique human-readable ID
      final readableId = _generateRequestId(outingDate);
      final docRef = _requestsRef.doc();

      final now = DateTime.now();
      final request = OutingRequestModel(
        id: docRef.id,
        requestId: readableId,
        studentUid: studentUid,
        studentName: studentName,
        studentId: studentId,
        hostel: hostel,
        roomNumber: roomNumber,
        outingDate: outingDate,
        leavingTime: leavingTime,
        expectedReturnTime: expectedReturnTime,
        destination: destination.trim(),
        purpose: purpose.trim(),
        remarks: remarks.trim(),
        status: AppConstants.statusPending,
        createdAt: now,
      );

      await docRef.set(request.toMap());
      return request;
    } catch (e) {
      if (e is String) rethrow;
      throw 'Failed to submit outing request: $e';
    }
  }

  // Stream of requests for a specific student (real-time)
  Stream<List<OutingRequestModel>> getStudentRequestsStream(String studentUid) {
    return _requestsRef
        .where('studentUid', isEqualTo: studentUid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => OutingRequestModel.fromFirestore(doc))
          .toList();
      // Sort client-side by createdAt descending to avoid compound index requirements
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // Stream of a single request (real-time updates on status, approval, gate pass)
  Stream<OutingRequestModel?> getRequestStream(String requestId) {
    return _requestsRef.doc(requestId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return OutingRequestModel.fromFirestore(doc);
    });
  }

  // Stream of all requests (for Warden Dashboard & history)
  Stream<List<OutingRequestModel>> getAllRequestsStream() {
    return _requestsRef.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => OutingRequestModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // Stream of Pending Requests (for Warden review queue)
  Stream<List<OutingRequestModel>> getPendingRequestsStream() {
    return _requestsRef
        .where('status', isEqualTo: AppConstants.statusPending)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => OutingRequestModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // Stream of Outside Requests (for Warden currently outside screen)
  Stream<List<OutingRequestModel>> getOutsideRequestsStream() {
    return _requestsRef
        .where('status', isEqualTo: AppConstants.statusOutside)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => OutingRequestModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => a.expectedReturnTime.compareTo(b.expectedReturnTime));
      return list;
    });
  }

  // Stream of Approved Requests (waiting for departure)
  Stream<List<OutingRequestModel>> getApprovedRequestsStream() {
    return _requestsRef
        .where('status', isEqualTo: AppConstants.statusApproved)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => OutingRequestModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => a.leavingTime.compareTo(b.leavingTime));
      return list;
    });
  }

  // WARDEN ACTION: Approve Request
  Future<void> approveRequest({
    required String requestId,
    required String wardenUid,
  }) async {
    try {
      final docRef = _requestsRef.doc(requestId);
      final doc = await docRef.get();
      if (!doc.exists) throw 'Request not found';

      final currentStatus = (doc.data() as Map<String, dynamic>)['status'];
      if (currentStatus != AppConstants.statusPending) {
        throw 'Invalid status transition: Only PENDING requests can be approved.';
      }

      await docRef.update({
        'status': AppConstants.statusApproved,
        'approvedAt': FieldValue.serverTimestamp(),
        'processedBy': wardenUid,
      });
    } catch (e) {
      if (e is String) rethrow;
      throw 'Failed to approve request: $e';
    }
  }

  // WARDEN ACTION: Reject Request with Reason
  Future<void> rejectRequest({
    required String requestId,
    required String wardenUid,
    required String reason,
  }) async {
    try {
      if (reason.trim().isEmpty) {
        throw 'Rejection reason is required.';
      }

      final docRef = _requestsRef.doc(requestId);
      final doc = await docRef.get();
      if (!doc.exists) throw 'Request not found';

      final currentStatus = (doc.data() as Map<String, dynamic>)['status'];
      if (currentStatus != AppConstants.statusPending) {
        throw 'Invalid status transition: Only PENDING requests can be rejected.';
      }

      await docRef.update({
        'status': AppConstants.statusRejected,
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectionReason': reason.trim(),
        'processedBy': wardenUid,
      });
    } catch (e) {
      if (e is String) rethrow;
      throw 'Failed to reject request: $e';
    }
  }

  // WARDEN / GATE ACTION: Mark as OUTSIDE
  Future<void> markOutside({required String requestId}) async {
    try {
      final docRef = _requestsRef.doc(requestId);
      final doc = await docRef.get();
      if (!doc.exists) throw 'Request not found';

      final currentStatus = (doc.data() as Map<String, dynamic>)['status'];
      if (currentStatus != AppConstants.statusApproved) {
        throw 'Invalid status transition: Only APPROVED requests can be marked OUTSIDE.';
      }

      await docRef.update({
        'status': AppConstants.statusOutside,
        'departureAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (e is String) rethrow;
      throw 'Failed to record gate departure: $e';
    }
  }

  // WARDEN / GATE ACTION: Mark as RETURNED
  Future<void> markReturned({required String requestId}) async {
    try {
      final docRef = _requestsRef.doc(requestId);
      final doc = await docRef.get();
      if (!doc.exists) throw 'Request not found';

      final currentStatus = (doc.data() as Map<String, dynamic>)['status'];
      if (currentStatus != AppConstants.statusOutside) {
        throw 'Invalid status transition: Only OUTSIDE requests can be marked RETURNED.';
      }

      await docRef.update({
        'status': AppConstants.statusReturned,
        'returnedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (e is String) rethrow;
      throw 'Failed to record return to hostel: $e';
    }
  }

  // Provision / Setup a Warden user document in Firestore (for secure setup)
  Future<void> provisionWardenProfile({
    required String uid,
    required String name,
    required String email,
    required String hostel,
  }) async {
    await _firestore.collection(AppConstants.collectionUsers).doc(uid).set({
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'studentId': 'WARDEN-AUTH',
      'hostel': hostel.trim(),
      'roomNumber': 'Warden Office',
      'role': AppConstants.roleWarden,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
