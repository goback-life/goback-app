/// Strips all non-digit characters to match auth.users format (no + prefix).
class PhoneNumberNormalizer {
  static String normalize(String phoneNumber) {
    return phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
  }

  static List<String> normalizeList(List<String> phoneNumbers) {
    return phoneNumbers
        .map((phone) => normalize(phone))
        .where((phone) => phone.isNotEmpty)
        .toList();
  }
}
