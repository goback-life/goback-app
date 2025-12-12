import 'package:cloudless/presentation/pages/invite_to_circle/components/invite_to_circle_contact_item.dart';
import 'package:cloudless/presentation/pages/invite_to_circle/invite_to_circle_layout.dart';
import 'package:cloudless/presentation/pages/invite_to_circle/models/contact_model.dart';
import 'package:cloudless/presentation/utilities/main_layout.dart';
import 'package:dedecube_startup/dedecube_startup.dart';
import 'package:flutter/material.dart';

class InviteToCircleContactList extends StatelessWidget
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

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
                    Padding(
                      padding: const EdgeInsets.symmetric(),
                      child: Container(
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
                    ),
                  ],
                );
              },
            ),
    );
  }
}
