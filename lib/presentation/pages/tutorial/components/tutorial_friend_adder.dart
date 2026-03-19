import 'package:cloudless/core/features/auth/utilities/phone_number_normalizer.dart';
import 'package:cloudless/core/features/connection/domain/hooks/use_contact_with_permission.dart';
import 'package:cloudless/core/features/connection/domain/hooks/use_phone_contact.dart';
import 'package:cloudless/core/features/connection/domain/hooks/use_search_users.dart';
import 'package:cloudless/core/features/connection/domain/models/connection_request_model.dart';
import 'package:cloudless/core/features/connection/domain/providers/connection_request_actions_provider.dart';
import 'package:cloudless/presentation/components/glass/app_glass_container.dart';
import 'package:cloudless/presentation/components/glass/glass_config.dart';
import 'package:cloudless/presentation/pages/invite_to_circle/hooks/use_sms_launch.dart';
import 'package:cloudless/presentation/pages/invite_to_circle/models/contact_model.dart';
import 'package:cloudless/presentation/pages/tutorial/tutorial_layout.dart';
import 'package:cloudless/presentation/themes/constants/main_colors.dart';
import 'package:cloudless/presentation/themes/constants/main_font_families.dart';
import 'package:dedecube_core/dedecube_core.dart';
import 'package:flutter/material.dart';

/// Friend-adding panel for the tutorial lockout phase.
///
/// Two tabs (Invite user, Existing user) with a progress
/// indicator showing friend requests sent out of 4.
class TutorialFriendAdder extends HookConsumerWidget {
  const TutorialFriendAdder({
    super.key,
    required this.friendsAdded,
    required this.onFriendAdded,
  });

  final int friendsAdded;
  final VoidCallback onFriendAdded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = useState(0); // 0 = Invite user, 1 = Existing user

    return AppGlassContainer(
      config: const GlassConfig(
        variant: GlassVariant.regular,
        cornerRadius: 24,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress indicator
            _ProgressRow(friendsAdded: friendsAdded),
            const SizedBox(height: 16),
            // Tab switcher
            _TabSwitcher(
              selectedTab: selectedTab.value,
              onTabChanged: (i) => selectedTab.value = i,
            ),
            const SizedBox(height: 16),
            // Tab content
            Expanded(
              child: selectedTab.value == 0
                  ? _InviteTab(onFriendAdded: onFriendAdded)
                  : _SearchTab(onFriendAdded: onFriendAdded),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.friendsAdded});

  final int friendsAdded;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$friendsAdded of 4 requests sent',
          style: const TextStyle(
            fontFamily: MainFontFamilies.quicksand,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: MainColors.dark,
            decoration: TextDecoration.none,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final filled = i < friendsAdded;
            return Container(
              width: TutorialLayout.progressDotSize,
              height: TutorialLayout.progressDotSize,
              margin: EdgeInsets.symmetric(
                horizontal: TutorialLayout.progressDotSpacing / 2,
              ),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? MainColors.accent : MainColors.grey300,
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _TabSwitcher extends StatelessWidget {
  const _TabSwitcher({
    required this.selectedTab,
    required this.onTabChanged,
  });

  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TabButton(
          label: 'Invite user',
          isSelected: selectedTab == 0,
          onTap: () => onTabChanged(0),
        ),
        const SizedBox(width: 8),
        _TabButton(
          label: 'Existing user',
          isSelected: selectedTab == 1,
          onTap: () => onTabChanged(1),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isSelected
                ? MainColors.accent.withValues(alpha: 0.3)
                : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? MainColors.accent
                  : MainColors.grey300.withValues(alpha: 0.5),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: MainFontFamilies.quicksand,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? MainColors.accent : MainColors.grey500,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }
}

/// SMS invite tab — search contacts by name or phone, tap to send invite.
class _InviteTab extends HookConsumerWidget {
  const _InviteTab({required this.onFriendAdded});

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
        // Unified search field
        SizedBox(
          height: 48,
          child: TextField(
            onChanged: (v) => searchQuery.value = v,
            onTapOutside: (_) =>
                FocusManager.instance.primaryFocus?.unfocus(),
            cursorColor: MainColors.dark,
            style: const TextStyle(color: MainColors.dark, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search by name or phone',
              hintStyle: const TextStyle(
                color: MainColors.grey500,
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: MainColors.grey500,
                size: 20,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: MainColors.grey300.withValues(alpha: 0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: MainColors.grey300.withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: MainColors.accent),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Contact list (with optional "send to number" row)
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
      return const Center(
        child: Text(
          'Grant contacts access to invite friends',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: MainFontFamilies.quicksand,
            fontSize: 13,
            color: MainColors.grey500,
            decoration: TextDecoration.none,
          ),
        ),
      );
    }

    final phoneOffset = showPhoneOption ? 1 : 0;
    final totalCount = contacts.length + phoneOffset;

    if (totalCount == 0) {
      return const Center(
        child: Text(
          'No contacts found',
          style: TextStyle(
            fontFamily: MainFontFamilies.quicksand,
            fontSize: 13,
            color: MainColors.grey500,
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
                      child: Icon(
                        Icons.phone,
                        color: MainColors.white,
                        size: 16,
                      ),
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
                  const Icon(
                    Icons.send_rounded,
                    color: MainColors.accent,
                    size: 18,
                  ),
                ],
              ),
            ),
          );
        }

        final contact = contacts[index - phoneOffset];
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
                  decoration: const BoxDecoration(
                    color: MainColors.grey300,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      contact.firstLetter,
                      style: const TextStyle(
                        fontFamily: MainFontFamilies.quicksand,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: MainColors.white,
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
                const Icon(
                  Icons.send_rounded,
                  color: MainColors.accent,
                  size: 18,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Username search tab.
class _SearchTab extends HookConsumerWidget {
  const _SearchTab({
    required this.onFriendAdded,
  });

  final VoidCallback onFriendAdded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = useSearchUsers(ref);
    final sendingIds = useState<Set<String>>({});

    Future<void> addFriend(String userId) async {
      if (sendingIds.value.contains(userId)) return;
      sendingIds.value = {...sendingIds.value, userId};

      final result = await ref.read(
        sendConnectionRequestProvider(userId).future,
      );
      result.fold(
        (_) => onFriendAdded(),
        (_) {},
      );

      sendingIds.value = {...sendingIds.value}..remove(userId);
    }

    return Column(
      children: [
        // Search input
        SizedBox(
          height: 48,
          child: TextField(
            onChanged: search.updateQuery,
            cursorColor: MainColors.dark,
            style: const TextStyle(
              color: MainColors.dark,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Search by username',
              hintStyle: const TextStyle(
                color: MainColors.grey500,
                fontSize: 14,
              ),
              prefixIcon:
                  const Icon(Icons.search, color: MainColors.grey500, size: 20),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: MainColors.grey300.withValues(alpha: 0.5),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: MainColors.grey300.withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: MainColors.accent),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Results
        Expanded(
          child: search.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: MainColors.accent),
                )
              : ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: search.results.length,
                  itemBuilder: (context, index) {
                    final (profile, status) = search.results[index];
                    final isSending =
                        sendingIds.value.contains(profile.id);
                    final isAlreadyConnected =
                        status == ConnectionStatus.connected;
                    final isPending =
                        status == ConnectionStatus.pendingOutgoing;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: MainColors.grey300,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                profile.username.isNotEmpty
                                    ? profile.username[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontFamily: MainFontFamilies.quicksand,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: MainColors.white,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              profile.username,
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
                          if (isAlreadyConnected)
                            const Text(
                              'Connected',
                              style: TextStyle(
                                fontFamily: MainFontFamilies.quicksand,
                                fontSize: 12,
                                color: MainColors.grey500,
                                decoration: TextDecoration.none,
                              ),
                            )
                          else if (isPending)
                            const Text(
                              'Pending',
                              style: TextStyle(
                                fontFamily: MainFontFamilies.quicksand,
                                fontSize: 12,
                                color: MainColors.grey500,
                                decoration: TextDecoration.none,
                              ),
                            )
                          else
                            GestureDetector(
                              onTap: isSending
                                  ? null
                                  : () => addFriend(profile.id),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: MainColors.accent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: isSending
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: MainColors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Add',
                                        style: TextStyle(
                                          fontFamily:
                                              MainFontFamilies.quicksand,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: MainColors.white,
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
