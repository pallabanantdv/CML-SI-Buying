abstract final class Validators {
  static String? required(String? value, [String label = 'This field']) =>
      value == null || value.trim().isEmpty ? '$label is required.' : null;
  static String? email(String? value) =>
      value == null ||
          !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())
      ? 'Enter a valid email address.'
      : null;
}
