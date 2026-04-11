import 'package:cloudless/core/features/auth/domain/hooks/use_check_phone_numbers.dart';
import 'package:cloudless/core/features/auth/utilities/phone_number_normalizer.dart';
import 'package:cloudless/presentation/pages/invite_to_circle/components/invite_to_circle_contact_item.dart';
import 'package:cloudless/presentation/pages/invite_to_circle/invite_to_circle_layout.dart';
import 'package:cloudless/presentation/pages/invite_to_circle/models/contact_model.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class InviteToCircleContactList extends HookConsumerWidget
    with MainLayout, InviteToCircleLayout {
  const InviteToCircleContactList({
    required this.groupedContacts,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onContactTap,
    super.key,
  });

  final Map<String, List<ContactModel>> groupedContacts;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<ContactModel> onContactTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    // Extract all phone numbers from contacts - memoized to prevent excessive RPC calls
    final allPhoneNumbers = useMemoized(() {
      final phoneNumbers = <String>[];
      for (final contacts in groupedContacts.values) {
        for (final contact in contacts) {
          if (contact.primaryPhoneNumber != null) {
            phoneNumbers.add(contact.primaryPhoneNumber!);
          }
        }
      }
      return phoneNumbers;
    }, [groupedContacts]);

    // Check which phone numbers have accounts - only called when phone numbers list changes
    final existingPhones = useCheckPhoneNumbers(ref, allPhoneNumbers);

    // Create a map of normalized phone numbers to account status - memoized
    final phoneAccountMap = useMemoized(() {
      final map = <String, bool>{};
      for (final phone in allPhoneNumbers) {
        final normalized = PhoneNumberNormalizer.normalize(phone);
        map[normalized] = existingPhones.contains(normalized);
      }
      return map;
    }, [allPhoneNumbers, existingPhones]);

    return Expanded(
      child: groupedContacts.isEmpty
          ? Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: verticalPadding * 2),
                child: Text(
                  translator.translate('components.searchbar.no_results'),
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.only(bottom: verticalPadding),
              itemCount: groupedContacts.length,
              itemBuilder: (context, index) {
                final entry = groupedContacts.entries.elementAt(index);
                final letter = entry.key;
                final contacts = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        top: index > 0 ? verticalSpacing : 0.0,
                        left: horizontalMargin,
                        bottom: verticalPadding / 2,
                      ),
                      child: Text(
                        letter,
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.scrim,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      child: Column(
                        children: [
                          for (int i = 0; i < contacts.length; i++) ...[
                            InviteToCircleContactItem(
                              contact: contacts[i],
                              onTap: () => onContactTap(contacts[i]),
                              hasAccount: contacts[i].primaryPhoneNumber != null
                                  ? phoneAccountMap[PhoneNumberNormalizer.normalize(
                                          contacts[i].primaryPhoneNumber!,
                                        )] ??
                                        false
                                  : false,
                            ),
                            if (i < contacts.length - 1)
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: colorScheme.surfaceContainerHighest,
                                indent:
                                    horizontalPadding +
                                    40.0 +
                                    horizontalPadding,
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
