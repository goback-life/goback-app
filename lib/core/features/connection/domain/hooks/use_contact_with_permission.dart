import 'package:cloudless/core/features/connection/domain/hooks/use_phone_contact.dart';
import 'package:cloudless/core/features/connection/domain/providers/get_contact_with_permission_provider.dart';
import 'package:cloudless/core/features/permission/data/exceptions/contact_permission_denied_exception.dart';
import 'package:cloudless/core/features/permission/domain/enums/permission_type.dart';
import 'package:cloudless/core/features/permission/domain/providers/request_permission_provider.dart';
import 'package:cloudless/presentation/components/alerts/main_alert.dart';
import 'package:cloudless/presentation/pages/invite_to_circle/models/contact_model.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

typedef ContactsWithPermissionCallback =
    Future<Result<PhoneContactData>> Function();

ContactsWithPermissionCallback useContactWithPermission(WidgetRef ref) {
  return useCallback(() async {
    final result = await ref.read(getContactWithPermissionProvider.future);

    return result.fold(
      (contactsList) {
        final phoneContactData = _createPhoneContactData(contactsList);
        return Result.success(phoneContactData);
      },
      (failure) async {
        if (failure is ContactPermissionDeniedException &&
            failure.isPermanentlyDenied) {
          final confirmed =
              await MainAlert.showFull<bool>(
                context: ref.context,
                title: translator.translate(
                  'permission.permanently_denied.title',
                ),
                content: Text(
                  translator.translate('permission.permanently_denied.message'),
                ),
                primaryButtonText: translator.translate(
                  'permission.permanently_denied.open_settings',
                ),
                onPrimaryPressed: () => Navigator.of(ref.context).pop(true),
                secondaryButtonText: translator.translate(
                  'components.alert.cancel',
                ),
                onSecondaryPressed: () => Navigator.of(ref.context).pop(false),
              ) ??
              false;

          if (confirmed) {
            openAppSettings();
          }

          return Result.failure(failure);
        } else if (failure is ContactPermissionDeniedException &&
            !failure.isPermanentlyDenied) {
          await ref.read(
            requestPermissionProvider(type: PermissionType.contact).future,
          );
          final retryResult = await ref.read(
            getContactWithPermissionProvider.future,
          );
          return retryResult.fold((contactsList) {
            final phoneContactData = _createPhoneContactData(contactsList);
            return Result.success(phoneContactData);
          }, (error) => Result.failure(error));
        }

        return Result.failure(failure);
      },
    );
  }, [ref]);
}

PhoneContactData _createPhoneContactData(List<ContactModel> contacts) {
  const searchQuery = '';

  return PhoneContactData(
    groupedContacts: _groupContacts(contacts, searchQuery),
    searchQuery: searchQuery,
    updateSearchQuery: (_) {},
    isLoading: false,
    hasPermission: true,
    isEmpty: contacts.isEmpty,
    error: null,
  );
}

Map<String, List<ContactModel>> _groupContacts(
  List<ContactModel> contacts,
  String searchQuery,
) {
  final filteredContacts = searchQuery.isEmpty
      ? contacts
      : contacts
            .where(
              (contact) =>
                  contact.displayName.toLowerCase().contains(
                    searchQuery.toLowerCase(),
                  ) ||
                  contact.phoneNumbers.any(
                    (phone) => phone.contains(searchQuery),
                  ),
            )
            .toList();

  final grouped = <String, List<ContactModel>>{};

  for (final contact in filteredContacts) {
    final firstLetter = contact.displayName.isNotEmpty
        ? contact.displayName[0].toUpperCase()
        : '#';

    grouped.putIfAbsent(firstLetter, () => []).add(contact);
  }

  grouped.forEach((key, value) {
    value.sort((a, b) => a.displayName.compareTo(b.displayName));
  });

  return grouped;
}
