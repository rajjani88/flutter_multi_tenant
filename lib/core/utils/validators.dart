/// Centralized validation utilities for the application.
class Validators {
  Validators._();

  /// Standard RFC 5322 simplified email validation regular expression.
  /// Requires local part, @, domain part, and a top-level domain of at least 2 letters.
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  /// Validates email address format and presence.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final trimmed = value.trim();
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validates password presence and minimum length (at least 6 characters).
  static String? validatePassword(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }

  /// Validates display/full name presence and minimum length.
  static String? validateName(String? value, {int minLength = 2}) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < minLength) {
      return 'Name must be at least $minLength characters';
    }
    return null;
  }

  /// Generic required field validator.
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}
