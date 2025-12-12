import 'dart:typed_data';

class ContactModel {
  const ContactModel({
    required this.id,
    required this.displayName,
    required this.phoneNumbers,
    this.photo,
  });

  final String id;
  final String displayName;
  final List<String> phoneNumbers;
  final Uint8List? photo;

  String? get primaryPhoneNumber =>
      phoneNumbers.isNotEmpty ? phoneNumbers.first : null;

  String get firstLetter =>
      displayName.isNotEmpty ? displayName[0].toUpperCase() : '#';
}
