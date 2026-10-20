import 'package:flutter_test/flutter_test.dart';
import 'package:hostel_gate_pass/utils/validators.dart';

void main() {
  group('Validators - validateRequired', () {
    test('returns error when value is null or empty or whitespace', () {
      expect(Validators.validateRequired(null, 'Name'), 'Name is required');
      expect(Validators.validateRequired('', 'Name'), 'Name is required');
      expect(Validators.validateRequired('   ', 'Name'), 'Name is required');
    });

    test('returns null when valid value is provided', () {
      expect(Validators.validateRequired('John Doe', 'Name'), isNull);
    });
  });

  group('Validators - validateEmail', () {
    test('returns error when email is null or empty', () {
      expect(Validators.validateEmail(null), 'Email is required');
      expect(Validators.validateEmail(''), 'Email is required');
      expect(Validators.validateEmail('   '), 'Email is required');
    });

    test('returns error when email format is invalid', () {
      expect(Validators.validateEmail('plainaddress'), 'Enter a valid email address');
      expect(Validators.validateEmail('@missingusername.com'), 'Enter a valid email address');
      expect(Validators.validateEmail('username@.com'), 'Enter a valid email address');
      expect(Validators.validateEmail('username@domain'), 'Enter a valid email address');
    });

    test('returns null for valid emails', () {
      expect(Validators.validateEmail('student@university.edu'), isNull);
      expect(Validators.validateEmail('warden.hostel@ddu.ac.in'), isNull);
    });
  });

  group('Validators - validatePassword', () {
    test('returns error when password is null or empty', () {
      expect(Validators.validatePassword(null), 'Password is required');
      expect(Validators.validatePassword(''), 'Password is required');
    });

    test('returns error when password is less than 6 characters', () {
      expect(
        Validators.validatePassword('12345'),
        'Password must be at least 6 characters long',
      );
    });

    test('returns null when password is 6 characters or longer', () {
      expect(Validators.validatePassword('123456'), isNull);
      expect(Validators.validatePassword('StrongPass123!'), isNull);
    });
  });

  group('Validators - validateConfirmPassword', () {
    test('returns error when confirm password is null or empty', () {
      expect(Validators.validateConfirmPassword(null, 'secret123'), 'Please confirm your password');
      expect(Validators.validateConfirmPassword('', 'secret123'), 'Please confirm your password');
    });

    test('returns error when passwords do not match', () {
      expect(
        Validators.validateConfirmPassword('secret456', 'secret123'),
        'Passwords do not match',
      );
    });

    test('returns null when passwords match exactly', () {
      expect(Validators.validateConfirmPassword('secret123', 'secret123'), isNull);
    });
  });

  group('Validators - validateStudentId', () {
    test('returns error when student ID is null or empty', () {
      expect(Validators.validateStudentId(null), 'Student ID is required');
      expect(Validators.validateStudentId(''), 'Student ID is required');
      expect(Validators.validateStudentId('   '), 'Student ID is required');
    });

    test('returns error when student ID length is less than 3', () {
      expect(Validators.validateStudentId('12'), 'Enter a valid Student ID');
    });

    test('returns null when student ID is valid', () {
      expect(Validators.validateStudentId('23IT045'), isNull);
      expect(Validators.validateStudentId('STU-101'), isNull);
    });
  });

  group('Validators - validateRoomNumber', () {
    test('returns error when room number is null or empty', () {
      expect(Validators.validateRoomNumber(null), 'Room number is required');
      expect(Validators.validateRoomNumber(''), 'Room number is required');
      expect(Validators.validateRoomNumber('   '), 'Room number is required');
    });

    test('returns null when room number is valid', () {
      expect(Validators.validateRoomNumber('302'), isNull);
      expect(Validators.validateRoomNumber('A-104'), isNull);
    });
  });

  group('Validators - validateTimes', () {
    final now = DateTime(2026, 10, 17, 10, 0);

    test('returns error when leavingTime is null', () {
      expect(
        Validators.validateTimes(leavingTime: null, returnTime: now.add(const Duration(hours: 2))),
        'Leaving time is required',
      );
    });

    test('returns error when returnTime is null', () {
      expect(
        Validators.validateTimes(leavingTime: now, returnTime: null),
        'Expected return time is required',
      );
    });

    test('returns error when returnTime is before or equal to leavingTime', () {
      expect(
        Validators.validateTimes(
          leavingTime: now,
          returnTime: now,
        ),
        'Expected return time must be strictly after leaving time',
      );

      expect(
        Validators.validateTimes(
          leavingTime: now,
          returnTime: now.subtract(const Duration(hours: 1)),
        ),
        'Expected return time must be strictly after leaving time',
      );
    });

    test('returns null when returnTime is strictly after leavingTime', () {
      expect(
        Validators.validateTimes(
          leavingTime: now,
          returnTime: now.add(const Duration(hours: 2)),
        ),
        isNull,
      );
    });
  });
}
