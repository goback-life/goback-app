import 'dart:typed_data';

import 'package:cloudless/presentation/pages/invite_to_circle/models/contact_model.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class PhoneContactData {
  const PhoneContactData({
    required this.groupedContacts,
    required this.searchQuery,
    required this.updateSearchQuery,
    required this.isLoading,
    required this.hasPermission,
    required this.isEmpty,
    this.error,
  });

  final Map<String, List<ContactModel>> groupedContacts;
  final String searchQuery;
  final ValueChanged<String> updateSearchQuery;
  final bool isLoading;
  final bool hasPermission;
  final bool isEmpty;
  final String? error;
}

PhoneContactData usePhoneContacts(WidgetRef ref) {
  final searchQuery = useState<String>('');
  final contacts = useState<List<ContactModel>>([]);
  final isLoading = useState<bool>(false);
  final hasPermission = useState<bool>(false);
  final error = useState<String?>(null);
  final mounted = useRef(true);

  useEffect(() {
    return () {
      mounted.value = false;
    };
  }, []);

  Future<void> loadContacts() async {
    if (!mounted.value) {
      return;
    }

    isLoading.value = true;
    error.value = null;

    final phoneContacts = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: true,
    );

    if (!mounted.value) {
      return;
    }

    final validContacts = <ContactModel>[];

    for (final contact in phoneContacts) {
      if (contact.phones.isNotEmpty) {
        final phoneNumbers = contact.phones
            .map((phone) => phone.number)
            .where((number) => number.isNotEmpty)
            .toList();

        if (phoneNumbers.isNotEmpty) {
          Uint8List? photo;
          if (contact.photo != null && contact.photo!.isNotEmpty) {
            photo = contact.photo;
          }

          validContacts.add(
            ContactModel(
              id: contact.id,
              displayName: contact.displayName.isNotEmpty
                  ? contact.displayName
                  : phoneNumbers.first,
              phoneNumbers: phoneNumbers,
              photo: photo,
            ),
          );
        }
      }
    }

    if (!mounted.value) {
      return;
    }

    contacts.value = validContacts;
  }

  useEffect(() {
    Future<void> checkPermissionAndLoadContacts() async {
      if (!mounted.value) {
        return;
      }

      final permissionStatus = await Permission.contacts.status;
      hasPermission.value = permissionStatus.isGranted;

      if (permissionStatus.isGranted) {
        await loadContacts();
      }
    }

    checkPermissionAndLoadContacts();
    return null;
  }, []);

  final groupedContacts = useMemoized(() {
    return _groupAndFilterContacts(contacts.value, searchQuery.value);
  }, [contacts.value, searchQuery.value]);

  return PhoneContactData(
    groupedContacts: groupedContacts,
    searchQuery: searchQuery.value,
    updateSearchQuery: (query) => searchQuery.value = query,
    isLoading: isLoading.value,
    hasPermission: hasPermission.value,
    isEmpty: contacts.value.isEmpty && hasPermission.value && !isLoading.value,
    error: error.value,
  );
}

Map<String, List<ContactModel>> _groupAndFilterContacts(
  List<ContactModel> contacts,
  String searchQuery,
) {
  final filteredContacts = searchQuery.isEmpty
      ? contacts
      : contacts.where((contact) {
          final displayName = contact.displayName.toLowerCase();
          final query = searchQuery.toLowerCase();

          return displayName.contains(query) ||
              contact.phoneNumbers.any((phone) => phone.contains(query));
        }).toList();

  final grouped = <String, List<ContactModel>>{};

  for (final contact in filteredContacts) {
    final firstLetter = contact.firstLetter;
    grouped.putIfAbsent(firstLetter, () => []).add(contact);
  }

  final sortedKeys = grouped.keys.toList()..sort();
  final sortedGrouped = <String, List<ContactModel>>{};

  for (final key in sortedKeys) {
    final sortedContacts = grouped[key]!
      ..sort(
        (a, b) =>
            a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
      );
    sortedGrouped[key] = sortedContacts;
  }

  return sortedGrouped;
}
