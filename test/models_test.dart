import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_gate_pass/models/user_model.dart';
import 'package:hostel_gate_pass/models/outing_request_model.dart';
import 'package:hostel_gate_pass/utils/constants.dart';

void main() {
  group('UserModel Tests', () {
    test('User serialization and role helpers work correctly', () {
      final user = UserModel(
        uid: 'user_123',
        name: 'Rahul Sharma',
        email: 'rahul@hostel.edu',
        studentId: '23CS104',
        hostel: 'Block A - Boys Hostel',
        roomNumber: '204',
        role: AppConstants.roleStudent,
        createdAt: DateTime(2026, 8, 25),
      );

      expect(user.isStudent, isTrue);
      expect(user.isWarden, isFalse);

      final map = user.toMap();
      expect(map['name'], 'Rahul Sharma');
      expect(map['role'], 'student');
      expect(map['studentId'], '23CS104');
    });
  });

  group('OutingRequestModel Tests', () {
    test('Status flags and lifecycle checks work as expected', () {
      final pendingReq = OutingRequestModel(
        id: 'doc_1',
        requestId: 'REQ-20260825-1001',
        studentUid: 'user_123',
        studentName: 'Rahul Sharma',
        studentId: '23CS104',
        hostel: 'Block A',
        roomNumber: '204',
        outingDate: DateTime(2026, 8, 25),
        leavingTime: DateTime(2026, 8, 25, 17, 0),
        expectedReturnTime: DateTime(2026, 8, 25, 21, 0),
        destination: 'City Centre',
        purpose: 'Shopping',
        status: AppConstants.statusPending,
        createdAt: DateTime(2026, 8, 25, 16, 0),
      );

      expect(pendingReq.isPending, isTrue);
      expect(pendingReq.isApproved, isFalse);
      expect(pendingReq.isActive, isTrue);
      expect(pendingReq.displayRequestId, 'REQ-20260825-1001');

      final approvedReq = OutingRequestModel(
        id: 'doc_2',
        requestId: 'REQ-20260825-1002',
        studentUid: 'user_123',
        studentName: 'Rahul Sharma',
        studentId: '23CS104',
        hostel: 'Block A',
        roomNumber: '204',
        outingDate: DateTime(2026, 8, 25),
        leavingTime: DateTime(2026, 8, 25, 17, 0),
        expectedReturnTime: DateTime(2026, 8, 25, 21, 0),
        destination: 'City Centre',
        purpose: 'Shopping',
        status: AppConstants.statusApproved,
        createdAt: DateTime(2026, 8, 25, 16, 0),
        approvedAt: DateTime(2026, 8, 25, 16, 30),
      );

      expect(approvedReq.isApproved, isTrue);
      expect(approvedReq.isActive, isTrue);
      expect(approvedReq.isOutside, isFalse);

      final returnedReq = OutingRequestModel(
        id: 'doc_3',
        requestId: 'REQ-20260825-1003',
        studentUid: 'user_123',
        studentName: 'Rahul Sharma',
        studentId: '23CS104',
        hostel: 'Block A',
        roomNumber: '204',
        outingDate: DateTime(2026, 8, 25),
        leavingTime: DateTime(2026, 8, 25, 17, 0),
        expectedReturnTime: DateTime(2026, 8, 25, 21, 0),
        destination: 'City Centre',
        purpose: 'Shopping',
        status: AppConstants.statusReturned,
        createdAt: DateTime(2026, 8, 25, 16, 0),
        returnedAt: DateTime(2026, 8, 25, 20, 45),
      );

      expect(returnedReq.isReturned, isTrue);
      expect(returnedReq.isActive, isFalse);
    });

    test('Overdue detection correctly flags past return time when outside', () {
      final pastReturnTime = DateTime.now().subtract(const Duration(minutes: 30));
      final overdueReq = OutingRequestModel(
        id: 'doc_4',
        requestId: 'REQ-20260825-1004',
        studentUid: 'user_123',
        studentName: 'Rahul Sharma',
        studentId: '23CS104',
        hostel: 'Block A',
        roomNumber: '204',
        outingDate: DateTime.now(),
        leavingTime: DateTime.now().subtract(const Duration(hours: 4)),
        expectedReturnTime: pastReturnTime,
        destination: 'City Centre',
        purpose: 'Shopping',
        status: AppConstants.statusOutside,
        createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      );

      expect(overdueReq.isOverdue, isTrue);
    });

    test('Multi-day home leave helpers correctly calculate durations', () {
      final multiDayLeave = OutingRequestModel(
        id: 'doc_5',
        requestId: 'REQ-20260825-1005',
        studentUid: 'user_123',
        studentName: 'Rahul Sharma',
        studentId: '23CS104',
        hostel: 'Block A',
        roomNumber: '204',
        outingDate: DateTime(2026, 8, 28),
        leavingTime: DateTime(2026, 8, 28, 17, 0),
        expectedReturnTime: DateTime(2026, 9, 1, 20, 0),
        destination: 'Home, Ahmedabad',
        purpose: 'Home Visit',
        status: AppConstants.statusPending,
        createdAt: DateTime(2026, 8, 27, 10, 0),
      );

      expect(multiDayLeave.isMultiDay, isTrue);
      expect(multiDayLeave.durationDays, 5);
      expect(multiDayLeave.durationLabel, contains('5 Days'));
      expect(multiDayLeave.formattedTimeSummary, contains('5 Days'));
    });
  });
}
