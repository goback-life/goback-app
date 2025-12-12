extension StringValidation on String {
  /// Validates if the string is a valid password.
  ///
  /// The default pattern requires at least one uppercase letter, one lowercase letter,
  /// one digit, one special character, and a minimum length of 8 characters.
  bool isValidPassword({
    String pattern =
        r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!?@#\$&*~]).{8,}$',
  }) {
    final RegExp regExp = RegExp(pattern);
    return regExp.hasMatch(this);
  }

  /// Validates if the string is a valid email address.
  bool isValidEmail({
    String pattern =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$',
  }) {
    final RegExp regExp = RegExp(pattern);
    return regExp.hasMatch(this);
  }

  /// Validates if the string is a valid URL.
  bool isValidUrl() {
    return Uri.tryParse(this) != null;
  }

  /// Validates if the string is a valid integer.
  bool isValidInt() {
    return int.tryParse(this) != null;
  }

  /// Validates if the string is a valid number.
  bool isValidDouble() {
    return double.tryParse(this) != null;
  }

  /// Validates if the string is a valid phone number.
  bool isValidPhoneNumber({
    String pattern = r'^\+*[1-9]{1}[0-9]{3,14}$',
  }) {
    final RegExp regExp = RegExp(pattern);
    return regExp.hasMatch(this);
  }
}
