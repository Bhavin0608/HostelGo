class Validators {
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? validateStudentId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Student ID is required';
    }
    if (value.trim().length < 3) {
      return 'Enter a valid Student ID';
    }
    return null;
  }

  static String? validateRoomNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Room number is required';
    }
    return null;
  }

  static String? validateTimes({
    required DateTime? leavingTime,
    required DateTime? returnTime,
  }) {
    if (leavingTime == null) {
      return 'Leaving time is required';
    }
    if (returnTime == null) {
      return 'Expected return time is required';
    }
    if (!returnTime.isAfter(leavingTime)) {
      return 'Expected return time must be strictly after leaving time';
    }
    return null;
  }
}
