/// Utility class for normalizing phone numbers consistently across the app.
class PhoneNumberNormalizer {
  /// Normalizes phone numbers by removing all non-digit characters
  /// Removes the + prefix to match auth.users format (country code without +)
  /// 
  /// Example:
  /// - "+1 (555) 123-4567" -> "15551234567"
  /// - "1-555-123-4567" -> "15551234567"
  /// - "+39 123 456 7890" -> "391234567890"
  /// - "15551234567" -> "15551234567"
  static String normalize(String phoneNumber) {
    // Remove all non-digit characters (including +)
    return phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
  }

  /// Normalizes a list of phone numbers
  static List<String> normalizeList(List<String> phoneNumbers) {
    return phoneNumbers
        .map((phone) => normalize(phone))
        .where((phone) => phone.isNotEmpty)
        .toList();
  }
}

