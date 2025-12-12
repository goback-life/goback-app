class PhoneNumberFormatter {
  static String format(String phoneNumber) {
    if (phoneNumber.length >= 4) {
      final visibleEnd = phoneNumber.substring(phoneNumber.length - 4);

      final stars = '*' * (phoneNumber.length - 4);

      return '$stars$visibleEnd';
    }
    return phoneNumber;
  }
}
