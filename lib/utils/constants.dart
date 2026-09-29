class AppConstants {
  // App Info from Design
  static const String appName = 'HostelGo';
  static const String appTagline = 'Simple. Digital. Hassle-free.';

  // User Roles
  static const String roleStudent = 'student';
  static const String roleWarden = 'warden';

  // Request Statuses
  static const String statusPending = 'pending';
  static const String statusApproved = 'approved';
  static const String statusRejected = 'rejected';
  static const String statusOutside = 'outside';
  static const String statusReturned = 'returned';

  // Feedback Statuses
  static const String feedbackSubmitted = 'submitted';
  static const String feedbackReviewed = 'reviewed';

  // Firestore Collections
  static const String collectionUsers = 'users';
  static const String collectionRequests = 'outing_requests';
  static const String collectionFeedbacks = 'student_feedbacks';

  // Common Outing Purposes
  static const List<String> commonPurposes = [
    'Shopping',
    'Medical / Doctor Appointment',
    'Home Visit',
    'Coaching / Classes',
    'Exam / Project Work',
    'Family Event',
    'Emergency',
    'Personal / Other',
  ];

  // Feedback Categories
  static const List<String> feedbackCategories = [
    'Outing & Gate Process',
    'Gate Security & Timing',
    'Warden & Administration Support',
    'Hostel Facilities & Rooms',
    'App Experience & Technical',
    'General Suggestion / Grievance',
  ];

  // Common Hostels
  static const List<String> hostelBlocks = [
    'Boys Hostel A',
    'Boys Hostel B',
    'Boys Hostel C',
    'Girls Hostel D',
    'Girls Hostel E',
    'PG Hostel F',
  ];
}
