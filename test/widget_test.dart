import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_gate_pass/models/outing_request_model.dart';
import 'package:hostel_gate_pass/utils/constants.dart';
import 'package:hostel_gate_pass/widgets/status_badge.dart';
import 'package:hostel_gate_pass/widgets/outing_request_card.dart';

void main() {
  testWidgets('StatusBadge renders correct label and icons', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusBadge(status: AppConstants.statusApproved),
        ),
      ),
    );

    expect(find.text('APPROVED'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('StatusBadge renders OVERDUE badge for overdue outside outing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusBadge(status: AppConstants.statusOutside, isOverdue: true),
        ),
      ),
    );

    expect(find.text('OVERDUE'), findsOneWidget);
  });

  testWidgets('OutingRequestCard displays destination, purpose and status', (WidgetTester tester) async {
    final sampleRequest = OutingRequestModel(
      id: 'req_123',
      requestId: 'REQ-20260825-5555',
      studentUid: 'uid_1',
      studentName: 'Rahul Sharma',
      studentId: 'STU2026-104',
      hostel: 'Boys Hostel A',
      roomNumber: '204',
      outingDate: DateTime(2026, 8, 25),
      leavingTime: DateTime(2026, 8, 25, 17, 0),
      expectedReturnTime: DateTime(2026, 8, 25, 21, 0),
      destination: 'City Centre Mall',
      purpose: 'Shopping',
      status: AppConstants.statusApproved,
      createdAt: DateTime(2026, 8, 25, 12, 0),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OutingRequestCard(
            request: sampleRequest,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('City Centre Mall'), findsOneWidget);
    expect(find.text('Shopping'), findsOneWidget);
    expect(find.text('APPROVED'), findsOneWidget);
  });
}
