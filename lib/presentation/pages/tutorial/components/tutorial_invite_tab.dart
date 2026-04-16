import 'package:cloudless/core/features/auth/utilities/phone_number_normalizer.dart';
import 'package:cloudless/core/features/connection/domain/hooks/use_contact_with_permission.dart';
import 'package:cloudless/core/features/connection/domain/hooks/use_phone_contact.dart';
import 'package:cloudless/presentation/pages/invite_to_circle/hooks/use_sms_launch.dart';
import 'package:cloudless/presentation/pages/invite_to_circle/models/contact_model.dart';
import 'package:cloudless/presentation/pages/tutorial/components/tutorial_search_field.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

/// SMS invite tab -- search contacts by name or phone, tap to send invite.
class TutorialInviteTab extends HookConsumerWidget {
  const TutorialInviteTab({required this.onFriendAdded, super.key});

  final VoidCallback onFriendAdded;

  /// Returns true when [input] looks like a phone number (mostly digits).
  static bool _looksLikePhone(String input) {
    final digitsOnly = input.replaceAll(RegExp(r'[^\d]'), '');
    return digitsOnly.length >= 4 && digitsOnly.length / input.length > 0.5;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final getContacts = useContactWithPermission(ref);
    final contactsData = useState<PhoneContactData?>(null);
    final inviteState = useSmsSender(ref);
    final searchQuery = useState('');

    // Load contacts on mount
    useEffect(() {
      Future<void> load() async {
        final result = await getContacts();
        result.fold(
          (data) {
            if (context.mounted) contactsData.value = data;
          },
          (_) {
            if (context.mounted) {
              contactsData.value = PhoneContactData(
                groupedContacts: {},
                searchQuery: '',
                updateSearchQuery: (_) {},
                isLoading: false,
                hasPermission: false,
                isEmpty: true,
              );
            }
          },
        );
      }

      load();
      return null;
    }, []);

    // Track SMS sends to count as friend request sent.
    final prevLoading = useRef(false);
    useEffect(() {
      if (prevLoading.value && !inviteState.isLoading) {
        if (inviteState.error == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onFriendAdded();
          });
        }
      }
      prevLoading.value = inviteState.isLoading;
      return null;
    }, [inviteState.isLoading]);

    // Filter contacts locally by name or phone number.
    final allContacts = useMemoized(() {
      final data = contactsData.value;
      if (data == null) return <ContactModel>[];
      final list = <ContactModel>[];
      for (final group in data.groupedContacts.values) {
        list.addAll(group);
      }
      return list;
    }, [contactsData.value]);

    final filteredContacts = useMemoized(() {
      final q = searchQuery.value.toLowerCase();
      if (q.isEmpty) return allContacts;
      return allContacts.where((c) {
        return c.displayName.toLowerCase().contains(q) ||
            c.phoneNumbers.any((p) => p.contains(q));
      }).toList();
    }, [allContacts, searchQuery.value]);

    final showPhoneOption =
        searchQuery.value.isNotEmpty && _looksLikePhone(searchQuery.value);

    return Column(
      children: [
        TutorialSearchField(
          hintText: 'Search by name or phone',
          onChanged: (v) => searchQuery.value = v,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _buildContactList(
            contactsData.value,
            filteredContacts,
            inviteState,
            showPhoneOption: showPhoneOption,
            rawQuery: searchQuery.value,
          ),
        ),
      ],
    );
  }

  Widget _buildContactList(
    PhoneContactData? data,
    List<ContactModel> contacts,
    InviteSendingState inviteState, {
    required bool showPhoneOption,
    required String rawQuery,
  }) {
    if (data == null) {
      return const Center(
        child: CircularProgressIndicator(color: MainColors.accent),
      );
    }
    if (!data.hasPermission) {
      return Center(
        child: Text(
          'Grant contacts access to invite friends',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: MainFontFamilies.quicksand,
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            decoration: TextDecoration.none,
          ),
        ),
      );
    }

    final phoneOffset = showPhoneOption ? 1 : 0;
    final totalCount = contacts.length + phoneOffset;

    if (totalCount == 0) {
      return Center(
        child: Text(
          'No contacts found',
          style: TextStyle(
            fontFamily: MainFontFamilies.quicksand,
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            decoration: TextDecoration.none,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: totalCount,
      itemBuilder: (context, index) {
        // First row: "Send invite to <number>" when input is phone-like
        if (showPhoneOption && index == 0) {
          return _PhoneInviteRow(rawQuery: rawQuery, inviteState: inviteState);
        }

        final contact = contacts[index - phoneOffset];
        return _ContactRow(contact: contact, inviteState: inviteState);
      },
    );
  }
}

class _PhoneInviteRow extends StatelessWidget {
  const _PhoneInviteRow({required this.rawQuery, required this.inviteState});

  final String rawQuery;
  final InviteSendingState inviteState;

  @override
  Widget build(BuildContext context) {
    final normalized = PhoneNumberNormalizer.normalize(rawQuery);
    return GestureDetector(
      onTap: inviteState.isLoading
          ? null
          : () {
              final contact = ContactModel.fromPhoneNumber(normalized);
              inviteState.sendInvite(contact);
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: MainColors.accent,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.phone, color: MainColors.white, size: 16),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Send invite to $normalized',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: MainFontFamilies.quicksand,
                  fontSize: 14,
                  color: MainColors.accent,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            const Icon(Icons.send_rounded, color: MainColors.accent, size: 18),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.contact, required this.inviteState});

  final ContactModel contact;
  final InviteSendingState inviteState;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: inviteState.isLoading
          ? null
          : () => inviteState.sendInvite(contact),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  contact.firstLetter,
                  style: TextStyle(
                    fontFamily: MainFontFamilies.quicksand,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                contact.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: MainFontFamilies.quicksand,
                  fontSize: 14,
                  color: MainColors.dark,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            const Icon(Icons.send_rounded, color: MainColors.accent, size: 18),
          ],
        ),
      ),
    );
  }
}
